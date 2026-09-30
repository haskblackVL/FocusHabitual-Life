import 'package:flutter/material.dart';

/// Categorías del diario espiritual de oración.
enum PrayerCategory {
  personal('personal', 'Personal & Sabiduría', Icons.person_outline_rounded, Color(0xFF6366F1)),
  family('family', 'Familia & Hogar', Icons.favorite_border_rounded, Color(0xFFEC4899)),
  workPurpose('work_purpose', 'Trabajo & Propósito', Icons.business_center_outlined, Color(0xFF3B82F6)),
  health('health', 'Salud & Fortaleza', Icons.health_and_safety_outlined, Color(0xFF10B981)),
  gratitude('gratitude', 'Alabanza & Gratitud', Icons.auto_awesome_rounded, Color(0xFFF59E0B));

  const PrayerCategory(this.code, this.label, this.icon, this.color);
  final String code;
  final String label;
  final IconData icon;
  final Color color;

  static PrayerCategory fromCode(String code) {
    return PrayerCategory.values.firstWhere(
      (c) => c.code == code,
      orElse: () => PrayerCategory.personal,
    );
  }
}

/// Estado de una petición de oración.
enum PrayerStatus {
  active('active', 'En Intercesión Activa', Icons.hourglass_top_rounded),
  answered('answered', 'Oración Respondida', Icons.check_circle_rounded);

  const PrayerStatus(this.code, this.label, this.icon);
  final String code;
  final String label;
  final IconData icon;

  static PrayerStatus fromCode(String code) {
    return PrayerStatus.values.firstWhere(
      (s) => s.code == code,
      orElse: () => PrayerStatus.active,
    );
  }
}

/// Modelo de datos para peticiones de oración y testimonios.
class PrayerRequest {
  const PrayerRequest({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.category = 'personal',
    this.status = 'active',
    this.answeredAt,
    this.answerNotes,
    required this.createdAt,
    required this.clientId,
    required this.clientUpdatedAt,
  });

  final String id;
  final String userId;
  final String title;
  final String? description;
  final String category;
  final String status;
  final DateTime? answeredAt;
  final String? answerNotes;
  final DateTime createdAt;
  final String clientId;
  final DateTime clientUpdatedAt;

  bool get isAnswered => status == 'answered';
  PrayerCategory get categoryEnum => PrayerCategory.fromCode(category);
  PrayerStatus get statusEnum => PrayerStatus.fromCode(status);

  factory PrayerRequest.fromMap(Map<String, dynamic> map) {
    return PrayerRequest(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      category: (map['category'] as String?) ?? 'personal',
      status: (map['status'] as String?) ?? 'active',
      answeredAt: map['answered_at'] != null ? DateTime.parse(map['answered_at'] as String) : null,
      answerNotes: map['answer_notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      clientId: map['client_id'] as String,
      clientUpdatedAt: DateTime.parse(map['client_updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'category': category,
      'status': status,
      'answered_at': answeredAt?.toIso8601String(),
      'answer_notes': answerNotes,
      'created_at': createdAt.toIso8601String(),
      'client_id': clientId,
      'client_updated_at': clientUpdatedAt.toIso8601String(),
    };
  }

  PrayerRequest copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? category,
    String? status,
    DateTime? answeredAt,
    String? answerNotes,
    DateTime? createdAt,
    String? clientId,
    DateTime? clientUpdatedAt,
  }) {
    return PrayerRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      status: status ?? this.status,
      answeredAt: answeredAt ?? this.answeredAt,
      answerNotes: answerNotes ?? this.answerNotes,
      createdAt: createdAt ?? this.createdAt,
      clientId: clientId ?? this.clientId,
      clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
    );
  }
}
