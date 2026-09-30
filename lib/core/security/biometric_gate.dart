import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme.dart';
import 'security_controller.dart';
import 'six_digit_pin_view.dart';

/// Notifier tracking whether the entire app has been unlocked for the active session.
class AppUnlockedNotifier extends Notifier<bool> {
  @override
  bool build() {
    final settings = ref.watch(securityControllerProvider);
    // If biometric app lock is disabled, app starts unlocked
    if (!settings.biometricLockEnabled || !settings.lockOnAppLaunch) {
      return true;
    }
    return false;
  }

  void setUnlocked(bool value) {
    state = value;
  }
}

/// Provider tracking whether the entire app has been unlocked for the active session.
final appUnlockedProvider =
    NotifierProvider<AppUnlockedNotifier, bool>(AppUnlockedNotifier.new);

/// Notifier tracking which sensitive modules are temporarily unlocked in this session.
class ModuleUnlockedMapNotifier extends Notifier<Map<String, bool>> {
  @override
  Map<String, bool> build() => const {};

  void unlockModule(String moduleKey) {
    state = {...state, moduleKey: true};
  }

  void lockAll() {
    state = const {};
  }
}

/// Provider tracking which sensitive modules are temporarily unlocked in this session.
final moduleUnlockedMapProvider =
    NotifierProvider<ModuleUnlockedMapNotifier, Map<String, bool>>(
  ModuleUnlockedMapNotifier.new,
);

/// Master biometric gateway and app-level overlay.
/// Protects the entire application when biometricLockEnabled is on.
class BiometricGateOverlay extends ConsumerStatefulWidget {
  final Widget child;

  const BiometricGateOverlay({super.key, required this.child});

  @override
  ConsumerState<BiometricGateOverlay> createState() => _BiometricGateOverlayState();

  /// Verifies access to a confidential sub-module (NoFap, Cycle, Finance).
  /// Prompts for biometrics only if the module lock is enabled and hasn't been unlocked yet.
  static Future<bool> verifyModuleAccess({
    required BuildContext context,
    required WidgetRef ref,
    required String moduleKey,
    required String moduleTitle,
  }) async {
    final settings = ref.read(securityControllerProvider);
    if (!settings.biometricLockEnabled) return true;

    // Check specific module rule
    final isModuleLocked = switch (moduleKey) {
      'nofap' => settings.lockNofap,
      'cycle' => settings.lockCycle,
      'finance' => settings.lockFinance,
      _ => false,
    };

    if (!isModuleLocked) return true;

    // Check if already unlocked in this session
    final unlockedMap = ref.read(moduleUnlockedMapProvider);
    if (unlockedMap[moduleKey] == true) {
      return true;
    }

    final biometricService = ref.read(biometricServiceProvider);
    final authenticated = await biometricService.authenticate(
      localizedReason: 'Confirma tu identidad para acceder a $moduleTitle',
    );

    if (authenticated) {
      ref.read(moduleUnlockedMapProvider.notifier).unlockModule(moduleKey);
      return true;
    }

    // Biometrics failed, not recognized, or device lacks hardware: fallback to 6-digit PIN!
    if (context.mounted) {
      final pinSuccess = await SixDigitPinDialog.show(
        context: context,
        expectedPin: settings.securityPin,
        title: '$moduleTitle Protegido',
        subtitle: 'Ingresa tu PIN de 6 dígitos para acceder',
      );

      if (pinSuccess) {
        ref.read(moduleUnlockedMapProvider.notifier).unlockModule(moduleKey);
        return true;
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.surfaceContainerLowest,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppTheme.outlineVariant),
            ),
            content: Row(
              children: [
                const Icon(Icons.lock_rounded, color: AppTheme.error, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Acceso denegado a $moduleTitle. PIN o biometría no verificados.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppTheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    return false;
  }
}

class _BiometricGateOverlayState extends ConsumerState<BiometricGateOverlay>
    with WidgetsBindingObserver {
  DateTime? _pausedAt;
  bool _isPrompting = false;
  String? _errorMessage;
  bool _usePinFallback = false;
  bool _deviceHasBiometrics = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initLockState();
    });
  }

