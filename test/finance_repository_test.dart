import 'package:flutter_test/flutter_test.dart';
import 'package:focus_habitual_life/core/local_db/database.dart';
import 'package:focus_habitual_life/features/finance/data/finance_repository.dart';
import 'package:focus_habitual_life/features/finance/domain/finance_account.dart';
import 'package:focus_habitual_life/features/finance/domain/finance_budget.dart';
import 'package:focus_habitual_life/features/finance/domain/finance_transaction.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FinanceRepository repository;

  setUp(() async {
    await AppDatabase.init();
    repository = FinanceRepository();

    // Clean tables for reproducible unit testing
    final db = AppDatabase.instance;
    db.execute('DELETE FROM finance_transactions');
    db.execute('DELETE FROM finance_accounts');
    db.execute('DELETE FROM finance_budgets');
    db.execute('DELETE FROM sync_queue');
    db.execute("UPDATE user_xp SET total_xp = 0, level = 1 WHERE user_id = 'local_user'");
  });

  group('FinanceRepository & Domain Tests', () {
    test('createAccount saves account and enqueues sync', () async {
      final account = await repository.createAccount(
        name: 'BBVA Nómina',
        type: AccountType.bank,
        currency: 'MXN',
        initialBalance: 5000.0,
      );

      expect(account.id, isNotEmpty);
      expect(account.name, equals('BBVA Nómina'));
      expect(account.type, equals(AccountType.bank));
      expect(account.initialBalance, equals(5000.0));
      expect(account.currentBalance, equals(5000.0));

      final accounts = await repository.getAccounts();
      expect(accounts.length, equals(1));
      expect(accounts.first.name, equals('BBVA Nómina'));

      final pendingSync = AppDatabase.getPendingSync();
      expect(pendingSync.any((s) => s['table_name'] == 'finance_accounts'), isTrue);
    });

    test('recordTransaction updates account balance, enqueues sync and awards XP', () async {
      final account = await repository.createAccount(
        name: 'Efectivo',
        type: AccountType.cash,
        initialBalance: 1000.0,
      );

      // Record an Income
      final incomeTx = await repository.recordTransaction(
        accountId: account.id,
        amount: 2500.0,
        type: TransactionType.income,
        category: FinanceCategory.incomeSalary,
        note: 'Pago quincenal',
      );

      expect(incomeTx.amount, equals(2500.0));

      // Record an Expense (Needs 50%)
      final expenseTx = await repository.recordTransaction(
        accountId: account.id,
        amount: 800.0,
        type: TransactionType.expense,
        category: FinanceCategory.needsGroceries,
        note: 'Supermercado',
      );

      expect(expenseTx.amount, equals(800.0));

      // Verify balance = 1000 + 2500 - 800 = 2700
      final accounts = await repository.getAccounts();
      final updatedAccount = accounts.firstWhere((a) => a.id == account.id);
      expect(updatedAccount.currentBalance, equals(2700.0));

      // Verify XP awarded: 2 transactions * 10 XP = 20 XP
      final xpRows = AppDatabase.instance.select("SELECT total_xp FROM user_xp WHERE user_id = 'local_user'");
      expect(xpRows.first['total_xp'], equals(20));

      // Verify sync queue entries
      final pendingSync = AppDatabase.getPendingSync();
      final txSyncItems = pendingSync.where((s) => s['table_name'] == 'finance_transactions').toList();
      expect(txSyncItems.length, equals(2));
    });

    test('transfer between accounts properly adjusts sender and receiver balances', () async {
      final bank = await repository.createAccount(
        name: 'Banco BBVA',
        type: AccountType.bank,
        initialBalance: 10000.0,
      );

      final savings = await repository.createAccount(
        name: 'Fondo Emergencia',
        type: AccountType.savings,
        initialBalance: 2000.0,
      );

      // Transfer 3000 from bank to savings
      await repository.recordTransaction(
        accountId: bank.id,
        toAccountId: savings.id,
        amount: 3000.0,
        type: TransactionType.transfer,
        category: FinanceCategory.transfer,
        note: 'Ahorro mensual',
      );

      final accounts = await repository.getAccounts();
      final updatedBank = accounts.firstWhere((a) => a.id == bank.id);
      final updatedSavings = accounts.firstWhere((a) => a.id == savings.id);

      expect(updatedBank.currentBalance, equals(7000.0));
      expect(updatedSavings.currentBalance, equals(5000.0));
    });

    test('getRuleSummaryForMonth accurately classifies 50/30/20 expenses and cash flow', () async {
      final now = DateTime.now();
      final account = await repository.createAccount(
        name: 'Cuenta Nómina',
        type: AccountType.bank,
        initialBalance: 0.0,
      );

      // Income: 20,000
      await repository.recordTransaction(
        accountId: account.id,
        amount: 20000.0,
        type: TransactionType.income,
        category: FinanceCategory.incomeSalary,
      );

      // Needs (50%): 6,000 (Renta) + 2,000 (Comida) = 8,000
      await repository.recordTransaction(
        accountId: account.id,
        amount: 6000.0,
        type: TransactionType.expense,
        category: FinanceCategory.needsHousing,
      );
      await repository.recordTransaction(
        accountId: account.id,
        amount: 2000.0,
        type: TransactionType.expense,
        category: FinanceCategory.needsGroceries,
      );

      // Wants (30%): 3,000 (Restaurantes) + 1,000 (Ocio) = 4,000
      await repository.recordTransaction(
        accountId: account.id,
        amount: 3000.0,
        type: TransactionType.expense,
        category: FinanceCategory.wantsDining,
      );
      await repository.recordTransaction(
        accountId: account.id,
        amount: 1000.0,
        type: TransactionType.expense,
        category: FinanceCategory.wantsEntertainment,
      );

      // Savings (20%): 4,000 (Cetes)
      await repository.recordTransaction(
        accountId: account.id,
        amount: 4000.0,
        type: TransactionType.expense,
        category: FinanceCategory.investmentAssets,
      );

      final summary = await repository.getRuleSummaryForMonth(now);

      expect(summary.totalIncome, equals(20000.0));
      expect(summary.totalExpenses, equals(16000.0));
      expect(summary.cashFlow, equals(4000.0));

      expect(summary.needs.spent, equals(8000.0));
      expect(summary.needs.limit, equals(10000.0)); // 50% of 20,000
      expect(summary.needs.isOverBudget, isFalse);

      expect(summary.wants.spent, equals(4000.0));
      expect(summary.wants.limit, equals(6000.0)); // 30% of 20,000
      expect(summary.wants.isOverBudget, isFalse);

      expect(summary.savings.spent, equals(4000.0));
      expect(summary.savings.limit, equals(4000.0)); // 20% of 20,000
      expect(summary.savingsRate, equals(20.0)); // 4000 / 20000 * 100
    });

    test('getFinanceOverview calculates Net Worth considering Assets and Liabilities', () async {
      final now = DateTime.now();

      // Asset 1: Bank (50,000)
      await repository.createAccount(
        name: 'Banco Inbursa',
        type: AccountType.bank,
        initialBalance: 50000.0,
      );

      // Asset 2: Investments (30,000)
      await repository.createAccount(
        name: 'Cetes Directo',
        type: AccountType.investment,
        initialBalance: 30000.0,
      );

      // Liability: Credit Card (15,000 debt)
      final card = await repository.createAccount(
        name: 'Tarjeta Oro',
        type: AccountType.creditCard,
        initialBalance: 5000.0, // initial debt
      );

      // Add expense on credit card of 10,000 -> debt becomes 15,000
      await repository.recordTransaction(
        accountId: card.id,
        amount: 10000.0,
        type: TransactionType.expense,
        category: FinanceCategory.wantsShopping,
      );

      final overview = await repository.getFinanceOverview(now);

      // Total Assets: 50,000 + 30,000 = 80,000
      expect(overview.totalAssets, equals(80000.0));

      // Total Liabilities: 5,000 + 10,000 = 15,000
      expect(overview.totalLiabilities, equals(15000.0));

      // Net Worth: 80,000 - 15,000 = 65,000
      expect(overview.netWorth, equals(65000.0));
    });

    test('setBudgetCap overrides default ratio limits in getRuleSummaryForMonth', () async {
      final now = DateTime.now();
      final monthStr = FinanceRepository.formatMonthYear(now);

      await repository.setBudgetCap(
        monthYear: monthStr,
        group: BudgetGroup.needs50,
        limit: 12500.0,
      );

      final summary = await repository.getRuleSummaryForMonth(now);
      expect(summary.needs.limit, equals(12500.0));
    });

    test('FinanceBudget serialization toMap and fromMap works correctly', () {
      final now = DateTime.now();
      final budget = FinanceBudget(
        id: 'budget-1',
        userId: 'local_user',
        monthYear: '2026-09',
        group: BudgetGroup.wants30,
        monthlyLimit: 7500.0,
        createdAt: now,
        clientId: 'budget-1',
        clientUpdatedAt: now,
      );

      final map = budget.toMap();
      expect(map['id'], equals('budget-1'));
      expect(map['category'], equals('wants30'));
      expect(map['monthly_limit'], equals(7500.0));

      final restored = FinanceBudget.fromMap(map);
      expect(restored.id, equals(budget.id));
      expect(restored.group, equals(BudgetGroup.wants30));
      expect(restored.monthlyLimit, equals(7500.0));
    });
  });
}
