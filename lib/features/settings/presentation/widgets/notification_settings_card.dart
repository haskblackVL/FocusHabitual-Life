import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme.dart';
import '../../../../core/notifications/notification_controller.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

/// Executive card managing smart notifications, routine time pickers,
/// hydration cadence, streak risk alerts, and test triggers.
class NotificationSettingsCard extends ConsumerWidget {
  const NotificationSettingsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(notificationControllerProvider);
    final notifier = ref.read(notificationControllerProvider.notifier);
    final profile = ref.watch(userProfileControllerProvider).value;
    final isReligious = profile?.isReligious ?? false;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Routine Reminders Master Tile
          _buildMasterTile(
            context: context,
            icon: Icons.alarm_rounded,
            title: 'Recordatorios de Rutinas',
            subtitle: settings.habitRemindersEnabled
                ? 'Activo · Alarmas para Rutina Matutina y Nocturna'
                : 'Desactivado · Sin recordatorios de hábitos',
            value: settings.habitRemindersEnabled,
            onChanged: (val) async {
              if (val) {
                await notifier.requestPermissions();
              }
              notifier.toggleHabitReminders(val);
            },
          ),

          if (settings.habitRemindersEnabled) ...[
            _buildDivider(),
            _buildTimePickerTile(
              context: context,
              icon: Icons.wb_sunny_rounded,
              title: 'Hora Rutina Matutina',
              subtitle: 'Alarma de inicio del día sin snooze',
              timeString: settings.checklistAmTime,
              accentColor: const Color(0xFFD97706),
              onTimeSelected: (newTime) => notifier.setChecklistAmTime(newTime),
            ),
            _buildDivider(),
            _buildTimePickerTile(
              context: context,
              icon: Icons.nightlight_round,
              title: 'Hora Rutina Nocturna',
              subtitle: 'Desconexión digital y cierre de jornada',
              timeString: settings.checklistPmTime,
              accentColor: const Color(0xFF6366F1),
              onTimeSelected: (newTime) => notifier.setChecklistPmTime(newTime),
            ),
          ],

          _buildDivider(),

          // 2. Hydration Reminders
          _buildMasterTile(
            context: context,
            icon: Icons.water_drop_rounded,
            title: 'Alertas de Hidratación',
            subtitle: settings.hydrationRemindersEnabled
                ? 'Activo · Pausas periódicas para beber agua'
                : 'Desactivado · Sin alertas de agua',
            value: settings.hydrationRemindersEnabled,
            onChanged: (val) async {
              if (val) {
                await notifier.requestPermissions();
              }
              notifier.toggleHydrationReminders(val);
            },
          ),

          if (settings.hydrationRemindersEnabled) ...[
            _buildDivider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Frecuencia de alerta',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onSurface,
                          ),
                        ),
                        Text(
                          'Entre 09:00 AM y 08:00 PM',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [2, 3].map((hours) {
                      final isSelected =
                          settings.hydrationIntervalHours == hours;
                      return Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: ChoiceChip(
                          label: Text(
                            'Cada ${hours}h',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.onSurface,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppTheme.primary,
                          backgroundColor: AppTheme.surfaceContainerHigh,
                          onSelected: (_) =>
                              notifier.setHydrationInterval(hours),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],

          _buildDivider(),

          // 3. Streak Protection Alert
          _buildMasterTile(
            context: context,
            icon: Icons.local_fire_department_rounded,
            title: 'Alerta de Racha en Riesgo',
            subtitle: settings.streakRiskAlertsEnabled
                ? 'Activo · Aviso si tienes hábitos pendientes'
                : 'Desactivado · Sin alerta de racha',
            value: settings.streakRiskAlertsEnabled,
            onChanged: (val) => notifier.toggleStreakRiskAlerts(val),
          ),

          if (settings.streakRiskAlertsEnabled) ...[
            _buildDivider(),
            _buildTimePickerTile(
              context: context,
              icon: Icons.schedule_rounded,
              title: 'Hora de auditoría vespertina',
              subtitle: 'Check-in antes del cierre diario',
              timeString: settings.streakRiskTime,
              accentColor: Colors.orange,
              onTimeSelected: (newTime) => notifier.setStreakRiskTime(newTime),
            ),
          ],

          _buildDivider(),

          // 4. Pomodoro Focus Completion
          _buildMasterTile(
            context: context,
            icon: Icons.timelapse_rounded,
            title: 'Notificación Fin de Pomodoro',
            subtitle: settings.pomodoroNotificationsEnabled
                ? 'Alerta sonora y vibración al terminar bloque de enfoque'
                : 'Desactivado',
            value: settings.pomodoroNotificationsEnabled,
            onChanged: (val) => notifier.togglePomodoroNotifications(val),
          ),

          // 5. Spiritual Verse (Conditional)
          if (isReligious) ...[
            _buildDivider(),
            _buildMasterTile(
              context: context,
              icon: Icons.menu_book_rounded,
              title: 'Principio Bíblico Diario',
              subtitle: settings.verseReminderEnabled
                  ? 'Pasaje matutino de sabiduría y enfoque'
                  : 'Desactivado',
              value: settings.verseReminderEnabled,
              onChanged: (val) => notifier.toggleSpiritualVerse(val),
            ),
            if (settings.verseReminderEnabled) ...[
              _buildDivider(),
              _buildTimePickerTile(
                context: context,
                icon: Icons.schedule_rounded,
                title: 'Hora de reflexión matutina',
                subtitle: 'Envío del proverbio del día',
                timeString: settings.verseReminderTime,
                accentColor: const Color(0xFF6366F1),
                onTimeSelected: (newTime) =>
                    notifier.setSpiritualVerseTime(newTime),
              ),
            ],
          ],

          _buildDivider(),

          // 6. Test Notification Button
          Padding(
            padding: const EdgeInsets.all(14),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await notifier.requestPermissions();
                  await notifier.sendTestNotification();

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppTheme.surfaceContainerLowest,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: AppTheme.outlineVariant),
                        ),
                        content: Row(
                          children: [
                            const Icon(
                              Icons.notifications_active_rounded,
                              color: AppTheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Notificación de prueba enviada a la bandeja de tu dispositivo.',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  color: AppTheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.notifications_active_outlined, size: 18),
                label: Text(
                  'Probar Notificación Ahora',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: BorderSide(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMasterTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: value
                  ? AppTheme.primary.withValues(alpha: 0.1)
                  : AppTheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: value ? AppTheme.primary : AppTheme.outline,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppTheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppTheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildTimePickerTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String timeString,
    required Color accentColor,
    required ValueChanged<String> onTimeSelected,
  }) {
    return InkWell(
      onTap: () async {
        final parts = timeString.split(':');
        final currentHour = int.tryParse(parts.first) ?? 8;
        final currentMinute = int.tryParse(parts.last) ?? 0;

        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: currentHour, minute: currentMinute),
          helpText: title.toUpperCase(),
        );

        if (picked != null) {
          final h = picked.hour.toString().padLeft(2, '0');
          final m = picked.minute.toString().padLeft(2, '0');
          onTimeSelected('$h:$m');
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 18, color: accentColor),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    timeString,
                    style: AppTheme.numeric(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.edit_calendar_rounded,
                    size: 14,
                    color: accentColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: AppTheme.outlineVariant,
    );
  }
}
