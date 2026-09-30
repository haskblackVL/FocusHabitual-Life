import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/gamification/xp_engine.dart';
import '../../../core/local_db/database.dart';
import '../domain/finance_account.dart';
import '../domain/finance_budget.dart';
import '../domain/finance_transaction.dart';

/// Repository responsible for financial accounts, transactions, 50/30/20 budgets, and metrics.
class FinanceRepository {
  FinanceRepository({this.currentUserId});

  final String? currentUserId;
  static const _uuid = Uuid();

  String get _activeUserId => currentUserId ?? 'local_user';

  static String formatMonthYear(DateTime date) {
    return DateFormat('yyyy-MM').format(date);
  }

  // ---------------------------------------------------------------------------
  // ACCOUNTS
  // ---------------------------------------------------------------------------

  /// Retrieves all accounts with their real-time calculated balances.
  Future<List<FinanceAccount>> getAccounts() async {
    final db = AppDatabase.instance;
    var rows = db.select('''
      SELECT * FROM finance_accounts
      WHERE user_id = ?
      ORDER BY created_at ASC
    ''', [_activeUserId]);

    if (rows.isEmpty) {
      _seedDefaultAccounts(db);
      rows = db.select('''
        SELECT * FROM finance_accounts
        WHERE user_id = ?
        ORDER BY created_at ASC
      ''', [_activeUserId]);
    }

    final accounts = <FinanceAccount>[];
    for (final row in rows) {
      final acc = FinanceAccount.fromMap(row);
      final balance = _calculateAccountBalance(db, acc);
      accounts.add(acc.copyWith(currentBalance: balance));
    }

    return accounts;
  }

  void _seedDefaultAccounts(dynamic db) {
    final now = DateTime.now().toIso8601String();
    final defaultAccounts = [
      {'name': 'Cuenta Principal', 'type': 'bank', 'balance': 0.0},
      {'name': 'Efectivo / Cartera', 'type': 'cash', 'balance': 0.0},
      {'name': 'Fondo de Ahorro / Inversión', 'type': 'investment', 'balance': 0.0},
    ];

    for (final acc in defaultAccounts) {
      final id = _uuid.v4();
      db.execute('''
        INSERT INTO finance_accounts (id, user_id, name, type, currency, initial_balance, created_at, client_id, client_updated_at)
        VALUES (?, ?, ?, ?, 'MXN', ?, ?, ?, ?)
      ''', [
        id,
        _activeUserId,
        acc['name'],
        acc['type'],
        acc['balance'],
        now,
        id,
        now,
      ]);

      AppDatabase.enqueueSync(
        tableName: 'finance_accounts',
        recordId: id,
        action: 'INSERT',
        payload: {
          'id': id,
          'user_id': _activeUserId,
          'name': acc['name'],
          'type': acc['type'],
          'currency': 'MXN',
          'initial_balance': acc['balance'],
          'created_at': now,
          'client_id': id,
          'client_updated_at': now,
        },
      );
    }
  }

  double _calculateAccountBalance(dynamic db, FinanceAccount acc) {
    final incomeRow = db.select('''
      SELECT coalesce(sum(amount), 0.0) as total FROM finance_transactions
      WHERE user_id = ? AND account_id = ? AND type = 'income'
    ''', [_activeUserId, acc.id]);

    final expenseRow = db.select('''
      SELECT coalesce(sum(amount), 0.0) as total FROM finance_transactions
      WHERE user_id = ? AND account_id = ? AND type = 'expense'
    ''', [_activeUserId, acc.id]);

    final sentTransferRow = db.select('''
      SELECT coalesce(sum(amount), 0.0) as total FROM finance_transactions
      WHERE user_id = ? AND account_id = ? AND type = 'transfer'
    ''', [_activeUserId, acc.id]);

    final receivedTransferRow = db.select('''
      SELECT coalesce(sum(amount), 0.0) as total FROM finance_transactions
      WHERE user_id = ? AND to_account_id = ? AND type = 'transfer'
    ''', [_activeUserId, acc.id]);

    final double income = (incomeRow.first['total'] as num).toDouble();
    final double expense = (expenseRow.first['total'] as num).toDouble();
    final double sent = (sentTransferRow.first['total'] as num).toDouble();
    final double received = (receivedTransferRow.first['total'] as num).toDouble();

    if (acc.isLiability) {
      // For credit cards: expense increases debt, income/payment decreases debt
      return acc.initialBalance + expense - income + sent - received;
    } else {
      // For asset accounts: income increases balance, expense decreases balance
      return acc.initialBalance + income - expense - sent + received;
    }
  }

