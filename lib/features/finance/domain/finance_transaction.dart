import 'package:flutter/material.dart';

/// Supported types of financial movements.
enum TransactionType {
  income,
  expense,
  transfer;

  String get dbValue {
    switch (this) {
      case TransactionType.income:
        return 'income';
      case TransactionType.expense:
        return 'expense';
      case TransactionType.transfer:
        return 'transfer';
    }
  }

  static TransactionType fromDbValue(String value) {
    switch (value) {
      case 'income':
        return TransactionType.income;
      case 'expense':
        return TransactionType.expense;
      case 'transfer':
        return TransactionType.transfer;
      default:
        return TransactionType.expense;
    }
  }

  String get label {
    switch (this) {
      case TransactionType.income:
        return 'Ingreso';
      case TransactionType.expense:
        return 'Gasto';
      case TransactionType.transfer:
        return 'Transferencia';
    }
  }

  Color get color {
    switch (this) {
      case TransactionType.income:
        return const Color(0xFF10B981);
      case TransactionType.expense:
        return const Color(0xFFEF4444);
      case TransactionType.transfer:
        return const Color(0xFF3B82F6);
    }
  }
}

/// 50/30/20 Budgeting Rule Pillar classification.
enum BudgetGroup {
  needs50,
  wants30,
  savings20,
  income,
  transfer;

  String get label {
    switch (this) {
      case BudgetGroup.needs50:
        return '50% Necesidades';
      case BudgetGroup.wants30:
        return '30% Deseos';
      case BudgetGroup.savings20:
        return '20% Inversión/Ahorro';
      case BudgetGroup.income:
        return 'Ingreso';
      case BudgetGroup.transfer:
        return 'Transferencia';
    }
  }

  Color get color {
    switch (this) {
      case BudgetGroup.needs50:
        return const Color(0xFF0284C7); // Blue
      case BudgetGroup.wants30:
        return const Color(0xFFF59E0B); // Amber/Orange
      case BudgetGroup.savings20:
        return const Color(0xFF8B5CF6); // Purple/Violet
      case BudgetGroup.income:
        return const Color(0xFF10B981); // Emerald
      case BudgetGroup.transfer:
        return const Color(0xFF64748B); // Slate
    }
  }
}

/// Detailed categories mapped into 50/30/20 pillars.
enum FinanceCategory {
  // 50% Necesidades
  needsHousing,
  needsGroceries,
  needsUtilities,
  needsTransport,
  needsHealth,
  needsGeneral,

  // 30% Deseos
  wantsDining,
  wantsEntertainment,
  wantsShopping,
  wantsTravel,
  wantsGeneral,

  // 20% Ahorro / Inversión & Educación Continua
  savingsEmergency,
  investmentAssets,
  polymathEducation,
  savingsGeneral,

  // Ingresos
  incomeSalary,
  incomeFreelance,
  incomeBusiness,
  incomeDividends,
  incomeGeneral,

  // Transferencia
  transfer;

  String get dbValue {
    switch (this) {
      case FinanceCategory.needsHousing:
        return 'needs_housing';
      case FinanceCategory.needsGroceries:
        return 'needs_groceries';
      case FinanceCategory.needsUtilities:
        return 'needs_utilities';
      case FinanceCategory.needsTransport:
        return 'needs_transport';
      case FinanceCategory.needsHealth:
        return 'needs_health';
      case FinanceCategory.needsGeneral:
        return 'needs_general';
      case FinanceCategory.wantsDining:
        return 'wants_dining';
      case FinanceCategory.wantsEntertainment:
        return 'wants_entertainment';
      case FinanceCategory.wantsShopping:
        return 'wants_shopping';
      case FinanceCategory.wantsTravel:
        return 'wants_travel';
      case FinanceCategory.wantsGeneral:
        return 'wants_general';
      case FinanceCategory.savingsEmergency:
        return 'savings_emergency';
      case FinanceCategory.investmentAssets:
        return 'investment_assets';
      case FinanceCategory.polymathEducation:
        return 'polymath_education';
      case FinanceCategory.savingsGeneral:
        return 'savings_general';
      case FinanceCategory.incomeSalary:
        return 'income_salary';
      case FinanceCategory.incomeFreelance:
        return 'income_freelance';
      case FinanceCategory.incomeBusiness:
        return 'income_business';
      case FinanceCategory.incomeDividends:
        return 'income_dividends';
      case FinanceCategory.incomeGeneral:
        return 'income_general';
      case FinanceCategory.transfer:
        return 'transfer';
    }
  }

