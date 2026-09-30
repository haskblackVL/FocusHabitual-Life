import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../core/gamification/xp_engine.dart';
import '../../../core/local_db/database.dart';
import '../domain/affirmation.dart';
import '../domain/challenge_data.dart';
import '../domain/nutrition_data.dart';
import '../domain/water_data.dart';

class WellnessRepository {
  WellnessRepository({this.currentUserId});

  final String? currentUserId;
  final _uuid = const Uuid();

  String get _activeUserId => currentUserId ?? 'local_user';

  // ---------------------------------------------------------------------------
  // 1. WATER & HYDRATION
  // ---------------------------------------------------------------------------

  Future<WaterSettings> getWaterSettings({String? userId}) async {
    final effectiveUserId = userId ?? _activeUserId;
    try {
      final rows = AppDatabase.instance.select(
        'SELECT * FROM water_settings WHERE user_id = ?',
        [effectiveUserId],
      );

      if (rows.isNotEmpty) {
        return WaterSettings.fromMap(rows.first);
      }

      // Default settings
      final defaultSettings = WaterSettings(userId: effectiveUserId);
      final now = DateTime.now().toIso8601String();
      AppDatabase.instance.execute('''
        INSERT OR REPLACE INTO water_settings (user_id, daily_goal_ml, reminder_interval_minutes, wake_time, sleep_time, reminders_enabled, client_updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?)
      ''', [
        effectiveUserId,
        defaultSettings.dailyGoalMl,
        defaultSettings.reminderIntervalMinutes,
        defaultSettings.wakeTime,
        defaultSettings.sleepTime,
        defaultSettings.remindersEnabled ? 1 : 0,
        now,
      ]);
      return defaultSettings;
    } catch (e) {
      if (kDebugMode) print('[WellnessRepository] Error getting water settings: $e');
      return WaterSettings(userId: effectiveUserId);
    }
  }

  Future<void> updateWaterGoal(int goalMl, {String? userId}) async {
    final effectiveUserId = userId ?? _activeUserId;
    try {
      final now = DateTime.now().toIso8601String();
      AppDatabase.instance.execute('''
        INSERT INTO water_settings (user_id, daily_goal_ml, reminder_interval_minutes, wake_time, sleep_time, reminders_enabled, client_updated_at)
        VALUES (?, ?, 90, '07:00', '22:30', 1, ?)
        ON CONFLICT(user_id) DO UPDATE SET
          daily_goal_ml = excluded.daily_goal_ml,
          client_updated_at = excluded.client_updated_at
      ''', [effectiveUserId, goalMl, now]);

      AppDatabase.enqueueSync(
        tableName: 'water_settings',
        recordId: effectiveUserId,
        action: 'UPSERT',
        payload: {
          'user_id': effectiveUserId,
          'daily_goal_ml': goalMl,
          'client_updated_at': now,
        },
      );
    } catch (e) {
      if (kDebugMode) print('[WellnessRepository] Error updating water goal: $e');
    }
  }

  Future<WaterLogEntry> logWater({
    required int amountMl,
    String? userId,
  }) async {
    final effectiveUserId = userId ?? _activeUserId;
    final id = _uuid.v4();
    final now = DateTime.now();
    final nowIso = now.toIso8601String();

    // Check if goal was already achieved before this log
    final summaryBefore = await getDailyWaterSummary(userId: effectiveUserId);
    final wasGoalAchievedBefore = summaryBefore.isGoalAchieved;

    AppDatabase.instance.execute('''
      INSERT INTO water_log (id, user_id, amount_ml, logged_at, client_id, client_updated_at)
      VALUES (?, ?, ?, ?, ?, ?)
    ''', [id, effectiveUserId, amountMl, nowIso, id, nowIso]);

    AppDatabase.enqueueSync(
      tableName: 'water_log',
      recordId: id,
      action: 'INSERT',
      payload: {
        'id': id,
        'user_id': effectiveUserId,
        'amount_ml': amountMl,
        'logged_at': nowIso,
        'client_id': id,
        'client_updated_at': nowIso,
      },
    );

    // Gamification: Base water log XP
    int earnedXp = XpEngine.waterLogXp;

    // Check if this log achieved the goal for the first time today
    final newTotal = summaryBefore.totalAmountMl + amountMl;
    if (!wasGoalAchievedBefore && newTotal >= summaryBefore.dailyGoalMl) {
      earnedXp += XpEngine.waterGoalBonusXp;
    }

    _addXp(effectiveUserId, earnedXp);

    return WaterLogEntry(
      id: id,
      userId: effectiveUserId,
      amountMl: amountMl,
      loggedAt: now,
      clientId: id,
    );
  }

