import 'dart:math' as math;

/// Unified XP & Gamification Engine for FocusHabitual Life.
/// Implements the formula from schema.sql: level = floor(sqrt(total_xp / 100.0)) + 1
class XpEngine {
  XpEngine._();

  static const int habitXp = 10;
  static const int pomodoroXp = 25;
  static const int deepWorkPomodoroXp = 38;
  static const int checklistBonusXp = 15;
  static const int devotionalReflectionXp = 15;
  static const int prayerRecordXp = 10;
  static const int waterLogXp = 5;
  static const int waterGoalBonusXp = 15;
  static const int nutritionLogXp = 10;
  static const int affirmationReadXp = 5;
  static const int wellnessChallengeDayXp = 15;
  static const int wellnessChallengeCompleteXp = 50;

  /// Calculates user level based on total XP.
  /// For brand-new users with 0 XP, level begins at 0.
  static int calculateLevel(int totalXp) {
    if (totalXp <= 0) return 0;
    return (math.sqrt(totalXp / 100.0)).floor() + 1;
  }

  /// Calculates total XP required to reach [level].
  static int xpForLevel(int level) {
    if (level <= 1) return 0;
    final l = level - 1;
    return l * l * 100;
  }

  /// Calculates the progress (0.0 to 1.0) towards the next level.
  static double calculateLevelProgress(int totalXp) {
    if (totalXp <= 0) return 0.0;
    final currentLevel = calculateLevel(totalXp);
    final currentLevelMinXp = xpForLevel(currentLevel);
    final nextLevelMinXp = xpForLevel(currentLevel + 1);

    final range = nextLevelMinXp - currentLevelMinXp;
    if (range <= 0) return 1.0;

    final earnedInLevel = totalXp - currentLevelMinXp;
    return (earnedInLevel / range).clamp(0.0, 1.0);
  }

  /// Returns executive titles based on level for FocusHabitual Life.
  static String getLevelTitle(int level) {
    if (level <= 0) return 'Nuevo Usuario';
    if (level <= 1) return 'Iniciado en Disciplina';
    if (level <= 3) return 'Iniciado en Disciplina';
    if (level <= 6) return 'Estratega del Enfoque';
    if (level <= 10) return 'Consolidado Focus';
    if (level <= 15) return 'Maestro de la Rutina';
    if (level <= 20) return 'Arquitecto de Hábitos';
    return 'Élite FocusHabitual';
  }
}
