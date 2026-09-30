import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Service interfacing with local_auth for hardware-backed biometrics and device credentials.
class BiometricService {
  final LocalAuthentication _auth;

  BiometricService({LocalAuthentication? auth}) : _auth = auth ?? LocalAuthentication();

  /// Checks if device hardware supports biometrics or device PIN/Pattern.
  Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } on PlatformException catch (e) {
      if (kDebugMode) print('[BiometricService] isDeviceSupported error: $e');
      return false;
    }
  }

  /// Checks whether biometrics can be checked on the device.
  Future<bool> canCheckBiometrics() async {
    try {
      return await _auth.canCheckBiometrics;
    } on PlatformException catch (e) {
      if (kDebugMode) print('[BiometricService] canCheckBiometrics error: $e');
      return false;
    }
  }

  /// Lists available biometric hardware types (fingerprint, face, iris, etc.).
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      if (kDebugMode) print('[BiometricService] getAvailableBiometrics error: $e');
      return const [];
    }
  }

  /// Checks whether the device has enrolled biometric credentials (fingerprint, face, etc.).
  Future<bool> hasEnrolledBiometrics() async {
    try {
      final isSupported = await isDeviceSupported();
      if (!isSupported) return false;
      final canCheck = await canCheckBiometrics();
      if (!canCheck) return false;
      final available = await getAvailableBiometrics();
      return available.isNotEmpty;
    } on PlatformException catch (e) {
      if (kDebugMode) print('[BiometricService] hasEnrolledBiometrics error: $e');
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Prompts the user to authenticate using biometrics.
  /// If the device lacks biometric hardware or enrolled fingerprints, returns false
  /// so the security system can seamlessly prompt for the 6-digit PIN fallback.
  Future<bool> authenticate({
    required String localizedReason,
    bool biometricOnly = false,
  }) async {
    try {
      final isSupported = await isDeviceSupported();
      final canCheck = await canCheckBiometrics();
      if (!isSupported || !canCheck) {
        if (kDebugMode) {
          print('[BiometricService] Biometrics not available on device; delegating to 6-digit PIN.');
        }
        return false;
      }

      return await _auth.authenticate(
        localizedReason: localizedReason,
        biometricOnly: biometricOnly,
        persistAcrossBackgrounding: true,
      );
    } on PlatformException catch (e) {
      if (kDebugMode) print('[BiometricService] authenticate error: $e');
      return false;
    } catch (_) {
      return false;
    }
  }
}
