import 'package:flutter/foundation.dart';

/// Available time horizon filters for analytics.
enum TimeRange {
  week,
  month,
  year;

  String get label {
    switch (this) {
      case TimeRange.week:
        return 'Semana';
      case TimeRange.month:
        return 'Mes';
      case TimeRange.year:
        return 'Año';
    }
  }

  String get description {
    switch (this) {
      case TimeRange.week:
        return 'Últimos 7 días';
      case TimeRange.month:
        return 'Últimos 30 días';
      case TimeRange.year:
        return 'Últimos 12 meses';
    }
  }
}

/// Daily metric point for trend charts.
@immutable
class DailyMetric {
  const DailyMetric({
    required this.date,
    required this.label,
    required this.habitsCompleted,
    required this.focusMinutes,
    required this.xpEarned,
  });

  final DateTime date;
  final String label;
  final int habitsCompleted;
  final int focusMinutes;
  final int xpEarned;
}

/// Distribution of activities across categories.
@immutable
class CategoryDistribution {
  const CategoryDistribution({
    required this.category,
    required this.displayName,
    required this.count,
    required this.percentage,
  });

  final String category;
  final String displayName;
  final int count;
  final double percentage;
}

/// Cell data for the habit consistency heatmap.
@immutable
class ConsistencyDay {
  const ConsistencyDay({
    required this.date,
    required this.count,
    required this.intensityLevel,
  });

  final DateTime date;
  final int count;

  /// Intensity level from 0 (none) to 4 (maximum execution).
  final int intensityLevel;
}

/// Ranked habit with execution count and current streak.
@immutable
class TopHabitStat {
  const TopHabitStat({
    required this.id,
    required this.title,
    required this.completions,
    required this.streak,
  });

  final String id;
  final String title;
  final int completions;
  final int streak;
}

/// Aggregated analytics summary for the selected [TimeRange].
@immutable
class AnalyticsSummary {
  const AnalyticsSummary({
    required this.range,
    required this.totalHabitsCompleted,
    required this.totalFocusMinutes,
    required this.totalSessionsCompleted,
    required this.totalXpEarned,
    required this.consistencyRate,
    required this.currentLevel,
    required this.totalXp,
    required this.levelTitle,
    required this.levelProgress,
    required this.dailyMetrics,
    required this.categoryDistribution,
    required this.topHabits,
    required this.heatmapDays,
    this.bimodalFocus = BimodalFocusStats.empty,
  });

  final TimeRange range;
  final int totalHabitsCompleted;
  final int totalFocusMinutes;
  final int totalSessionsCompleted;
  final int totalXpEarned;
  final double consistencyRate;
  final int currentLevel;
  final int totalXp;
  final String levelTitle;
  final double levelProgress;
  final List<DailyMetric> dailyMetrics;
  final List<CategoryDistribution> categoryDistribution;
  final List<TopHabitStat> topHabits;
  final List<ConsistencyDay> heatmapDays;
  final BimodalFocusStats bimodalFocus;

  /// Formatted focus time string, e.g. "3h 45m" or "45m".
  String get formattedFocusTime {
    if (totalFocusMinutes <= 0) return '0m';
    final hours = totalFocusMinutes ~/ 60;
    final mins = totalFocusMinutes % 60;
    if (hours > 0 && mins > 0) return '${hours}h ${mins}m';
    if (hours > 0) return '${hours}h';
    return '${mins}m';
  }
}

/// Breakdown of Pomodoro focus metrics by work type (Deep Work vs Shallow Work) and timer modes.
@immutable
class BimodalFocusStats {
  const BimodalFocusStats({
    required this.deepWorkMinutes,
    required this.shallowWorkMinutes,
    required this.deepWorkSessions,
    required this.shallowWorkSessions,
    required this.classicSessions,
    required this.extendedSessions,
    required this.ultradianSessions,
    required this.flowmodoroSessions,
  });

  final int deepWorkMinutes;
  final int shallowWorkMinutes;
  final int deepWorkSessions;
  final int shallowWorkSessions;
  final int classicSessions;
  final int extendedSessions;
  final int ultradianSessions;
  final int flowmodoroSessions;

  int get totalMinutes => deepWorkMinutes + shallowWorkMinutes;
  int get totalSessions => deepWorkSessions + shallowWorkSessions;

  double get deepWorkRatio => totalMinutes > 0 ? (deepWorkMinutes / totalMinutes) : 0.0;
  double get shallowWorkRatio => totalMinutes > 0 ? (shallowWorkMinutes / totalMinutes) : 0.0;

  String get formattedDeepWorkTime {
    if (deepWorkMinutes <= 0) return '0m';
    final hours = deepWorkMinutes ~/ 60;
    final mins = deepWorkMinutes % 60;
    if (hours > 0 && mins > 0) return '${hours}h ${mins}m';
    if (hours > 0) return '${hours}h';
    return '${mins}m';
  }

  String get formattedShallowWorkTime {
    if (shallowWorkMinutes <= 0) return '0m';
    final hours = shallowWorkMinutes ~/ 60;
    final mins = shallowWorkMinutes % 60;
    if (hours > 0 && mins > 0) return '${hours}h ${mins}m';
    if (hours > 0) return '${hours}h';
    return '${mins}m';
  }

  static const empty = BimodalFocusStats(
    deepWorkMinutes: 0,
    shallowWorkMinutes: 0,
    deepWorkSessions: 0,
    shallowWorkSessions: 0,
    classicSessions: 0,
    extendedSessions: 0,
    ultradianSessions: 0,
    flowmodoroSessions: 0,
  );
}
