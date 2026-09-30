import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/gamification/gamification_controller.dart';
import '../../../../core/local_db/sync_engine.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/finance_repository.dart';
import '../../domain/finance_account.dart';
import '../../domain/finance_budget.dart';
import '../../domain/finance_transaction.dart';

/// Provider for FinanceRepository instance.
final financeRepositoryProvider = Provider<FinanceRepository>((ref) {
  final user = ref.watch(authControllerProvider).value;
  return FinanceRepository(currentUserId: user?.id);
});

/// Notifier for currently selected month.
class SelectedFinanceMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  void selectMonth(DateTime month) => state = DateTime(month.year, month.month);
  void previousMonth() => state = DateTime(state.year, state.month - 1);
  void nextMonth() => state = DateTime(state.year, state.month + 1);
}

/// Currently selected month for viewing financial data.
final selectedFinanceMonthProvider =
    NotifierProvider<SelectedFinanceMonthNotifier, DateTime>(
  SelectedFinanceMonthNotifier.new,
);

/// Notifier for filtering transactions list.
class FinanceTransactionFilterNotifier extends Notifier<TransactionType?> {
  @override
  TransactionType? build() => null;

  void setFilter(TransactionType? filter) => state = filter;
}

/// Filter for transactions list (null = all, or specific type).
final financeTransactionFilterProvider =
    NotifierProvider<FinanceTransactionFilterNotifier, TransactionType?>(
  FinanceTransactionFilterNotifier.new,
);

/// Provider for accounts with live calculated balances.
final financeAccountsProvider = FutureProvider<List<FinanceAccount>>((ref) async {
  final repo = ref.watch(financeRepositoryProvider);
  return repo.getAccounts();
});

/// Provider for transactions in the selected month.
final financeMonthTransactionsProvider = FutureProvider<List<FinanceTransaction>>((ref) async {
  final repo = ref.watch(financeRepositoryProvider);
  final month = ref.watch(selectedFinanceMonthProvider);
  return repo.getTransactionsForMonth(month);
});

/// Provider for the executive overview (Net Worth, 50/30/20 summary, cashflow).
final financeOverviewProvider = FutureProvider<FinanceOverview>((ref) async {
  final repo = ref.watch(financeRepositoryProvider);
  final month = ref.watch(selectedFinanceMonthProvider);
  return repo.getFinanceOverview(month);
});

/// Actions notifier for executing financial mutations and refreshing state.
final financeControllerProvider =
    NotifierProvider<FinanceController, void>(FinanceController.new);

class FinanceController extends Notifier<void> {
  @override
  void build() {}

  void selectMonth(DateTime month) {
    ref.read(selectedFinanceMonthProvider.notifier).selectMonth(month);
  }

  void previousMonth() {
    ref.read(selectedFinanceMonthProvider.notifier).previousMonth();
  }

  void nextMonth() {
    ref.read(selectedFinanceMonthProvider.notifier).nextMonth();
  }

  Future<FinanceTransaction> recordTransaction({
    required String accountId,
    required double amount,
    required TransactionType type,
    required FinanceCategory category,
    String? toAccountId,
    DateTime? occurredAt,
    String? note,
  }) async {
    final repo = ref.read(financeRepositoryProvider);
    final tx = await repo.recordTransaction(
      accountId: accountId,
      amount: amount,
      type: type,
      category: category,
      toAccountId: toAccountId,
      occurredAt: occurredAt,
      note: note,
    );

    _refreshAll();
    ref.read(syncEngineProvider).syncNow();
    return tx;
  }

  Future<void> deleteTransaction(String transactionId) async {
    final repo = ref.read(financeRepositoryProvider);
    await repo.deleteTransaction(transactionId);
    _refreshAll();
    ref.read(syncEngineProvider).syncNow();
  }

  Future<FinanceAccount> createAccount({
    required String name,
    required AccountType type,
    String currency = 'MXN',
    double initialBalance = 0.0,
  }) async {
    final repo = ref.read(financeRepositoryProvider);
    final acc = await repo.createAccount(
      name: name,
      type: type,
      currency: currency,
      initialBalance: initialBalance,
    );

    _refreshAll();
    ref.read(syncEngineProvider).syncNow();
    return acc;
  }

  Future<void> updateAccount(FinanceAccount account) async {
    final repo = ref.read(financeRepositoryProvider);
    await repo.updateAccount(account);
    _refreshAll();
    ref.read(syncEngineProvider).syncNow();
  }

  Future<void> deleteAccount(String accountId) async {
    final repo = ref.read(financeRepositoryProvider);
    await repo.deleteAccount(accountId);
    _refreshAll();
    ref.read(syncEngineProvider).syncNow();
  }

  Future<void> setBudgetCap({
    required String monthYear,
    required BudgetGroup group,
    required double limit,
  }) async {
    final repo = ref.read(financeRepositoryProvider);
    await repo.setBudgetCap(
      monthYear: monthYear,
      group: group,
      limit: limit,
    );
    _refreshAll();
  }

  void _refreshAll() {
    ref.invalidate(financeAccountsProvider);
    ref.invalidate(financeMonthTransactionsProvider);
    ref.invalidate(financeOverviewProvider);
    // Also refresh launcher XP and progress
    ref.invalidate(gamificationProvider);
  }
}
