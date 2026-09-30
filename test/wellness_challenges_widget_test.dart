import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_habitual_life/core/local_db/database.dart';
import 'package:focus_habitual_life/features/wellness/domain/challenge_data.dart';
import 'package:focus_habitual_life/features/wellness/presentation/widgets/challenges_tab_view.dart';
import 'package:focus_habitual_life/features/wellness/presentation/widgets/exercise_timer_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await AppDatabase.init();
  });

  testWidgets('ChallengesTabView renders selector, progress card, and 21-day matrix', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ChallengesTabView(),
          ),
        ),
      ),
    );

    // Pump to settle async providers
    await tester.pumpAndSettle();

    // Verify 3 selector options
    expect(find.text('Meditación'), findsOneWidget);
    expect(find.text('Yoga'), findsOneWidget);
    expect(find.text('Facial'), findsOneWidget);

    // Verify 21-day timeline text
    expect(find.text('LÍNEA TEMPORAL DE LOS 21 DÍAS'), findsOneWidget);

    // Verify ambient sounds bar
    expect(find.textContaining('paisajes sonoros'), findsOneWidget);

    // Tap Yoga tab
    await tester.tap(find.text('Yoga'));
    await tester.pumpAndSettle();

    expect(find.text('Yoga & Postura'), findsOneWidget);
    // Verify catalog banner exists
    expect(find.textContaining('Biblioteca de Yoga'), findsOneWidget);
  });

  testWidgets('ExerciseTimerWidget displays 10s preparation and transitions to exercise', (tester) async {
    final steps = [
      const ExerciseStep(
        title: 'Utkatasana (Silla Clásica)',
        category: 'Fuerza',
        instructions: 'Flexión de rodillas a 90 grados y brazos arriba.',
        durationSeconds: 30,
        preparationSeconds: 10,
      ),
      const ExerciseStep(
        title: 'Virabhadrasana I (Guerrero 1)',
        category: 'Fuerza',
        instructions: 'Zancada profunda y brazos elevados.',
        durationSeconds: 30,
        preparationSeconds: 10,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExerciseTimerWidget(steps: steps),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify step counter and preparation banner
    expect(find.text('PASO 1 DE 2'), findsOneWidget);
    expect(find.text('¡PREPÁRATE! (10s)'), findsOneWidget);
    expect(find.text('10s'), findsOneWidget);
    expect(find.text('PREPARACIÓN'), findsOneWidget);
    expect(find.text('Utkatasana (Silla Clásica)'), findsOneWidget);
    expect(find.text('Comenzar ya (Saltar 10s)'), findsOneWidget);

    // Tap "Comenzar ya (Saltar 10s)"
    await tester.tap(find.text('Comenzar ya (Saltar 10s)'));
    await tester.pump();

    // Preparation finished -> In exercise phase!
    expect(find.text('EN EJECUCIÓN'), findsOneWidget);
    expect(find.text('ACTIVO'), findsOneWidget);
    expect(find.text('0:30'), findsOneWidget);
  });
}

