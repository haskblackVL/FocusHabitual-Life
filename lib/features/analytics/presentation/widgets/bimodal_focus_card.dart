import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme.dart';
import '../../domain/analytics_data.dart';

/// Card displaying the Deep Work vs Shallow Work bimodal split and Pomodoro timer mode counts.
class BimodalFocusCard extends StatelessWidget {
  const BimodalFocusCard({
    super.key,
    required this.bimodalStats,
  });

  final BimodalFocusStats bimodalStats;

  @override
  Widget build(BuildContext context) {
    final totalMinutes = bimodalStats.totalMinutes;
    final deepPct = totalMinutes > 0 ? (bimodalStats.deepWorkMinutes / totalMinutes * 100).round() : 0;
    final shallowPct = totalMinutes > 0 ? (bimodalStats.shallowWorkMinutes / totalMinutes * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceContainerHigh, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ENFOQUE BIMODAL',
                    style: AppTheme.labelCaps(
                      fontSize: 10,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Deep Work vs. Shallow Work',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '1.5x XP DEEP WORK',
                  style: AppTheme.labelCaps(
                    fontSize: 9,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Ratio bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  if (totalMinutes == 0)
                    Expanded(
                      child: Container(color: AppTheme.surfaceContainerHigh),
                    )
                  else ...[
                    if (bimodalStats.deepWorkMinutes > 0)
                      Expanded(
                        flex: bimodalStats.deepWorkMinutes,
                        child: Container(
                          color: AppTheme.primary,
                        ),
                      ),
                    if (bimodalStats.shallowWorkMinutes > 0)
                      Expanded(
                        flex: bimodalStats.shallowWorkMinutes,
                        child: Container(
                          color: AppTheme.accentEmerald,
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Two-column comparison
          Row(
            children: [
              // Deep Work
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'DEEP WORK ($deepPct%)',
                            style: AppTheme.labelCaps(
                              fontSize: 9,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        bimodalStats.formattedDeepWorkTime,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${bimodalStats.deepWorkSessions} sesiones nucleares',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Shallow Work
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.accentEmerald.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.accentEmerald,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'SHALLOW WORK ($shallowPct%)',
                            style: AppTheme.labelCaps(
                              fontSize: 9,
                              color: AppTheme.accentEmerald,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        bimodalStats.formattedShallowWorkTime,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${bimodalStats.shallowWorkSessions} sesiones mant.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Modos Pomodoro utilizados
          Text(
            'SESIONES POR MODO DE TEMPORIZADOR',
            style: AppTheme.labelCaps(
              fontSize: 10,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _ModeChip(
                label: 'Clásico',
                count: bimodalStats.classicSessions,
                icon: Icons.timer_outlined,
              ),
              const SizedBox(width: 6),
              _ModeChip(
                label: 'Extendido',
                count: bimodalStats.extendedSessions,
                icon: Icons.hourglass_top_rounded,
              ),
              const SizedBox(width: 6),
              _ModeChip(
                label: 'Ultradiano',
                count: bimodalStats.ultradianSessions,
                icon: Icons.psychology_rounded,
              ),
              const SizedBox(width: 6),
              _ModeChip(
                label: 'Flowmodoro',
                count: bimodalStats.flowmodoroSessions,
                icon: Icons.all_inclusive_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.count,
    required this.icon,
  });

  final String label;
  final int count;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.surfaceContainerHigh),
        ),
        child: Column(
          children: [
            Icon(icon, size: 14, color: AppTheme.onSurfaceVariant),
            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: GoogleFonts.jetBrainsMono(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: AppTheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
