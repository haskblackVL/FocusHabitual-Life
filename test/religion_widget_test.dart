import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_habitual_life/core/local_db/database.dart';
import 'package:focus_habitual_life/features/religion/presentation/religion_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await AppDatabase.init();
  });

  testWidgets('ReligionScreen renders tabs, daily devotional hero, and stats', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ReligionScreen(),
        ),
      ),
    );

    // Initial pump and settle
    await tester.pumpAndSettle();

    // Verify Title & Subtitle
    expect(find.text('Religión & Espiritualidad'), findsOneWidget);
    expect(find.text('Pilar rector, discernimiento y oración'), findsOneWidget);

    // Verify 3 Tabs exist
    expect(find.text('Devocional'), findsOneWidget);
    expect(find.text('Oración'), findsOneWidget);
    expect(find.text('Biblioteca'), findsOneWidget);

    // Verify Devotional Hero components
    expect(find.text('DISCERNIMIENTO & ANÁLISIS ESTRATÉGICO'), findsOneWidget);
    expect(find.text('PRINCIPIO EN ACCIÓN HOY'), findsOneWidget);
    expect(find.text('DIARIO DE REFLEXIÓN PERSONAL'), findsOneWidget);

    // Switch to Oración tab
    await tester.tap(find.text('Oración'));
    await tester.pumpAndSettle();

    expect(find.text('En Intercesión Activa'), findsOneWidget);
    expect(find.text('Testimonios (Respondidas)'), findsOneWidget);
    expect(find.text('Nueva Petición (+10 XP)'), findsOneWidget);

    // Switch to Biblioteca tab
    await tester.tap(find.text('Biblioteca'));
    await tester.pumpAndSettle();

    expect(find.text('Proverbios 16:3'), findsAtLeastNWidgets(1));
  });
}