  /// Creates a new financial account and enqueues sync.
  Future<FinanceAccount> createAccount({
    required String name,
    required AccountType type,
    String currency = 'MXN',
    double initialBalance = 0.0,
  }) async {
    final db = AppDatabase.instance;
    final id = _uuid.v4();
    final now = DateTime.now();
    final nowStr = now.toIso8601String();

    final account = FinanceAccount(
      id: id,
      userId: _activeUserId,
      name: name.trim(),
      type: type,
      currency: currency,
      initialBalance: initialBalance,
      currentBalance: initialBalance,
      createdAt: now,
      clientId: id,
      clientUpdatedAt: now,
    );

    db.execute('''
      INSERT INTO finance_accounts (
        id, user_id, name, type, currency, initial_balance, created_at, client_id, client_updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', [
      account.id,
      account.userId,
      account.name,
      account.type.dbValue,
      account.currency,
      account.initialBalance,
      nowStr,
      account.clientId,
      nowStr,
    ]);

    AppDatabase.enqueueSync(
      tableName: 'finance_accounts',
      recordId: account.id,
      action: 'INSERT',
      payload: account.toMap(),
    );

    return account;
  }

  /// Updates an existing account's details.
  Future<void> updateAccount(FinanceAccount account) async {
    final db = AppDatabase.instance;
    final now = DateTime.now();
    final nowStr = now.toIso8601String();

    db.execute('''
      UPDATE finance_accounts
      SET name = ?, type = ?, currency = ?, initial_balance = ?, client_updated_at = ?
      WHERE id = ? AND user_id = ?
    ''', [
      account.name.trim(),
      account.type.dbValue,
      account.currency,
      account.initialBalance,
      nowStr,
      account.id,
      _activeUserId,
    ]);

    AppDatabase.enqueueSync(
      tableName: 'finance_accounts',
      recordId: account.id,
      action: 'UPDATE',
      payload: account.copyWith(clientUpdatedAt: now).toMap(),
    );
  }

  /// Deletes an account and its linked transactions.
  Future<void> deleteAccount(String accountId) async {
    final db = AppDatabase.instance;
    db.execute('''
      DELETE FROM finance_transactions
      WHERE account_id = ? AND user_id = ?
    ''', [accountId, _activeUserId]);

    db.execute('''
      DELETE FROM finance_accounts
      WHERE id = ? AND user_id = ?
    ''', [accountId, _activeUserId]);

    AppDatabase.enqueueSync(
      tableName: 'finance_accounts',
      recordId: accountId,
      action: 'DELETE',
      payload: {'id': accountId, 'user_id': _activeUserId},
    );
  }

  // ---------------------------------------------------------------------------
  // TRANSACTIONS
  // ---------------------------------------------------------------------------

  /// Records a new financial movement (expense, income, or transfer) and awards +10 XP.
  Future<FinanceTransaction> recordTransaction({
    required String accountId,
    required double amount,
    required TransactionType type,
    required FinanceCategory category,
    String? toAccountId,
    DateTime? occurredAt,
    String? note,
  }) async {
    final db = AppDatabase.instance;
    final id = _uuid.v4();
    final now = DateTime.now();
    final date = occurredAt ?? now;
    final nowStr = now.toIso8601String();
    final dateStr = date.toIso8601String();

    final tx = FinanceTransaction(
      id: id,
      userId: _activeUserId,
      accountId: accountId,
      amount: amount,
      type: type,
      category: category,
      toAccountId: toAccountId,
      occurredAt: date,
      note: note?.trim(),
      createdAt: now,
      clientId: id,
      clientUpdatedAt: now,
    );

    db.execute('''
      INSERT INTO finance_transactions (
        id, user_id, account_id, amount, type, category, to_account_id, occurred_at, note, created_at, client_id, client_updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', [
      tx.id,
      tx.userId,
      tx.accountId,
      tx.amount,
      tx.type.dbValue,
      tx.category.dbValue,
      tx.toAccountId,
      dateStr,
      tx.note,
      nowStr,
      tx.clientId,
      nowStr,
    ]);

    AppDatabase.enqueueSync(
      tableName: 'finance_transactions',
      recordId: tx.id,
      action: 'INSERT',
      payload: tx.toMap(),
    );

    // Award +10 XP for mindful financial tracking
    await _adjustXp(10);

    return tx;
  }

