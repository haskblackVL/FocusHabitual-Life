import 'yoga_and_facial_catalog.dart';

/// Challenge types supported by the Wellness module.
enum ChallengeType {
  meditation('meditation', 'Meditación Consciente', 'Calma mental, respiración y sonidos naturales'),
  yoga('yoga', 'Yoga & Postura', 'Alineación espinal, fuerza isométrica y flexibilidad'),
  yogaFacial('yoga_facial', 'Yoga Facial', 'Drenaje linfático, tonificación mandibular y tersura');

  final String key;
  final String label;
  final String description;

  const ChallengeType(this.key, this.label, this.description);

  static ChallengeType fromKey(String key) {
    return ChallengeType.values.firstWhere(
      (e) => e.key == key,
      orElse: () => ChallengeType.meditation,
    );
  }
}

/// A 21-day challenge instance for a user.
class WellnessChallenge {
  final String id;
  final String userId;
  final ChallengeType challengeType;
  final int totalDays;
  final DateTime startedAt;
  final bool isActive;
  final String clientId;
  final DateTime clientUpdatedAt;

  const WellnessChallenge({
    required this.id,
    required this.userId,
    required this.challengeType,
    this.totalDays = 21,
    required this.startedAt,
    this.isActive = true,
    required this.clientId,
    required this.clientUpdatedAt,
  });

