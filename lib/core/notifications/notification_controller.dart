import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../local_db/database.dart';
import '../security/security_controller.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import 'local_notification_service.dart';
import 'notification_settings_model.dart';

const String _kNotificationSettingsKey = 'notification_settings_v1';

/// Provider for LocalNotificationService singleton.
final localNotificationServiceProvider =
    Provider<LocalNotificationService>((ref) {
  return LocalNotificationService();
});

/// Riverpod controller managing notification preferences and device alarm scheduling.
class NotificationController extends Notifier<NotificationSettings> {
  LocalNotificationService get _service => ref.read(localNotificationServiceProvider);

  @override
  NotificationSettings build() {
    ref.watch(localNotificationServiceProvider);

    // Watch security settings for discreet mode changes
    final securitySettings = ref.watch(securityControllerProvider);
    final isDiscreet = securitySettings.discreetModeEnabled;

    // Watch user profile for religious status
    final profile = ref.watch(userProfileControllerProvider).value;
    final isReligious = profile?.isReligious ?? false;

    final initialSettings = _loadSettings();

    // Schedule notifications in background after build
    Future.microtask(() async {
      try {
        await _service.rescheduleAll(
          settings: initialSettings,
          isDiscreet: isDiscreet,
          isReligious: isReligious,
        );
      } catch (_) {}
    });

    return initialSettings;
  }

  NotificationSettings _loadSettings() {
    try {
      final savedJson = AppDatabase.getSetting(_kNotificationSettingsKey);
      if (savedJson != null && savedJson.isNotEmpty) {
        return NotificationSettings.fromJson(savedJson);
      }
    } catch (_) {}
    return const NotificationSettings();
  }

  void _persistAndReschedule(NotificationSettings newSettings) {
    state = newSettings;
    try {
      AppDatabase.setSetting(_kNotificationSettingsKey, newSettings.toJson());
    } catch (_) {}

    final isDiscreet =
        ref.read(securityControllerProvider).discreetModeEnabled;
    final isReligious =
        ref.read(userProfileControllerProvider).value?.isReligious ?? false;

    _service.rescheduleAll(
      settings: newSettings,
      isDiscreet: isDiscreet,
      isReligious: isReligious,
    );
  }

  Future<bool> requestPermissions() async {
    return await _service.requestPermissions();
  }

  Future<void> sendTestNotification() async {
    final isDiscreet =
        ref.read(securityControllerProvider).discreetModeEnabled;
    await _service.showTestNotification(isDiscreet: isDiscreet);
  }

  void toggleHabitReminders(bool enabled) {
    _persistAndReschedule(state.copyWith(habitRemindersEnabled: enabled));
  }

  void setChecklistAmTime(String time) {
    _persistAndReschedule(state.copyWith(checklistAmTime: time));
  }

  void setChecklistPmTime(String time) {
    _persistAndReschedule(state.copyWith(checklistPmTime: time));
  }

  void toggleHydrationReminders(bool enabled) {
    _persistAndReschedule(state.copyWith(hydrationRemindersEnabled: enabled));
  }

  void setHydrationInterval(int hours) {
    _persistAndReschedule(state.copyWith(hydrationIntervalHours: hours));
  }

  void togglePomodoroNotifications(bool enabled) {
    _persistAndReschedule(state.copyWith(pomodoroNotificationsEnabled: enabled));
  }

  void toggleStreakRiskAlerts(bool enabled) {
    _persistAndReschedule(state.copyWith(streakRiskAlertsEnabled: enabled));
  }

  void setStreakRiskTime(String time) {
    _persistAndReschedule(state.copyWith(streakRiskTime: time));
  }

  void toggleSpiritualVerse(bool enabled) {
    _persistAndReschedule(state.copyWith(verseReminderEnabled: enabled));
  }

  void setSpiritualVerseTime(String time) {
    _persistAndReschedule(state.copyWith(verseReminderTime: time));
  }
}

final notificationControllerProvider =
    NotifierProvider<NotificationController, NotificationSettings>(
  NotificationController.new,
);