  Future<void> _initLockState() async {
    final bio = ref.read(biometricServiceProvider);
    final hasBio = await bio.hasEnrolledBiometrics();
    if (mounted) {
      setState(() {
        _deviceHasBiometrics = hasBio;
        // If device has no biometrics configured, default directly to PIN pad
        if (!hasBio) {
          _usePinFallback = true;
        }
      });
    }
    _checkInitialLock();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final settings = ref.read(securityControllerProvider);
    if (!settings.biometricLockEnabled || !settings.lockOnAppLaunch) return;

    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (_pausedAt != null) {
        final elapsed = DateTime.now().difference(_pausedAt!).inSeconds;
        if (elapsed >= settings.autoLockTimeoutSeconds) {
          // Re-lock app and module caches
          ref.read(appUnlockedProvider.notifier).setUnlocked(false);
          ref.read(moduleUnlockedMapProvider.notifier).lockAll();
          if (_deviceHasBiometrics) {
            _triggerUnlock();
          } else {
            setState(() {
              _usePinFallback = true;
            });
          }
        }
      }
      _pausedAt = null;
    }
  }

  void _checkInitialLock() {
    final isUnlocked = ref.read(appUnlockedProvider);
    final settings = ref.read(securityControllerProvider);
    if (settings.biometricLockEnabled && settings.lockOnAppLaunch && !isUnlocked) {
      if (_deviceHasBiometrics) {
        _triggerUnlock();
      } else {
        setState(() {
          _usePinFallback = true;
        });
      }
    }
  }

  Future<void> _triggerUnlock() async {
    if (_isPrompting) return;
    setState(() {
      _isPrompting = true;
      _errorMessage = null;
    });

    try {
      final biometricService = ref.read(biometricServiceProvider);
      final success = await biometricService.authenticate(
        localizedReason: 'Desbloquea FocusHabitual Life para continuar',
      );

      if (success) {
        ref.read(appUnlockedProvider.notifier).setUnlocked(true);
        setState(() {
          _errorMessage = null;
          _usePinFallback = false;
        });
      } else {
        // Biometrics failed, not recognized, or canceled: fallback to 6-digit PIN!
        setState(() {
          _usePinFallback = true;
          _errorMessage = 'Huella no reconocida. Ingresa tu PIN de 6 dígitos.';
        });
      }
    } catch (e) {
      setState(() {
        _usePinFallback = true;
        _errorMessage = 'Error en biometría: $e. Ingresa tu PIN.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isPrompting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(securityControllerProvider);
    final isUnlocked = ref.watch(appUnlockedProvider);

    // If lock is enabled, on-launch lock is on, and currently locked -> Show Executive Lock Screen
    if (settings.biometricLockEnabled && settings.lockOnAppLaunch && !isUnlocked) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: Scaffold(
          backgroundColor: AppTheme.background,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: _usePinFallback
                    ? SixDigitPinPad(
                        expectedPin: settings.securityPin,
                        title: 'Ingresa tu PIN de 6 dígitos',
                        subtitle: _errorMessage ??
                            (_deviceHasBiometrics
                                ? 'Autenticación alternativa de seguridad'
                                : 'Tu dispositivo no cuenta con huella registrada'),
                        onSuccess: () {
                          ref.read(appUnlockedProvider.notifier).setUnlocked(true);
                        },
                        onUseBiometrics: _deviceHasBiometrics
                            ? () {
                                setState(() {
                                  _usePinFallback = false;
                                  _errorMessage = null;
                                });
                                _triggerUnlock();
                              }
                            : null,
                        biometricButtonLabel: 'Usar Huella',
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Shield / Biometric Emblem
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primaryContainer.withValues(alpha: 0.18),
                                  AppTheme.primaryContainer.withValues(alpha: 0.05),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.primaryContainer.withValues(alpha: 0.35),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryContainer.withValues(alpha: 0.12),
                                  blurRadius: 28,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.fingerprint_rounded,
                                size: 46,
                                color: AppTheme.primaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),

                          Text(
                            'FocusHabitual Seguro',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.onSurface,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 8),

                          Text(
                            'Esta sesión está protegida con seguridad biométrica y PIN de 6 dígitos.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              color: AppTheme.outline,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 36),

                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: AppTheme.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.info_outline_rounded, size: 16, color: AppTheme.error),
                                  const SizedBox(width: 8),
                                  Text(
                                    _errorMessage!,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.error,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Biometric Unlock Button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryContainer,
                                foregroundColor: AppTheme.onPrimaryContainer,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: _isPrompting ? null : _triggerUnlock,
                              icon: _isPrompting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppTheme.onPrimaryContainer,
                                      ),
                                    )
                                  : const Icon(Icons.lock_open_rounded, size: 20),
                              label: Text(
                                _isPrompting ? 'Verificando...' : 'Desbloquear con Face ID / Huella',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Fallback to 6-digit PIN button
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _usePinFallback = true;
                                _errorMessage = null;
                              });
                            },
                            icon: const Icon(Icons.dialpad_rounded, size: 18, color: AppTheme.onSurfaceVariant),
                            label: Text(
                              'Ingresar con PIN de 6 dígitos',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}
