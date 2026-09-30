import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme.dart';
import 'biometric_gate.dart';
import 'security_controller.dart';
import 'six_digit_pin_view.dart';

/// Gate widget protecting sensitive feature modules (NoFap, Woman Cycle, Finance)
/// with biometrics according to granular security preferences.
class ModuleSecurityGate extends ConsumerStatefulWidget {
  final String moduleKey; // 'nofap' | 'cycle' | 'finance'
  final String moduleTitle;
  final Widget child;

  const ModuleSecurityGate({
    super.key,
    required this.moduleKey,
    required this.moduleTitle,
    required this.child,
  });

  @override
  ConsumerState<ModuleSecurityGate> createState() => _ModuleSecurityGateState();
}

class _ModuleSecurityGateState extends ConsumerState<ModuleSecurityGate> {
  bool _isAuthenticating = false;
  bool _usePinFallback = false;
  bool _deviceHasBiometrics = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _detectAndPrompt();
    });
  }

  Future<void> _detectAndPrompt() async {
    final bio = ref.read(biometricServiceProvider);
    final hasBio = await bio.hasEnrolledBiometrics();
    if (mounted) {
      setState(() {
        _deviceHasBiometrics = hasBio;
        if (!hasBio) {
          _usePinFallback = true;
        }
      });
    }

    if (hasBio) {
      _checkAndPrompt();
    }
  }

  bool _isModuleLocked() {
    final settings = ref.read(securityControllerProvider);
    if (!settings.biometricLockEnabled) return false;

    return switch (widget.moduleKey) {
      'nofap' => settings.lockNofap,
      'cycle' => settings.lockCycle,
      'finance' => settings.lockFinance,
      _ => false,
    };
  }

  bool _isUnlocked() {
    if (!_isModuleLocked()) return true;
    final unlockedMap = ref.watch(moduleUnlockedMapProvider);
    return unlockedMap[widget.moduleKey] == true;
  }

  Future<void> _checkAndPrompt() async {
    if (!_isModuleLocked() || _isUnlocked() || _isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    try {
      final biometricService = ref.read(biometricServiceProvider);
      final success = await biometricService.authenticate(
        localizedReason: 'Confirma tu identidad para acceder al módulo de ${widget.moduleTitle}',
      );

      if (success) {
        ref.read(moduleUnlockedMapProvider.notifier).unlockModule(widget.moduleKey);
      } else {
        setState(() {
          _usePinFallback = true;
          _errorMessage = 'Huella no reconocida. Ingresa tu PIN de 6 dígitos.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isUnlocked()) {
      return widget.child;
    }

    final settings = ref.watch(securityControllerProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.onSurface),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: _usePinFallback
                ? SixDigitPinPad(
                    expectedPin: settings.securityPin,
                    title: '${widget.moduleTitle} Protegido',
                    subtitle: _errorMessage ??
                        (_deviceHasBiometrics
                            ? 'Autenticación alternativa con PIN de 6 dígitos'
                            : 'Ingresa tu PIN de 6 dígitos para acceder'),
                    onSuccess: () {
                      ref.read(moduleUnlockedMapProvider.notifier).unlockModule(widget.moduleKey);
                    },
                    onUseBiometrics: _deviceHasBiometrics
                        ? () {
                            setState(() {
                              _usePinFallback = false;
                              _errorMessage = null;
                            });
                            _checkAndPrompt();
                          }
                        : null,
                    biometricButtonLabel: 'Usar Huella',
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryContainer.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.primaryContainer.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.lock_rounded,
                            size: 40,
                            color: AppTheme.primaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '${widget.moduleTitle} Protegido',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Este módulo tiene activada la protección biométrica y por PIN para salvaguardar tu privacidad.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppTheme.outline,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryContainer,
                            foregroundColor: AppTheme.onPrimaryContainer,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _isAuthenticating ? null : _checkAndPrompt,
                          icon: _isAuthenticating
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.onPrimaryContainer,
                                  ),
                                )
                              : const Icon(Icons.fingerprint_rounded, size: 20),
                          label: Text(
                            _isAuthenticating ? 'Verificando...' : 'Desbloquear con Biometría',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _usePinFallback = true;
                            _errorMessage = null;
                          });
                        },
                        icon: const Icon(Icons.dialpad_rounded, size: 18, color: AppTheme.onSurfaceVariant),
                        label: Text(
                          'Desbloquear con PIN de 6 dígitos',
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
    );
  }
}

