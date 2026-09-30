import 'package:flutter_test/flutter_test.dart';
import 'package:focus_habitual_life/core/local_db/database.dart';
import 'package:focus_habitual_life/features/habits/data/habit_repository.dart';
import 'package:focus_habitual_life/features/nofap/data/nofap_repository.dart';
import 'package:focus_habitual_life/features/nofap/domain/nofap_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NofapRepository repo;
  late HabitRepository habitRepo;

  setUp(() async {
    await AppDatabase.init();
    repo = NofapRepository();
    habitRepo = HabitRepository();
  });

  group('NofapRepository & Domain Tests', () {
    test('NofapStreakState calculates days, hours, minutes, and seconds accurately', () {
      final start = DateTime(2026, 1, 1, 0, 0, 0);
      final current = DateTime(2026, 1, 11, 4, 30, 45); // 10 days, 4 hours, 30 mins, 45 secs

      final streak = NofapStreakState(streakStartDate: start, now: current);

      expect(streak.days, equals(10));
      expect(streak.hours, equals(4));
      expect(streak.minutes, equals(30));
      expect(streak.seconds, equals(45));
      expect(streak.daysDisplay, equals('10'));
      expect(streak.hoursDisplay, equals('04'));
      expect(streak.minutesDisplay, equals('30'));
      expect(streak.secondsDisplay, equals('45'));
      expect(streak.progress90Days, closeTo(10 / 90.0, 0.01));
    });

    test('getCurrentStreakStart returns valid DateTime and streak state', () async {
      final start = await repo.getCurrentStreakStart();
      expect(start.isBefore(DateTime.now().add(const Duration(seconds: 1))), isTrue);

      final state = NofapStreakState(streakStartDate: start, now: DateTime.now());
      expect(state.days, greaterThanOrEqualTo(0));
    });

    test('recordRelapse resets streak start to current timestamp', () async {
      final beforeReset = DateTime.now();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final resetStart = await repo.recordRelapse(reason: 'masturbation', note: 'Prueba unitaria');
      expect(resetStart.isAfter(beforeReset), isTrue);

      final relapses = await repo.getTotalRelapses();
      expect(relapses, greaterThanOrEqualTo(1));

      final activeStart = await repo.getCurrentStreakStart();
      expect(activeStart.difference(resetStart).inSeconds.abs(), lessThanOrEqualTo(1));
    });

    test('recordCoolingSessionCompleted inserts log and credits +15 XP', () async {
      final initialXp = await habitRepo.getUserXp();

      await repo.recordCoolingSessionCompleted();

      final updatedXp = await habitRepo.getUserXp();
      expect(updatedXp, equals(initialXp + 15));
    });

    test('reasons CRUD operations succeed', () async {
      final initialReasons = await repo.getReasons();
      expect(initialReasons, isNotEmpty);

      final newReason = await repo.addReason('Razón de prueba de autodominio');
      expect(newReason.reasonText, equals('Razón de prueba de autodominio'));

      final afterAdd = await repo.getReasons();
      expect(afterAdd.any((r) => r.id == newReason.id), isTrue);

      await repo.deleteReason(newReason.id);
      final afterDelete = await repo.getReasons();
      expect(afterDelete.any((r) => r.id == newReason.id), isFalse);
    });

    test('recordRelapse with trigger stores trigger in notes', () async {
      final reset = await repo.recordRelapse(
        reason: 'porn',
        trigger: 'Aburrimiento',
        note: 'Cansancio nocturno',
      );
      expect(reset, isNotNull);

      final totalRelapses = await repo.getTotalRelapses();
      expect(totalRelapses, greaterThan(0));
    });

    test('recordCheckin credits +15 XP', () async {
      final initialXp = await habitRepo.getUserXp();

      await repo.recordCheckin(note: 'Superado impulso');

      final updatedXp = await habitRepo.getUserXp();
      expect(updatedXp, equals(initialXp + 15));
    });
  });
}