  factory WellnessChallenge.fromMap(Map<String, dynamic> map) {
    return WellnessChallenge(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      challengeType: ChallengeType.fromKey(map['challenge_type'] as String),
      totalDays: (map['total_days'] as num?)?.toInt() ?? 21,
      startedAt: DateTime.tryParse(map['started_at'] as String? ?? '') ?? DateTime.now(),
      isActive: (map['is_active'] as int?) == 1,
      clientId: map['client_id'] as String? ?? '',
      clientUpdatedAt: DateTime.tryParse(map['client_updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'challenge_type': challengeType.key,
      'total_days': totalDays,
      'started_at': startedAt.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'client_id': clientId,
      'client_updated_at': clientUpdatedAt.toIso8601String(),
    };
  }
}

/// Completion record for a specific day in a challenge.
class WellnessChallengeProgress {
  final String id;
  final String challengeId;
  final String userId;
  final int dayNumber;
  final DateTime completedAt;
  final String clientId;
  final DateTime clientUpdatedAt;

  const WellnessChallengeProgress({
    required this.id,
    required this.challengeId,
    required this.userId,
    required this.dayNumber,
    required this.completedAt,
    required this.clientId,
    required this.clientUpdatedAt,
  });

  factory WellnessChallengeProgress.fromMap(Map<String, dynamic> map) {
    return WellnessChallengeProgress(
      id: map['id'] as String,
      challengeId: map['challenge_id'] as String,
      userId: map['user_id'] as String,
      dayNumber: (map['day_number'] as num).toInt(),
      completedAt: DateTime.tryParse(map['completed_at'] as String? ?? '') ?? DateTime.now(),
      clientId: map['client_id'] as String? ?? '',
      clientUpdatedAt: DateTime.tryParse(map['client_updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'challenge_id': challengeId,
      'user_id': userId,
      'day_number': dayNumber,
      'completed_at': completedAt.toIso8601String(),
      'client_id': clientId,
      'client_updated_at': clientUpdatedAt.toIso8601String(),
    };
  }
}

/// An individual exercise / pose within a multi-exercise session.
class ExerciseStep {
  final String title;
  final String category; // e.g. "Frente y Entrecejo", "Fuerza", "Contorno de Ojos", "Flexibilidad"
  final String instructions;
  final int durationSeconds; // Active exercise time
  final int preparationSeconds; // Preparation time (10s by default)
  final String? tip;

  const ExerciseStep({
    required this.title,
    required this.category,
    required this.instructions,
    this.durationSeconds = 40,
    this.preparationSeconds = 10,
    this.tip,
  });

  factory ExerciseStep.fromMap(Map<String, dynamic> map) {
    return ExerciseStep(
      title: map['title'] as String,
      category: map['category'] as String? ?? '',
      instructions: map['instructions'] as String? ?? '',
      durationSeconds: (map['duration_seconds'] as num?)?.toInt() ?? 40,
      preparationSeconds: (map['preparation_seconds'] as num?)?.toInt() ?? 10,
      tip: map['tip'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'category': category,
      'instructions': instructions,
      'duration_seconds': durationSeconds,
      'preparation_seconds': preparationSeconds,
      'tip': tip,
    };
  }
}

/// Static curated exercise / session for a day in a challenge.
class WellnessExercise {
  final String id;
  final ChallengeType challengeType;
  final int dayNumber;
  final String title;
  final String? tip;
  final String instructions;
  final String? videoUrl;
  final int durationMinutes;
  final List<ExerciseStep> steps;

  const WellnessExercise({
    required this.id,
    required this.challengeType,
    required this.dayNumber,
    required this.title,
    this.tip,
    required this.instructions,
    this.videoUrl,
    this.durationMinutes = 5,
    this.steps = const [],
  });

  /// Returns the configured steps if present, or dynamically resolves the structured
  /// multi-exercise routine with 10s preparation per exercise from [YogaAndFacialCatalog].
  List<ExerciseStep> get effectiveSteps {
    if (steps.isNotEmpty) return steps;
    if (challengeType == ChallengeType.yoga) {
      return YogaAndFacialCatalog.getYogaRoutineForDay(dayNumber);
    } else if (challengeType == ChallengeType.yogaFacial) {
      return YogaAndFacialCatalog.getFacialRoutineForDay(dayNumber);
    } else if (challengeType == ChallengeType.meditation) {
      return YogaAndFacialCatalog.getMeditationStagesForDay(dayNumber, title, instructions, durationMinutes);
    }
    return const [];
  }

  factory WellnessExercise.fromMap(Map<String, dynamic> map) {
    return WellnessExercise(
      id: map['id'] as String,
      challengeType: ChallengeType.fromKey(map['challenge_type'] as String),
      dayNumber: (map['day_number'] as num).toInt(),
      title: map['title'] as String,
      tip: map['tip'] as String?,
      instructions: map['instructions'] as String? ?? '',
      videoUrl: map['video_url'] as String?,
      durationMinutes: (map['duration_minutes'] as num?)?.toInt() ?? 5,
      steps: const [],
    );
  }

  WellnessExercise copyWith({
    String? id,
    ChallengeType? challengeType,
    int? dayNumber,
    String? title,
    String? tip,
    String? instructions,
    String? videoUrl,
    int? durationMinutes,
    List<ExerciseStep>? steps,
  }) {
    return WellnessExercise(
      id: id ?? this.id,
      challengeType: challengeType ?? this.challengeType,
      dayNumber: dayNumber ?? this.dayNumber,
      title: title ?? this.title,
      tip: tip ?? this.tip,
      instructions: instructions ?? this.instructions,
      videoUrl: videoUrl ?? this.videoUrl,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      steps: steps ?? this.steps,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'challenge_type': challengeType.key,
      'day_number': dayNumber,
      'title': title,
      'tip': tip,
      'instructions': instructions,
      'video_url': videoUrl,
      'duration_minutes': durationMinutes,
    };
  }
}

/// Ambient sound for meditation and focus sessions.
class AmbientSound {
  final String id;
  final String name;
  final String category;
  final String audioUrl;
  final bool loopable;

  const AmbientSound({
    required this.id,
    required this.name,
    this.category = 'nature',
    required this.audioUrl,
    this.loopable = true,
  });

  factory AmbientSound.fromMap(Map<String, dynamic> map) {
    return AmbientSound(
      id: map['id'] as String,
      name: map['name'] as String,
      category: map['category'] as String? ?? 'nature',
      audioUrl: map['audio_url'] as String,
      loopable: (map['loopable'] as int?) != 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'audio_url': audioUrl,
      'loopable': loopable ? 1 : 0,
    };
  }
}

/// Summary state for a challenge including progress and current exercise.
class ChallengeSummary {
  final WellnessChallenge challenge;
  final List<WellnessChallengeProgress> completedDays;
  final WellnessExercise? currentExercise;
  final List<WellnessExercise> allExercises;

  const ChallengeSummary({
    required this.challenge,
    required this.completedDays,
    this.currentExercise,
    required this.allExercises,
  });

  int get completedCount => completedDays.length;
  double get progressPercent => (completedCount / challenge.totalDays).clamp(0.0, 1.0);
  bool get isCompleted => completedCount >= challenge.totalDays;

  int get nextPendingDay {
    final completedDaySet = completedDays.map((e) => e.dayNumber).toSet();
    for (int i = 1; i <= challenge.totalDays; i++) {
      if (!completedDaySet.contains(i)) return i;
    }
    return challenge.totalDays;
  }

  bool isDayCompleted(int day) {
    return completedDays.any((d) => d.dayNumber == day);
  }
}
