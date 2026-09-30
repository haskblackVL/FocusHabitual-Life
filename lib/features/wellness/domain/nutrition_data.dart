import 'package:flutter/material.dart';

enum MealType {
  breakfast('breakfast', 'Desayuno', Icons.wb_sunny_outlined, Color(0xFFF59E0B)),
  lunch('lunch', 'Almuerzo', Icons.wb_twilight_rounded, Color(0xFF10B981)),
  dinner('dinner', 'Cena', Icons.nights_stay_outlined, Color(0xFF6366F1)),
  snack('snack', 'Snack Estratégico', Icons.apple_outlined, Color(0xFFEC4899));

  final String key;
  final String label;
  final IconData icon;
  final Color color;

  const MealType(this.key, this.label, this.icon, this.color);

  static MealType fromKey(String key) {
    return MealType.values.firstWhere(
      (m) => m.key == key,
      orElse: () => MealType.snack,
    );
  }
}

class NutritionSettings {
  final String userId;
  final String breakfastTime;
  final String lunchTime;
  final String dinnerTime;
  final bool remindersEnabled;

  const NutritionSettings({
    required this.userId,
    this.breakfastTime = '08:00',
    this.lunchTime = '14:00',
    this.dinnerTime = '20:00',
    this.remindersEnabled = true,
  });

  factory NutritionSettings.fromMap(Map<String, dynamic> map) {
    return NutritionSettings(
      userId: map['user_id'] as String? ?? 'local_user',
      breakfastTime: map['breakfast_time'] as String? ?? '08:00',
      lunchTime: map['lunch_time'] as String? ?? '14:00',
      dinnerTime: map['dinner_time'] as String? ?? '20:00',
      remindersEnabled: (map['reminders_enabled'] as int? ?? 1) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'breakfast_time': breakfastTime,
      'lunch_time': lunchTime,
      'dinner_time': dinnerTime,
      'reminders_enabled': remindersEnabled ? 1 : 0,
    };
  }

  NutritionSettings copyWith({
    String? userId,
    String? breakfastTime,
    String? lunchTime,
    String? dinnerTime,
    bool? remindersEnabled,
  }) {
    return NutritionSettings(
      userId: userId ?? this.userId,
      breakfastTime: breakfastTime ?? this.breakfastTime,
      lunchTime: lunchTime ?? this.lunchTime,
      dinnerTime: dinnerTime ?? this.dinnerTime,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
    );
  }
}

class NutritionMealLog {
  final String id;
  final String userId;
  final MealType mealType;
  final String? title;
  final String? note;
  final DateTime loggedAt;
  final String clientId;

  const NutritionMealLog({
    required this.id,
    required this.userId,
    required this.mealType,
    this.title,
    this.note,
    required this.loggedAt,
    required this.clientId,
  });

  factory NutritionMealLog.fromMap(Map<String, dynamic> map) {
    return NutritionMealLog(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      mealType: MealType.fromKey(map['meal_type'] as String),
      title: map['title'] as String?,
      note: map['note'] as String?,
      loggedAt: DateTime.parse(map['logged_at'] as String),
      clientId: map['client_id'] as String? ?? map['id'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'meal_type': mealType.key,
      'title': title,
      'note': note,
      'logged_at': loggedAt.toIso8601String(),
      'client_id': clientId,
    };
  }
}

class NutritionTip {
  final String id;
  final String tipText;
  final String category;

  const NutritionTip({
    required this.id,
    required this.tipText,
    required this.category,
  });

  factory NutritionTip.fromMap(Map<String, dynamic> map) {
    return NutritionTip(
      id: map['id'] as String,
      tipText: map['tip_text'] as String,
      category: map['category'] as String? ?? 'general',
    );
  }
}

class DailyNutritionSummary {
  final List<NutritionMealLog> mealsToday;
  final NutritionTip dailyTip;

  const DailyNutritionSummary({
    required this.mealsToday,
    required this.dailyTip,
  });

  bool get hasBreakfast => mealsToday.any((m) => m.mealType == MealType.breakfast);
  bool get hasLunch => mealsToday.any((m) => m.mealType == MealType.lunch);
  bool get hasDinner => mealsToday.any((m) => m.mealType == MealType.dinner);
  int get mealsLoggedCount => mealsToday.length;
}
