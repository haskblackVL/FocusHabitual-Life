import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme.dart';
import '../../domain/finance_transaction.dart';

/// Executive interactive financial calendar for the active month.
/// Visualizes income and expense events per calendar day.
class FinanceCalendarWidget extends StatelessWidget {
  final DateTime selectedMonth;
  final List<FinanceTransaction> transactions;
  final DateTime? selectedDay;
  final ValueChanged<DateTime?> onDaySelected;
  final bool isDark;
  final Color cardBg;
  final Color borderColor;

  const FinanceCalendarWidget({
    super.key,
    required this.selectedMonth,
    required this.transactions,
    required this.selectedDay,
    required this.onDaySelected,
    required this.isDark,
    required this.cardBg,
    required this.borderColor,
  });

  static const List<String> _weekDayHeaders = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;
    final firstDayWeekday = DateTime(selectedMonth.year, selectedMonth.month, 1).weekday; // 1 = Mon, 7 = Sun
    final leadingBlanks = firstDayWeekday - 1;

    // Group transactions by day of month
    final Map<int, List<FinanceTransaction>> dailyTxs = {};
    for (final tx in transactions) {
      if (tx.date.year == selectedMonth.year && tx.date.month == selectedMonth.month) {
        final day = tx.date.day;
        dailyTxs.putIfAbsent(day, () => []).add(tx);
      }
    }

    final totalGridCells = leadingBlanks + daysInMonth;
    final rowsCount = (totalGridCells / 7).ceil();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
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
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.calendar_month_rounded, size: 16, color: Color(0xFF6366F1)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'CALENDARIO DE MOVIMIENTOS',
                    style: AppTheme.labelCaps(
                      fontSize: 11,
                      color: isDark ? Colors.white60 : AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              if (selectedDay != null)
                InkWell(
                  onTap: () => onDaySelected(null),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Text(
                      'Ver todo el mes',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Weekday header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _weekDayHeaders.map((header) {
              return SizedBox(
                width: 32,
                child: Center(
                  child: Text(
                    header,
                    style: AppTheme.labelCaps(
                      fontSize: 11,
                      color: isDark ? Colors.white38 : AppTheme.outline,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // Calendar Grid
          for (int r = 0; r < rowsCount; r++) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (int c = 0; c < 7; c++) ...[
                  Builder(
                    builder: (context) {
                      final cellIndex = r * 7 + c;
                      final dayNumber = cellIndex - leadingBlanks + 1;

                      if (cellIndex < leadingBlanks || dayNumber > daysInMonth) {
                        return const SizedBox(width: 34, height: 40);
                      }

                      final txsOnDay = dailyTxs[dayNumber] ?? [];
                      final hasIncome = txsOnDay.any((t) => t.isIncome);
                      final hasExpense = txsOnDay.any((t) => t.isExpense);

                      final isSelected = selectedDay != null &&
                          selectedDay!.year == selectedMonth.year &&
                          selectedDay!.month == selectedMonth.month &&
                          selectedDay!.day == dayNumber;

                      final isToday = DateTime.now().year == selectedMonth.year &&
                          DateTime.now().month == selectedMonth.month &&
                          DateTime.now().day == dayNumber;

                      return GestureDetector(
                        onTap: () {
                          if (isSelected) {
                            onDaySelected(null);
                          } else {
                            onDaySelected(DateTime(selectedMonth.year, selectedMonth.month, dayNumber));
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 34,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primary.withValues(alpha: 0.16)
                                : (isToday ? (isDark ? const Color(0xFF1E2533) : const Color(0xFFF1F5F9)) : Colors.transparent),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primary
                                  : (isToday ? borderColor : Colors.transparent),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$dayNumber',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: isSelected || isToday ? FontWeight.w800 : FontWeight.w600,
                                  color: isSelected
                                      ? AppTheme.primary
                                      : (isDark ? Colors.white : AppTheme.onSurface),
                                ),
                              ),
                              const SizedBox(height: 2),
                              // Dots indicator
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (hasIncome)
                                    Container(
                                      width: 4,
                                      height: 4,
                                      margin: const EdgeInsets.symmetric(horizontal: 1),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF10B981),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  if (hasExpense)
                                    Container(
                                      width: 4,
                                      height: 4,
                                      margin: const EdgeInsets.symmetric(horizontal: 1),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFEF4444),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
            if (r < rowsCount - 1) const SizedBox(height: 4),
          ],

          // Footer info when a day is selected
          if (selectedDay != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.filter_list_rounded, size: 14, color: AppTheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Filtrando por día ${selectedDay!.day}/${selectedDay!.month}:',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${dailyTxs[selectedDay!.day]?.length ?? 0} movimientos',
                    style: AppTheme.numeric(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppTheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
