import '../../local_db/database.dart';
import '../achievement_model.dart';
import '../xp_engine.dart';

/// Repository managing local SQLite persistence and queries for achievements and XP.
class AchievementRepository {
  const AchievementRepository();

  /// Retrieves all unlocked achievements for [userId].
  Future<List<UnlockedAchievement>> getUnlockedAchievements({String userId = 'local_user'}) async {
    final rows = AppDatabase.getUnlockedAchievements(userId: userId);
    final List<UnlockedAchievement> result = [];

    for (final row in rows) {
      final key = row['achievement_key'] as String;
      final def = MasterAchievements.findByKey(key);
      if (def != null) {
        final unlockedAt = DateTime.tryParse(row['unlocked_at'] as String) ?? DateTime.now();
        result.add(UnlockedAchievement(definition: def, unlockedAt: unlockedAt));
      }
    }

    return result;
  }

  /// Attempts to unlock an achievement.
  /// If it's a new unlock, credits its XP reward and logs an XP event.
  /// Returns the [AchievementDefinition] if newly unlocked, or null if already unlocked or not found.
  Future<AchievementDefinition?> unlockAchievement(
    String key, {
    String userId = 'local_user',
  }) async {
    final def = MasterAchievements.findByKey(key);
    if (def == null) return null;

    final isNew = AppDatabase.unlockAchievement(
      achievementKey: key,
      module: def.module.key,
      userId: userId,
    );

    if (isNew) {
      // Record XP reward for this achievement
      AppDatabase.recordXpEvent(
        sourceModule: 'achievement',
        xpAmount: def.xpReward,
        userId: userId,
      );

      // Increment user_xp
      final db = AppDatabase.instance;
      final xpRows = db.select('SELECT total_xp FROM user_xp WHERE user_id = ?', [userId]);
      int currentXp = 0;
      if (xpRows.isNotEmpty) {
        currentXp = (xpRows.first['total_xp'] as int?) ?? 0;
      }
      final newXp = currentXp + def.xpReward;
      final newLevel = XpEngine.calculateLevel(newXp);
      final now = DateTime.now().toIso8601String();

      db.execute('''
        INSERT OR REPLACE INTO user_xp (user_id, total_xp, level, updated_at)
        VALUES (?, ?, ?, ?)
      ''', [userId, newXp, newLevel, now]);

      return def;
    }

    return null;
  }

  /// Checks if an achievement is already unlocked.
  bool isUnlocked(String key, {String userId = 'local_user'}) {
    return AppDatabase.isAchievementUnlocked(key, userId: userId);
  }

  /// Records an XP event and updates total XP and level in SQLite.
  Future<int> awardXp({
    required String sourceModule,
    required int amount,
    String userId = 'local_user',
  }) async {
    if (amount <= 0) return 0;

    AppDatabase.recordXpEvent(
      sourceModule: sourceModule,
      xpAmount: amount,
      userId: userId,
    );

    final db = AppDatabase.instance;
    final xpRows = db.select('SELECT total_xp FROM user_xp WHERE user_id = ?', [userId]);
    int currentXp = 0;
    if (xpRows.isNotEmpty) {
      currentXp = (xpRows.first['total_xp'] as int?) ?? 0;
    }
    final newXp = currentXp + amount;
    final newLevel = XpEngine.calculateLevel(newXp);
    final now = DateTime.now().toIso8601String();

    db.execute('''
      INSERT OR REPLACE INTO user_xp (user_id, total_xp, level, updated_at)
      VALUES (?, ?, ?, ?)
    ''', [userId, newXp, newLevel, now]);

    // Check level achievements automatically
    checkLevelAchievements(newLevel, userId: userId);

    return newXp;
  }

  /// Evaluates level milestone achievements.
  void checkLevelAchievements(int level, {String userId = 'local_user'}) {
    if (level >= 3) unlockAchievement('level_3_polymath', userId: userId);
    if (level >= 5) unlockAchievement('level_5_polymath', userId: userId);
    if (level >= 10) unlockAchievement('level_10_polymath', userId: userId);
    if (level >= 20) unlockAchievement('level_20_polymath', userId: userId);
  }

  /// Retrieves user's total XP from SQLite.
  Future<int> getUserXp({String userId = 'local_user'}) async {
    try {
      final db = AppDatabase.instance;
      final xpRows = db.select('SELECT total_xp FROM user_xp WHERE user_id = ?', [userId]);
      if (xpRows.isNotEmpty) {
        return (xpRows.first['total_xp'] as int?) ?? 0;
      }
    } catch (_) {}
    return 0;
  }

  /// Retrieves recent XP event history.
  List<Map<String, dynamic>> getRecentXpEvents({String userId = 'local_user', int limit = 20}) {
    return AppDatabase.getRecentXpEvents(userId: userId, limit: limit);
  }
}
