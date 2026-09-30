import 'package:flutter_test/flutter_test.dart';
import 'package:focus_habitual_life/core/gamification/achievement_engine.dart';
import 'package:focus_habitual_life/core/gamification/achievement_model.dart';
import 'package:focus_habitual_life/core/gamification/data/achievement_repository.dart';
import 'package:focus_habitual_life/core/gamification/gamification_controller.dart';
import 'package:focus_habitual_life/core/local_db/database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AchievementRepository repository;
  late AchievementEngine engine;
  const testUserId = 'test_polymath_achiever';

  setUpAll(() async {
    await AppDatabase.init();
    repository = const AchievementRepository();
    engine = AchievementEngine(repository);
  });

  group('MasterAchievements Catalog Integrity', () {
    test('Contains exactly 43 curated master achievements', () {
      expect(MasterAchievements.all.length, equals(43));
    });

    test('All achievement keys are unique and non-empty', () {
      final keys = <String>{};
      for (final def in MasterAchievements.all) {
        expect(def.key.isNotEmpty, isTrue);
        expect(keys.contains(def.key), isFalse, reason: 'Duplicate key: ${def.key}');
        keys.add(def.key);
      }
    });

    test('All modules and tiers are represented with valid XP rewards', () {
      final modules = MasterAchievements.all.map((a) => a.module).toSet();
      expect(modules.contains(AchievementModule.habits), isTrue);
      expect(modules.contains(AchievementModule.pomodoro), isTrue);
      expect(modules.contains(AchievementModule.wellness), isTrue);
      expect(modules.contains(AchievementModule.challenges), isTrue);
      expect(modules.contains(AchievementModule.nofap), isTrue);
      expect(modules.contains(AchievementModule.cycle), isTrue);
      expect(modules.contains(AchievementModule.religion), isTrue);
      expect(modules.contains(AchievementModule.finance), isTrue);
      expect(modules.contains(AchievementModule.gratitude), isTrue);
      expect(modules.contains(AchievementModule.polymath), isTrue);

      for (final def in MasterAchievements.all) {
        expect(def.title.isNotEmpty, isTrue);
        expect(def.description.isNotEmpty, isTrue);
        expect(def.xpReward, greaterThan(0));
        expect(def.icon, isNotNull);
      }
    });

    test('findByKey and byModule return correct definitions', () {
      final habitFirst = MasterAchievements.findByKey('habit_first');
      expect(habitFirst, isNotNull);
      expect(habitFirst!.module, equals(AchievementModule.habits));
      expect(habitFirst.tier, equals(AchievementTier.bronze));

      final pomodoroMedals = MasterAchievements.byModule(AchievementModule.pomodoro);
      expect(pomodoroMedals.length, equals(7));
    });
  });

  group('AchievementRepository & SQLite Persistence', () {
    test('Unlocks achievement, credits XP and prevents duplicate unlocks', () async {
      // 1. Initial state
      expect(repository.isUnlocked('habit_first', userId: testUserId), isFalse);

      // 2. Unlock
      final unlocked = await repository.unlockAchievement('habit_first', userId: testUserId);
      expect(unlocked, isNotNull);
      expect(unlocked!.key, equals('habit_first'));

      // 3. Status check
      expect(repository.isUnlocked('habit_first', userId: testUserId), isTrue);

      // 4. Duplicate unlock is idempotent
      final duplicate = await repository.unlockAchievement('habit_first', userId: testUserId);
      expect(duplicate, isNull);

      // 5. Retrieved list includes habit_first
      final list = await repository.getUnlockedAchievements(userId: testUserId);
      expect(list.any((a) => a.definition.key == 'habit_first'), isTrue);
    });

    test('awardXp increments user XP, checks level thresholds, and logs event', () async {
      final initialXp = await repository.getUserXp(userId: testUserId);
      final newXp = await repository.awardXp(
        sourceModule: 'pomodoro_test',
        amount: 500,
        userId: testUserId,
      );
      expect(newXp, equals(initialXp + 500));

      final recentEvents = repository.getRecentXpEvents(userId: testUserId);
      expect(recentEvents.any((e) => e['source_module'] == 'pomodoro_test'), isTrue);

      // With > 400 XP, level should be at least 3, which triggers level_3_polymath medal
      expect(repository.isUnlocked('level_3_polymath', userId: testUserId), isTrue);
    });
  });

  group('AchievementEngine Multi-Module Evaluation', () {
    test('evaluateAll detects completed records in SQLite tables and awards medals', () async {
      final db = AppDatabase.instance;

      // Seed 1 pomodoro session
      db.execute('''
        INSERT INTO pomodoro_sessions (id, user_id, duration_minutes, task_tag, started_at, completed_at, was_completed, client_updated_at)
        VALUES ('p_test_1', '$testUserId', 25, 'deep_work', datetime('now'), datetime('now'), 1, datetime('now'))
      ''');

      // Seed 1 gratitude entry
      db.execute('''
        INSERT INTO gratitude_entries (id, user_id, entry_date, item1, item2, item3, reflection, prompt_used, created_at, client_id, client_updated_at)
        VALUES ('g_test_1', '$testUserId', '2026-09-25', 'Familia', 'Salud', 'Trabajo', 'Excelente día', 'Mañana', datetime('now'), 'g_cid_1', datetime('now'))
      ''');

      // Seed 1 water log
      db.execute('''
        INSERT INTO water_log (id, user_id, amount_ml, logged_at, client_id, client_updated_at)
        VALUES ('w_test_1', '$testUserId', 500, datetime('now'), 'w_cid_1', datetime('now'))
      ''');

      await engine.evaluateAll(userId: testUserId);

      // pomodoro_first, gratitude_first, and water_first should be among unlocked
      final unlockedList = await repository.getUnlockedAchievements(userId: testUserId);
      final unlockedKeys = unlockedList.map((a) => a.definition.key).toSet();

      expect(unlockedKeys.contains('pomodoro_first'), isTrue);
      expect(unlockedKeys.contains('gratitude_first'), isTrue);
      expect(unlockedKeys.contains('water_first'), isTrue);
    });
  });

  group('GamificationState Telemetry & Calculations', () {
    test('Calculates exact level boundaries and progress percentage', () {
      final state = GamificationState.create(
        totalXp: 250,
        unlockedAchievements: [
          UnlockedAchievement(
            definition: MasterAchievements.findByKey('habit_first')!,
            unlockedAt: DateTime.now(),
          ),
        ],
      );

      // Level 2 (100 to 400)
      expect(state.level, equals(2));
      expect(state.currentLevelMinXp, equals(100));
      expect(state.nextLevelMinXp, equals(400));
      expect(state.xpRemainingToNextLevel, equals(150));
      expect(state.levelProgress, closeTo(0.5, 0.01));
      expect(state.totalUnlockedCount, equals(1));
      expect(state.totalAvailableCount, equals(MasterAchievements.all.length));
      expect(state.completionPercentage, closeTo(1 / MasterAchievements.all.length, 0.01));
      expect(state.recentAchievements.length, equals(1));
    });
  });
}
