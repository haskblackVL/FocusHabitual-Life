import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme.dart';
import '../controllers/pomodoro_controller.dart';

/// Modal dialog showing the post-session debrief: flow minutes, XP gained, and Bloc de Descarga conversion.
class PostSessionSummaryDialog extends ConsumerWidget {
  const PostSessionSummaryDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PostSessionSummaryDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pomodoroProvider);
    final notifier = ref.read(pomodoroProvider.notifier);
    final isDeepWork = state.workType.isDeepWork;

    return Dialog(
      backgroundColor: AppTheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with trophy / check
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDeepWork
                          ? AppTheme.primary.withValues(alpha: 0.12)
                          : AppTheme.accentEmerald.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isDeepWork ? Icons.workspace_premium_rounded : Icons.check_circle_rounded,
                      color: isDeepWork ? AppTheme.primary : AppTheme.accentEmerald,
                      size: 28,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '+${state.lastAwardedXp} XP',
                      style: AppTheme.numeric(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Text(
                'Sesión de Enfoque Completada',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isDeepWork
                    ? 'Excelente inmersión cognitiva. Se ha otorgado bono de 1.5x XP.'
                    : 'Bloque de mantenimiento ejecutado con efectividad.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),

              // Metrics Row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetricCol('MODO', state.mode.name),
                    Container(width: 1, height: 28, color: AppTheme.outlineVariant),
                    _buildMetricCol('TIPO', state.workType.title),
                    Container(width: 1, height: 28, color: AppTheme.outlineVariant),
                    _buildMetricCol('PAUSA SUGERIDA', '${state.calculatedBreakMinutes}m'),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Objective review
              if (state.taskObjective != null && state.taskObjective!.isNotEmpty) ...[
                Text(
                  'OBJETIVO EJECUTADO',
                  style: AppTheme.labelCaps(fontSize: 10, color: AppTheme.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    state.taskObjective!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Bloc de Descarga Captured Notes Review
              if (state.interruptionNotes.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'PENSAMIENTOS CAPTURADOS (${state.interruptionNotes.length})',
                      style: AppTheme.labelCaps(fontSize: 10, color: AppTheme.onSurfaceVariant),
                    ),
                    Text(
                      'Toca + para convertir a hábito',
                      style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppTheme.outline),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 140),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: state.interruptionNotes.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final note = state.interruptionNotes[index];
                      final isConverted = note.convertedToHabitId != null;

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                note.noteText,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.onSurface,
                                ),
                              ),
                            ),
                            if (!isConverted)
                              IconButton(
                                onPressed: () {
                                  notifier.convertNoteToHabit(note.id, note.noteText);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Guardado como hábito: "${note.noteText}"'),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.add_task_rounded, size: 18),
                                color: AppTheme.primary,
                                tooltip: 'Convertir en Hábito',
                              )
                            else
                              const Icon(Icons.check_circle_rounded, size: 18, color: AppTheme.accentEmerald),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Bottom Actions
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        notifier.dismissPostSessionDialog();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Continuar al Descanso Activo',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCol(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTheme.labelCaps(fontSize: 9, color: AppTheme.onSurfaceVariant),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurface,
          ),
        ),
      ],
    );
  }
}
