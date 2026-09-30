import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme.dart';
import '../../domain/water_data.dart';
import '../controllers/wellness_controller.dart';
import 'custom_water_dialog.dart';

/// Executive, high-impact Hydration Tracker Card.
/// Can be embedded into the Dashboard (Launcher), Habits screen, or Wellness screen.
class WaterTrackerCard extends ConsumerWidget {
  final bool showHeader;
  final bool isCompact;
  final VoidCallback? onOpenDetails;

  const WaterTrackerCard({
    super.key,
    this.showHeader = true,
    this.isCompact = false,
    this.onOpenDetails,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waterAsync = ref.watch(dailyWaterSummaryProvider);

    return waterAsync.when(
      loading: () => Container(
        height: 180,
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.surfaceContainerHigh),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (e, _) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.surfaceContainerHigh),
        ),
        child: Text('Error al cargar hidratación: $e'),
      ),
      data: (summary) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.surfaceContainerHigh),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(isCompact ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showHeader) ...[
                  _buildHeader(context, ref, summary),
                  const SizedBox(height: 16),
                ],

                // Central Gauge & Metrics Row
                Row(
                  children: [
                    // Circular Progress Ring
                    _buildCircularGauge(summary),
                    const SizedBox(width: 18),

                    // Metrics & Status Information
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${summary.totalAmountMl}',
                                style: AppTheme.numeric(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.onSurface,
                                ),
                              ),
                              Text(
                                ' / ${summary.dailyGoalMl} ml',
                                style: AppTheme.numeric(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            summary.isGoalAchieved
                                ? '¡Meta del día superada! Claridad mental y rendimiento óptimo.'
                                : 'Faltan ${summary.remainingMl} ml para tu meta diaria sugerida.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: summary.isGoalAchieved
                                  ? const Color(0xFF10B981)
                                  : AppTheme.onSurfaceVariant,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Linear Bar with Percentage
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: summary.progressRatio.clamp(0.0, 1.0),
                              backgroundColor: const Color(0xFF0284C7).withValues(alpha: 0.12),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                summary.isGoalAchieved
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF0284C7),
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Quick Add Pills Row
                _buildQuickAddRow(context, ref, summary),

                // Undo & History Footer
                if (summary.entries.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(color: AppTheme.surfaceContainerHigh, height: 1),
                  const SizedBox(height: 10),
                  _buildFooterActions(context, ref, summary),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, DailyWaterSummary summary) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: InkWell(
            onTap: onOpenDetails,
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.water_drop_rounded,
                    color: Color(0xFF0284C7),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BIENESTAR FÍSICO',
                        style: AppTheme.labelCaps(
                          fontSize: 9.5,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Tracker de Hidratación',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (onOpenDetails != null) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 11,
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.tune_rounded, size: 18, color: AppTheme.onSurfaceVariant),
          tooltip: 'Calibrar meta de agua',
          visualDensity: VisualDensity.compact,
          onPressed: () => _openCustomWaterDialog(context, ref, summary.dailyGoalMl),
        ),
      ],
    );
  }

  Widget _buildCircularGauge(DailyWaterSummary summary) {
    final progress = summary.progressRatio.clamp(0.0, 1.0);

    return SizedBox(
      width: 82,
      height: 82,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 82,
            height: 82,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 8,
              strokeCap: StrokeCap.round,
              backgroundColor: const Color(0xFF0284C7).withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(
                summary.isGoalAchieved
                    ? const Color(0xFF10B981)
                    : const Color(0xFF0284C7),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                summary.isGoalAchieved
                    ? Icons.emoji_events_rounded
                    : Icons.water_drop_rounded,
                size: 24,
                color: summary.isGoalAchieved
                    ? const Color(0xFF10B981)
                    : const Color(0xFF0284C7),
              ),
              const SizedBox(height: 2),
              Text(
                '${summary.progressPercent}%',
                style: AppTheme.numeric(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAddRow(BuildContext context, WidgetRef ref, DailyWaterSummary summary) {
    return Row(
      children: [
        Expanded(
          child: _QuickPillButton(
            icon: Icons.local_drink_rounded,
            label: '+250 ml',
            subtitle: 'Vaso',
            onTap: () => _addWater(context, ref, 250),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickPillButton(
            icon: Icons.water_drop_rounded,
            label: '+500 ml',
            subtitle: 'Botella',
            onTap: () => _addWater(context, ref, 500),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickPillButton(
            icon: Icons.sports_gymnastics_rounded,
            label: '+750 ml',
            subtitle: 'Termo',
            onTap: () => _addWater(context, ref, 750),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickPillButton(
            icon: Icons.add_rounded,
            label: 'Otro',
            subtitle: 'Manual',
            isOutlined: true,
            onTap: () => _openCustomWaterDialog(context, ref, summary.dailyGoalMl),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterActions(BuildContext context, WidgetRef ref, DailyWaterSummary summary) {
    final lastEntry = summary.entries.first;
    final timeStr = _formatTime(lastEntry.loggedAt);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => _showHistorySheet(context, ref, summary),
          child: Row(
            children: [
              const Icon(Icons.history_rounded, size: 15, color: AppTheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                'Último: +${lastEntry.amountMl} ml a las $timeStr (${summary.entries.length} tomas)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: () {
            ref.read(waterControllerProvider.notifier).undoLastLog();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Se eliminó el último registro de agua.'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Row(
              children: [
                const Icon(Icons.undo_rounded, size: 14, color: AppTheme.error),
                const SizedBox(width: 4),
                Text(
                  'Deshacer',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.error,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _addWater(BuildContext context, WidgetRef ref, int amountMl) {
    ref.read(waterControllerProvider.notifier).logWater(amountMl);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('💧 Registraste +$amountMl ml de hidratación.'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openCustomWaterDialog(BuildContext context, WidgetRef ref, int currentGoal) {
    showDialog(
      context: context,
      builder: (ctx) => CustomWaterDialog(
        currentGoal: currentGoal,
        onAddCustom: (amount) {
          ref.read(waterControllerProvider.notifier).logWater(amount);
        },
        onUpdateGoal: (newGoal) {
          ref.read(waterControllerProvider.notifier).updateGoal(newGoal);
        },
      ),
    );
  }

  void _showHistorySheet(BuildContext context, WidgetRef ref, DailyWaterSummary summary) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'INGESTAS DE HOY',
                      style: AppTheme.labelCaps(
                        color: AppTheme.onSurfaceVariant,
                        letterSpacing: 0.1,
                      ),
                    ),
                    Text(
                      '${summary.totalAmountMl} ml total',
                      style: AppTheme.numeric(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0284C7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (summary.entries.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('Aún no has registrado tomas de agua hoy.')),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: summary.entries.length,
                      separatorBuilder: (_, _) => const Divider(height: 1, color: AppTheme.surfaceContainerHigh),
                      itemBuilder: (context, idx) {
                        final entry = summary.entries[idx];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.water_drop_rounded,
                              size: 18,
                              color: Color(0xFF0284C7),
                            ),
                          ),
                          title: Text(
                            '+${entry.amountMl} ml',
                            style: AppTheme.numeric(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.onSurface,
                            ),
                          ),
                          subtitle: Text(
                            _formatTime(entry.loggedAt),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.error),
                            tooltip: 'Eliminar registro',
                            onPressed: () {
                              ref.read(waterControllerProvider.notifier).deleteWaterLog(entry.id);
                              Navigator.of(ctx).pop();
                            },
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _QuickPillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool isOutlined;

  const _QuickPillButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFF0284C7);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: isOutlined
              ? AppTheme.surfaceContainerLowest
              : brandColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isOutlined
                ? AppTheme.surfaceContainerHigh
                : brandColor.withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: brandColor),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTheme.numeric(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: brandColor,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
