import 'package:flutter_test/flutter_test.dart';
import 'package:focus_habitual_life/core/local_db/database.dart';
import 'package:focus_habitual_life/features/analytics/data/analytics_repository.dart';
import 'package:focus_habitual_life/features/analytics/domain/analytics_data.dart';
import 'package:focus_habitual_life/features/habits/data/habit_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AnalyticsRepository analyticsRepo;
  late HabitRepository habitRepo;

  setUp(() async {
    await AppDatabase.init();
    analyticsRepo = AnalyticsRepository();
    habitRepo = HabitRepository();
  });

  group('AnalyticsRepository Tests', () {
    test('getSummary returns default summary for week, month, and year', () async {
      for (final range in TimeRange.values) {
        final summary = await analyticsRepo.getSummary(range);

        expect(summary.range, equals(range));
        expect(summary.dailyMetrics, isNotEmpty);
        expect(summary.heatmapDays, isNotEmpty);
        expect(summary.currentLevel, greaterThanOrEqualTo(0));
        expect(summary.levelTitle, isNotEmpty);
        expect(summary.consistencyRate, inInclusiveRange(0.0, 1.0));
      }
    });

    test('getSummary reflects habit completions and Pomodoro focus time', () async {
      final initialSummary = await analyticsRepo.getSummary(TimeRange.week);

      // Fetch active habits to toggle one
      final habits = await habitRepo.getHabitsWithStatus();
      expect(habits, isNotEmpty);

      // Complete a habit
      final firstHabit = habits.first;
      await habitRepo.toggleHabitCompletion(firstHabit.habit.id);

      // Record a 25-minute Pomodoro session
      await habitRepo.recordPomodoroSession(durationMinutes: 25, taskTag: 'Deep Work');

      // Re-fetch analytics summary
      final updatedSummary = await analyticsRepo.getSummary(TimeRange.week);

      expect(
        updatedSummary.totalHabitsCompleted,
        greaterThanOrEqualTo(initialSummary.totalHabitsCompleted + 1),
      );
      expect(
        updatedSummary.totalFocusMinutes,
        greaterThanOrEqualTo(initialSummary.totalFocusMinutes + 25),
      );
      expect(
        updatedSummary.totalSessionsCompleted,
        greaterThanOrEqualTo(initialSummary.totalSessionsCompleted + 1),
      );
      expect(updatedSummary.formattedFocusTime, isNotEmpty);
    });

    test('Heatmap days generation returns 42 days with valid intensity', () async {
      final summary = await analyticsRepo.getSummary(TimeRange.week);

      expect(summary.heatmapDays.length, equals(42));
      for (final day in summary.heatmapDays) {
        expect(day.intensityLevel, inInclusiveRange(0, 4));
        expect(day.count, greaterThanOrEqualTo(0));
      }
    });
  });
}
