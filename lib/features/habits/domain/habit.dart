/// Categories corresponding to check constraints in schema.sql
enum HabitCategory {
  general,
  challenge21,
  checklistAm,
  checklistPm,
  finance,
  gratitude;

  String get dbValue {
    switch (this) {
      case HabitCategory.general:
        return 'general';
      case HabitCategory.challenge21:
        return 'challenge_21';
      case HabitCategory.checklistAm:
        return 'checklist_am';
      case HabitCategory.checklistPm:
        return 'checklist_pm';
      case HabitCategory.finance:
        return 'finance';
      case HabitCategory.gratitude:
        return 'gratitude';
    }
  }

  String get displayName {
    switch (this) {
      case HabitCategory.general:
        return 'General';
      case HabitCategory.challenge21:
        return 'Reto 21 Días';
      case HabitCategory.checklistAm:
        return 'Rutina Matutina (AM)';
      case HabitCategory.checklistPm:
        return 'Rutina Nocturna (PM)';
      case HabitCategory.finance:
        return 'Finanzas';
      case HabitCategory.gratitude:
        return 'Gratitud';
    }
  }

  static HabitCategory fromDb(String val) {
    switch (val) {
      case 'challenge_21':
        return HabitCategory.challenge21;
      case 'checklist_am':
        return HabitCategory.checklistAm;
      case 'checklist_pm':
        return HabitCategory.checklistPm;
      case 'finance':
        return HabitCategory.finance;
      case 'gratitude':
        return HabitCategory.gratitude;
      case 'general':
      default:
        return HabitCategory.general;
    }
  }
}

/// Domain entity representing a Habit.
class Habit {
  const Habit({
    required this.id,
    required this.title,
    this.description,
    this.category = HabitCategory.general,
    this.icon,
    this.color,
    this.frequency = 'daily',
    this.targetCount = 1,
    this.isActive = true,
    required this.startDate,
    this.endDate,
    required this.createdAt,
    this.clientUpdatedAt,
  });

  final String id;
  final String title;
  final String? description;
  final HabitCategory category;
  final String? icon;
  final String? color;
  final String frequency;
  final int targetCount;
  final bool isActive;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime createdAt;
  final DateTime? clientUpdatedAt;

  Habit copyWith({
    String? id,
    String? title,
    String? description,
    HabitCategory? category,
    String? icon,
    String? color,
    String? frequency,
    int? targetCount,
    bool? isActive,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    DateTime? clientUpdatedAt,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      frequency: frequency ?? this.frequency,
      targetCount: targetCount ?? this.targetCount,
      isActive: isActive ?? this.isActive,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
    );
  }
}

/// Extended model representing a habit with current daily completion and streak status.
class HabitWithStatus {
  const HabitWithStatus({
    required this.habit,
    required this.isCompletedToday,
    required this.streakCount,
    this.completedTimesToday = 0,
    this.lastCompletedAt,
  });

  final Habit habit;
  final bool isCompletedToday;
  final int streakCount;
  final int completedTimesToday;
  final DateTime? lastCompletedAt;

  HabitWithStatus copyWith({
    Habit? habit,
    bool? isCompletedToday,
    int? streakCount,
    int? completedTimesToday,
    DateTime? lastCompletedAt,
  }) {
    return HabitWithStatus(
      habit: habit ?? this.habit,
      isCompletedToday: isCompletedToday ?? this.isCompletedToday,
      streakCount: streakCount ?? this.streakCount,
      completedTimesToday: completedTimesToday ?? this.completedTimesToday,
      lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
    );
  }
}