  static FinanceCategory fromDbValue(String value) {
    for (final cat in FinanceCategory.values) {
      if (cat.dbValue == value) return cat;
    }
    // Fallback for simple 'general' from schema.sql
    if (value == 'general') return FinanceCategory.needsGeneral;
    return FinanceCategory.needsGeneral;
  }

  BudgetGroup get budgetGroup {
    switch (this) {
      case FinanceCategory.needsHousing:
      case FinanceCategory.needsGroceries:
      case FinanceCategory.needsUtilities:
      case FinanceCategory.needsTransport:
      case FinanceCategory.needsHealth:
      case FinanceCategory.needsGeneral:
        return BudgetGroup.needs50;

      case FinanceCategory.wantsDining:
      case FinanceCategory.wantsEntertainment:
      case FinanceCategory.wantsShopping:
      case FinanceCategory.wantsTravel:
      case FinanceCategory.wantsGeneral:
        return BudgetGroup.wants30;

      case FinanceCategory.savingsEmergency:
      case FinanceCategory.investmentAssets:
      case FinanceCategory.polymathEducation:
      case FinanceCategory.savingsGeneral:
        return BudgetGroup.savings20;

      case FinanceCategory.incomeSalary:
      case FinanceCategory.incomeFreelance:
      case FinanceCategory.incomeBusiness:
      case FinanceCategory.incomeDividends:
      case FinanceCategory.incomeGeneral:
        return BudgetGroup.income;

      case FinanceCategory.transfer:
        return BudgetGroup.transfer;
    }
  }

  String get label {
    switch (this) {
      case FinanceCategory.needsHousing:
        return 'Vivienda / Renta';
      case FinanceCategory.needsGroceries:
        return 'Supermercado & Comida';
      case FinanceCategory.needsUtilities:
        return 'Servicios (Luz, Agua, Net)';
      case FinanceCategory.needsTransport:
        return 'Transporte / Gasolina';
      case FinanceCategory.needsHealth:
        return 'Salud & Medicina';
      case FinanceCategory.needsGeneral:
        return 'Necesidades Generales';

      case FinanceCategory.wantsDining:
        return 'Restaurantes & Café';
      case FinanceCategory.wantsEntertainment:
        return 'Ocio & Streaming';
      case FinanceCategory.wantsShopping:
        return 'Compras Personales';
      case FinanceCategory.wantsTravel:
        return 'Viajes & Salidas';
      case FinanceCategory.wantsGeneral:
        return 'Deseos Generales';

      case FinanceCategory.savingsEmergency:
        return 'Fondo de Paz Mental';
      case FinanceCategory.investmentAssets:
        return 'Inversión en Activos / Cetes';
      case FinanceCategory.polymathEducation:
        return 'Libros, Cursos & Cognición';
      case FinanceCategory.savingsGeneral:
        return 'Ahorro General';

      case FinanceCategory.incomeSalary:
        return 'Salario / Nómina';
      case FinanceCategory.incomeFreelance:
        return 'Proyectos Freelance';
      case FinanceCategory.incomeBusiness:
        return 'Negocio Propio';
      case FinanceCategory.incomeDividends:
        return 'Dividendos & Rendimientos';
      case FinanceCategory.incomeGeneral:
        return 'Otros Ingresos';

      case FinanceCategory.transfer:
        return 'Transferencia entre Cuentas';
    }
  }