  /// Deletes a transaction by ID.
  Future<void> deleteTransaction(String transactionId) async {
    final db = AppDatabase.instance;
    db.execute('''
      DELETE FROM finance_transactions
      WHERE id = ? AND user_id = ?
    ''', [transactionId, _activeUserId]);

    AppDatabase.enqueueSync(
      tableName: 'finance_transactions',
      recordId: transactionId,
      action: 'DELETE',
      payload: {'id': transactionId, 'user_id': _activeUserId},
    );
  }

  /// Retrieves all transactions for a specific month (e.g. September 2026).
  Future<List<FinanceTransaction>> getTransactionsForMonth(DateTime month) async {
    final db = AppDatabase.instance;
    final monthPrefix = formatMonthYear(month);

    final rows = db.select('''
      SELECT * FROM finance_transactions
      WHERE user_id = ? AND occurred_at LIKE ?
      ORDER BY occurred_at DESC
    ''', [_activeUserId, '$monthPrefix%']);

    return rows.map((r) => FinanceTransaction.fromMap(r)).toList();
  }

  /// Retrieves the most recent transactions up to [limit].
  Future<List<FinanceTransaction>> getRecentTransactions({int limit = 30}) async {
    final db = AppDatabase.instance;
    final rows = db.select('''
      SELECT * FROM finance_transactions
      WHERE user_id = ?
      ORDER BY occurred_at DESC
      LIMIT ?
    ''', [_activeUserId, limit]);

    return rows.map((r) => FinanceTransaction.fromMap(r)).toList();
  }

  // ---------------------------------------------------------------------------
  // BUDGET & 50/30/20 RULE
  // ---------------------------------------------------------------------------

  /// Sets or updates a budget cap for a specific month and pillar.
  Future<void> setBudgetCap({
    required String monthYear,
    required BudgetGroup group,
    required double limit,
  }) async {
    final db = AppDatabase.instance;
    final now = DateTime.now();
    final nowStr = now.toIso8601String();
    final id = _uuid.v4();

    db.execute('''
      INSERT INTO finance_budgets (
        id, user_id, month_year, category, monthly_limit, created_at, client_id, client_updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(user_id, month_year, category) DO UPDATE SET
        monthly_limit = excluded.monthly_limit,
        client_updated_at = excluded.client_updated_at
    ''', [
      id,
      _activeUserId,
      monthYear,
      group.name,
      limit,
      nowStr,
      id,
      nowStr,
    ]);
  }

