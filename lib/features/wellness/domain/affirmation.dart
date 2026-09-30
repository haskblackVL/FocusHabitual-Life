import 'package:flutter/material.dart';

enum AffirmationCategory {
  disciplina('disciplina', 'Disciplina & Enfoque', Icons.fitness_center_rounded, Color(0xFF3B82F6)),
  autoestima('autoestima', 'Carácter & Autoestima', Icons.shield_outlined, Color(0xFF8B5CF6)),
  abundancia('abundancia', 'Abundancia & Prosperidad', Icons.account_balance_rounded, Color(0xFF10B981)),
  salud('salud', 'Vitalidad & Biohacking', Icons.favorite_border_rounded, Color(0xFFEF4444)),
  fe('fe', 'Fe & Propósito Superior', Icons.menu_book_rounded, Color(0xFFF59E0B)),
  liderazgo('liderazgo', 'Liderazgo & Excelencia', Icons.military_tech_outlined, Color(0xFF6366F1)),
  general('general', 'Mente & Enfoque', Icons.lightbulb_outline_rounded, Color(0xFF06B6D4));

  final String key;
  final String label;
  final IconData icon;
  final Color color;

  const AffirmationCategory(this.key, this.label, this.icon, this.color);

  static AffirmationCategory fromKey(String key) {
    return AffirmationCategory.values.firstWhere(
      (c) => c.key == key,
      orElse: () => AffirmationCategory.general,
    );
  }
}

class Affirmation {
  final String id;
  final String text;
  final AffirmationCategory category;
  final String? author;
  final String language;
  final bool isFavorite;

  const Affirmation({
    required this.id,
    required this.text,
    required this.category,
    this.author,
    this.language = 'es',
    this.isFavorite = false,
  });

  factory Affirmation.fromMap(Map<String, dynamic> map, {bool isFavorite = false}) {
    return Affirmation(
      id: map['id'] as String,
      text: map['text'] as String,
      category: AffirmationCategory.fromKey(map['category'] as String? ?? 'general'),
      author: map['author'] as String?,
      language: map['language'] as String? ?? 'es',
      isFavorite: isFavorite,
    );
  }

  Affirmation copyWith({
    String? id,
    String? text,
    AffirmationCategory? category,
    String? author,
    String? language,
    bool? isFavorite,
  }) {
    return Affirmation(
      id: id ?? this.id,
      text: text ?? this.text,
      category: category ?? this.category,
      author: author ?? this.author,
      language: language ?? this.language,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

class AffirmationLog {
  final String id;
  final String userId;
  final String affirmationId;
  final DateTime shownAt;
  final bool isFavorite;
  final String clientId;

  const AffirmationLog({
    required this.id,
    required this.userId,
    required this.affirmationId,
    required this.shownAt,
    this.isFavorite = false,
    required this.clientId,
  });

  factory AffirmationLog.fromMap(Map<String, dynamic> map) {
    return AffirmationLog(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      affirmationId: map['affirmation_id'] as String,
      shownAt: DateTime.parse(map['shown_at'] as String),
      isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
      clientId: map['client_id'] as String? ?? map['id'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'affirmation_id': affirmationId,
      'shown_at': shownAt.toIso8601String(),
      'is_favorite': isFavorite ? 1 : 0,
      'client_id': clientId,
    };
  }
}
