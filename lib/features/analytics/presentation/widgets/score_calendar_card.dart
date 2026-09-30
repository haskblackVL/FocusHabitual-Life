import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme.dart';
import '../../domain/analytics_data.dart';

/// Executive Precision Monthly Calendar for the Score/Analytics Menu.
/// Allows browsing past and current months to inspect day-by-day habit completion,
/// focus minutes, and discipline consistency.
class ExecutiveScoreCalendarCard extends StatefulWidget {
  final List<ConsistencyDay> heatmapDays;
  final List<DailyMetric> dailyMetrics;

  const ExecutiveScoreCalendarCard({
    super.key,
    required this.heatmapDays,
    required this.dailyMetrics,
  });

  @override
  State<ExecutiveScoreCalendarCard> createState() => _ExecutiveScoreCalendarCardState();
}

class _ExecutiveScoreCalendarCardState extends State<ExecutiveScoreCalendarCard> {
  late DateTime _selectedMonth;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month, 1);
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    });
  }

  /// Finds consistency data for a given date.
  ConsistencyDay? _getDayData(DateTime date) {
    for (final d in widget.heatmapDays) {
      if (d.date.year == date.year && d.date.month == date.month && d.date.day == date.day) {
        return d;
      }
    }
    return null;
  }

  /// Finds daily metric for a given date (focus minutes, etc.)
  DailyMetric? _getDailyMetric(DateTime date) {
    for (final m in widget.dailyMetrics) {
      if (m.date.year == date.year && m.date.month == date.month && m.date.day == date.day) {
        return m;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final monthFormat = DateFormat('MMMM yyyy', 'es');
    final formattedMonthTitle = monthFormat.format(_selectedMonth).toUpperCase();

    final daysInMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    // DateTime weekday: 1 = Lunes, 7 = Domingo
    final firstWeekday = DateTime(_selectedMonth.year, _selectedMonth.month, 1).weekday; // 1..7
    final leadingEmptyCells = firstWeekday - 1;

    final selectedDayData = _getDayData(_selectedDay);
    final selectedDayMetric = _getDailyMetric(_selectedDay);
    final selectedDayFormatted = DateFormat("EEEE, d 'de' MMMM", 'es').format(_selectedDay);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
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
          // Header: Title & Month Navigator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CALENDARIO DE DISCIPLINA',
                    style: AppTheme.labelCaps(
                      color: AppTheme.onSurfaceVariant,
                      letterSpacing: 0.08,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formattedMonthTitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 22),
                    color: AppTheme.onSurfaceVariant,
                    visualDensity: VisualDensity.compact,
                    onPressed: _previousMonth,
                    tooltip: 'Mes anterior',
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, size: 22),
                    color: AppTheme.onSurfaceVariant,
                    visualDensity: VisualDensity.compact,
                    onPressed: _nextMonth,
                    tooltip: 'Mes siguiente',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Weekday header (L, M, X, J, V, S, D)
          Row(
            children: const [
              _WeekdayHeaderCell('L'),
              _WeekdayHeaderCell('M'),
              _WeekdayHeaderCell('X'),
              _WeekdayHeaderCell('J'),
              _WeekdayHeaderCell('V'),
              _WeekdayHeaderCell('S'),
              _WeekdayHeaderCell('D'),
            ],
          ),
          const SizedBox(height: 8),

          // Calendar Grid
          _buildMonthGrid(daysInMonth, leadingEmptyCells),

          const SizedBox(height: 16),
          const Divider(color: AppTheme.surfaceContainerHigh, height: 1),
          const SizedBox(height: 14),

          // Selected Day Telemetry Card
          _buildSelectedDayDetail(
            selectedDayFormatted,
            selectedDayData,
            selectedDayMetric,
          ),
        ],
      ),
    );
  }

  Widget _buildMonthGrid(int daysInMonth, int leadingEmptyCells) {
    final totalCells = leadingEmptyCells + daysInMonth;
    final rowCount = (totalCells / 7).ceil();
    final today = DateTime.now();

    return Column(
      children: List.generate(rowCount, (rowIndex) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: List.generate(7, (colIndex) {
              final cellIndex = rowIndex * 7 + colIndex;
              final dayNumber = cellIndex - leadingEmptyCells + 1;

              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const Expanded(child: SizedBox(height: 38));
              }

              final cellDate = DateTime(_selectedMonth.year, _selectedMonth.month, dayNumber);
              final isSelected = cellDate.year == _selectedDay.year &&
                  cellDate.month == _selectedDay.month &&
                  cellDate.day == _selectedDay.day;
              final isToday = cellDate.year == today.year &&
                  cellDate.month == today.month &&
                  cellDate.day == today.day;

              final dayData = _getDayData(cellDate);
              final intensity = dayData?.intensityLevel ?? 0;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDay = cellDate;
                    });
                  },
                  child: Container(
                    height: 38,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: _getCellBackgroundColor(intensity, isSelected),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryContainer
                            : (isToday ? AppTheme.accentEmerald : Colors.transparent),
                        width: isSelected ? 2 : (isToday ? 1.5 : 0),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$dayNumber',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            fontWeight: isToday || isSelected ? FontWeight.w800 : FontWeight.w500,
                            color: isSelected
                                ? AppTheme.primaryContainer
                                : (intensity > 2
                                    ? AppTheme.onSurface
                                    : AppTheme.onSurfaceVariant),
                          ),
                        ),
                        if (intensity > 0)
                          Container(
                            width: 4,
                            height: 4,
                            margin: const EdgeInsets.only(top: 2),
                            decoration: BoxDecoration(
                              color: _getIntensityDotColor(intensity),
                              shape: BoxShape.circle,
                            ),
                          )
                        else
                          const SizedBox(height: 6),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  Color _getCellBackgroundColor(int intensity, bool isSelected) {
    if (isSelected) {
      return AppTheme.primaryContainer.withValues(alpha: 0.12);
    }
    return switch (intensity) {
      1 => AppTheme.primaryContainer.withValues(alpha: 0.08),
      2 => AppTheme.primaryContainer.withValues(alpha: 0.16),
      3 => AppTheme.primaryContainer.withValues(alpha: 0.28),
      4 => AppTheme.primaryContainer.withValues(alpha: 0.42),
      _ => AppTheme.surfaceContainerLow.withValues(alpha: 0.4),
    };
  }

  Color _getIntensityDotColor(int intensity) {
    return switch (intensity) {
      1 => AppTheme.primaryContainer.withValues(alpha: 0.6),
      2 => AppTheme.primaryContainer,
      3 => AppTheme.accentEmerald,
      4 => AppTheme.accentGold,
      _ => Colors.transparent,
    };
  }

  Widget _buildSelectedDayDetail(
    String dateFormatted,
    ConsistencyDay? dayData,
    DailyMetric? metric,
  ) {
    final habitsDone = dayData?.count ?? 0;
    final focusMins = metric?.focusMinutes ?? 0;
    final xpEarned = metric?.xpEarned ?? (habitsDone * 10);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateFormatted.toUpperCase(),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _DetailMetricChip(
                  icon: Icons.check_circle_rounded,
                  label: 'Hábitos',
                  value: '$habitsDone comp.',
                  accentColor: AppTheme.primaryContainer,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DetailMetricChip(
                  icon: Icons.hourglass_top_rounded,
                  label: 'Deep Work',
                  value: '$focusMins min',
                  accentColor: AppTheme.accentEmerald,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DetailMetricChip(
                  icon: Icons.bolt_rounded,
                  label: 'XP Obtenido',
                  value: '+$xpEarned XP',
                  accentColor: AppTheme.accentGold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeekdayHeaderCell extends StatelessWidget {
  final String label;
  const _WeekdayHeaderCell(this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}

class _DetailMetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;

  const _DetailMetricChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: accentColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  color: AppTheme.outline,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
