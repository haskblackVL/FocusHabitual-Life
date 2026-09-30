import 'package:intl/intl.dart';
import '../../../core/gamification/xp_engine.dart';
import '../../../core/local_db/database.dart';
import '../../habits/domain/habit.dart';
import '../domain/analytics_data.dart';

/// Repository for aggregating habit execution, focus time, and gamification metrics.
class AnalyticsRepository {
  AnalyticsRepository({this.currentUserId});

  final String? currentUserId;

  String get _activeUserId => currentUserId ?? 'local_user';

  /// Computes full [AnalyticsSummary] for the given [range].
  Future<AnalyticsSummary> getSummary(TimeRange range) async {
    final db = AppDatabase.instance;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final DateTime rangeStart;
    switch (range) {
      case TimeRange.week:
        rangeStart = today.subtract(const Duration(days: 6));
        break;
      case TimeRange.month:
        rangeStart = today.subtract(const Duration(days: 29));
        break;
      case TimeRange.year:
        rangeStart = DateTime(today.year - 1, today.month, today.day);
        break;
    }

    final rangeStartIso = rangeStart.toIso8601String().substring(0, 10);

    // 1. Total habits & XP in period
    final habitStats = db.select('''
      SELECT count(*) as total_completed, coalesce(sum(xp_earned), 0) as total_xp
      FROM habit_logs
      WHERE user_id = ? AND completed_at >= ?
    ''', [_activeUserId, rangeStartIso]);
    final totalHabitsCompleted = (habitStats.first['total_completed'] as int?) ?? 0;
    final totalXpEarned = (habitStats.first['total_xp'] as int?) ?? 0;

    // 2. Focus minutes & Pomodoro sessions completed in period
    final pomodoroStats = db.select('''
      SELECT count(*) as total_sessions, coalesce(sum(duration_minutes), 0) as total_minutes
      FROM pomodoro_sessions
      WHERE user_id = ? AND was_completed = 1 AND started_at >= ?
    ''', [_activeUserId, rangeStartIso]);
    final totalSessionsCompleted = (pomodoroStats.first['total_sessions'] as int?) ?? 0;
    final totalFocusMinutes = (pomodoroStats.first['total_minutes'] as int?) ?? 0;

    // 3. User XP and Level progression
    final xpRow = db.select(
      'SELECT total_xp, level FROM user_xp WHERE user_id = ?',
      [_activeUserId],
    );
    final totalXp = xpRow.isNotEmpty ? (xpRow.first['total_xp'] as int) : 0;
    final currentLevel = XpEngine.calculateLevel(totalXp);
    final levelTitle = XpEngine.getLevelTitle(currentLevel);
    final levelProgress = XpEngine.calculateLevelProgress(totalXp);

    // 4. Distinct active days for consistency calculation
    final activeDaysRow = db.select('''
      SELECT count(DISTINCT substr(completed_at, 1, 10)) as active_days
      FROM habit_logs
      WHERE user_id = ? AND completed_at >= ?
    ''', [_activeUserId, rangeStartIso]);
    final activeDays = (activeDaysRow.first['active_days'] as int?) ?? 0;
    final totalDaysInRange = today.difference(rangeStart).inDays + 1;
    final consistencyRate = totalDaysInRange > 0
        ? (activeDays / totalDaysInRange).clamp(0.0, 1.0)
        : 0.0;

    // 5. Daily metrics series for charts
    final dailyMetrics = _buildDailyMetrics(range, rangeStart, today);

    // 6. Category breakdown
    final categoryDistribution = _buildCategoryDistribution(rangeStartIso, totalHabitsCompleted);

    // 7. Top habits ranking
    final topHabits = _buildTopHabits(rangeStartIso);

    // 8. Heatmap (last 42 days = 6 full weeks)
    final heatmapDays = _buildHeatmapDays(today, 42);

    // 9. Bimodal Focus distribution (Deep Work vs Shallow Work & Pomodoro modes)
    final bimodalFocus = _buildBimodalFocusStats(rangeStartIso);

    return AnalyticsSummary(
      range: range,
      totalHabitsCompleted: totalHabitsCompleted,
      totalFocusMinutes: totalFocusMinutes,
      totalSessionsCompleted: totalSessionsCompleted,
      totalXpEarned: totalXpEarned,
      consistencyRate: consistencyRate,
      currentLevel: currentLevel,
      totalXp: totalXp,
      levelTitle: levelTitle,
      levelProgress: levelProgress,
      dailyMetrics: dailyMetrics,
      categoryDistribution: categoryDistribution,
      topHabits: topHabits,
      heatmapDays: heatmapDays,
      bimodalFocus: bimodalFocus,
    );
  }

