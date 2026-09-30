import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'notification_settings_model.dart';

/// Service managing device-level smart notifications, channel setup,
/// exact alarms, recurring schedules, and discreet mode privacy filters.
class LocalNotificationService {
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();

  factory LocalNotificationService() => _instance;

  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// IDs reserved for notification categories
  static const int idMorningRoutine = 100;
  static const int idEveningRoutine = 101;
  static const int idStreakRisk = 300;
  static const int idSpiritualVerse = 400;
  static const int idPomodoro = 500;
  static const int idTest = 999;
  static const int idHydrationBase = 200;

  /// Android Notification Channels
  static const String channelHabits = 'focus_habits_channel';
  static const String channelHydration = 'focus_hydration_channel';
  static const String channelPomodoro = 'focus_pomodoro_channel';
  static const String channelSpiritual = 'focus_spiritual_channel';
  static const String channelStreaks = 'focus_streaks_channel';

  /// Initializes plugin, timezones, and sets up Android notification channels.
  Future<void> initialize({
    void Function(NotificationResponse)? onNotificationTap,
  }) async {
    if (_initialized) return;

    // Initialize Timezone Database
    try {
      tz.initializeTimeZones();
      final String currentTimeZone = DateTime.now().timeZoneName;
      try {
        tz.setLocalLocation(tz.getLocation(currentTimeZone));
      } catch (_) {
        tz.setLocalLocation(tz.local);
      }
    } catch (e) {
      debugPrint('[NotificationService] Timezone init warning: $e');
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const linuxSettings = LinuxInitializationSettings(
      defaultActionName: 'Open notification',
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
      linux: linuxSettings,
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: onNotificationTap,
    );

    // Create high-priority channels for Android
    if (Platform.isAndroid) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            channelHabits,
            'Hábitos & Rutinas',
            description: 'Recordatorios de Rutina Matutina y Rutina Nocturna',
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
        );

        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            channelPomodoro,
            'Enfoque & Pomodoro',
            description: 'Alertas de fin de bloque ultradiano y descansos',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );

        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            channelHydration,
            'Hidratación & Bienestar',
            description: 'Recordatorios conscientes para beber agua',
            importance: Importance.defaultImportance,
            playSound: true,
            enableVibration: false,
          ),
        );

        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            channelStreaks,
            'Rachas & Desafíos',
            description: 'Alertas de hábitos pendientes y protección de racha',
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
        );

        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            channelSpiritual,
            'Pilar Espiritual',
            description: 'Principio bíblico diario y reflexión de Proverbios',
            importance: Importance.defaultImportance,
            playSound: true,
          ),
        );
      }
    }

    _initialized = true;
    debugPrint('[NotificationService] Initialized successfully');
  }

  /// Request permissions on Android 13+ and iOS.
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        return granted ?? false;
      }
    } else if (Platform.isIOS) {
      final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        final granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    }
    return true;
  }

  // ---------------------------------------------------------------------------
  // SCHEDULING LOGIC
  // ---------------------------------------------------------------------------

  /// Calculates the next TZDateTime for a given time "HH:mm".
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Parses "HH:mm" string into hour and minute integers.
  List<int> _parseTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return [hour, minute];
    } catch (_) {
      return [8, 0];
    }
  }

  /// Reschedules all user notifications according to their settings and discreet mode.
  Future<void> rescheduleAll({
    required NotificationSettings settings,
    required bool isDiscreet,
    required bool isReligious,
  }) async {
    await cancelAll();

    // 1. Morning Routine Reminder
    if (settings.habitRemindersEnabled) {
      final timeParts = _parseTime(settings.checklistAmTime);
      final scheduledDate = _nextInstanceOfTime(timeParts[0], timeParts[1]);

      final title = isDiscreet
          ? 'Gestor Personal'
          : '☀️ Rutina Matutina • FocusHabitual';
      final body = isDiscreet
          ? 'Check-in matutino programado. Abre para ver tus prioridades.'
          : '¡Hora de despertar sin snooze! Bebe agua y revisa tus 3 prioridades del día.';

      await _plugin.zonedSchedule(
        id: idMorningRoutine,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            channelHabits,
            'Hábitos & Rutinas',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }

    // 2. Evening Routine Reminder
    if (settings.habitRemindersEnabled) {
      final timeParts = _parseTime(settings.checklistPmTime);
      final scheduledDate = _nextInstanceOfTime(timeParts[0], timeParts[1]);

      final title = isDiscreet
          ? 'Gestor Personal'
          : '🌙 Rutina Nocturna • FocusHabitual';
      final body = isDiscreet
          ? 'Cierre de jornada. Revisa tus pendientes y descanso.'
          : 'Desconecta pantallas en 30 min, lectura breve y 3 notas de gratitud.';

      await _plugin.zonedSchedule(
        id: idEveningRoutine,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            channelHabits,
            'Hábitos & Rutinas',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }

    // 3. Hydration Reminders (between 09:00 and 20:00 every N hours)
    if (settings.hydrationRemindersEnabled) {
      final interval = settings.hydrationIntervalHours.clamp(1, 4);
      int notificationIndex = 0;

      for (int hour = 9; hour <= 20; hour += interval) {
        final scheduledDate = _nextInstanceOfTime(hour, 0);

        final title = isDiscreet
            ? 'Gestor Personal'
            : '💧 Hidratación Consciente';
        final body = isDiscreet
            ? 'Pausa activa y descanso recomendados.'
            : 'Momento de beber un vaso de agua para reactivar tu claridad mental.';

        await _plugin.zonedSchedule(
          id: idHydrationBase + notificationIndex,
          title: title,
          body: body,
          scheduledDate: scheduledDate,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              channelHydration,
              'Hidratación & Bienestar',
              importance: Importance.defaultImportance,
              priority: Priority.defaultPriority,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
        notificationIndex++;
      }
    }

    // 4. Streak Risk Alert (default 20:00)
    if (settings.streakRiskAlertsEnabled) {
      final timeParts = _parseTime(settings.streakRiskTime);
      final scheduledDate = _nextInstanceOfTime(timeParts[0], timeParts[1]);

      final title = isDiscreet
          ? 'Gestor Personal'
          : '🔥 ¡Protege tu Racha Diaria!';
      final body = isDiscreet
          ? 'Tienes tareas pendientes antes de culminar el día.'
          : 'Aún tienes hábitos sin marcar hoy. Cumple tus objetivos y no rompas la cadena.';

      await _plugin.zonedSchedule(
        id: idStreakRisk,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            channelStreaks,
            'Rachas & Desafíos',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }

    // 5. Daily Spiritual Verse Reminder (Conditional)
    if (isReligious && settings.verseReminderEnabled) {
      final timeParts = _parseTime(settings.verseReminderTime);
      final scheduledDate = _nextInstanceOfTime(timeParts[0], timeParts[1]);

      final title = isDiscreet
          ? 'Gestor Personal'
          : '📖 Principio Rector del Día';
      final body = isDiscreet
          ? 'Reflexión matutina disponible en tu panel.'
          : '«Encomienda al Señor tus obras, y tus pensamientos serán afirmados.» — Proverbios 16:3';

      await _plugin.zonedSchedule(
        id: idSpiritualVerse,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            channelSpiritual,
            'Pilar Espiritual',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }

    debugPrint('[NotificationService] All notifications rescheduled.');
  }

  // ---------------------------------------------------------------------------
  // IMMEDIATE / EVENT NOTIFICATIONS
  // ---------------------------------------------------------------------------

  /// Shows an instant notification when a Pomodoro focus block finishes.
  Future<void> showPomodoroCompletedNotification({
    required String taskName,
    required int minutesFocused,
    required bool isDiscreet,
  }) async {
    final title = isDiscreet
        ? 'Gestor Personal'
        : '⏳ ¡Bloque de Enfoque Completado!';
    final body = isDiscreet
        ? 'Ventana de trabajo finalizada.'
        : 'Completaste $minutesFocused min de enfoque en "$taskName". ¡Toma un merecido descanso!';

    await _plugin.show(
      id: idPomodoro,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          channelPomodoro,
          'Enfoque & Pomodoro',
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          sound: 'default',
        ),
      ),
    );
  }

  /// Fires a quick instant test notification to verify device audio/vibrate/display.
  Future<void> showTestNotification({required bool isDiscreet}) async {
    final title = isDiscreet
        ? 'Gestor Personal'
        : '🔔 FocusHabitual • Notificaciones Activas';
    final body = isDiscreet
        ? 'Sistema de notificaciones verificado correctamente.'
        : 'Tus alarmas de hábitos matutinos, nocturnos y de enfoque están operativas.';

    await _plugin.show(
      id: idTest,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          channelHabits,
          'Hábitos & Rutinas',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(sound: 'default'),
      ),
    );
  }

  /// Cancels all scheduled or active notifications.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
