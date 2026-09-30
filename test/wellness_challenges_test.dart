import 'package:flutter_test/flutter_test.dart';
import 'package:focus_habitual_life/core/gamification/xp_engine.dart';
import 'package:focus_habitual_life/core/local_db/database.dart';
import 'package:focus_habitual_life/features/wellness/data/wellness_repository.dart';
import 'package:focus_habitual_life/features/wellness/domain/challenge_catalog.dart';
import 'package:focus_habitual_life/features/wellness/domain/challenge_data.dart';
import 'package:focus_habitual_life/features/wellness/domain/yoga_and_facial_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late WellnessRepository repository;

  setUpAll(() async {
    await AppDatabase.init();
    repository = WellnessRepository();
  });

  group('Wellness Challenges Catalog & Seed Tests', () {
    test('ChallengeCatalog contains 7 ambient sounds with valid paths', () {
      expect(ChallengeCatalog.allSounds.length, equals(7));
      for (final sound in ChallengeCatalog.allSounds) {
        expect(sound.audioUrl.startsWith('assets/sounds/'), isTrue);
        expect(sound.audioUrl.endsWith('.mp3'), isTrue);
        expect(sound.name.isNotEmpty, isTrue);
      }
    });

    test('ChallengeCatalog contains 21 exercises for Meditation, Yoga and Yoga Facial', () {
      expect(ChallengeCatalog.meditationExercises.length, equals(21));
      expect(ChallengeCatalog.yogaExercises.length, equals(21));
      expect(ChallengeCatalog.yogaFacialExercises.length, equals(21));
      expect(ChallengeCatalog.allExercises.length, equals(63));

      for (int i = 1; i <= 21; i++) {
        expect(ChallengeCatalog.meditationExercises.any((e) => e.dayNumber == i), isTrue);
        expect(ChallengeCatalog.yogaExercises.any((e) => e.dayNumber == i), isTrue);
        expect(ChallengeCatalog.yogaFacialExercises.any((e) => e.dayNumber == i), isTrue);
      }
    });

    test('Database seeded 7 ambient sounds correctly', () async {
      final sounds = await repository.getAmbientSounds();
      expect(sounds.length, equals(7));
      expect(sounds.any((s) => s.name == 'Bosque Profundo'), isTrue);
      expect(sounds.any((s) => s.name == 'Olas del Océano'), isTrue);
    });

    test('Database seeded 21 exercises per challenge type correctly', () async {
      final medExercises = await repository.getExercises(ChallengeType.meditation);
      final yogaExercises = await repository.getExercises(ChallengeType.yoga);
      final facialExercises = await repository.getExercises(ChallengeType.yogaFacial);

      expect(medExercises.length, equals(21));
      expect(yogaExercises.length, equals(21));
      expect(facialExercises.length, equals(21));
    });
  });

  group('Wellness Challenges Lifecycle & Progress Tests', () {
    test('getActiveChallenge returns active challenge for Meditation', () async {
      final challenge = await repository.getActiveChallenge(ChallengeType.meditation);
      expect(challenge.challengeType, equals(ChallengeType.meditation));
      expect(challenge.totalDays, equals(21));
      expect(challenge.isActive, isTrue);
    });

    test('getChallengeSummary calculates correct next pending day and progress', () async {
      final summary = await repository.getChallengeSummary(ChallengeType.meditation);
      expect(summary.challenge.totalDays, equals(21));
      expect(summary.allExercises.length, equals(21));
      expect(summary.nextPendingDay, inInclusiveRange(1, 21));
      expect(summary.currentExercise, isNotNull);
    });

    test('completeChallengeDay records progress and awards +15 XP', () async {
      final initialSummary = await repository.getChallengeSummary(ChallengeType.yoga);
      final targetDay = initialSummary.nextPendingDay;

      // Get initial XP
      final initialXpRows = AppDatabase.instance.select(
        'SELECT total_xp FROM user_xp WHERE user_id = ?',
        ['local_user'],
      );
      final initialXp = initialXpRows.isNotEmpty ? (initialXpRows.first['total_xp'] as int) : 0;

      await repository.completeChallengeDay(
        challengeId: initialSummary.challenge.id,
        type: ChallengeType.yoga,
        dayNumber: targetDay,
      );

      final updatedSummary = await repository.getChallengeSummary(ChallengeType.yoga);
      expect(updatedSummary.isDayCompleted(targetDay), isTrue);

      // Verify XP increment
      final updatedXpRows = AppDatabase.instance.select(
        'SELECT total_xp FROM user_xp WHERE user_id = ?',
        ['local_user'],
      );
      final updatedXp = updatedXpRows.first['total_xp'] as int;
      expect(updatedXp, equals(initialXp + XpEngine.wellnessChallengeDayXp));
    });

    test('completeChallengeDay for day 21 awards bonus +50 XP (+65 XP total)', () async {
      final summary = await repository.getChallengeSummary(ChallengeType.yogaFacial);

      final initialXpRows = AppDatabase.instance.select(
        'SELECT total_xp FROM user_xp WHERE user_id = ?',
        ['local_user'],
      );
      final initialXp = initialXpRows.isNotEmpty ? (initialXpRows.first['total_xp'] as int) : 0;

      await repository.completeChallengeDay(
        challengeId: summary.challenge.id,
        type: ChallengeType.yogaFacial,
        dayNumber: 21,
      );

      final updatedXpRows = AppDatabase.instance.select(
        'SELECT total_xp FROM user_xp WHERE user_id = ?',
        ['local_user'],
      );
      final updatedXp = updatedXpRows.first['total_xp'] as int;
      expect(updatedXp, equals(initialXp + XpEngine.wellnessChallengeDayXp + XpEngine.wellnessChallengeCompleteXp));
    });

    test('resetChallenge creates a fresh active challenge', () async {
      await repository.resetChallenge(ChallengeType.meditation);
      final freshSummary = await repository.getChallengeSummary(ChallengeType.meditation);

      expect(freshSummary.challenge.isActive, isTrue);
      expect(freshSummary.completedCount, equals(0));
      expect(freshSummary.nextPendingDay, equals(1));
    });
  });

  group('Yoga (150 Asanas) & Facial Yoga (50 Ejercicios) Multi-Step Session Tests', () {
    test('Yoga catalog contains 150 total asanas (50 Fuerza, 50 Flexibilidad, 50 Relajación)', () {
      expect(YogaAndFacialCatalog.yogaFuerza.length, equals(50));
      expect(YogaAndFacialCatalog.yogaFlexibilidad.length, equals(50));
      expect(YogaAndFacialCatalog.yogaRelajacion.length, equals(50));

      final allYoga = [
        ...YogaAndFacialCatalog.yogaFuerza,
        ...YogaAndFacialCatalog.yogaFlexibilidad,
        ...YogaAndFacialCatalog.yogaRelajacion,
      ];
      expect(allYoga.length, equals(150));
      for (final asana in allYoga) {
        expect(asana.title.isNotEmpty, isTrue);
        expect(asana.description.isNotEmpty, isTrue);
      }
    });

    test('Face Yoga catalog contains 50 total exercises across 5 facial zones', () {
      expect(YogaAndFacialCatalog.facialFrente.length, equals(10));
      expect(YogaAndFacialCatalog.facialOjos.length, equals(10));
      expect(YogaAndFacialCatalog.facialPomulos.length, equals(10));
      expect(YogaAndFacialCatalog.facialLabios.length, equals(10));
      expect(YogaAndFacialCatalog.facialMandibulaCuello.length, equals(10));

      final allFacial = [
        ...YogaAndFacialCatalog.facialFrente,
        ...YogaAndFacialCatalog.facialOjos,
        ...YogaAndFacialCatalog.facialPomulos,
        ...YogaAndFacialCatalog.facialLabios,
        ...YogaAndFacialCatalog.facialMandibulaCuello,
      ];
      expect(allFacial.length, equals(50));
      for (final ex in allFacial) {
        expect(ex.title.isNotEmpty, isTrue);
        expect(ex.description.isNotEmpty, isTrue);
      }
    });

    test('Every Yoga session contains 5 sequential asanas, each with 10s preparation time', () {
      for (int day = 1; day <= 21; day++) {
        final routine = YogaAndFacialCatalog.getYogaRoutineForDay(day);
        expect(routine.length, equals(5));

        for (final step in routine) {
          expect(step.preparationSeconds, equals(10), reason: 'Day $day step ${step.title} must have 10s preparation');
          expect(step.durationSeconds, greaterThan(0));
          expect(step.instructions.isNotEmpty, isTrue);
        }
      }
    });

    test('Every Face Yoga session contains 7 sequential exercises, each with 10s preparation time', () {
      for (int day = 1; day <= 21; day++) {
        final routine = YogaAndFacialCatalog.getFacialRoutineForDay(day);
        expect(routine.length, equals(7));

        for (final step in routine) {
          expect(step.preparationSeconds, equals(10), reason: 'Day $day step ${step.title} must have 10s preparation');
          expect(step.durationSeconds, greaterThan(0));
          expect(step.instructions.isNotEmpty, isTrue);
        }
      }
    });

    test('WellnessExercise.effectiveSteps dynamically returns multi-exercise routine with 10s prep', () {
      const yogaEx = WellnessExercise(
        id: 'yoga-test',
        challengeType: ChallengeType.yoga,
        dayNumber: 3,
        title: 'Guerrero & Apertura',
        instructions: 'Test instructions',
      );
      final yogaSteps = yogaEx.effectiveSteps;
      expect(yogaSteps.length, equals(5));
      expect(yogaSteps.every((s) => s.preparationSeconds == 10), isTrue);

      const facialEx = WellnessExercise(
        id: 'facial-test',
        challengeType: ChallengeType.yogaFacial,
        dayNumber: 5,
        title: 'Pómulos & Drenaje',
        instructions: 'Test instructions',
      );
      final facialSteps = facialEx.effectiveSteps;
      expect(facialSteps.length, equals(7));
      expect(facialSteps.every((s) => s.preparationSeconds == 10), isTrue);
    });
  });
}