  /// Calculates the 50/30/20 rule breakdown and progress for the given month.
  Future<Rule503020Summary> getRuleSummaryForMonth(DateTime month) async {
    final db = AppDatabase.instance;
    final monthStr = formatMonthYear(month);
    final transactions = await getTransactionsForMonth(month);

    double totalIncome = 0.0;
    double totalExpenses = 0.0;
    double spentNeeds = 0.0;
    double spentWants = 0.0;
    double spentSavings = 0.0;

    for (final tx in transactions) {
      if (tx.type == TransactionType.income) {
        totalIncome += tx.amount;
      } else if (tx.type == TransactionType.expense) {
        totalExpenses += tx.amount;
        switch (tx.category.budgetGroup) {
          case BudgetGroup.needs50:
            spentNeeds += tx.amount;
            break;
          case BudgetGroup.wants30:
            spentWants += tx.amount;
            break;
          case BudgetGroup.savings20:
            spentSavings += tx.amount;
            break;
          default:
            spentNeeds += tx.amount;
            break;
        }
      }
    }

    // Retrieve custom budget caps if set
    final budgetRows = db.select('''
      SELECT category, monthly_limit FROM finance_budgets
      WHERE user_id = ? AND month_year = ?
    ''', [_activeUserId, monthStr]);

    final customCaps = <String, double>{};
    for (final row in budgetRows) {
      final cat = row['category'] as String;
      final limit = (row['monthly_limit'] as num).toDouble();
      customCaps[cat] = limit;
    }

    // Recommended 50/30/20 caps based on income (or fallback base target)
    final baseIncome = totalIncome > 0 ? totalIncome : 0.0;
    final defaultNeedsCap = baseIncome * 0.50;
    final defaultWantsCap = baseIncome * 0.30;
    final defaultSavingsCap = baseIncome * 0.20;

    final limitNeeds = customCaps[BudgetGroup.needs50.name] ?? defaultNeedsCap;
    final limitWants = customCaps[BudgetGroup.wants30.name] ?? defaultWantsCap;
    final limitSavings = customCaps[BudgetGroup.savings20.name] ?? defaultSavingsCap;

    return Rule503020Summary(
      monthYear: monthStr,
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      needs: PillarProgress(
        group: BudgetGroup.needs50,
        spent: spentNeeds,
        limit: limitNeeds,
      ),
      wants: PillarProgress(
        group: BudgetGroup.wants30,
        spent: spentWants,
        limit: limitWants,
      ),
      savings: PillarProgress(
        group: BudgetGroup.savings20,
        spent: spentSavings,
        limit: limitSavings,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // EXECUTIVE OVERVIEW
  // ---------------------------------------------------------------------------

  /// Calculates Net Worth, total assets, total liabilities, and monthly cash flow.
  Future<FinanceOverview> getFinanceOverview(DateTime month) async {
    final accounts = await getAccounts();
    final ruleSummary = await getRuleSummaryForMonth(month);

    double totalAssets = 0.0;
    double totalLiabilities = 0.0;

    for (final acc in accounts) {
      if (acc.isLiability) {
        totalLiabilities += acc.currentBalance;
      } else {
        totalAssets += acc.currentBalance;
      }
    }

    final netWorth = totalAssets - totalLiabilities;

    return FinanceOverview(
      netWorth: netWorth,
      totalAssets: totalAssets,
      totalLiabilities: totalLiabilities,
      monthIncome: ruleSummary.totalIncome,
      monthExpenses: ruleSummary.totalExpenses,
      monthCashFlow: ruleSummary.cashFlow,
      ruleSummary: ruleSummary,
    );
  }

  /// Adjusts user XP and recalculates level.
  Future<void> _adjustXp(int amount) async {
    try {
      final db = AppDatabase.instance;
      final now = DateTime.now().toIso8601String();
      final row = db.select('SELECT total_xp FROM user_xp WHERE user_id = ?', [_activeUserId]);
      final currentXp = row.isNotEmpty ? (row.first['total_xp'] as int? ?? 0) : 0;
      final newXp = (currentXp + amount).clamp(0, 9999999);
      final newLevel = XpEngine.calculateLevel(newXp);
      db.execute('''
        INSERT INTO user_xp (user_id, total_xp, level, updated_at)
        VALUES (?, ?, ?, ?)
        ON CONFLICT(user_id) DO UPDATE SET
          total_xp = excluded.total_xp,
          level = excluded.level,
          updated_at = excluded.updated_at
      ''', [_activeUserId, newXp, newLevel, now]);
    } catch (e) {
      if (kDebugMode) {
        print('[FinanceRepository] Error awarding XP: $e');
      }
    }
  }
}
