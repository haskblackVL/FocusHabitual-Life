import 'finance_transaction.dart';

/// Represents a budget cap set by the user for a specific month and pillar.
class FinanceBudget {
  const FinanceBudget({
    required this.id,
    required this.userId,
    required this.monthYear,
    required this.group,
    required this.monthlyLimit,
    required this.createdAt,
    required this.clientId,
    required this.clientUpdatedAt,
  });

  final String id;
  final String userId;
  final String monthYear; // Format: "yyyy-MM"
  final BudgetGroup group;
  final double monthlyLimit;
  final DateTime createdAt;
  final String clientId;
  final DateTime clientUpdatedAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'month_year': monthYear,
      'category': group.name,
      'monthly_limit': monthlyLimit,
      'created_at': createdAt.toIso8601String(),
      'client_id': clientId,
      'client_updated_at': clientUpdatedAt.toIso8601String(),
    };
  }

  factory FinanceBudget.fromMap(Map<String, dynamic> map) {
    BudgetGroup parsedGroup = BudgetGroup.needs50;
    final catStr = (map['category'] as String?) ?? '';
    for (final g in BudgetGroup.values) {
      if (g.name == catStr) {
        parsedGroup = g;
        break;
      }
    }

    return FinanceBudget(
      id: map['id'] as String,
      userId: (map['user_id'] as String?) ?? 'local_user',
      monthYear: (map['month_year'] as String?) ?? '',
      group: parsedGroup,
      monthlyLimit: ((map['monthly_limit'] as num?) ?? 0.0).toDouble(),
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      clientId: (map['client_id'] as String?) ?? (map['id'] as String),
      clientUpdatedAt: DateTime.tryParse(map['client_updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

/// Progress metrics for an individual pillar of the 50/30/20 rule.
class PillarProgress {
  const PillarProgress({
    required this.group,
    required this.spent,
    required this.limit,
  });

  final BudgetGroup group;
  final double spent;
  final double limit;

  double get progress => limit > 0 ? (spent / limit) : 0.0;
  bool get isOverBudget => limit > 0 && spent > limit;
  double get remaining => (limit - spent) > 0 ? (limit - spent) : 0.0;
}

/// Comprehensive summary of the 50/30/20 rule and cashflow for a month.
class Rule503020Summary {
  const Rule503020Summary({
    required this.monthYear,
    required this.totalIncome,
    required this.totalExpenses,
    required this.needs,
    required this.wants,
    required this.savings,
  });

  final String monthYear;
  final double totalIncome;
  final double totalExpenses;
  final PillarProgress needs;
  final PillarProgress wants;
  final PillarProgress savings;

  double get cashFlow => totalIncome - totalExpenses;

  double get savingsRate {
    if (totalIncome <= 0) return 0.0;
    return (savings.spent / totalIncome) * 100;
  }
}

/// Executive overview of user's overall financial health.
class FinanceOverview {
  const FinanceOverview({
    required this.netWorth,
    required this.totalAssets,
    required this.totalLiabilities,
    required this.monthIncome,
    required this.monthExpenses,
    required this.monthCashFlow,
    required this.ruleSummary,
  });

  final double netWorth;
  final double totalAssets;
  final double totalLiabilities;
  final double monthIncome;
  final double monthExpenses;
  final double monthCashFlow;
  final Rule503020Summary ruleSummary;

  double get monthNetSavings => ruleSummary.savings.spent;
}
