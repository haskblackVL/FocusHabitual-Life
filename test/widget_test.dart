import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_habitual_life/app/app.dart';
import 'package:focus_habitual_life/core/local_db/database.dart';
import 'package:focus_habitual_life/features/auth/onboarding/onboarding_screen.dart';

import 'package:focus_habitual_life/features/settings/presentation/settings_screen.dart';

void main() {
  setUp(() async {
    await AppDatabase.init();
  });

  testWidgets('FocusHabitualApp starts at Login with Iniciar Sesion as first option when not logged in', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: FocusHabitualApp(),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Initial load without session should display Login Screen with "Iniciar Sesión" as first option
    expect(find.text('FocusHabitual Life'), findsOneWidget);
    expect(find.text('Iniciar Sesión'), findsWidgets);
    expect(find.text('Crear Cuenta'), findsOneWidget);

    final guestButton = find.text('Entrar como Invitado (Modo Offline)');
    expect(guestButton, findsOneWidget);

    // 2. Entering as guest takes user into Launcher
    await tester.tap(guestButton);
    await tester.pumpAndSettle();

    expect(find.text('Panel'), findsOneWidget);
    expect(find.text('Hábitos'), findsOneWidget);
    expect(find.text('Pomodoro'), findsOneWidget);
    expect(find.text('Score'), findsOneWidget);
  });

  testWidgets('OnboardingScreen displays clean gender buttons without Activa NoFap or Activa Ciclo', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: OnboardingScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Should display the configuration fields
    expect(find.text('Personaliza tu Perfil'), findsOneWidget);
    expect(find.text('NOMBRE O ALIAS'), findsOneWidget);
    expect(find.text('GÉNERO'), findsOneWidget);
    expect(find.text('Hombre'), findsOneWidget);
    expect(find.text('Mujer'), findsOneWidget);

    // MUST NOT display 'Activa NoFap' or 'Activa Ciclo'
    expect(find.text('Activa NoFap'), findsNothing);
    expect(find.text('Activa Ciclo'), findsNothing);

    // Displays spiritual module and submit button
    expect(find.text('MÓDULO ESPIRITUAL'), findsOneWidget);
    expect(find.text('Comenzar Experiencia'), findsOneWidget);
  });

  testWidgets('SettingsScreen has no repeat onboarding button, locks gender, and hides woman config for male users', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    AppDatabase.setSetting('profile_gender', 'male');

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SettingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. MUST NOT have 'Repetir Onboarding Inicial'
    expect(find.text('Repetir Onboarding Inicial'), findsNothing);

    // 2. Gender selector must be locked (no DropdownButton)
    expect(find.byType(DropdownButton<String>), findsNothing);
    expect(find.text('Género Registrado'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline_rounded), findsWidgets);

    // 3. For male users, woman configuration MUST NOT be shown
    expect(find.text('CONFIGURACIÓN DE LA MUJER (SALUD & CICLOS)'), findsNothing);
    expect(find.text('Duración del Ciclo'), findsNothing);
    expect(find.text('Visualizar Dial Biológico y Bienestar Completo'), findsNothing);
  });

  testWidgets('SettingsScreen displays woman configuration ONLY if user is female', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    AppDatabase.setSetting('profile_gender', 'female');

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SettingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. MUST NOT have 'Repetir Onboarding Inicial'
    expect(find.text('Repetir Onboarding Inicial'), findsNothing);

    // 2. Gender selector must be locked
    expect(find.byType(DropdownButton<String>), findsNothing);
    expect(find.text('Género Registrado'), findsOneWidget);

    // 3. For female users, woman configuration MUST be shown
    expect(find.text('CONFIGURACIÓN DE LA MUJER (SALUD & CICLOS)'), findsOneWidget);
    expect(find.text('Duración del Ciclo'), findsOneWidget);
    expect(find.text('Duración de Menstruación'), findsOneWidget);
    expect(find.text('Visualizar Dial Biológico y Bienestar Completo'), findsOneWidget);

    // 4. Tap visualizer button to open WomanCycleDetailSheet
    await tester.tap(find.text('Visualizar Dial Biológico y Bienestar Completo'));
    await tester.pumpAndSettle();

    expect(find.text('Ciclo Biológico & Neuroquímica'), findsOneWidget);
    expect(find.text('Pico de Creatividad & Energía'), findsOneWidget);
    expect(find.text('REGISTRO RÁPIDO DE BIENESTAR'), findsOneWidget);
  });
}
