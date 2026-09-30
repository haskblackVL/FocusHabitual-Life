/// Domain models for Hydration & Water Tracking.
class WaterSettings {
  final String userId;
  final int dailyGoalMl;
  final int reminderIntervalMinutes;
  final String wakeTime;
  final String sleepTime;
  final bool remindersEnabled;

  const WaterSettings({
    required this.userId,
    this.dailyGoalMl = 2000,
    this.reminderIntervalMinutes = 90,
    this.wakeTime = '07:00',
    this.sleepTime = '22:30',
    this.remindersEnabled = true,
  });

  factory WaterSettings.fromMap(Map<String, dynamic> map) {
    return WaterSettings(
      userId: map['user_id'] as String? ?? 'local_user',
      dailyGoalMl: (map['daily_goal_ml'] as num?)?.toInt() ?? 2000,
      reminderIntervalMinutes: (map['reminder_interval_minutes'] as num?)?.toInt() ?? 90,
      wakeTime: map['wake_time'] as String? ?? '07:00',
      sleepTime: map['sleep_time'] as String? ?? '22:30',
      remindersEnabled: (map['reminders_enabled'] as int? ?? 1) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'daily_goal_ml': dailyGoalMl,
      'reminder_interval_minutes': reminderIntervalMinutes,
      'wake_time': wakeTime,
      'sleep_time': sleepTime,
      'reminders_enabled': remindersEnabled ? 1 : 0,
    };
  }

  WaterSettings copyWith({
    String? userId,
    int? dailyGoalMl,
    int? reminderIntervalMinutes,
    String? wakeTime,
    String? sleepTime,
    bool? remindersEnabled,
  }) {
    return WaterSettings(
      userId: userId ?? this.userId,
      dailyGoalMl: dailyGoalMl ?? this.dailyGoalMl,
      reminderIntervalMinutes: reminderIntervalMinutes ?? this.reminderIntervalMinutes,
      wakeTime: wakeTime ?? this.wakeTime,
      sleepTime: sleepTime ?? this.sleepTime,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
    );
  }
}

class WaterLogEntry {
  final String id;
  final String userId;
  final int amountMl;
  final DateTime loggedAt;
  final String clientId;

  const WaterLogEntry({
    required this.id,
    required this.userId,
    required this.amountMl,
    required this.loggedAt,
    required this.clientId,
  });

  factory WaterLogEntry.fromMap(Map<String, dynamic> map) {
    return WaterLogEntry(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      amountMl: (map['amount_ml'] as num).toInt(),
      loggedAt: DateTime.parse(map['logged_at'] as String),
      clientId: map['client_id'] as String? ?? map['id'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'amount_ml': amountMl,
      'logged_at': loggedAt.toIso8601String(),
      'client_id': clientId,
    };
  }
}

class DailyWaterSummary {
  final int totalAmountMl;
  final int dailyGoalMl;
  final List<WaterLogEntry> entries;

  const DailyWaterSummary({
    required this.totalAmountMl,
    required this.dailyGoalMl,
    required this.entries,
  });

  double get progressRatio => (dailyGoalMl > 0) ? (totalAmountMl / dailyGoalMl).clamp(0.0, 1.5) : 0.0;
  int get progressPercent => (progressRatio * 100).toInt();
  bool get isGoalAchieved => totalAmountMl >= dailyGoalMl;
  int get remainingMl => (dailyGoalMl - totalAmountMl).clamp(0, dailyGoalMl);
}
