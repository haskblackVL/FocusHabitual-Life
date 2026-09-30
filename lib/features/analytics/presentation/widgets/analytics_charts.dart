import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme.dart';
import '../../domain/analytics_data.dart';

/// Interactive dual-metric trend chart (Habits completed vs Focus minutes).
class ActivityTrendChart extends StatefulWidget {
  const ActivityTrendChart({
    super.key,
    required this.metrics,
    required this.range,
  });

  final List<DailyMetric> metrics;
  final TimeRange range;

  @override
  State<ActivityTrendChart> createState() => _ActivityTrendChartState();
}

class _ActivityTrendChartState extends State<ActivityTrendChart> {
  bool _showFocusMinutes = false;

  @override
  Widget build(BuildContext context) {
    if (widget.metrics.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(child: Text('Sin datos en este período')),
      );
    }

    final values = widget.metrics
        .map((m) => _showFocusMinutes ? m.focusMinutes.toDouble() : m.habitsCompleted.toDouble())
        .toList();
    final maxVal = values.fold<double>(0, math.max);
    final chartMaxY = maxVal > 0 ? (maxVal * 1.25).ceilToDouble() : 5.0;

    final primaryColor = _showFocusMinutes ? AppTheme.accentEmerald : AppTheme.primaryContainer;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceContainerHigh, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with metric toggles
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _showFocusMinutes ? 'MINUTOS DE ENFOQUE' : 'HÁBITOS COMPLETADOS',
                    style: AppTheme.labelCaps(
                      color: AppTheme.onSurfaceVariant,
                      letterSpacing: 0.08,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.range.description,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ],
              ),
              // Metric Toggle Pills
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.surfaceContainerHigh, width: 1),
                ),
                child: Row(
                  children: [
                    _MetricPill(
                      label: 'Hábitos',
                      isSelected: !_showFocusMinutes,
                      activeColor: AppTheme.primaryContainer,
                      onTap: () => setState(() => _showFocusMinutes = false),
                    ),
                    const SizedBox(width: 4),
                    _MetricPill(
                      label: 'Enfoque',
                      isSelected: _showFocusMinutes,
                      activeColor: AppTheme.accentEmerald,
                      onTap: () => setState(() => _showFocusMinutes = true),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Bar Chart Canvas
          SizedBox(
            height: 190,
            child: BarChart(
              BarChartData(
                maxY: chartMaxY,
                minY: 0,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppTheme.onSurface,
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final item = widget.metrics[group.x.toInt()];
                      final valStr = _showFocusMinutes
                          ? '${rod.toY.toInt()} min'
                          : '${rod.toY.toInt()} hábitos';
                      return BarTooltipItem(
                        '${item.label}\n',
                        GoogleFonts.plusJakartaSans(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        children: [
                          TextSpan(
                            text: valStr,
                            style: AppTheme.numeric(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: chartMaxY > 4 ? (chartMaxY / 4).roundToDouble() : 1,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.max || value == meta.min) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          value.toInt().toString(),
                          style: AppTheme.numeric(
                            color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= widget.metrics.length) {
                          return const SizedBox.shrink();
                        }
                        final label = widget.metrics[idx].label;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            label,
                            style: AppTheme.numeric(
                              color: AppTheme.onSurface,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: chartMaxY > 4 ? (chartMaxY / 4).roundToDouble() : 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.6),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(widget.metrics.length, (i) {
                  final val = _showFocusMinutes
                      ? widget.metrics[i].focusMinutes.toDouble()
                      : widget.metrics[i].habitsCompleted.toDouble();
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: val,
                        width: widget.range == TimeRange.year ? 14 : 22,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                        color: primaryColor,
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: chartMaxY,
                          color: AppTheme.surfaceContainerLow,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.label,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// Swiss Neo-Minimalist Heatmap (Matrix of habit consistency).
class ConsistencyHeatmapCard extends StatelessWidget {
  const ConsistencyHeatmapCard({
    super.key,
    required this.days,
  });

  final List<ConsistencyDay> days;

  @override
  Widget build(BuildContext context) {
    // 42 days = 6 columns of 7 days (or 7 rows x N columns)
    // Structure: 7 rows (Lunes a Domingo), N columns (weeks)
    final numWeeks = (days.length / 7).ceil();
    final dayNames = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceContainerHigh, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MATRIZ DE DISCIPLINA & CONSISTENCIA',
                style: AppTheme.labelCaps(
                  color: AppTheme.onSurfaceVariant,
                  letterSpacing: 0.08,
                ),
              ),
              Text(
                'Últimas 6 semanas',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Heatmap Grid: 7 rows (weekdays), numWeeks columns
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row labels (L, M, X, J, V, S, D)
              Column(
                children: List.generate(7, (rowIdx) {
                  return Container(
                    height: 18,
                    width: 16,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      dayNames[rowIdx],
                      style: AppTheme.numeric(
                        fontSize: 9,
                        color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(width: 6),

              // Columns for each week
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(numWeeks, (colIdx) {
                    return Column(
                      children: List.generate(7, (rowIdx) {
                        final itemIndex = colIdx * 7 + rowIdx;
                        if (itemIndex >= days.length) {
                          return const SizedBox(width: 18, height: 18);
                        }
                        final day = days[itemIndex];
                        return _HeatmapCell(day: day);
                      }),
                    );
                  }),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Heatmap Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Menos',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 6),
              ...List.generate(5, (level) {
                return Container(
                  width: 11,
                  height: 11,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: _getColorForLevel(level),
                    borderRadius: BorderRadius.circular(2.5),
                    border: Border.all(
                      color: level == 0
                          ? AppTheme.surfaceContainerHigh
                          : Colors.transparent,
                      width: 0.5,
                    ),
                  ),
                );
              }),
              const SizedBox(width: 6),
              Text(
                'Más',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Color _getColorForLevel(int level) {
    switch (level) {
      case 0:
        return AppTheme.surfaceContainer;
      case 1:
        return AppTheme.primaryContainer.withValues(alpha: 0.25);
      case 2:
        return AppTheme.primaryContainer.withValues(alpha: 0.50);
      case 3:
        return AppTheme.primaryContainer.withValues(alpha: 0.78);
      case 4:
      default:
        return AppTheme.primary;
    }
  }
}

class _HeatmapCell extends StatelessWidget {
  const _HeatmapCell({required this.day});

  final ConsistencyDay day;

  @override
  Widget build(BuildContext context) {
    final color = ConsistencyHeatmapCard._getColorForLevel(day.intensityLevel);
    final dateStr = DateFormat('dd/MM').format(day.date);

    return Tooltip(
      message: '$dateStr: ${day.count} hábito${day.count == 1 ? '' : 's'}',
      triggerMode: TooltipTriggerMode.tap,
      child: Container(
        width: 18,
        height: 18,
        margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 1),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: day.intensityLevel == 0
                ? AppTheme.surfaceContainerHigh
                : Colors.transparent,
            width: 0.5,
          ),
        ),
      ),
    );
  }
}

/// Category distribution card showing percentage execution per module.
class CategoryBreakdownCard extends StatelessWidget {
  const CategoryBreakdownCard({
    super.key,
    required this.categories,
  });

  final List<CategoryDistribution> categories;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceContainerHigh, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DISTRIBUCIÓN POR DISCIPLINA',
            style: AppTheme.labelCaps(
              color: AppTheme.onSurfaceVariant,
              letterSpacing: 0.08,
            ),
          ),
          const SizedBox(height: 14),
          if (categories.isEmpty || categories.every((c) => c.count == 0))
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Aún no hay hábitos completados en este período.'),
            )
          else
            ...categories.where((c) => c.count > 0).map((cat) {
              final pct = (cat.percentage * 100).round();
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          cat.displayName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onSurface,
                          ),
                        ),
                        Text(
                          '${cat.count} ejecuciones ($pct%)',
                          style: AppTheme.numeric(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryContainer,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: cat.percentage.clamp(0.02, 1.0),
                        backgroundColor: AppTheme.surfaceContainerLow,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryContainer,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

/// Card showcasing the top habits with highest streaks and completions.
class TopHabitsCard extends StatelessWidget {
  const TopHabitsCard({
    super.key,
    required this.habits,
  });

  final List<TopHabitStat> habits;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceContainerHigh, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HÁBITOS MÁS CONSTANTES',
            style: AppTheme.labelCaps(
              color: AppTheme.onSurfaceVariant,
              letterSpacing: 0.08,
            ),
          ),
          const SizedBox(height: 12),
          if (habits.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Registra hábitos para ver tu ranking de constancia.'),
            )
          else
            ...List.generate(habits.length, (idx) {
              final h = habits[idx];
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 5),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.surfaceContainerHigh, width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: idx == 0
                            ? AppTheme.primaryContainer
                            : AppTheme.surfaceContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${idx + 1}',
                        style: AppTheme.numeric(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: idx == 0 ? Colors.white : AppTheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        h.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.local_fire_department_rounded,
                          size: 16,
                          color: AppTheme.accentAmber,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${h.streak}d',
                          style: AppTheme.numeric(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
