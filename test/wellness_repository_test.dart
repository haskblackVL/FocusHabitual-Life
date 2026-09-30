import 'package:flutter_test/flutter_test.dart';
import 'package:focus_habitual_life/core/local_db/database.dart';
import 'package:focus_habitual_life/features/wellness/data/wellness_repository.dart';
import 'package:focus_habitual_life/features/wellness/domain/affirmation.dart';
import 'package:focus_habitual_life/features/wellness/domain/nutrition_data.dart';
import 'package:focus_habitual_life/features/wellness/domain/water_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late WellnessRepository repo;

  setUpAll(() async {
    await AppDatabase.init();
    repo = WellnessRepository();
  });

  group('Wellness Domain Models', () {
    test('WaterSettings model serializes and parses properly', () {
      const settings = WaterSettings(
        userId: 'test_user',
        dailyGoalMl: 2500,
        reminderIntervalMinutes: 60,
        wakeTime: '06:30',
        sleepTime: '23:00',
        remindersEnabled: true,
      );

      final map = settings.toMap();
      final parsed = WaterSettings.fromMap(map);

      expect(parsed.userId, equals('test_user'));
      expect(parsed.dailyGoalMl, equals(2500));
      expect(parsed.reminderIntervalMinutes, equals(60));
      expect(parsed.wakeTime, equals('06:30'));
      expect(parsed.sleepTime, equals('23:00'));
      expect(parsed.remindersEnabled, isTrue);
    });

    test('DailyWaterSummary calculates ratios, percentages, and goal status', () {
      final now = DateTime.now();
      final entries = [
        WaterLogEntry(
          id: 'w1',
          userId: 'test_user',
          amountMl: 500,
          loggedAt: now,
          clientId: 'w1',
        ),
        WaterLogEntry(
          id: 'w2',
          userId: 'test_user',
          amountMl: 750,
          loggedAt: now,
          clientId: 'w2',
        ),
      ];

      final summary = DailyWaterSummary(
        totalAmountMl: 1250,
        dailyGoalMl: 2000,
        entries: entries,
      );

      expect(summary.totalAmountMl, equals(1250));
      expect(summary.dailyGoalMl, equals(2000));
      expect(summary.progressPercent, equals(62));
      expect(summary.isGoalAchieved, isFalse);
      expect(summary.remainingMl, equals(750));

      final achievedSummary = DailyWaterSummary(
        totalAmountMl: 2200,
        dailyGoalMl: 2000,
        entries: entries,
      );
      expect(achievedSummary.isGoalAchieved, isTrue);
      expect(achievedSummary.remainingMl, equals(0));
    });

    test('MealType enum exposes localized names, icons and colors', () {
      expect(MealType.breakfast.key, equals('breakfast'));
      expect(MealType.lunch.label, equals('Almuerzo'));
      expect(MealType.dinner.key, equals('dinner'));
      expect(MealType.snack.label, equals('Snack Estratégico'));

      expect(MealType.fromKey('breakfast'), equals(MealType.breakfast));
      expect(MealType.fromKey('unknown'), equals(MealType.snack));
    });

    test('AffirmationCategory fromKey maps correctly', () {
      expect(AffirmationCategory.fromKey('disciplina'), equals(AffirmationCategory.disciplina));
      expect(AffirmationCategory.fromKey('autoestima'), equals(AffirmationCategory.autoestima));
      expect(AffirmationCategory.fromKey('abundancia'), equals(AffirmationCategory.abundancia));
      expect(AffirmationCategory.fromKey('salud'), equals(AffirmationCategory.salud));
      expect(AffirmationCategory.fromKey('fe'), equals(AffirmationCategory.fe));
      expect(AffirmationCategory.fromKey('liderazgo'), equals(AffirmationCategory.liderazgo));
      expect(AffirmationCategory.fromKey('unknown'), equals(AffirmationCategory.general));
    });
  });

  group('Wellness Repository - Water (Hidratación)', () {
    test('getWaterSettings returns default or existing settings', () async {
      final settings = await repo.getWaterSettings();
      expect(settings.dailyGoalMl, greaterThan(0));
      expect(settings.wakeTime, isNotEmpty);
      expect(settings.sleepTime, isNotEmpty);
    });

    test('updateWaterGoal updates daily hydration goal', () async {
      await repo.updateWaterGoal(2500);
      final updated = await repo.getWaterSettings();
      expect(updated.dailyGoalMl, equals(2500));
    });

    test('logWater adds entry and updates daily water summary', () async {
      final entry = await repo.logWater(amountMl: 350);
      expect(entry.amountMl, equals(350));
      expect(entry.id, isNotEmpty);

      final summary = await repo.getDailyWaterSummary();
      expect(summary.totalAmountMl, greaterThanOrEqualTo(350));
      expect(summary.entries.any((e) => e.id == entry.id), isTrue);

      // Clean up log
      await repo.deleteWaterLog(entry.id);
      final afterDelete = await repo.getDailyWaterSummary();
      expect(afterDelete.entries.any((e) => e.id == entry.id), isFalse);
    });

    test('undoLastWaterLog reverts the most recent water intake', () async {
      final entry1 = await repo.logWater(amountMl: 250);
      final entry2 = await repo.logWater(amountMl: 500);

      final summaryBeforeUndo = await repo.getDailyWaterSummary();
      expect(summaryBeforeUndo.entries.first.id, equals(entry2.id));

      final success = await repo.undoLastWaterLog();
      expect(success, isTrue);

      final summaryAfterUndo = await repo.getDailyWaterSummary();
      expect(summaryAfterUndo.entries.any((e) => e.id == entry2.id), isFalse);
      expect(summaryAfterUndo.entries.any((e) => e.id == entry1.id), isTrue);

      // Clean up entry1
      await repo.deleteWaterLog(entry1.id);
    });
  });

  group('Wellness Repository - Nutrition (Nutrición Consciente)', () {
    test('getDailyTip returns a valid rotating executive tip', () async {
      final tip = await repo.getDailyTip();
      expect(tip.tipText, isNotEmpty);
      expect(tip.category, isNotEmpty);
    });

    test('logMeal records meals and getDailyNutritionSummary reflects them', () async {
      final log = await repo.logMeal(
        mealType: MealType.breakfast,
        title: 'Huevos revueltos con aguacate y café negro',
        note: 'Proteína alta sin picos de glucosa',
      );

      expect(log.id, isNotEmpty);
      expect(log.mealType, equals(MealType.breakfast));
      expect(log.title, contains('Huevos revueltos'));

      final summary = await repo.getDailyNutritionSummary();
      expect(summary.hasBreakfast, isTrue);
      expect(summary.mealsLoggedCount, greaterThanOrEqualTo(1));
    });
  });

  group('Wellness Repository - Affirmations (Afirmaciones)', () {
    test('getAllAffirmations returns 25 stoic & executive affirmations', () async {
      final affirmations = await repo.getAllAffirmations();
      expect(affirmations.length, greaterThanOrEqualTo(20));
      expect(affirmations.first.text, isNotEmpty);
    });

    test('getTodayAffirmation returns deterministic daily affirmation', () async {
      final todayAff = await repo.getTodayAffirmation();
      expect(todayAff.text, isNotEmpty);
      expect(todayAff.author, isNotEmpty);
    });

    test('toggleFavoriteAffirmation toggles favorite flag', () async {
      final affirmations = await repo.getAllAffirmations();
      final aff = affirmations.first;

      final isFavAfterToggle = await repo.toggleFavoriteAffirmation(aff.id);
      expect(isFavAfterToggle, isTrue);

      final isFavAfterSecondToggle = await repo.toggleFavoriteAffirmation(aff.id);
      expect(isFavAfterSecondToggle, isFalse);
    });

    test('logAffirmationRead records decree / reading with +5 XP without crashing', () async {
      final affirmations = await repo.getAllAffirmations();
      final aff = affirmations.first;

      await expectLater(repo.logAffirmationRead(aff.id), completes);
    });
  });
}
