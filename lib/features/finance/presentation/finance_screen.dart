import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../domain/finance_account.dart';
import '../domain/finance_budget.dart';
import '../domain/finance_transaction.dart';
import 'controllers/finance_controller.dart';
import 'widgets/add_account_sheet.dart';
import 'widgets/add_transaction_sheet.dart';
import 'widgets/edit_budget_sheet.dart';
import 'widgets/finance_calendar_widget.dart';
import 'widgets/finance_chart_widget.dart';
import 'widgets/quick_receive_sheet.dart';

/// Executive Finance & Budget Screen for FocusHabitual Life.
/// Adheres strictly to the Executive Precision aesthetic.
class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> {
  DateTime? _selectedCalendarDay;

  static const List<String> _spanishMonths = [
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

  String _formatMonthYearHeader(DateTime date) {
    final monthName = _spanishMonths[date.month - 1];
    return '$monthName ${date.year}';
  }

  String _formatCurrency(double amount) {
    final f = NumberFormat('#,##0.00', 'en_US');
    return f.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final selectedMonth = ref.watch(selectedFinanceMonthProvider);
    final AsyncValue<List<FinanceAccount>> accountsAsync = ref.watch(financeAccountsProvider);
    final AsyncValue<FinanceOverview> overviewAsync = ref.watch(financeOverviewProvider);
    final AsyncValue<List<FinanceTransaction>> transactionsAsync = ref.watch(financeMonthTransactionsProvider);
    final filter = ref.watch(financeTransactionFilterProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkBackground : AppTheme.background;
    final cardBg = isDark ? AppTheme.darkSurface : Colors.white;
    final borderColor = isDark ? const Color(0xFF262D3D) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FINANZAS & PRESUPUESTO',
              style: AppTheme.labelCaps(
                fontSize: 11,
                color: isDark ? Colors.white60 : AppTheme.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Patrimonio & Regla 50/30/20',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppTheme.onSurface,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'Añadir Cuenta',
            onPressed: () => AddAccountSheet.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Configurar Presupuesto',
            onPressed: () {
              overviewAsync.whenData((overview) {
                EditBudgetSheet.show(context, overview.ruleSummary);
              });
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AddTransactionSheet.show(context),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: Text(
          'Movimiento (+10 XP)',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(financeAccountsProvider);
          ref.invalidate(financeOverviewProvider);
          ref.invalidate(financeMonthTransactionsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 84),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Month Selector Bar
              _buildMonthSelector(context, ref, selectedMonth, isDark, cardBg, borderColor),
              const SizedBox(height: 16),

              // Net Worth & Monthly Cash Flow Hero Card
              overviewAsync.when(
                data: (overview) => _buildHeroNetWorthCard(context, overview, isDark, cardBg, borderColor),
                loading: () => _buildCardSkeleton(cardBg, borderColor, 160),
                error: (err, _) => _buildErrorCard(err.toString(), isDark, cardBg, borderColor),
              ),
              const SizedBox(height: 16),

              // Executive Chart: Income vs Expenses vs Net Savings
              overviewAsync.when(
                data: (overview) => FinanceChartWidget(
                  overview: overview,
                  isDark: isDark,
                  cardBg: cardBg,
                  borderColor: borderColor,
                ),
                loading: () => _buildCardSkeleton(cardBg, borderColor, 220),
                error: (_, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),

              // 50/30/20 Rule Budget Section
              overviewAsync.when(
                data: (overview) => _buildRule503020Card(context, ref, overview.ruleSummary, isDark, cardBg, borderColor),
                loading: () => _buildCardSkeleton(cardBg, borderColor, 220),
                error: (_, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 20),

              // Interactive Financial Calendar
              transactionsAsync.when(
                data: (txs) => FinanceCalendarWidget(
                  selectedMonth: selectedMonth,
                  transactions: txs,
                  selectedDay: _selectedCalendarDay,
                  onDaySelected: (day) {
                    setState(() {
                      if (_selectedCalendarDay != null &&
                          day != null &&
                          _selectedCalendarDay!.year == day.year &&
                          _selectedCalendarDay!.month == day.month &&
                          _selectedCalendarDay!.day == day.day) {
                        _selectedCalendarDay = null;
                      } else {
                        _selectedCalendarDay = day;
                      }
                    });
                  },
                  isDark: isDark,
                  cardBg: cardBg,
                  borderColor: borderColor,
                ),
                loading: () => _buildCardSkeleton(cardBg, borderColor, 240),
                error: (_, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 20),

              // Financial Accounts Carousel
              accountsAsync.when(
                data: (accounts) => _buildAccountsSection(context, accounts, isDark, cardBg, borderColor),
                loading: () => _buildCardSkeleton(cardBg, borderColor, 110),
                error: (_, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 20),

              // Transactions History Section
              _buildTransactionsSection(context, ref, transactionsAsync, filter, isDark, cardBg, borderColor),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MONTH SELECTOR
  // ---------------------------------------------------------------------------

  Widget _buildMonthSelector(
    BuildContext context,
    WidgetRef ref,
    DateTime selectedMonth,
    bool isDark,
    Color cardBg,
    Color borderColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () => ref.read(financeControllerProvider.notifier).previousMonth(),
            splashRadius: 20,
            color: isDark ? Colors.white70 : AppTheme.onSurface,
          ),
          Text(
            _formatMonthYearHeader(selectedMonth),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppTheme.onSurface,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: () => ref.read(financeControllerProvider.notifier).nextMonth(),
            splashRadius: 20,
            color: isDark ? Colors.white70 : AppTheme.onSurface,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // NET WORTH & CASH FLOW HERO
  // ---------------------------------------------------------------------------

  Widget _buildHeroNetWorthCard(
    BuildContext context,
    FinanceOverview overview,
    bool isDark,
    Color cardBg,
    Color borderColor,
  ) {
    final netWorthColor = overview.netWorth >= 0
        ? (isDark ? Colors.white : AppTheme.onSurface)
        : const Color(0xFFEF4444);

    final cashFlowPositive = overview.monthCashFlow >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 16,
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
                'PATRIMONIO NETO',
                style: AppTheme.labelCaps(
                  fontSize: 11,
                  color: isDark ? Colors.white60 : AppTheme.onSurfaceVariant,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (cashFlowPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      cashFlowPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                      size: 12,
                      color: cashFlowPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${cashFlowPositive ? '+' : ''}\$${_formatCurrency(overview.monthCashFlow)} este mes',
                      style: AppTheme.numeric(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: cashFlowPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Total Net Worth Readout
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '\$${_formatCurrency(overview.netWorth)}',
                style: AppTheme.numeric(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: netWorthColor,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'MXN',
                style: AppTheme.numeric(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white54 : AppTheme.outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: borderColor, height: 1),
          const SizedBox(height: 14),

          // Assets, Liabilities, and Income/Expense Mini Grid
          Row(
            children: [
              Expanded(
                child: _buildMiniMetric(
                  label: 'ACTIVOS',
                  value: '\$${_formatCurrency(overview.totalAssets)}',
                  color: const Color(0xFF10B981),
                  isDark: isDark,
                ),
              ),
              Container(width: 1, height: 28, color: borderColor),
              Expanded(
                child: _buildMiniMetric(
                  label: 'PASIVOS / DEUDA',
                  value: '\$${_formatCurrency(overview.totalLiabilities)}',
                  color: const Color(0xFFEF4444),
                  isDark: isDark,
                ),
              ),
              Container(width: 1, height: 28, color: borderColor),
              Expanded(
                child: _buildMiniMetric(
                  label: 'TASA DE AHORRO',
                  value: '${overview.ruleSummary.savingsRate.toStringAsFixed(1)}%',
                  color: const Color(0xFF8B5CF6),
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric({
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: AppTheme.labelCaps(
            fontSize: 9,
            color: isDark ? Colors.white54 : AppTheme.outline,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: AppTheme.numeric(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 50/30/20 BUDGET CARD
  // ---------------------------------------------------------------------------

  Widget _buildRule503020Card(
    BuildContext context,
    WidgetRef ref,
    Rule503020Summary summary,
    bool isDark,
    Color cardBg,
    Color borderColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.pie_chart_outline_rounded, size: 16, color: AppTheme.primary),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'REGLA 50 / 30 / 20',
                    style: AppTheme.labelCaps(
                      fontSize: 11,
                      color: isDark ? Colors.white70 : AppTheme.primary,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => EditBudgetSheet.show(context, summary),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 13, color: isDark ? Colors.white60 : AppTheme.outline),
                      const SizedBox(width: 4),
                      Text(
                        'Ajustar',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 50% Needs Progress
          _buildPillarMeter(
            title: '50% Necesidades Básicas',
            subtitle: 'Vivienda, despensa, salud, transporte',
            progress: summary.needs,
            color: const Color(0xFF0284C7),
            isDark: isDark,
          ),
          const SizedBox(height: 14),

          // 30% Wants Progress
          _buildPillarMeter(
            title: '30% Deseos & Calidad de Vida',
            subtitle: 'Ocio, restaurantes, viajes, caprichos',
            progress: summary.wants,
            color: const Color(0xFFF59E0B),
            isDark: isDark,
          ),
          const SizedBox(height: 14),

          // 20% Savings Progress
          _buildPillarMeter(
            title: '20% Inversión & Ahorro',
            subtitle: 'Cetes, acciones, libros, fondo de paz',
            progress: summary.savings,
            color: const Color(0xFF8B5CF6),
            isDark: isDark,
            isSavingsPillar: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPillarMeter({
    required String title,
    required String subtitle,
    required PillarProgress progress,
    required Color color,
    required bool isDark,
    bool isSavingsPillar = false,
  }) {
    final pct = (progress.progress * 100).clamp(0, 999).toStringAsFixed(0);
    final isOver = progress.isOverBudget && !isSavingsPillar;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppTheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: isDark ? Colors.white38 : AppTheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${_formatCurrency(progress.spent)} / \$${_formatCurrency(progress.limit)}',
                  style: AppTheme.numeric(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isOver ? const Color(0xFFEF4444) : (isDark ? Colors.white70 : AppTheme.onSurface),
                  ),
                ),
                Text(
                  isOver ? 'Excedido por \$${_formatCurrency(progress.spent - progress.limit)}' : '$pct% del tope',
                  style: AppTheme.numeric(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isOver ? const Color(0xFFEF4444) : color,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress.limit > 0 ? (progress.spent / progress.limit).clamp(0.0, 1.0) : 0.0,
            backgroundColor: isDark ? const Color(0xFF1E2533) : const Color(0xFFF1F5F9),
            valueColor: AlwaysStoppedAnimation<Color>(isOver ? const Color(0xFFEF4444) : color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // ACCOUNTS SECTION
  // ---------------------------------------------------------------------------

  Widget _buildAccountsSection(
    BuildContext context,
    List<FinanceAccount> accounts,
    bool isDark,
    Color cardBg,
    Color borderColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'MIS CUENTAS (${accounts.length})',
              style: AppTheme.labelCaps(
                fontSize: 11,
                color: isDark ? Colors.white60 : AppTheme.onSurfaceVariant,
              ),
            ),
            InkWell(
              onTap: () => AddAccountSheet.show(context),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Text(
                  '+ Añadir',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (accounts.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Center(
              child: Text(
                'No hay cuentas registradas. Toca "+ Añadir" para crear la primera.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : AppTheme.outline,
                ),
              ),
            ),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: accounts.map((acc) {
                return Container(
                  width: 185,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: acc.type.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(acc.type.icon, size: 16, color: acc.type.color),
                          ),
                          Text(
                            acc.currency,
                            style: AppTheme.numeric(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white38 : AppTheme.outline,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        acc.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppTheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${_formatCurrency(acc.currentBalance)}',
                        style: AppTheme.numeric(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: acc.isLiability ? const Color(0xFFEF4444) : acc.type.color,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 28,
                        child: OutlinedButton.icon(
                          onPressed: () => QuickReceiveSheet.show(context, acc),
                          icon: const Icon(Icons.add_rounded, size: 14),
                          label: Text(
                            '+ Recibir',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF10B981),
                            side: BorderSide(
                              color: const Color(0xFF10B981).withValues(alpha: 0.35),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TRANSACTIONS SECTION
  // ---------------------------------------------------------------------------

  Widget _buildTransactionsSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<FinanceTransaction>> transactionsAsync,
    TransactionType? filter,
    bool isDark,
    Color cardBg,
    Color borderColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'MOVIMIENTOS DEL MES',
              style: AppTheme.labelCaps(
                fontSize: 11,
                color: isDark ? Colors.white60 : AppTheme.onSurfaceVariant,
              ),
            ),
            // Filter Pills
            Row(
              children: [
                _buildFilterChip(
                  label: 'Todos',
                  isSelected: filter == null,
                  onTap: () => ref.read(financeTransactionFilterProvider.notifier).setFilter(null),
                  isDark: isDark,
                  borderColor: borderColor,
                ),
                const SizedBox(width: 4),
                _buildFilterChip(
                  label: 'Gastos',
                  isSelected: filter == TransactionType.expense,
                  onTap: () => ref.read(financeTransactionFilterProvider.notifier).setFilter(TransactionType.expense),
                  isDark: isDark,
                  borderColor: borderColor,
                ),
                const SizedBox(width: 4),
                _buildFilterChip(
                  label: 'Ingresos',
                  isSelected: filter == TransactionType.income,
                  onTap: () => ref.read(financeTransactionFilterProvider.notifier).setFilter(TransactionType.income),
                  isDark: isDark,
                  borderColor: borderColor,
                ),
              ],
            ),
          ],
        ),
        if (_selectedCalendarDay != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.event_available_rounded, size: 14, color: AppTheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Filtrado por día: ${_selectedCalendarDay!.day} de ${_spanishMonths[_selectedCalendarDay!.month - 1]}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppTheme.primary,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => setState(() => _selectedCalendarDay = null),
                  child: Row(
                    children: [
                      Text(
                        'Ver todo',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.close_rounded, size: 15, color: AppTheme.primary),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        transactionsAsync.when(
          data: (transactions) {
            var filtered = filter == null
                ? transactions
                : transactions.where((t) => t.type == filter).toList();

            if (_selectedCalendarDay != null) {
              final selDay = _selectedCalendarDay!;
              filtered = filtered.where((t) =>
                  t.date.year == selDay.year &&
                  t.date.month == selDay.month &&
                  t.date.day == selDay.day).toList();
            }

            if (filtered.isEmpty) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 38,
                        color: isDark ? Colors.white24 : Colors.black26,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Sin movimientos en este período',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white54 : AppTheme.outline,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Toca "Movimiento (+10 XP)" para registrar tu primer gasto o ingreso.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: isDark ? Colors.white38 : AppTheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final tx = filtered[index];
                final isIncome = tx.type == TransactionType.income;
                final isExpense = tx.type == TransactionType.expense;
                final group = tx.category.budgetGroup;

                return Dismissible(
                  key: ValueKey(tx.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.centerRight,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    ref.read(financeControllerProvider.notifier).deleteTransaction(tx.id);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: group.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(tx.category.icon, size: 20, color: group.color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tx.category.label,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : AppTheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${DateFormat('dd MMM').format(tx.occurredAt)}${tx.note != null ? ' • ${tx.note}' : ''}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: isDark ? Colors.white38 : AppTheme.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${isIncome ? '+' : isExpense ? '-' : ''}\$${_formatCurrency(tx.amount)}',
                          style: AppTheme.numeric(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isIncome
                                ? const Color(0xFF10B981)
                                : isExpense
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFF3B82F6),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => _buildCardSkeleton(cardBg, borderColor, 120),
          error: (err, _) => _buildErrorCard(err.toString(), isDark, cardBg, borderColor),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    required Color borderColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary
              : (isDark ? const Color(0xFF1E2533) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primary : borderColor,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppTheme.onSurfaceVariant),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SKELETON & ERROR HELPERS
  // ---------------------------------------------------------------------------

  Widget _buildCardSkeleton(Color cardBg, Color borderColor, double height) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildErrorCard(String error, bool isDark, Color cardBg, Color borderColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
      ),
      child: Text(
        'Error cargando finanzas: $error',
        style: GoogleFonts.plusJakartaSans(color: AppTheme.error, fontSize: 12),
      ),
    );
  }
}