  /// Builds trend data points based on [range].
  List<DailyMetric> _buildDailyMetrics(
    TimeRange range,
    DateTime rangeStart,
    DateTime today,
  ) {
    final db = AppDatabase.instance;
    final List<DailyMetric> series = [];

    if (range == TimeRange.week) {
      // 7 days: Lun to Dom
      const weekdayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
      for (int i = 0; i < 7; i++) {
        final d = rangeStart.add(Duration(days: i));
        final dayStr = d.toIso8601String().substring(0, 10);

        final habitRows = db.select('''
          SELECT count(*) as count, coalesce(sum(xp_earned), 0) as xp
          FROM habit_logs
          WHERE user_id = ? AND completed_at LIKE ?
        ''', [_activeUserId, '$dayStr%']);
        final hCount = (habitRows.first['count'] as int?) ?? 0;
        final xp = (habitRows.first['xp'] as int?) ?? 0;

        final pomoRows = db.select('''
          SELECT coalesce(sum(duration_minutes), 0) as minutes
          FROM pomodoro_sessions
          WHERE user_id = ? AND was_completed = 1 AND started_at LIKE ?
        ''', [_activeUserId, '$dayStr%']);
        final pMins = (pomoRows.first['minutes'] as int?) ?? 0;

        final label = weekdayLabels[(d.weekday - 1) % 7];
        series.add(
          DailyMetric(
            date: d,
            label: label,
            habitsCompleted: hCount,
            focusMinutes: pMins,
            xpEarned: xp,
          ),
        );
      }
    } else if (range == TimeRange.month) {
      // 4 periods of 7-8 days (Sem 1 to Sem 4)
      for (int w = 0; w < 4; w++) {
        final startPeriod = rangeStart.add(Duration(days: w * 7));
        final endPeriod = w == 3 ? today : rangeStart.add(Duration(days: (w + 1) * 7 - 1));
        final startIso = startPeriod.toIso8601String().substring(0, 10);
        final endIso = '${endPeriod.toIso8601String().substring(0, 10)}T23:59:59';

        final habitRows = db.select('''
          SELECT count(*) as count, coalesce(sum(xp_earned), 0) as xp
          FROM habit_logs
          WHERE user_id = ? AND completed_at >= ? AND completed_at <= ?
        ''', [_activeUserId, startIso, endIso]);
        final hCount = (habitRows.first['count'] as int?) ?? 0;
        final xp = (habitRows.first['xp'] as int?) ?? 0;

        final pomoRows = db.select('''
          SELECT coalesce(sum(duration_minutes), 0) as minutes
          FROM pomodoro_sessions
          WHERE user_id = ? AND was_completed = 1 AND started_at >= ? AND started_at <= ?
        ''', [_activeUserId, startIso, endIso]);
        final pMins = (pomoRows.first['minutes'] as int?) ?? 0;

        series.add(
          DailyMetric(
            date: startPeriod,
            label: 'S${w + 1}',
            habitsCompleted: hCount,
            focusMinutes: pMins,
            xpEarned: xp,
          ),
        );
      }
    } else {
      // Year: 12 months
      const monthNames = [
        'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
        'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
      ];
      for (int m = 11; m >= 0; m--) {
        final d = DateTime(today.year, today.month - m, 1);
        final monthPrefix = DateFormat('yyyy-MM').format(d);

        final habitRows = db.select('''
          SELECT count(*) as count, coalesce(sum(xp_earned), 0) as xp
          FROM habit_logs
          WHERE user_id = ? AND completed_at LIKE ?
        ''', [_activeUserId, '$monthPrefix%']);
        final hCount = (habitRows.first['count'] as int?) ?? 0;
        final xp = (habitRows.first['xp'] as int?) ?? 0;

        final pomoRows = db.select('''
          SELECT coalesce(sum(duration_minutes), 0) as minutes
          FROM pomodoro_sessions
          WHERE user_id = ? AND was_completed = 1 AND started_at LIKE ?
        ''', [_activeUserId, '$monthPrefix%']);
        final pMins = (pomoRows.first['minutes'] as int?) ?? 0;

        series.add(
          DailyMetric(
            date: d,
            label: monthNames[d.month - 1],
            habitsCompleted: hCount,
            focusMinutes: pMins,
            xpEarned: xp,
          ),
        );
      }
    }

    return series;
  }

  /// Calculates proportion of habit completions by category.
  List<CategoryDistribution> _buildCategoryDistribution(
    String rangeStartIso,
    int totalCompletions,
  ) {
    final db = AppDatabase.instance;
    final rows = db.select('''
      SELECT h.category, count(hl.id) as count
      FROM habit_logs hl
      JOIN habits h ON hl.habit_id = h.id
      WHERE hl.user_id = ? AND hl.completed_at >= ?
      GROUP BY h.category
      ORDER BY count DESC
    ''', [_activeUserId, rangeStartIso]);

    if (rows.isEmpty) {
      return [
        const CategoryDistribution(
          category: 'general',
          displayName: 'General',
          count: 0,
          percentage: 0.0,
        ),
      ];
    }

    return rows.map((row) {
      final catKey = row['category'] as String;
      final count = (row['count'] as int?) ?? 0;
      final habitCat = HabitCategory.fromDb(catKey);
      final percentage = totalCompletions > 0 ? (count / totalCompletions) : 0.0;

      return CategoryDistribution(
        category: catKey,
        displayName: habitCat.displayName,
        count: count,
        percentage: percentage,
      );
    }).toList();
  }

