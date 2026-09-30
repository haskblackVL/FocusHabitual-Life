import 'package:flutter_test/flutter_test.dart';
import 'package:focus_habitual_life/core/local_db/database.dart';
import 'package:focus_habitual_life/features/gratitude/domain/gratitude_model.dart';
import 'package:focus_habitual_life/features/gratitude/data/gratitude_repository.dart';
import 'package:focus_habitual_life/features/habits/domain/master_habits_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GratitudeRepository repo;

  setUpAll(() async {
    await AppDatabase.init();
    repo = GratitudeRepository(currentUserId: 'test_polymath_user');
  });

  group('Master Habits Catalog (50 Habits)', () {
    test('Catalog contains exactly 50 polymath habits', () {
      expect(MasterHabitsCatalog.allHabits.length, equals(50));
    });

    test('All 5 categories have appropriate distribution totaling 50', () {
      final clarity = MasterHabitsCatalog.getByCategory(MasterHabitCategory.clarity);
      final bio = MasterHabitsCatalog.getByCategory(MasterHabitCategory.biohacking);
      final finance = MasterHabitsCatalog.getByCategory(MasterHabitCategory.finance);
      final self = MasterHabitsCatalog.getByCategory(MasterHabitCategory.selfMastery);
      final rel = MasterHabitsCatalog.getByCategory(MasterHabitCategory.relationships);

      expect(clarity.length, equals(10));
      expect(bio.length, equals(12));
      expect(finance.length, equals(10));
      expect(self.length, equals(10));
      expect(rel.length, equals(8));
      expect(clarity.length + bio.length + finance.length + self.length + rel.length, equals(50));
    });

    test('Every habit has rich data and neuroscientific rationale', () {
      final ids = <String>{};
      for (final habit in MasterHabitsCatalog.allHabits) {
        expect(habit.id.isNotEmpty, isTrue);
        expect(ids.contains(habit.id), isFalse, reason: 'Duplicate habit ID: ${habit.id}');
        ids.add(habit.id);

        expect(habit.title.isNotEmpty, isTrue);
        expect(habit.shortDescription.isNotEmpty, isTrue);
        expect(habit.scientificRationale.isNotEmpty, isTrue);
        expect(habit.xpReward, greaterThanOrEqualTo(10));
        expect(habit.targetCount, greaterThanOrEqualTo(1));
      }
    });
  });

  group('Gratitude & Stoic Reflection Domain & Repository', () {
    test('StoicQuote.forDate rotates quotes deterministically', () {
      final q1 = StoicQuote.forDate(DateTime(2026, 9, 24));
      final q2 = StoicQuote.forDate(DateTime(2026, 9, 24));
      expect(q1.quote, equals(q2.quote));
      expect(q1.author, equals(q2.author));

      expect(StoicQuote.curatedQuotes.length, greaterThanOrEqualTo(10));
    });

    test('GratitudeRepository saves entry and enqueues to sync_queue', () async {
      final entry = await repo.saveEntry(
        item1: 'Claridad mental en el sprint matutino',
        item2: 'Conversación técnica con el equipo',
        item3: 'Caminata de 15 minutos en silencio',
        reflection: 'La disciplina es libertad.',
      );

      expect(entry.item1, equals('Claridad mental en el sprint matutino'));
      expect(entry.item2, equals('Conversación técnica con el equipo'));
      expect(entry.item3, equals('Caminata de 15 minutos en silencio'));
      expect(entry.reflection, equals('La disciplina es libertad.'));
      expect(entry.items.length, equals(3));
      expect(entry.combinedContent.contains('1. Claridad mental'), isTrue);

      // Verify today's entry retrieval
      final today = await repo.getTodayEntry();
      expect(today, isNotNull);
      expect(today?.id, equals(entry.id));

      // Verify sync_queue entry
      final pending = AppDatabase.getPendingSync(limit: 50);
      final gratitudeQueue = pending.where((q) => q['table_name'] == 'gratitude_entries');
      expect(gratitudeQueue.isNotEmpty, isTrue);
      expect(gratitudeQueue.last['action'], equals('INSERT'));
    });

    test('Gratitude streak calculates correctly', () async {
      final streak = await repo.getGratitudeStreak();
      expect(streak, greaterThanOrEqualTo(1));
    });
  });
}
