import 'package:flutter_test/flutter_test.dart';
import 'package:focus_habitual_life/core/local_db/database.dart';
import 'package:focus_habitual_life/features/habits/data/habit_repository.dart';
import 'package:focus_habitual_life/features/habits/domain/habit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await AppDatabase.init();
  });

  group('HabitRepository Tests', () {
    late HabitRepository repo;

    setUp(() {
      repo = HabitRepository();
    });

    test('getHabitsWithStatus returns seeded polymath habits', () async {
      final habits = await repo.getHabitsWithStatus();
      expect(habits, isNotEmpty);
      expect(habits.any((h) => h.habit.title.contains('Lectura')), isTrue);
    });

    test('toggleHabitCompletion increments XP and marks habit completed', () async {
      final habits = await repo.getHabitsWithStatus();
      final target = habits.first;

      final initialXp = await repo.getUserXp();
      final isNowCompleted = await repo.toggleHabitCompletion(target.habit.id);
      expect(isNowCompleted, isTrue);

      final newXp = await repo.getUserXp();
      expect(newXp, equals(initialXp + 10));

      // Untoggle should revert XP
      final isReverted = await repo.toggleHabitCompletion(target.habit.id);
      expect(isReverted, isFalse);

      final revertedXp = await repo.getUserXp();
      expect(revertedXp, equals(initialXp));
    });

    test('addHabit inserts a custom habit that can be fetched', () async {
      await repo.addHabit(
        title: 'Estudio de Lenguajes',
        description: 'Práctica diaria de vocabulario',
        category: HabitCategory.general,
      );

      final habits = await repo.getHabitsWithStatus();
      expect(habits.any((h) => h.habit.title == 'Estudio de Lenguajes'), isTrue);
    });

    test('recordPomodoroSession adds session and credits +25 XP', () async {
      final initialXp = await repo.getUserXp();
      await repo.recordPomodoroSession(
        durationMinutes: 25,
        taskTag: 'Investigación',
      );

      final newXp = await repo.getUserXp();
      expect(newXp, equals(initialXp + 25));
    });
  });
}