  Future<List<WaterLogEntry>> getTodayWaterLogs({String? userId}) async {
    final effectiveUserId = userId ?? _activeUserId;
    try {
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final rows = AppDatabase.instance.select('''
        SELECT * FROM water_log
        WHERE user_id = ? AND logged_at LIKE ?
        ORDER BY logged_at DESC
      ''', [effectiveUserId, '$todayStr%']);

      return rows.map((r) => WaterLogEntry.fromMap(r)).toList();
    } catch (e) {
      if (kDebugMode) print('[WellnessRepository] Error getting today water logs: $e');
      return [];
    }
  }

  Future<DailyWaterSummary> getDailyWaterSummary({String? userId}) async {
    final effectiveUserId = userId ?? _activeUserId;
    final settings = await getWaterSettings(userId: effectiveUserId);
    final entries = await getTodayWaterLogs(userId: effectiveUserId);
    final totalMl = entries.fold<int>(0, (sum, entry) => sum + entry.amountMl);

    return DailyWaterSummary(
      totalAmountMl: totalMl,
      dailyGoalMl: settings.dailyGoalMl,
      entries: entries,
    );
  }

  Future<void> deleteWaterLog(String id, {String? userId}) async {
    final effectiveUserId = userId ?? _activeUserId;
    try {
      AppDatabase.instance.execute('DELETE FROM water_log WHERE id = ? AND user_id = ?', [id, effectiveUserId]);
      AppDatabase.enqueueSync(
        tableName: 'water_log',
        recordId: id,
        action: 'DELETE',
        payload: {'id': id, 'user_id': effectiveUserId},
      );
    } catch (e) {
      if (kDebugMode) print('[WellnessRepository] Error deleting water log: $e');
    }
  }

