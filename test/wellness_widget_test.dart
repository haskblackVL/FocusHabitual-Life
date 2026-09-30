import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_habitual_life/core/local_db/database.dart';
import 'package:focus_habitual_life/features/wellness/presentation/wellness_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await AppDatabase.init();
  });

  testWidgets('WellnessScreen renders header, telemetry, and 3 executive tabs', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: WellnessScreen(),
        ),
      ),
    );

    // Initial pump and settle
    await tester.pumpAndSettle();

    // Verify Title & Subtitle in AppBar
    expect(find.text('Salud & Bienestar'), findsOneWidget);
    expect(find.text('AGUA · NUTRICIÓN · RETOS 21D'), findsOneWidget);

    // Verify 4 Tabs exist
    expect(find.text('Hidratación'), findsOneWidget);
    expect(find.text('Nutrición'), findsOneWidget);
    expect(find.text('Afirmaciones'), findsOneWidget);
    expect(find.text('Retos 21D'), findsOneWidget);

    // Verify Hidratación tab components
    expect(find.textContaining('250 ml'), findsAtLeastNWidgets(1));
    expect(find.textContaining('500 ml'), findsAtLeastNWidgets(1));

    // Tap on Nutrición tab
    await tester.tap(find.text('Nutrición'));
    await tester.pumpAndSettle();

    // Verify Nutrición content (Meal types and Biohacking tip)
    expect(find.text('Desayuno'), findsAtLeastNWidgets(1));
    expect(find.text('Almuerzo'), findsAtLeastNWidgets(1));
    expect(find.text('Cena'), findsAtLeastNWidgets(1));
    expect(find.text('BIOHACKING & ALIMENTACIÓN CONSCIENTE'), findsOneWidget);

    // Tap on Afirmaciones tab
    await tester.tap(find.text('Afirmaciones'));
    await tester.pumpAndSettle();

    // Verify Afirmaciones content
    expect(find.text('Decretar (+5 XP)'), findsOneWidget);
  });
}