  IconData get icon {
    switch (this) {
      case FinanceCategory.needsHousing:
        return Icons.home_outlined;
      case FinanceCategory.needsGroceries:
        return Icons.shopping_basket_outlined;
      case FinanceCategory.needsUtilities:
        return Icons.bolt_outlined;
      case FinanceCategory.needsTransport:
        return Icons.directions_car_outlined;
      case FinanceCategory.needsHealth:
        return Icons.medical_services_outlined;
      case FinanceCategory.needsGeneral:
        return Icons.check_circle_outline;

      case FinanceCategory.wantsDining:
        return Icons.restaurant_outlined;
      case FinanceCategory.wantsEntertainment:
        return Icons.movie_outlined;
      case FinanceCategory.wantsShopping:
        return Icons.shopping_bag_outlined;
      case FinanceCategory.wantsTravel:
        return Icons.flight_takeoff_outlined;
      case FinanceCategory.wantsGeneral:
        return Icons.stars_outlined;

      case FinanceCategory.savingsEmergency:
        return Icons.shield_outlined;
      case FinanceCategory.investmentAssets:
        return Icons.trending_up_rounded;
      case FinanceCategory.polymathEducation:
        return Icons.menu_book_rounded;
      case FinanceCategory.savingsGeneral:
        return Icons.savings_outlined;

      case FinanceCategory.incomeSalary:
        return Icons.work_outline;
      case FinanceCategory.incomeFreelance:
        return Icons.laptop_chromebook_outlined;
      case FinanceCategory.incomeBusiness:
        return Icons.storefront_outlined;
      case FinanceCategory.incomeDividends:
        return Icons.account_balance_outlined;
      case FinanceCategory.incomeGeneral:
        return Icons.monetization_on_outlined;

      case FinanceCategory.transfer:
        return Icons.swap_horiz_rounded;
    }
  }
}

/// Represents a single financial transaction.
class FinanceTransaction {
  const FinanceTransaction({
    required this.id,
    required this.userId,
    required this.accountId,
    required this.amount,
    required this.type,
    required this.category,
    this.toAccountId,
    required this.occurredAt,
    this.note,
    required this.createdAt,
    required this.clientId,
    required this.clientUpdatedAt,
  });

  final String id;
  final String userId;
  final String accountId;
  final double amount;
  final TransactionType type;
  final FinanceCategory category;
  final String? toAccountId;
  final DateTime occurredAt;
  final String? note;
  final DateTime createdAt;
  final String clientId;
  final DateTime clientUpdatedAt;

  DateTime get date => occurredAt;
  bool get isIncome => type == TransactionType.income;
  bool get isExpense => type == TransactionType.expense;
  bool get isTransfer => type == TransactionType.transfer;

  FinanceTransaction copyWith({
    String? id,
    String? userId,
    String? accountId,
    double? amount,
    TransactionType? type,
    FinanceCategory? category,
    String? toAccountId,
    DateTime? occurredAt,
    String? note,
    DateTime? createdAt,
    String? clientId,
    DateTime? clientUpdatedAt,
  }) {
    return FinanceTransaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      accountId: accountId ?? this.accountId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      toAccountId: toAccountId ?? this.toAccountId,
      occurredAt: occurredAt ?? this.occurredAt,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      clientId: clientId ?? this.clientId,
      clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'account_id': accountId,
      'amount': amount,
      'type': type.dbValue,
      'category': category.dbValue,
      'to_account_id': toAccountId,
      'occurred_at': occurredAt.toIso8601String(),
      'note': note,
      'created_at': createdAt.toIso8601String(),
      'client_id': clientId,
      'client_updated_at': clientUpdatedAt.toIso8601String(),
    };
  }

  factory FinanceTransaction.fromMap(Map<String, dynamic> map) {
    return FinanceTransaction(
      id: map['id'] as String,
      userId: (map['user_id'] as String?) ?? 'local_user',
      accountId: map['account_id'] as String,
      amount: ((map['amount'] as num?) ?? 0.0).toDouble(),
      type: TransactionType.fromDbValue((map['type'] as String?) ?? 'expense'),
      category: FinanceCategory.fromDbValue((map['category'] as String?) ?? 'needs_general'),
      toAccountId: map['to_account_id'] as String?,
      occurredAt: DateTime.tryParse(map['occurred_at'] as String? ?? '') ?? DateTime.now(),
      note: map['note'] as String?,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      clientId: (map['client_id'] as String?) ?? (map['id'] as String),
      clientUpdatedAt: DateTime.tryParse(map['client_updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
