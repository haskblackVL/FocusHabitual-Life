import '../local_db/database.dart';
import 'achievement_model.dart';
import 'data/achievement_repository.dart';

/// Central evaluation engine that checks criteria across all modules of FocusHabitual Life
/// and automatically unlocks achievements in SQLite.
class AchievementEngine {
  final AchievementRepository _repository;

  const AchievementEngine([this._repository = const AchievementRepository()]);

  /// Evaluates all modules and returns any newly unlocked achievements.
  Future<List<AchievementDefinition>> evaluateAll({String userId = 'local_user'}) async {
    final List<AchievementDefinition> newlyUnlocked = [];

    try {
      final db = AppDatabase.instance;

      // 1. Hábitos
      final habitLogs = db.select('SELECT count(*) as count FROM habit_logs WHERE user_id = ?', [userId]);
      final habitCount = (habitLogs.first['count'] as int?) ?? 0;
      if (habitCount >= 1) await _tryUnlock('habit_first', newlyUnlocked, userId);
      if (habitCount >= 3) await _tryUnlock('habit_streak_3', newlyUnlocked, userId);
      if (habitCount >= 7) await _tryUnlock('habit_streak_7', newlyUnlocked, userId);
      if (habitCount >= 21) await _tryUnlock('habit_streak_21', newlyUnlocked, userId);
      if (habitCount >= 50) await _tryUnlock('habit_streak_50', newlyUnlocked, userId);

      // 2. Pomodoro
      final pomodoroRows = db.select('SELECT count(*) as count FROM pomodoro_sessions WHERE user_id = ? AND was_completed = 1', [userId]);
      final pomodoroCount = (pomodoroRows.first['count'] as int?) ?? 0;
      if (pomodoroCount >= 1) await _tryUnlock('pomodoro_first', newlyUnlocked, userId);
      if (pomodoroCount >= 5) await _tryUnlock('pomodoro_5', newlyUnlocked, userId);
      if (pomodoroCount >= 25) await _tryUnlock('pomodoro_25', newlyUnlocked, userId);
      if (pomodoroCount >= 100) await _tryUnlock('pomodoro_100', newlyUnlocked, userId);

      // Deep Work, Flowmodoro & Ultradiano evaluations per Pomodoro.md
      final deepWorkRows = db.select(
        "SELECT count(*) as count FROM pomodoro_sessions WHERE user_id = ? AND was_completed = 1 AND work_type = 'deep_work'",
        [userId],
      );
      final deepWorkCount = (deepWorkRows.first['count'] as int?) ?? 0;
      if (deepWorkCount >= 10) await _tryUnlock('deep_work_10_sessions', newlyUnlocked, userId);

      final flowmodoroRows = db.select(
        "SELECT count(*) as count FROM pomodoro_sessions WHERE user_id = ? AND was_completed = 1 AND mode_key = 'flowmodoro'",
        [userId],
      );
      final flowmodoroCount = (flowmodoroRows.first['count'] as int?) ?? 0;
      if (flowmodoroCount >= 1) await _tryUnlock('flowmodoro_explorer', newlyUnlocked, userId);

      final ultradianDays = db.select('''
        SELECT count(*) as count FROM (
          SELECT substr(started_at, 1, 10) as day, count(*) as ultradian_count
          FROM pomodoro_sessions
          WHERE user_id = ? AND was_completed = 1 AND mode_key = 'ultradian'
          GROUP BY day
          HAVING ultradian_count >= 2
        )
      ''', [userId]);
      final ultradianDaysCount = (ultradianDays.first['count'] as int?) ?? 0;
      if (ultradianDaysCount >= 1) await _tryUnlock('ultradian_master', newlyUnlocked, userId);

      // 3. Agua
      final waterRows = db.select('SELECT count(*) as count FROM water_log WHERE user_id = ?', [userId]);
      final waterCount = (waterRows.first['count'] as int?) ?? 0;
      if (waterCount >= 1) await _tryUnlock('water_first', newlyUnlocked, userId);

      final daysGoalMet = db.select('''
        SELECT count(*) as count FROM (
          SELECT substr(logged_at, 1, 10) as day, sum(amount_ml) as total
          FROM water_log
          WHERE user_id = ?
          GROUP BY day
          HAVING total >= 2000
        )
      ''', [userId]);
      final goalMetCount = (daysGoalMet.first['count'] as int?) ?? 0;
      if (goalMetCount >= 1) await _tryUnlock('water_goal_1d', newlyUnlocked, userId);
      if (goalMetCount >= 7) await _tryUnlock('water_goal_7d', newlyUnlocked, userId);

      // 4. Nutrición
      final mealRows = db.select('SELECT count(*) as count FROM nutrition_log WHERE user_id = ?', [userId]);
      final mealCount = (mealRows.first['count'] as int?) ?? 0;
      if (mealCount >= 1) await _tryUnlock('nutrition_first', newlyUnlocked, userId);
      if (mealCount >= 7) await _tryUnlock('nutrition_streak_7', newlyUnlocked, userId);

      // 5. Afirmaciones
      final affLogs = db.select('SELECT count(*) as count FROM affirmation_log WHERE user_id = ?', [userId]);
      final affCount = (affLogs.first['count'] as int?) ?? 0;
      if (affCount >= 1) await _tryUnlock('affirmation_first', newlyUnlocked, userId);

      final favAff = db.select('SELECT count(*) as count FROM affirmation_log WHERE user_id = ? AND is_favorite = 1', [userId]);
      final favCount = (favAff.first['count'] as int?) ?? 0;
      if (favCount >= 5) await _tryUnlock('affirmation_favorite_5', newlyUnlocked, userId);

      // 6. Retos 21 Días (Meditación, Yoga, Yoga Facial)
      final challengeProgress = db.select('''
        SELECT c.challenge_type, count(p.day_number) as completed_days
        FROM wellness_challenges c
        JOIN wellness_challenge_progress p ON c.id = p.challenge_id
        WHERE c.user_id = ?
        GROUP BY c.challenge_type
      ''', [userId]);

      for (final row in challengeProgress) {
        final cType = row['challenge_type'] as String;
        final days = (row['completed_days'] as int?) ?? 0;

        if (cType == 'meditation') {
          if (days >= 1) await _tryUnlock('meditation_first', newlyUnlocked, userId);
          if (days >= 21) await _tryUnlock('meditation_streak_21', newlyUnlocked, userId);
        } else if (cType == 'yoga') {
          if (days >= 1) await _tryUnlock('yoga_first', newlyUnlocked, userId);
          if (days >= 21) await _tryUnlock('yoga_streak_21', newlyUnlocked, userId);
        } else if (cType == 'yoga_facial') {
          if (days >= 1) await _tryUnlock('facial_first', newlyUnlocked, userId);
          if (days >= 21) await _tryUnlock('facial_streak_21', newlyUnlocked, userId);
        }
      }

      // 7. NoFap
      final lastRelapse = db.select('''
        SELECT occurred_at FROM nofap_log
        WHERE user_id = ? AND event_type = 'relapse'
        ORDER BY occurred_at DESC LIMIT 1
      ''', [userId]);

      DateTime streakStart = DateTime.now().subtract(const Duration(days: 0));
      if (lastRelapse.isNotEmpty) {
        streakStart = DateTime.parse(lastRelapse.first['occurred_at'] as String);
      } else {
        final firstLog = db.select('SELECT occurred_at FROM nofap_log WHERE user_id = ? ORDER BY occurred_at ASC LIMIT 1', [userId]);
        if (firstLog.isNotEmpty) {
          streakStart = DateTime.parse(firstLog.first['occurred_at'] as String);
        }
      }
      final cleanDays = DateTime.now().difference(streakStart).inDays;
      if (cleanDays >= 3) await _tryUnlock('nofap_3d', newlyUnlocked, userId);
      if (cleanDays >= 7) await _tryUnlock('nofap_7d', newlyUnlocked, userId);
      if (cleanDays >= 21) await _tryUnlock('nofap_21d', newlyUnlocked, userId);
      if (cleanDays >= 90) await _tryUnlock('nofap_reboot_90d', newlyUnlocked, userId);

      // 8. Ciclo
      final cycleRows = db.select('SELECT count(*) as count FROM cycle_log WHERE user_id = ?', [userId]);
      final cycleCount = (cycleRows.first['count'] as int?) ?? 0;
      if (cycleCount >= 1) await _tryUnlock('cycle_first_log', newlyUnlocked, userId);
      if (cycleCount >= 3) await _tryUnlock('cycle_tracked_3', newlyUnlocked, userId);

      // 9. Religión
      final relRows = db.select('SELECT count(*) as count FROM religion_user_log WHERE user_id = ?', [userId]);
      final relCount = (relRows.first['count'] as int?) ?? 0;
      if (relCount >= 1) await _tryUnlock('devotional_first', newlyUnlocked, userId);
      if (relCount >= 7) await _tryUnlock('devotional_streak_7', newlyUnlocked, userId);

      final prayerRows = db.select('SELECT count(*) as count FROM prayer_requests WHERE user_id = ?', [userId]);
      final prayerCount = (prayerRows.first['count'] as int?) ?? 0;
      if (prayerCount >= 5) await _tryUnlock('prayer_warrior', newlyUnlocked, userId);

      // 10. Finanzas
      final txRows = db.select('SELECT count(*) as count FROM finance_transactions WHERE user_id = ?', [userId]);
      final txCount = (txRows.first['count'] as int?) ?? 0;
      if (txCount >= 1) await _tryUnlock('finance_first_tx', newlyUnlocked, userId);

      final budgetRows = db.select('SELECT count(*) as count FROM finance_budgets WHERE user_id = ?', [userId]);
      final budgetCount = (budgetRows.first['count'] as int?) ?? 0;
      if (budgetCount >= 1) await _tryUnlock('finance_budget_set', newlyUnlocked, userId);

      // 11. Gratitud
      final gratRows = db.select('SELECT count(*) as count FROM gratitude_entries WHERE user_id = ?', [userId]);
      final gratCount = (gratRows.first['count'] as int?) ?? 0;
      if (gratCount >= 1) await _tryUnlock('gratitude_first', newlyUnlocked, userId);
      if (gratCount >= 7) await _tryUnlock('gratitude_streak_7', newlyUnlocked, userId);

      // 12. Nivel
      final xpRows = db.select('SELECT level FROM user_xp WHERE user_id = ?', [userId]);
      if (xpRows.isNotEmpty) {
        final level = (xpRows.first['level'] as int?) ?? 1;
        if (level >= 3) await _tryUnlock('level_3_polymath', newlyUnlocked, userId);
        if (level >= 5) await _tryUnlock('level_5_polymath', newlyUnlocked, userId);
        if (level >= 10) await _tryUnlock('level_10_polymath', newlyUnlocked, userId);
        if (level >= 20) await _tryUnlock('level_20_polymath', newlyUnlocked, userId);
      }
    } catch (_) {
      // Tables might be initializing or empty
    }

    return newlyUnlocked;
  }

  Future<void> _tryUnlock(
    String key,
    List<AchievementDefinition> accumulator,
    String userId,
  ) async {
    final unlocked = await _repository.unlockAchievement(key, userId: userId);
    if (unlocked != null) {
      accumulator.add(unlocked);
    }
  }
}
