import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme.dart';
import '../../domain/finance_budget.dart';

/// Executive visual chart for income vs expenses and 50/30/20 budget performance.
class FinanceChartWidget extends StatelessWidget {
  final FinanceOverview overview;
  final bool isDark;
  final Color cardBg;
  final Color borderColor;

  const FinanceChartWidget({
    super.key,
    required this.overview,
    required this.isDark,
    required this.cardBg,
    required this.borderColor,
  });

  String _formatCurrency(double amount) {
    final f = NumberFormat('#,##0.00', 'en_US');
    return f.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final income = overview.monthIncome;
    final expense = overview.monthExpenses;
    final netSavings = overview.monthNetSavings;
    final double maxVal = math.max(income, math.max(expense, math.max(netSavings.abs(), 100.0)));

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
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.bar_chart_rounded, size: 16, color: AppTheme.primary),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'BALANCE & FLUJO MENSUAL',
                    style: AppTheme.labelCaps(
                      fontSize: 11,
                      color: isDark ? Colors.white60 : AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: netSavings >= 0
                      ? const Color(0xFF10B981).withValues(alpha: 0.12)
                      : const Color(0xFFEF4444).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  netSavings >= 0 ? 'SUPERÁVIT' : 'DÉFICIT',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: netSavings >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Bar Chart
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal * 1.25,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => isDark ? const Color(0xFF1E2533) : const Color(0xFF1E293B),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final title = groupIndex == 0
                          ? 'Ingresos'
                          : (groupIndex == 1 ? 'Gastos' : 'Ahorro Neto');
                      return BarTooltipItem(
                        '$title\n\$${_formatCurrency(rod.toY)}',
                        GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        final style = GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white70 : AppTheme.onSurfaceVariant,
                        );
                        switch (val.toInt()) {
                          case 0:
                            return Padding(padding: const EdgeInsets.only(top: 8), child: Text('Ingresos', style: style));
                          case 1:
                            return Padding(padding: const EdgeInsets.only(top: 8), child: Text('Gastos', style: style));
                          case 2:
                            return Padding(padding: const EdgeInsets.only(top: 8), child: Text('Ahorro', style: style));
                          default:
                            return const SizedBox.shrink();
                        }
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  // 0: Income
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: income,
                        gradient: const LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Color(0xFF059669), Color(0xFF10B981)],
                        ),
                        width: 28,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      ),
                    ],
                  ),
                  // 1: Expenses
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: expense,
                        gradient: const LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
                        ),
                        width: 28,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      ),
                    ],
                  ),
                  // 2: Net Savings / Balance
                  BarChartGroupData(
                    x: 2,
                    barRods: [
                      BarChartRodData(
                        toY: netSavings > 0 ? netSavings : 0.0,
                        gradient: const LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                        ),
                        width: 28,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Metrics Pills Footer
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'Ingresos',
                  amount: income,
                  color: const Color(0xFF10B981),
                  icon: Icons.arrow_downward_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  label: 'Gastos',
                  amount: expense,
                  color: const Color(0xFFEF4444),
                  icon: Icons.arrow_upward_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  label: 'Ahorro',
                  amount: netSavings,
                  color: const Color(0xFF3B82F6),
                  icon: Icons.savings_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 3),
              Text(
                label,
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: color),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '\$${_formatCurrency(amount)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.numeric(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppTheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
