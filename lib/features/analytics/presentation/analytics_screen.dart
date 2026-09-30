import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme.dart';
import '../../../app/widgets/brand_logo.dart';
import '../domain/analytics_data.dart';
import 'controllers/analytics_controller.dart';
import 'widgets/analytics_charts.dart';
import 'widgets/bimodal_focus_card.dart';
import 'widgets/score_calendar_card.dart';

/// Full Executive Precision Analytics & Performance Dashboard.
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(analyticsControllerProvider);
    final activeRange = ref.watch(analyticsTimeRangeProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest.withValues(alpha: 0.94),
            border: const Border(
              bottom: BorderSide(color: AppTheme.surfaceContainerHigh, width: 1),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const FocusHabitualLogo(size: 32),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FocusHabitual',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      Text(
                        'ANALÍTICA & RENDIMIENTO',
                        style: AppTheme.labelCaps(
                          color: AppTheme.onSurfaceVariant,
                          letterSpacing: 0.08,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.refresh_rounded,
                      size: 20,
                      color: AppTheme.onSurfaceVariant,
                    ),
                    tooltip: 'Recalcular métricas',
                    onPressed: () {
                      ref.read(analyticsControllerProvider.notifier).refresh();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryContainer,
        backgroundColor: AppTheme.surfaceContainerLowest,
        onRefresh: () async {
          await ref.read(analyticsControllerProvider.notifier).refresh();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Time Range Horizon Selector
              _buildTimeRangeSelector(context, ref, activeRange),
              const SizedBox(height: 18),

              analyticsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: CircularProgressIndicator(color: AppTheme.primaryContainer),
                  ),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Text(
                      'Error al cargar métricas: $err',
                      style: GoogleFonts.plusJakartaSans(color: AppTheme.error),
                    ),
                  ),
                ),
                data: (summary) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2. Executive KPI Deck (4 cards)
                    _buildKpiDeck(summary),
                    const SizedBox(height: 18),

                    // 3. Interactive Trend Chart (fl_chart)
                    ActivityTrendChart(
                      metrics: summary.dailyMetrics,
                      range: summary.range,
                    ),
                    const SizedBox(height: 18),

                    // 4. Bimodal Focus Card (Deep Work vs Shallow Work)
                    BimodalFocusCard(bimodalStats: summary.bimodalFocus),
                    const SizedBox(height: 18),

                    // 5. Executive Monthly Score Calendar
                    ExecutiveScoreCalendarCard(
                      heatmapDays: summary.heatmapDays,
                      dailyMetrics: summary.dailyMetrics,
                    ),
                    const SizedBox(height: 18),

                    // 5. Habit Consistency Heatmap
                    ConsistencyHeatmapCard(days: summary.heatmapDays),
                    const SizedBox(height: 18),

                    // 5. Category Distribution Breakdown
                    CategoryBreakdownCard(
                      categories: summary.categoryDistribution,
                    ),
                    const SizedBox(height: 18),

                    // 6. Top Habits Ranking
                    TopHabitsCard(habits: summary.topHabits),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Segmented horizon filter (Semana / Mes / Año).
  Widget _buildTimeRangeSelector(
    BuildContext context,
    WidgetRef ref,
    TimeRange activeRange,
  ) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceContainerHigh, width: 1),
      ),
      child: Row(
        children: TimeRange.values.map((range) {
          final isSelected = range == activeRange;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                ref.read(analyticsControllerProvider.notifier).setTimeRange(range);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryContainer : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  range.label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppTheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 2x2 grid of Executive KPI cards.
  Widget _buildKpiDeck(AnalyticsSummary summary) {
    final consistencyPct = (summary.consistencyRate * 100).round();

    return Column(
      children: [
        Row(
          children: [
            // Card 1: Hábitos completados
            Expanded(
              child: _KpiCard(
                label: 'HÁBITOS COMPLETADOS',
                value: summary.totalHabitsCompleted.toString(),
                unit: 'ejecuciones',
                icon: Icons.check_circle_rounded,
                accentColor: AppTheme.primaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            // Card 2: Minutos de Enfoque
            Expanded(
              child: _KpiCard(
                label: 'TIEMPO DE ENFOQUE',
                value: summary.formattedFocusTime,
                unit: '${summary.totalSessionsCompleted} sesiones',
                icon: Icons.hourglass_full_rounded,
                accentColor: AppTheme.accentEmerald,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Card 3: Tasa de Consistencia
            Expanded(
              child: _KpiCard(
                label: 'TASA DE CONSISTENCIA',
                value: '$consistencyPct%',
                unit: 'disciplina en período',
                icon: Icons.bolt_rounded,
                accentColor: AppTheme.accentAmber,
                progress: summary.consistencyRate,
              ),
            ),
            const SizedBox(width: 12),
            // Card 4: Nivel & XP
            Expanded(
              child: _KpiCard(
                label: 'NIVEL FOCUS',
                value: 'Nv. ${summary.currentLevel}',
                unit: '${summary.totalXp} XP total',
                icon: Icons.auto_awesome_rounded,
                accentColor: AppTheme.accentIndigo,
                subtitle: summary.levelTitle,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.accentColor,
    this.progress,
    this.subtitle,
  });

  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color accentColor;
  final double? progress;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceContainerHigh, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: AppTheme.labelCaps(
                    color: AppTheme.onSurfaceVariant,
                    letterSpacing: 0.06,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 14, color: accentColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTheme.numeric(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle ?? unit,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (progress != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress!.clamp(0.0, 1.0),
                backgroundColor: AppTheme.surfaceContainerLow,
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                minHeight: 4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
