import 'dart:convert';

/// Configuration model for application security, biometric gates, and discreet mode.
class SecuritySettings {
  final bool biometricLockEnabled;
  final bool lockOnAppLaunch;
  final bool lockNofap;
  final bool lockCycle;
  final bool lockFinance;
  final bool discreetModeEnabled;
  final String discreetAppAlias;
  final int autoLockTimeoutSeconds;
  final String securityPin;
  final bool hasCustomPin;

  const SecuritySettings({
    this.biometricLockEnabled = false,
    this.lockOnAppLaunch = true,
    this.lockNofap = true,
    this.lockCycle = true,
    this.lockFinance = false,
    this.discreetModeEnabled = false,
    this.discreetAppAlias = 'Gestor Personal',
    this.autoLockTimeoutSeconds = 60,
    this.securityPin = '123456',
    this.hasCustomPin = false,
  });

  bool validatePin(String enteredPin) =>
      enteredPin.trim() == securityPin.trim();

  SecuritySettings copyWith({
    bool? biometricLockEnabled,
    bool? lockOnAppLaunch,
    bool? lockNofap,
    bool? lockCycle,
    bool? lockFinance,
    bool? discreetModeEnabled,
    String? discreetAppAlias,
    int? autoLockTimeoutSeconds,
    String? securityPin,
    bool? hasCustomPin,
  }) {
    return SecuritySettings(
      biometricLockEnabled: biometricLockEnabled ?? this.biometricLockEnabled,
      lockOnAppLaunch: lockOnAppLaunch ?? this.lockOnAppLaunch,
      lockNofap: lockNofap ?? this.lockNofap,
      lockCycle: lockCycle ?? this.lockCycle,
      lockFinance: lockFinance ?? this.lockFinance,
      discreetModeEnabled: discreetModeEnabled ?? this.discreetModeEnabled,
      discreetAppAlias: discreetAppAlias ?? this.discreetAppAlias,
      autoLockTimeoutSeconds: autoLockTimeoutSeconds ?? this.autoLockTimeoutSeconds,
      securityPin: securityPin ?? this.securityPin,
      hasCustomPin: hasCustomPin ?? this.hasCustomPin,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'biometric_lock_enabled': biometricLockEnabled,
      'lock_on_app_launch': lockOnAppLaunch,
      'lock_nofap': lockNofap,
      'lock_cycle': lockCycle,
      'lock_finance': lockFinance,
      'discreet_mode_enabled': discreetModeEnabled,
      'discreet_app_alias': discreetAppAlias,
      'auto_lock_timeout_seconds': autoLockTimeoutSeconds,
      'security_pin': securityPin,
      'has_custom_pin': hasCustomPin,
    };
  }

  factory SecuritySettings.fromMap(Map<String, dynamic> map) {
    return SecuritySettings(
      biometricLockEnabled: map['biometric_lock_enabled'] as bool? ?? false,
      lockOnAppLaunch: map['lock_on_app_launch'] as bool? ?? true,
      lockNofap: map['lock_nofap'] as bool? ?? true,
      lockCycle: map['lock_cycle'] as bool? ?? true,
      lockFinance: map['lock_finance'] as bool? ?? false,
      discreetModeEnabled: map['discreet_mode_enabled'] as bool? ?? false,
      discreetAppAlias: map['discreet_app_alias'] as String? ?? 'Gestor Personal',
      autoLockTimeoutSeconds: (map['auto_lock_timeout_seconds'] as num?)?.toInt() ?? 60,
      securityPin: (map['security_pin'] as String?)?.trim().isNotEmpty == true
          ? (map['security_pin'] as String).trim()
          : '123456',
      hasCustomPin: map['has_custom_pin'] as bool? ?? false,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory SecuritySettings.fromJson(String source) {
    try {
      final decoded = jsonDecode(source) as Map<String, dynamic>;
      return SecuritySettings.fromMap(decoded);
    } catch (_) {
      return const SecuritySettings();
    }
  }
}
