import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme.dart';
import '../../domain/cycle_models.dart';
import '../controllers/cycle_controller.dart';
import 'cycle_day_logger_sheet.dart';

/// Interactive Multi-Layer Calendar displaying menstrual, ovulation, pregnancy,
/// natural family planning, and daily symptom markers.
class CycleLayerCalendar extends ConsumerWidget {
  const CycleLayerCalendar({super.key});

  static const _weekDays = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  static String _formatMonthYear(DateTime date) {
    final months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMonth = ref.watch(cycleCalendarMonthProvider);
    final selectedDate = ref.watch(cycleSelectedDateProvider);
    final activeLayers = ref.watch(cycleActiveLayersProvider);
    final monthDataAsync = ref.watch(cycleMonthDataProvider);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.outlineVariant),
      ),
      child: Column(
        children: [
          // 1. Month Header & Navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () {
                  ref.read(cycleCalendarMonthProvider.notifier).previousMonth();
                },
                tooltip: 'Mes anterior',
              ),
              Column(
                children: [
                  Text(
                    _formatMonthYear(currentMonth),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  if (currentMonth.year != today.year || currentMonth.month != today.month)
                    InkWell(
                      onTap: () {
                        ref.read(cycleCalendarMonthProvider.notifier).setMonth(today);
                        ref.read(cycleSelectedDateProvider.notifier).selectDate(today);
                      },
                      child: Text(
                        'Volver a Hoy',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: () {
                  ref.read(cycleCalendarMonthProvider.notifier).nextMonth();
                },
                tooltip: 'Mes siguiente',
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 2. Weekdays Header
          Row(
            children: _weekDays.map((d) {
              return Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // 3. Days Grid
          monthDataAsync.when(
            loading: () => const SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (err, _) => SizedBox(
              height: 220,
              child: Center(
                child: Text(
                  'Error cargando calendario: $err',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.error),
                ),
              ),
            ),
            data: (monthData) {
              return _buildMonthGrid(
                context: context,
                ref: ref,
                currentMonth: currentMonth,
                selectedDate: selectedDate,
                today: today,
                activeLayers: activeLayers,
                monthData: monthData,
              );
            },
          ),
          const SizedBox(height: 14),

          // 4. Quick Action for Selected Day
          _buildSelectedDayFooter(context, ref, selectedDate, monthDataAsync.value),
        ],
      ),
    );
  }

  Widget _buildMonthGrid({
    required BuildContext context,
    required WidgetRef ref,
    required DateTime currentMonth,
    required DateTime selectedDate,
    required DateTime today,
    required Set<CycleLayer> activeLayers,
    required CycleMonthData monthData,
  }) {
    final firstDayOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
    final daysInMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0).day;

    // Weekday of 1st day (1 = Mon, 7 = Sun)
    final startingWeekday = firstDayOfMonth.weekday;
    final totalCells = ((startingWeekday - 1 + daysInMonth) / 7).ceil() * 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: totalCells,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.05,
        crossAxisSpacing: 3,
        mainAxisSpacing: 3,
      ),
      itemBuilder: (context, index) {
        final dayOffset = index - (startingWeekday - 1);
        if (dayOffset < 0 || dayOffset >= daysInMonth) {
          return const SizedBox.shrink(); // Empty day outside month
        }

        final dayNumber = dayOffset + 1;
        final cellDate = DateTime(currentMonth.year, currentMonth.month, dayNumber);
        final dateKey = cellDate.toIso8601String().substring(0, 10);

        final isSelected = selectedDate.year == cellDate.year &&
            selectedDate.month == cellDate.month &&
            selectedDate.day == cellDate.day;
        final isToday = today.year == cellDate.year &&
            today.month == cellDate.month &&
            today.day == cellDate.day;

        // Layer Data
        final ovulation = monthData.ovulationLogs[dateKey];
        final fertility = monthData.fertilityLogs[dateKey];
        final symptoms = monthData.symptomsLogs[dateKey];

        // Period estimation / calculation
        bool isPeriod = false;
        bool isFertilePredict = false;
        if (monthData.activeCycle != null) {
          final cleanStart = DateTime(
            monthData.activeCycle!.periodStart.year,
            monthData.activeCycle!.periodStart.month,
            monthData.activeCycle!.periodStart.day,
          );
          final diff = cellDate.difference(cleanStart).inDays;
          if (diff >= 0) {
            final cycleLength = monthData.activeCycle!.cycleLength;
            final periodLen = monthData.activeCycle!.periodLength;
            final dayOfCycle = (diff % cycleLength) + 1;
            if (dayOfCycle <= periodLen) {
              isPeriod = true;
            }
            final ovDay = cycleLength - 14;
            if (dayOfCycle >= (ovDay - 5) && dayOfCycle <= (ovDay + 1)) {
              isFertilePredict = true;
            }
          }
        }

        return InkWell(
          onTap: () {
            ref.read(cycleSelectedDateProvider.notifier).selectDate(cellDate);
          },
          onDoubleTap: () {
            ref.read(cycleSelectedDateProvider.notifier).selectDate(cellDate);
            CycleDayLoggerSheet.show(context, cellDate);
          },
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primary.withValues(alpha: 0.14)
                  : (isPeriod && activeLayers.contains(CycleLayer.period)
                      ? AppTheme.accentRose.withValues(alpha: 0.08)
                      : Colors.transparent),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primary
                    : (isToday ? AppTheme.onSurface.withValues(alpha: 0.4) : Colors.transparent),
                width: isSelected ? 1.6 : 1.0,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Day number
                Text(
                  '$dayNumber',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: isSelected || isToday ? FontWeight.w800 : FontWeight.w500,
                    color: isPeriod && activeLayers.contains(CycleLayer.period)
                        ? AppTheme.accentRose
                        : AppTheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),

                // Indicators row for active layers
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Period layer indicator
                    if (isPeriod && activeLayers.contains(CycleLayer.period))
                      _buildIndicatorDot(AppTheme.accentRose),

                    // Ovulation & Temp indicator
                    if (activeLayers.contains(CycleLayer.ovulation) &&
                        (ovulation?.basalBodyTemp != null || ovulation?.ovulationTestResult == 'positive'))
                      _buildIndicatorDot(AppTheme.accentAmber),

                    // Fertility / Prenupcial indicator
                    if (activeLayers.contains(CycleLayer.fertility) &&
                        (fertility != null || isFertilePredict))
                      _buildIndicatorDot(AppTheme.accentEmerald),

                    // Symptoms indicator
                    if (activeLayers.contains(CycleLayer.symptoms) &&
                        symptoms != null &&
                        symptoms.symptoms.isNotEmpty)
                      _buildIndicatorDot(AppTheme.accentSky),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIndicatorDot(Color color) {
    return Container(
      width: 4,
      height: 4,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  static String _formatSelectedDate(DateTime date) {
    const days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    const months = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
    final weekdayName = days[date.weekday - 1];
    final monthName = months[date.month - 1];
    return '$weekdayName ${date.day} de $monthName';
  }

  Widget _buildSelectedDayFooter(
    BuildContext context,
    WidgetRef ref,
    DateTime selectedDate,
    CycleMonthData? monthData,
  ) {
    final dateKey = selectedDate.toIso8601String().substring(0, 10);
    final capitalizedDate = _formatSelectedDate(selectedDate);

    final ovulation = monthData?.ovulationLogs[dateKey];
    final symptoms = monthData?.symptomsLogs[dateKey];
    final fertility = monthData?.fertilityLogs[dateKey];

    final hasData = ovulation != null || symptoms != null || fertility != null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                capitalizedDate,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                ),
              ),
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.accentRose.withValues(alpha: 0.15),
                  foregroundColor: AppTheme.accentRose,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.edit_calendar_rounded, size: 16),
                label: Text(
                  hasData ? 'Editar Registro' : 'Registrar Día',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                onPressed: () => CycleDayLoggerSheet.show(context, selectedDate),
              ),
            ],
          ),
          if (hasData) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (ovulation?.basalBodyTemp != null)
                  _buildTag('${ovulation!.basalBodyTemp!.toStringAsFixed(1)}°C Temp', AppTheme.accentAmber),
                if (ovulation?.cervicalMucus != null)
                  _buildTag('Moco: ${ovulation!.cervicalMucus}', AppTheme.accentAmber),
                if (fertility?.fertileWindowStatus != null)
                  _buildTag('Ventana: ${fertility!.fertileWindowStatus}', AppTheme.accentEmerald),
                if (symptoms != null && symptoms.flowLevel != 'none')
                  _buildTag('Flujo: ${symptoms.flowLevel}', AppTheme.accentRose),
                if (symptoms != null && symptoms.crampsLevel > 0)
                  _buildTag('Cólicos: ${symptoms.crampsLevel}/5', AppTheme.accentRose),
                if (symptoms != null && symptoms.symptoms.isNotEmpty)
                  _buildTag('${symptoms.symptoms.length} síntomas', AppTheme.accentSky),
              ],
            ),
          ] else ...[
            const SizedBox(height: 4),
            Text(
              'No hay registros específicos de temperatura, síntomas o fertilidad para este día.',
              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