  /// Top 5 habits with most completions in the period.
  List<TopHabitStat> _buildTopHabits(String rangeStartIso) {
    final db = AppDatabase.instance;
    final rows = db.select('''
      SELECT h.id, h.title, count(hl.id) as completions,
             count(DISTINCT substr(hl.completed_at, 1, 10)) as streak
      FROM habits h
      JOIN habit_logs hl ON hl.habit_id = h.id
      WHERE hl.user_id = ? AND hl.completed_at >= ?
      GROUP BY h.id, h.title
      ORDER BY completions DESC
      LIMIT 5
    ''', [_activeUserId, rangeStartIso]);

    return rows.map((r) {
      return TopHabitStat(
        id: r['id'] as String,
        title: r['title'] as String,
        completions: (r['completions'] as int?) ?? 0,
        streak: (r['streak'] as int?) ?? 0,
      );
    }).toList();
  }

  /// Builds a matrix of recent days for the Swiss/GitHub-style habit heatmap.
  List<ConsistencyDay> _buildHeatmapDays(DateTime today, int totalDays) {
    final db = AppDatabase.instance;
    final startDay = today.subtract(Duration(days: totalDays - 1));
    final startIso = startDay.toIso8601String().substring(0, 10);

    final rows = db.select('''
      SELECT substr(completed_at, 1, 10) as day, count(*) as count
      FROM habit_logs
      WHERE user_id = ? AND completed_at >= ?
      GROUP BY day
    ''', [_activeUserId, startIso]);

    final Map<String, int> countsByDay = {};
    for (final row in rows) {
      final day = row['day'] as String;
      final count = (row['count'] as int?) ?? 0;
      countsByDay[day] = count;
    }

    final List<ConsistencyDay> days = [];
    for (int i = 0; i < totalDays; i++) {
      final d = startDay.add(Duration(days: i));
      final dStr = d.toIso8601String().substring(0, 10);
      final count = countsByDay[dStr] ?? 0;

      final int level;
      if (count == 0) {
        level = 0;
      } else if (count <= 1) {
        level = 1;
      } else if (count <= 2) {
        level = 2;
      } else if (count <= 4) {
        level = 3;
      } else {
        level = 4;
      }

      days.add(ConsistencyDay(date: d, count: count, intensityLevel: level));
    }

    return days;
  }

  /// Builds bimodal deep work vs shallow work and mode distribution stats.
  BimodalFocusStats _buildBimodalFocusStats(String rangeStartIso) {
    final db = AppDatabase.instance;
    try {
      final rows = db.select('''
        SELECT 
          work_type,
          mode_key,
          count(*) as session_count,
          coalesce(sum(duration_minutes), 0) as total_mins
        FROM pomodoro_sessions
        WHERE user_id = ? AND was_completed = 1 AND started_at >= ?
        GROUP BY work_type, mode_key
      ''', [_activeUserId, rangeStartIso]);

      int deepMinutes = 0;
      int shallowMinutes = 0;
      int deepSessions = 0;
      int shallowSessions = 0;
      int classicSessions = 0;
      int extendedSessions = 0;
      int ultradianSessions = 0;
      int flowmodoroSessions = 0;

      for (final r in rows) {
        final wType = r['work_type'] as String? ?? 'shallow_work';
        final mKey = r['mode_key'] as String? ?? 'classic';
        final count = (r['session_count'] as int?) ?? 0;
        final mins = (r['total_mins'] as int?) ?? 0;

        if (wType == 'deep_work') {
          deepMinutes += mins;
          deepSessions += count;
        } else {
          shallowMinutes += mins;
          shallowSessions += count;
        }

        switch (mKey) {
          case 'classic':
            classicSessions += count;
            break;
          case 'extended':
            extendedSessions += count;
            break;
          case 'ultradian':
            ultradianSessions += count;
            break;
          case 'flowmodoro':
            flowmodoroSessions += count;
            break;
        }
      }

      return BimodalFocusStats(
        deepWorkMinutes: deepMinutes,
        shallowWorkMinutes: shallowMinutes,
        deepWorkSessions: deepSessions,
        shallowWorkSessions: shallowSessions,
        classicSessions: classicSessions,
        extendedSessions: extendedSessions,
        ultradianSessions: ultradianSessions,
        flowmodoroSessions: flowmodoroSessions,
      );
    } catch (_) {
      return BimodalFocusStats.empty;
    }
  }
}
