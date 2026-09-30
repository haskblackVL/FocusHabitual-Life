import 'package:flutter/material.dart';

/// Supported types of financial accounts.
enum AccountType {
  cash,
  bank,
  creditCard,
  savings,
  investment;

  String get dbValue {
    switch (this) {
      case AccountType.cash:
        return 'cash';
      case AccountType.bank:
        return 'bank';
      case AccountType.creditCard:
        return 'credit_card';
      case AccountType.savings:
        return 'savings';
      case AccountType.investment:
        return 'investment';
    }
  }

  static AccountType fromDbValue(String value) {
    switch (value) {
      case 'cash':
        return AccountType.cash;
      case 'bank':
        return AccountType.bank;
      case 'credit_card':
        return AccountType.creditCard;
      case 'savings':
        return AccountType.savings;
      case 'investment':
        return AccountType.investment;
      default:
        return AccountType.bank;
    }
  }

  String get label {
    switch (this) {
      case AccountType.cash:
        return 'Efectivo';
      case AccountType.bank:
        return 'Cuenta Bancaria';
      case AccountType.creditCard:
        return 'Tarjeta de Crédito';
      case AccountType.savings:
        return 'Cuenta de Ahorros';
      case AccountType.investment:
        return 'Inversión / Bolsa';
    }
  }

  IconData get icon {
    switch (this) {
      case AccountType.cash:
        return Icons.payments_outlined;
      case AccountType.bank:
        return Icons.account_balance_outlined;
      case AccountType.creditCard:
        return Icons.credit_card_outlined;
      case AccountType.savings:
        return Icons.savings_outlined;
      case AccountType.investment:
        return Icons.trending_up_rounded;
    }
  }

  Color get color {
    switch (this) {
      case AccountType.cash:
        return const Color(0xFF10B981);
      case AccountType.bank:
        return const Color(0xFF004AC6);
      case AccountType.creditCard:
        return const Color(0xFFE11D48);
      case AccountType.savings:
        return const Color(0xFF0D9488);
      case AccountType.investment:
        return const Color(0xFF8B5CF6);
    }
  }
}

/// Represents a financial account belonging to the user.
class FinanceAccount {
  const FinanceAccount({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    this.currency = 'MXN',
    this.initialBalance = 0.0,
    this.currentBalance = 0.0,
    required this.createdAt,
    required this.clientId,
    required this.clientUpdatedAt,
  });

  final String id;
  final String userId;
  final String name;
  final AccountType type;
  final String currency;
  final double initialBalance;
  final double currentBalance;
  final DateTime createdAt;
  final String clientId;
  final DateTime clientUpdatedAt;

  bool get isLiability => type == AccountType.creditCard;

  FinanceAccount copyWith({
    String? id,
    String? userId,
    String? name,
    AccountType? type,
    String? currency,
    double? initialBalance,
    double? currentBalance,
    DateTime? createdAt,
    String? clientId,
    DateTime? clientUpdatedAt,
  }) {
    return FinanceAccount(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      currency: currency ?? this.currency,
      initialBalance: initialBalance ?? this.initialBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      createdAt: createdAt ?? this.createdAt,
      clientId: clientId ?? this.clientId,
      clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'type': type.dbValue,
      'currency': currency,
      'initial_balance': initialBalance,
      'created_at': createdAt.toIso8601String(),
      'client_id': clientId,
      'client_updated_at': clientUpdatedAt.toIso8601String(),
    };
  }

  factory FinanceAccount.fromMap(Map<String, dynamic> map, {double? currentBalance}) {
    return FinanceAccount(
      id: map['id'] as String,
      userId: (map['user_id'] as String?) ?? 'local_user',
      name: map['name'] as String,
      type: AccountType.fromDbValue((map['type'] as String?) ?? 'bank'),
      currency: (map['currency'] as String?) ?? 'MXN',
      initialBalance: ((map['initial_balance'] as num?) ?? 0.0).toDouble(),
      currentBalance: currentBalance ?? ((map['initial_balance'] as num?) ?? 0.0).toDouble(),
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      clientId: (map['client_id'] as String?) ?? (map['id'] as String),
      clientUpdatedAt: DateTime.tryParse(map['client_updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
