import 'dart:convert';

/// Configuration model for smart notifications and local reminders.
class NotificationSettings {
  final bool habitRemindersEnabled;
  final String checklistAmTime; // e.g. "07:00"
  final String checklistPmTime; // e.g. "21:30"
  final bool hydrationRemindersEnabled;
  final int hydrationIntervalHours; // e.g. 2
  final bool pomodoroNotificationsEnabled;
  final bool streakRiskAlertsEnabled;
  final String streakRiskTime; // e.g. "20:00"
  final bool verseReminderEnabled;
  final String verseReminderTime; // e.g. "08:00"
  final bool weeklySummaryEnabled;

  const NotificationSettings({
    this.habitRemindersEnabled = true,
    this.checklistAmTime = '07:00',
    this.checklistPmTime = '21:30',
    this.hydrationRemindersEnabled = true,
    this.hydrationIntervalHours = 2,
    this.pomodoroNotificationsEnabled = true,
    this.streakRiskAlertsEnabled = true,
    this.streakRiskTime = '20:00',
    this.verseReminderEnabled = true,
    this.verseReminderTime = '08:00',
    this.weeklySummaryEnabled = true,
  });

  NotificationSettings copyWith({
    bool? habitRemindersEnabled,
    String? checklistAmTime,
    String? checklistPmTime,
    bool? hydrationRemindersEnabled,
    int? hydrationIntervalHours,
    bool? pomodoroNotificationsEnabled,
    bool? streakRiskAlertsEnabled,
    String? streakRiskTime,
    bool? verseReminderEnabled,
    String? verseReminderTime,
    bool? weeklySummaryEnabled,
  }) {
    return NotificationSettings(
      habitRemindersEnabled:
          habitRemindersEnabled ?? this.habitRemindersEnabled,
      checklistAmTime: checklistAmTime ?? this.checklistAmTime,
      checklistPmTime: checklistPmTime ?? this.checklistPmTime,
      hydrationRemindersEnabled:
          hydrationRemindersEnabled ?? this.hydrationRemindersEnabled,
      hydrationIntervalHours:
          hydrationIntervalHours ?? this.hydrationIntervalHours,
      pomodoroNotificationsEnabled:
          pomodoroNotificationsEnabled ?? this.pomodoroNotificationsEnabled,
      streakRiskAlertsEnabled:
          streakRiskAlertsEnabled ?? this.streakRiskAlertsEnabled,
      streakRiskTime: streakRiskTime ?? this.streakRiskTime,
      verseReminderEnabled: verseReminderEnabled ?? this.verseReminderEnabled,
      verseReminderTime: verseReminderTime ?? this.verseReminderTime,
      weeklySummaryEnabled: weeklySummaryEnabled ?? this.weeklySummaryEnabled,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'habit_reminders_enabled': habitRemindersEnabled,
      'checklist_am_time': checklistAmTime,
      'checklist_pm_time': checklistPmTime,
      'hydration_reminders_enabled': hydrationRemindersEnabled,
      'hydration_interval_hours': hydrationIntervalHours,
      'pomodoro_notifications_enabled': pomodoroNotificationsEnabled,
      'streak_risk_alerts_enabled': streakRiskAlertsEnabled,
      'streak_risk_time': streakRiskTime,
      'verse_reminder_enabled': verseReminderEnabled,
      'verse_reminder_time': verseReminderTime,
      'weekly_summary_enabled': weeklySummaryEnabled,
    };
  }

  factory NotificationSettings.fromMap(Map<String, dynamic> map) {
    return NotificationSettings(
      habitRemindersEnabled:
          map['habit_reminders_enabled'] as bool? ?? true,
      checklistAmTime: map['checklist_am_time'] as String? ?? '07:00',
      checklistPmTime: map['checklist_pm_time'] as String? ?? '21:30',
      hydrationRemindersEnabled:
          map['hydration_reminders_enabled'] as bool? ?? true,
      hydrationIntervalHours:
          (map['hydration_interval_hours'] as num?)?.toInt() ?? 2,
      pomodoroNotificationsEnabled:
          map['pomodoro_notifications_enabled'] as bool? ?? true,
      streakRiskAlertsEnabled:
          map['streak_risk_alerts_enabled'] as bool? ?? true,
      streakRiskTime: map['streak_risk_time'] as String? ?? '20:00',
      verseReminderEnabled: map['verse_reminder_enabled'] as bool? ?? true,
      verseReminderTime: map['verse_reminder_time'] as String? ?? '08:00',
      weeklySummaryEnabled: map['weekly_summary_enabled'] as bool? ?? true,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory NotificationSettings.fromJson(String source) {
    try {
      final decoded = jsonDecode(source) as Map<String, dynamic>;
      return NotificationSettings.fromMap(decoded);
    } catch (_) {
      return const NotificationSettings();
    }
  }
}