  Future<bool> undoLastWaterLog({String? userId}) async {
    final effectiveUserId = userId ?? _activeUserId;
    try {
      final todayLogs = await getTodayWaterLogs(userId: effectiveUserId);
      if (todayLogs.isNotEmpty) {
        final latest = todayLogs.first;
        await deleteWaterLog(latest.id, userId: effectiveUserId);
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) print('[WellnessRepository] Error undoing last water log: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // 2. NUTRITION & MINDFUL FUEL
  // ---------------------------------------------------------------------------

  Future<NutritionSettings> getNutritionSettings({String? userId}) async {
    final effectiveUserId = userId ?? _activeUserId;
    try {
      final rows = AppDatabase.instance.select(
        'SELECT * FROM nutrition_settings WHERE user_id = ?',
        [effectiveUserId],
      );

      if (rows.isNotEmpty) {
        return NutritionSettings.fromMap(rows.first);
      }

      final defaultSettings = NutritionSettings(userId: effectiveUserId);
      final now = DateTime.now().toIso8601String();
      AppDatabase.instance.execute('''
        INSERT OR REPLACE INTO nutrition_settings (user_id, breakfast_time, lunch_time, dinner_time, reminders_enabled, client_updated_at)
        VALUES (?, ?, ?, ?, ?, ?)
      ''', [
        effectiveUserId,
        defaultSettings.breakfastTime,
        defaultSettings.lunchTime,
        defaultSettings.dinnerTime,
        defaultSettings.remindersEnabled ? 1 : 0,
        now,
      ]);
      return defaultSettings;
    } catch (e) {
      if (kDebugMode) print('[WellnessRepository] Error getting nutrition settings: $e');
      return NutritionSettings(userId: effectiveUserId);
    }
  }

  Future<NutritionMealLog> logMeal({
    required MealType mealType,
    String? title,
    String? note,
    String? userId,
  }) async {
    final effectiveUserId = userId ?? _activeUserId;
    final id = _uuid.v4();
    final now = DateTime.now();
    final nowIso = now.toIso8601String();

    AppDatabase.instance.execute('''
      INSERT INTO nutrition_log (id, user_id, meal_type, title, note, logged_at, client_id, client_updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ''', [id, effectiveUserId, mealType.key, title, note, nowIso, id, nowIso]);

    AppDatabase.enqueueSync(
      tableName: 'nutrition_log',
      recordId: id,
      action: 'INSERT',
      payload: {
        'id': id,
        'user_id': effectiveUserId,
        'meal_type': mealType.key,
        'title': title,
        'note': note,
        'logged_at': nowIso,
        'client_id': id,
        'client_updated_at': nowIso,
      },
    );

    _addXp(effectiveUserId, XpEngine.nutritionLogXp);

    return NutritionMealLog(
      id: id,
      userId: effectiveUserId,
      mealType: mealType,
      title: title,
      note: note,
      loggedAt: now,
      clientId: id,
    );
  }

  Future<List<NutritionMealLog>> getTodayMeals({String? userId}) async {
    final effectiveUserId = userId ?? _activeUserId;
    try {
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final rows = AppDatabase.instance.select('''
        SELECT * FROM nutrition_log
        WHERE user_id = ? AND logged_at LIKE ?
        ORDER BY logged_at ASC
      ''', [effectiveUserId, '$todayStr%']);

      return rows.map((r) => NutritionMealLog.fromMap(r)).toList();
    } catch (e) {
      if (kDebugMode) print('[WellnessRepository] Error getting today meals: $e');
      return [];
    }
  }

  Future<NutritionTip> getDailyTip() async {
    try {
      final rows = AppDatabase.instance.select('SELECT * FROM nutrition_tips ORDER BY id ASC');
      if (rows.isNotEmpty) {
        final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
        final index = dayOfYear % rows.length;
        return NutritionTip.fromMap(rows[index]);
      }
    } catch (e) {
      if (kDebugMode) print('[WellnessRepository] Error getting daily tip: $e');
    }
    return const NutritionTip(
      id: 'default',
      tipText: 'Bebe 500 ml de agua templada antes de tu café para rehidratar tus células cerebrales.',
      category: 'foco',
    );
  }

  Future<DailyNutritionSummary> getDailyNutritionSummary({String? userId}) async {
    final effectiveUserId = userId ?? _activeUserId;
    final meals = await getTodayMeals(userId: effectiveUserId);
    final tip = await getDailyTip();
    return DailyNutritionSummary(mealsToday: meals, dailyTip: tip);
  }

  // ---------------------------------------------------------------------------
  // 3. POSITIVE AFFIRMATIONS
  // ---------------------------------------------------------------------------

  Future<Affirmation> getTodayAffirmation({String? userId}) async {
    final effectiveUserId = userId ?? _activeUserId;
    try {
      final rows = AppDatabase.instance.select('SELECT * FROM affirmations ORDER BY id ASC');
      if (rows.isNotEmpty) {
        final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
        final index = dayOfYear % rows.length;
        final affMap = rows[index];
        final affId = affMap['id'] as String;

        // Check if favorite
        final favRows = AppDatabase.instance.select(
          'SELECT is_favorite FROM affirmation_log WHERE user_id = ? AND affirmation_id = ?',
          [effectiveUserId, affId],
        );
        final isFav = favRows.isNotEmpty && (favRows.first['is_favorite'] as int? ?? 0) == 1;

        return Affirmation.fromMap(affMap, isFavorite: isFav);
      }
    } catch (e) {
      if (kDebugMode) print('[WellnessRepository] Error getting today affirmation: $e');
    }

    return const Affirmation(
      id: 'default',
      text: 'Mi enfoque no depende de mis emociones momentáneas; ejecuto con precisión y determinación.',
      category: AffirmationCategory.disciplina,
      author: 'Principio Rector',
    );
  }

  Future<List<Affirmation>> getAllAffirmations({
    AffirmationCategory? category,
    String? userId,
  }) async {
    final effectiveUserId = userId ?? _activeUserId;
    try {
      String query = 'SELECT * FROM affirmations';
      List<dynamic> params = [];
      if (category != null) {
        query += ' WHERE category = ?';
        params.add(category.key);
      }
      query += ' ORDER BY category ASC, id ASC';

      final rows = AppDatabase.instance.select(query, params);

      // Get user favorites
      final favRows = AppDatabase.instance.select(
        'SELECT affirmation_id FROM affirmation_log WHERE user_id = ? AND is_favorite = 1',
        [effectiveUserId],
      );
      final favSet = favRows.map((r) => r['affirmation_id'] as String).toSet();

      return rows.map((r) {
        final affId = r['id'] as String;
        return Affirmation.fromMap(r, isFavorite: favSet.contains(affId));
      }).toList();
    } catch (e) {
      if (kDebugMode) print('[WellnessRepository] Error getting all affirmations: $e');
      return [];
    }
  }

  Future<bool> toggleFavoriteAffirmation(String affirmationId, {String? userId}) async {
    final effectiveUserId = userId ?? _activeUserId;
    try {
      final now = DateTime.now().toIso8601String();
      final existing = AppDatabase.instance.select(
        'SELECT id, is_favorite FROM affirmation_log WHERE user_id = ? AND affirmation_id = ?',
        [effectiveUserId, affirmationId],
      );

      final newFav = existing.isEmpty || (existing.first['is_favorite'] as int? ?? 0) == 0;
      final logId = existing.isNotEmpty ? (existing.first['id'] as String) : _uuid.v4();

      AppDatabase.instance.execute('''
        INSERT INTO affirmation_log (id, user_id, affirmation_id, shown_at, is_favorite, client_id, client_updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET
          is_favorite = excluded.is_favorite,
          client_updated_at = excluded.client_updated_at
      ''', [logId, effectiveUserId, affirmationId, now, newFav ? 1 : 0, logId, now]);

      AppDatabase.enqueueSync(
        tableName: 'affirmation_log',
        recordId: logId,
        action: 'UPSERT',
        payload: {
          'id': logId,
          'user_id': effectiveUserId,
          'affirmation_id': affirmationId,
          'shown_at': now,
          'is_favorite': newFav ? 1 : 0,
          'client_id': logId,
          'client_updated_at': now,
        },
      );

      return newFav;
    } catch (e) {
      if (kDebugMode) print('[WellnessRepository] Error toggling affirmation favorite: $e');
      return false;
    }
  }

  Future<void> logAffirmationRead(String affirmationId, {String? userId}) async {
    final effectiveUserId = userId ?? _activeUserId;
    try {
      final id = _uuid.v4();
      final now = DateTime.now().toIso8601String();

      // Check if already read today
      final todayStr = now.substring(0, 10);
      final readToday = AppDatabase.instance.select('''
        SELECT id FROM affirmation_log
        WHERE user_id = ? AND affirmation_id = ? AND shown_at LIKE ?
      ''', [effectiveUserId, affirmationId, '$todayStr%']);

      if (readToday.isEmpty) {
        AppDatabase.instance.execute('''
          INSERT INTO affirmation_log (id, user_id, affirmation_id, shown_at, is_favorite, client_id, client_updated_at)
          VALUES (?, ?, ?, ?, 0, ?, ?)
        ''', [id, effectiveUserId, affirmationId, now, id, now]);

        AppDatabase.enqueueSync(
          tableName: 'affirmation_log',
          recordId: id,
          action: 'INSERT',
          payload: {
            'id': id,
            'user_id': effectiveUserId,
            'affirmation_id': affirmationId,
            'shown_at': now,
            'is_favorite': 0,
            'client_id': id,
            'client_updated_at': now,
          },
        );

        _addXp(effectiveUserId, XpEngine.affirmationReadXp);
      }
    } catch (e) {
      if (kDebugMode) print('[WellnessRepository] Error logging affirmation read: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // 4. RETOS DE BIENESTAR: MEDITACIÓN, YOGA & YOGA FACIAL
  // ---------------------------------------------------------------------------

  Future<WellnessChallenge> getActiveChallenge(ChallengeType type, {String? userId}) async {
    final effectiveUserId = userId ?? _activeUserId;
    try {
      final rows = AppDatabase.instance.select(
        'SELECT * FROM wellness_challenges WHERE user_id = ? AND challenge_type = ? AND is_active = 1',
        [effectiveUserId, type.key],
      );

      if (rows.isNotEmpty) {
        return WellnessChallenge.fromMap(rows.first);
      }

      // Create new challenge instance
      final id = 'chal-${type.key}-${_uuid.v4().substring(0, 8)}';
      final now = DateTime.now().toIso8601String();
      AppDatabase.instance.execute('''
        INSERT INTO wellness_challenges (id, user_id, challenge_type, total_days, started_at, is_active, client_id, client_updated_at)
        VALUES (?, ?, ?, 21, ?, 1, ?, ?)
      ''', [id, effectiveUserId, type.key, now, id, now]);

      AppDatabase.enqueueSync(
        tableName: 'wellness_challenges',
        recordId: id,
        action: 'INSERT',
        payload: {
          'id': id,
          'user_id': effectiveUserId,
          'challenge_type': type.key,
          'total_days': 21,
          'started_at': now,
          'is_active': 1,
          'client_id': id,
          'client_updated_at': now,
        },
      );

      return WellnessChallenge(
        id: id,
        userId: effectiveUserId,
        challengeType: type,
        totalDays: 21,
        startedAt: DateTime.parse(now),
        isActive: true,
        clientId: id,
        clientUpdatedAt: DateTime.parse(now),
      );
    } catch (e) {
      if (kDebugMode) print('[WellnessRepository] Error getting active challenge: $e');
      final now = DateTime.now();
      return WellnessChallenge(
        id: 'fallback-${type.key}',
        userId: effectiveUserId,
        challengeType: type,
        totalDays: 21,
        startedAt: now,
        clientId: 'fallback',
        clientUpdatedAt: now,
      );
    }
  }

  Future<ChallengeSummary> getChallengeSummary(ChallengeType type, {String? userId}) async {
    final effectiveUserId = userId ?? _activeUserId;
    try {
      final challenge = await getActiveChallenge(type, userId: effectiveUserId);
      final progressRows = AppDatabase.instance.select(
        'SELECT * FROM wellness_challenge_progress WHERE challenge_id = ? AND user_id = ? ORDER BY day_number ASC',
        [challenge.id, effectiveUserId],
      );

      final completedDays = progressRows.map((r) => WellnessChallengeProgress.fromMap(r)).toList();
      final allExercises = await getExercises(type);

      // Determine current exercise
      final completedDaySet = completedDays.map((d) => d.dayNumber).toSet();
      int targetDay = 1;
      for (int i = 1; i <= challenge.totalDays; i++) {
        if (!completedDaySet.contains(i)) {
          targetDay = i;
          break;
        }
      }
      if (targetDay == 1 && completedDays.length >= challenge.totalDays) {
        targetDay = challenge.totalDays;
      }

      final currentExercise = allExercises.firstWhere(
        (ex) => ex.dayNumber == targetDay,
        orElse: () => allExercises.isNotEmpty
            ? allExercises.first
            : WellnessExercise(
                id: 'ex-default',
                challengeType: type,
                dayNumber: 1,
                title: 'Día 1',
                instructions: 'Inicia tu reto con calma y presencia.',
              ),
      );

      return ChallengeSummary(
        challenge: challenge,
        completedDays: completedDays,
        currentExercise: currentExercise,
        allExercises: allExercises,
      );
    } catch (e) {
      if (kDebugMode) print('[WellnessRepository] Error getting challenge summary: $e');
      final fallbackChallenge = WellnessChallenge(
        id: 'fallback-${type.key}',
        userId: effectiveUserId,
        challengeType: type,
        totalDays: 21,
        startedAt: DateTime.now(),
        clientId: 'fallback',
        clientUpdatedAt: DateTime.now(),
      );
      return ChallengeSummary(
        challenge: fallbackChallenge,
        completedDays: const [],
        currentExercise: null,
        allExercises: const [],
      );
    }
  }

  Future<List<WellnessExercise>> getExercises(ChallengeType type) async {
    try {
      final rows = AppDatabase.instance.select(
        'SELECT * FROM wellness_exercises WHERE challenge_type = ? ORDER BY day_number ASC',
        [type.key],
      );

      return rows.map((r) => WellnessExercise.fromMap(r)).toList();
    } catch (e) {
      if (kDebugMode) print('[WellnessRepository] Error getting exercises: $e');
      return const [];
    }
  }

  Future<void> completeChallengeDay({
    required String challengeId,
    required ChallengeType type,
    required int dayNumber,
    String? userId,
  }) async {
    final effectiveUserId = userId ?? _activeUserId;
    try {
      // Check if already completed
      final existing = AppDatabase.instance.select(
        'SELECT id FROM wellness_challenge_progress WHERE challenge_id = ? AND day_number = ? AND user_id = ?',
        [challengeId, dayNumber, effectiveUserId],
      );

      if (existing.isNotEmpty) {
        if (kDebugMode) print('[WellnessRepository] Day $dayNumber already completed');
        return;
      }

      final id = _uuid.v4();
      final now = DateTime.now().toIso8601String();

      AppDatabase.instance.execute('''
        INSERT INTO wellness_challenge_progress (id, challenge_id, user_id, day_number, completed_at, client_id, client_updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?)
      ''', [id, challengeId, effectiveUserId, dayNumber, now, id, now]);

      AppDatabase.enqueueSync(
        tableName: 'wellness_challenge_progress',
        recordId: id,
        action: 'INSERT',
        payload: {
          'id': id,
          'challenge_id': challengeId,
          'user_id': effectiveUserId,
          'day_number': dayNumber,
          'completed_at': now,
          'client_id': id,
          'client_updated_at': now,
        },
      );

      // Award XP
      int xpToAward = XpEngine.wellnessChallengeDayXp;
      if (dayNumber >= 21) {
        xpToAward += XpEngine.wellnessChallengeCompleteXp;
      }
      _addXp(effectiveUserId, xpToAward);
    } catch (e) {
      if (kDebugMode) print('[WellnessRepository] Error completing challenge day: $e');
    }
  }

  Future<void> resetChallenge(ChallengeType type, {String? userId}) async {
    final effectiveUserId = userId ?? _activeUserId;
    try {
      final now = DateTime.now().toIso8601String();
      // Deactivate current
      AppDatabase.instance.execute(
        'UPDATE wellness_challenges SET is_active = 0, client_updated_at = ? WHERE user_id = ? AND challenge_type = ? AND is_active = 1',
        [now, effectiveUserId, type.key],
      );

      // Create new active challenge
      await getActiveChallenge(type, userId: effectiveUserId);
    } catch (e) {
      if (kDebugMode) print('[WellnessRepository] Error resetting challenge: $e');
    }
  }

  Future<List<AmbientSound>> getAmbientSounds() async {
    try {
      final rows = AppDatabase.instance.select(
        'SELECT * FROM ambient_sounds ORDER BY name ASC',
      );
      return rows.map((r) => AmbientSound.fromMap(r)).toList();
    } catch (e) {
      if (kDebugMode) print('[WellnessRepository] Error getting ambient sounds: $e');
      return const [];
    }
  }

  // ---------------------------------------------------------------------------
  // XP HELPER
  // ---------------------------------------------------------------------------

  void _addXp(String userId, int earnedXp) {
    try {
      final rows = AppDatabase.instance.select(
        'SELECT total_xp FROM user_xp WHERE user_id = ?',
        [userId],
      );
      final currentXp = rows.isNotEmpty ? (rows.first['total_xp'] as int) : 0;
      final newXp = currentXp + earnedXp;
      final newLevel = XpEngine.calculateLevel(newXp);
      final now = DateTime.now().toIso8601String();

      AppDatabase.instance.execute('''
        INSERT INTO user_xp (user_id, total_xp, level, updated_at)
        VALUES (?, ?, ?, ?)
        ON CONFLICT(user_id) DO UPDATE SET
          total_xp = excluded.total_xp,
          level = excluded.level,
          updated_at = excluded.updated_at
      ''', [userId, newXp, newLevel, now]);
    } catch (e) {
      if (kDebugMode) print('[WellnessRepository] Error updating XP: $e');
    }
  }
}
