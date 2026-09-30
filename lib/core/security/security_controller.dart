import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../local_db/database.dart';
import 'biometric_service.dart';
import 'security_settings_model.dart';

const String _kSecuritySettingsKey = 'security_settings_v1';

/// Provider for BiometricService instance.
final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

/// Notifier managing persistent security and discreet mode settings.
class SecurityController extends Notifier<SecuritySettings> {
  late final BiometricService _biometricService;

  @override
  SecuritySettings build() {
    _biometricService = ref.watch(biometricServiceProvider);
    return _loadSettings();
  }

  SecuritySettings _loadSettings() {
    try {
      final savedJson = AppDatabase.getSetting(_kSecuritySettingsKey);
      if (savedJson != null && savedJson.isNotEmpty) {
        return SecuritySettings.fromJson(savedJson);
      }
    } catch (_) {}
    return const SecuritySettings();
  }

  void _persist() {
    try {
      AppDatabase.setSetting(_kSecuritySettingsKey, state.toJson());
    } catch (_) {}
  }

  /// Toggles global security lock. If enabling and device supports biometrics, prompts for biometric verification.
  /// If the device lacks biometric hardware, allows activating directly to use 6-digit PIN protection.
  Future<bool> setBiometricLock(bool enabled) async {
    if (enabled) {
      final canBiometrics = await _biometricService.canCheckBiometrics();
      if (canBiometrics) {
        final success = await _biometricService.authenticate(
          localizedReason: 'Confirma tu identidad biométrica para activar el bloqueo de seguridad',
        );
        if (!success) {
          return false;
        }
      }
    }

    state = state.copyWith(biometricLockEnabled: enabled);
    _persist();
    return true;
  }

  /// Sets or updates the 6-digit security PIN.
  bool setSecurityPin(String newPin) {
    final sanitized = newPin.trim();
    if (sanitized.length == 6 && RegExp(r'^\d{6}$').hasMatch(sanitized)) {
      state = state.copyWith(
        securityPin: sanitized,
        hasCustomPin: true,
      );
      _persist();
      return true;
    }
    return false;
  }

  /// Validates an entered PIN against the configured 6-digit PIN.
  bool validatePin(String pin) {
    return state.validatePin(pin);
  }

  void setLockOnAppLaunch(bool enabled) {
    state = state.copyWith(lockOnAppLaunch: enabled);
    _persist();
  }

  void setLockNofap(bool enabled) {
    state = state.copyWith(lockNofap: enabled);
    _persist();
  }

  void setLockCycle(bool enabled) {
    state = state.copyWith(lockCycle: enabled);
    _persist();
  }

  void setLockFinance(bool enabled) {
    state = state.copyWith(lockFinance: enabled);
    _persist();
  }

  void setDiscreetMode(bool enabled) {
    state = state.copyWith(discreetModeEnabled: enabled);
    _persist();
  }

  void setDiscreetAppAlias(String alias) {
    final sanitized = alias.trim();
    if (sanitized.isNotEmpty) {
      state = state.copyWith(discreetAppAlias: sanitized);
      _persist();
    }
  }

  void setAutoLockTimeoutSeconds(int seconds) {
    state = state.copyWith(autoLockTimeoutSeconds: seconds);
    _persist();
  }

  /// Verifies biometrics on demand (useful for testing from Settings screen).
  Future<bool> testAuthentication() async {
    return await _biometricService.authenticate(
      localizedReason: 'Prueba de autenticación biométrica en FocusHabitual Life',
    );
  }
}

/// Global provider for application security controller and settings state.
final securityControllerProvider =
    NotifierProvider<SecurityController, SecuritySettings>(
  SecurityController.new,
);
