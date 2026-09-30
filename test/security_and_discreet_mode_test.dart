import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_habitual_life/core/local_db/database.dart';
import 'package:focus_habitual_life/core/security/biometric_service.dart';
import 'package:focus_habitual_life/core/security/discreet_mode.dart';
import 'package:focus_habitual_life/core/security/module_security_gate.dart';
import 'package:focus_habitual_life/core/security/security_controller.dart';
import 'package:focus_habitual_life/core/security/security_settings_model.dart';
import 'package:focus_habitual_life/core/security/six_digit_pin_view.dart';
import 'package:local_auth/local_auth.dart';

class MockBiometricService extends BiometricService {
  bool shouldSucceed = true;
  bool isSupported = true;

  @override
  Future<bool> isDeviceSupported() async => isSupported;

  @override
  Future<bool> canCheckBiometrics() async => isSupported;

  @override
  Future<List<BiometricType>> getAvailableBiometrics() async => [BiometricType.fingerprint];

  @override
  Future<bool> authenticate({
    required String localizedReason,
    bool biometricOnly = false,
  }) async {
    return shouldSucceed;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await AppDatabase.init();
  });

  setUp(() {
    AppDatabase.setSetting('security_settings_v1', '');
  });

  group('SecuritySettings Model Tests', () {
    test('default settings have sensible executive privacy values', () {
      const settings = SecuritySettings();
      expect(settings.biometricLockEnabled, isFalse);
      expect(settings.lockOnAppLaunch, isTrue);
      expect(settings.lockNofap, isTrue);
      expect(settings.lockCycle, isTrue);
      expect(settings.lockFinance, isFalse);
      expect(settings.discreetModeEnabled, isFalse);
      expect(settings.discreetAppAlias, equals('Gestor Personal'));
      expect(settings.autoLockTimeoutSeconds, equals(60));
    });

    test('serialization toMap and fromMap preserves all fields', () {
      const original = SecuritySettings(
        biometricLockEnabled: true,
        lockOnAppLaunch: false,
        lockNofap: true,
        lockCycle: false,
        lockFinance: true,
        discreetModeEnabled: true,
        discreetAppAlias: 'Calculadora & Notas',
        autoLockTimeoutSeconds: 300,
      );

      final map = original.toMap();
      final reconstructed = SecuritySettings.fromMap(map);

      expect(reconstructed.biometricLockEnabled, isTrue);
      expect(reconstructed.lockOnAppLaunch, isFalse);
      expect(reconstructed.lockNofap, isTrue);
      expect(reconstructed.lockCycle, isFalse);
      expect(reconstructed.lockFinance, isTrue);
      expect(reconstructed.discreetModeEnabled, isTrue);
      expect(reconstructed.discreetAppAlias, equals('Calculadora & Notas'));
      expect(reconstructed.autoLockTimeoutSeconds, equals(300));
    });

    test('toJson and fromJson preserves data and survives corrupt input', () {
      const original = SecuritySettings(discreetAppAlias: 'Lector Ejecutivo');
      final json = original.toJson();
      final parsed = SecuritySettings.fromJson(json);

      expect(parsed.discreetAppAlias, equals('Lector Ejecutivo'));

      final fallback = SecuritySettings.fromJson('invalid json text');
      expect(fallback.discreetAppAlias, equals('Gestor Personal'));
    });
  });

  group('SecurityController & Persistence Tests', () {
    test('enables biometric lock only when authentication succeeds', () async {
      final mock = MockBiometricService();
      final container = ProviderContainer(
        overrides: [
          biometricServiceProvider.overrideWithValue(mock),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(securityControllerProvider.notifier);

      // 1. Success case
      mock.shouldSucceed = true;
      final ok = await controller.setBiometricLock(true);
      expect(ok, isTrue);
      expect(container.read(securityControllerProvider).biometricLockEnabled, isTrue);

      // Verify SQLite persistence
      final savedJson = AppDatabase.getSetting('security_settings_v1');
      expect(savedJson, isNotNull);
      expect(savedJson!.contains('"biometric_lock_enabled":true'), isTrue);

      // 2. Failure case
      mock.shouldSucceed = false;
      final failed = await controller.setBiometricLock(true);
      expect(failed, isFalse);
    });

    test('updates discreet mode and alias correctly', () {
      final mock = MockBiometricService();
      final container = ProviderContainer(
        overrides: [
          biometricServiceProvider.overrideWithValue(mock),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(securityControllerProvider.notifier);

      controller.setDiscreetMode(true);
      controller.setDiscreetAppAlias('Productividad VIP');

      final settings = container.read(securityControllerProvider);
      expect(settings.discreetModeEnabled, isTrue);
      expect(settings.discreetAppAlias, equals('Productividad VIP'));

      // Check title provider
      final title = container.read(discreetAppTitleProvider);
      expect(title, equals('Productividad VIP'));
    });

    test('granular module locks can be toggled independently', () {
      final mock = MockBiometricService();
      final container = ProviderContainer(
        overrides: [
          biometricServiceProvider.overrideWithValue(mock),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(securityControllerProvider.notifier);
      controller.setLockNofap(false);
      controller.setLockCycle(false);
      controller.setLockFinance(true);
      controller.setAutoLockTimeoutSeconds(0);

      final state = container.read(securityControllerProvider);
      expect(state.lockNofap, isFalse);
      expect(state.lockCycle, isFalse);
      expect(state.lockFinance, isTrue);
      expect(state.autoLockTimeoutSeconds, equals(0));
    });
  });

  group('DiscreetMaskWidget UI Tests', () {
    testWidgets('renders child directly when discreetMode is disabled', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DiscreetMaskWidget(
                title: 'NoFap',
                child: Text('14 DÍAS LIMPIOS', key: Key('secret-content')),
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('secret-content')), findsOneWidget);
      expect(find.text('Revelar'), findsNothing);
    });

    testWidgets('hides child and allows tap-to-reveal when discreetMode is enabled', (tester) async {
      final mock = MockBiometricService();
      final container = ProviderContainer(
        overrides: [
          biometricServiceProvider.overrideWithValue(mock),
        ],
      );
      container.read(securityControllerProvider.notifier).setDiscreetMode(true);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: DiscreetMaskWidget(
                title: 'Métrica Confidencial',
                subtitle: 'Toca para revelar',
                child: Text('CONTENIDO SECRETO', key: Key('secret-content')),
              ),
            ),
          ),
        ),
      );

      // Initially masked
      expect(find.text('Métrica Confidencial'), findsOneWidget);
      expect(find.text('Revelar'), findsOneWidget);

      // Tap to reveal
      await tester.tap(find.text('Revelar'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('secret-content')), findsOneWidget);
      expect(find.text('Ocultar'), findsOneWidget);

      // Tap to hide again
      await tester.tap(find.text('Ocultar'));
      await tester.pumpAndSettle();

      expect(find.text('Revelar'), findsOneWidget);
    });
  });

  group('ModuleSecurityGate UI Tests', () {
    testWidgets('renders content directly when module is not locked', (tester) async {
      final mock = MockBiometricService();
      final container = ProviderContainer(
        overrides: [
          biometricServiceProvider.overrideWithValue(mock),
        ],
      );
      // Biometrics disabled
      container.read(securityControllerProvider.notifier).setBiometricLock(false);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: ModuleSecurityGate(
                moduleKey: 'nofap',
                moduleTitle: 'NoFap & Autocontrol',
                child: Text('PANTALLA NOFAP', key: Key('nofap-screen')),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('nofap-screen')), findsOneWidget);
      expect(find.text('NoFap & Autocontrol Protegido'), findsNothing);
    });
  });

  group('SixDigitPinPad & PIN Security Tests', () {
    test('6-digit PIN defaults and validatePin work correctly', () {
      const settings = SecuritySettings();
      expect(settings.securityPin, equals('123456'));
      expect(settings.hasCustomPin, isFalse);
      expect(settings.validatePin('123456'), isTrue);
      expect(settings.validatePin('000000'), isFalse);
    });

    test('sets and validates 6-digit security PIN with persistence', () {
      final mock = MockBiometricService();
      final container = ProviderContainer(
        overrides: [
          biometricServiceProvider.overrideWithValue(mock),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(securityControllerProvider.notifier);

      // Rejects invalid formats
      expect(controller.setSecurityPin('123'), isFalse);
      expect(controller.setSecurityPin('abcdef'), isFalse);
      expect(controller.setSecurityPin('1234567'), isFalse);

      // Accepts valid 6-digit pin
      expect(controller.setSecurityPin('987654'), isTrue);
      final state = container.read(securityControllerProvider);
      expect(state.securityPin, equals('987654'));
      expect(state.hasCustomPin, isTrue);
      expect(controller.validatePin('987654'), isTrue);
      expect(controller.validatePin('123456'), isFalse);
    });

    testWidgets('entering correct 6 digits triggers onSuccess callback', (tester) async {
      bool unlocked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SixDigitPinPad(
              expectedPin: '123456',
              onSuccess: () {
                unlocked = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Ingresa tu PIN de 6 dígitos'), findsOneWidget);

      // Tap 1, 2, 3, 4, 5, 6
      for (final digit in ['1', '2', '3', '4', '5', '6']) {
        await tester.tap(find.text(digit));
        await tester.pump(const Duration(milliseconds: 50));
      }

      await tester.pumpAndSettle();
      expect(unlocked, isTrue);
    });

    testWidgets('entering incorrect PIN displays error message', (tester) async {
      bool unlocked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SixDigitPinPad(
              expectedPin: '123456',
              onSuccess: () {
                unlocked = true;
              },
            ),
          ),
        ),
      );

      // Tap 1, 1, 1, 1, 1, 1
      for (int i = 0; i < 6; i++) {
        await tester.tap(find.text('1'));
        await tester.pump(const Duration(milliseconds: 50));
      }

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('PIN incorrecto. Inténtalo de nuevo.'), findsOneWidget);
      expect(unlocked, isFalse);

      // Drain clear timer
      await tester.pump(const Duration(milliseconds: 600));
    });
  });
}
