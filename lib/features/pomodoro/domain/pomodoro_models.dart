import 'package:flutter/material.dart';

/// Available timer modes from Pomodoro Addendum.
enum PomodoroTimerMode {
  classic(
    key: 'classic',
    name: 'Clásico 25/5',
    workMinutes: 25,
    breakMinutes: 5,
    breakRatio: null,
    description: 'Tickets, correo, logística y tareas cortas.',
    suggestedDailyCap: null,
  ),
  extended(
    key: 'extended',
    name: 'Extendido 50/10',
    workMinutes: 50,
    breakMinutes: 10,
    breakRatio: null,
    description: 'Desarrollo de software, depuración y configuración.',
    suggestedDailyCap: 6,
  ),
  ultradian(
    key: 'ultradian',
    name: 'Ultradiano 90/20',
    workMinutes: 90,
    breakMinutes: 25,
    breakRatio: null,
    description: 'Arquitectura, estudio denso y máxima inmersión.',
    suggestedDailyCap: 2,
  ),
  flowmodoro(
    key: 'flowmodoro',
    name: 'Flowmodoro',
    workMinutes: null,
    breakMinutes: null,
    breakRatio: 0.20,
    description: 'Cronómetro ascendente; descanso automático del 20%.',
    suggestedDailyCap: null,
  );

  const PomodoroTimerMode({
    required this.key,
    required this.name,
    required this.workMinutes,
    required this.breakMinutes,
    required this.breakRatio,
    required this.description,
    required this.suggestedDailyCap,
  });

  final String key;
  final String name;
  final int? workMinutes;
  final int? breakMinutes;
  final double? breakRatio;
  final String description;
  final int? suggestedDailyCap;

  bool get isFlowmodoro => this == PomodoroTimerMode.flowmodoro;

  int get totalWorkSeconds => (workMinutes ?? 0) * 60;
  int get totalBreakSeconds => (breakMinutes ?? 0) * 60;

  static PomodoroTimerMode fromKey(String key) {
    return PomodoroTimerMode.values.firstWhere(
      (m) => m.key == key,
      orElse: () => PomodoroTimerMode.classic,
    );
  }
}

/// Work categorization: deep vs shallow work.
enum WorkType {
  deepWork('deep_work', 'Deep Work', Icons.psychology_rounded, 'Enfoque Profundo'),
  shallowWork('shallow_work', 'Shallow Work', Icons.task_alt_rounded, 'Mantenimiento');

  const WorkType(this.key, this.title, this.icon, this.subtitle);

  final String key;
  final String title;
  final IconData icon;
  final String subtitle;

  bool get isDeepWork => this == WorkType.deepWork;

  static WorkType fromKey(String key) {
    return WorkType.values.firstWhere(
      (w) => w.key == key,
      orElse: () => WorkType.deepWork,
    );
  }
}

/// Interruption note captured during an active session (Bloc de Descarga).
class InterruptionNote {
  const InterruptionNote({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.noteText,
    required this.capturedAt,
    this.convertedToHabitId,
  });

  final String id;
  final String sessionId;
  final String userId;
  final String noteText;
  final DateTime capturedAt;
  final String? convertedToHabitId;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'user_id': userId,
      'note_text': noteText,
      'captured_at': capturedAt.toIso8601String(),
      'converted_to_habit_id': convertedToHabitId,
    };
  }

  factory InterruptionNote.fromMap(Map<String, dynamic> map) {
    return InterruptionNote(
      id: map['id'] as String,
      sessionId: map['session_id'] as String,
      userId: map['user_id'] as String,
      noteText: map['note_text'] as String,
      capturedAt: DateTime.tryParse(map['captured_at'] as String? ?? '') ?? DateTime.now(),
      convertedToHabitId: map['converted_to_habit_id'] as String?,
    );
  }
}

/// Nature ambient sound track definition.
class AmbientSoundTrack {
  const AmbientSoundTrack({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.assetPath,
    required this.icon,
  });

  final String id;
  final String title;
  final String subtitle;
  final String assetPath;
  final IconData icon;
}

/// Available natural ambient sounds registered in assets/sounds/
class AmbientSoundCatalog {
  AmbientSoundCatalog._();

  static const List<AmbientSoundTrack> tracks = [
    AmbientSoundTrack(
      id: 'rain_thunder',
      title: 'Lluvia y Tormenta',
      subtitle: 'Gotas rítmicas con truenos lejanos',
      assetPath: 'assets/sounds/rain_thunder.mp3',
      icon: Icons.thunderstorm_rounded,
    ),
    AmbientSoundTrack(
      id: 'ocean_waves',
      title: 'Olas del Océano',
      subtitle: 'Marea continua y relajante',
      assetPath: 'assets/sounds/ocean_waves.mp3',
      icon: Icons.waves_rounded,
    ),
    AmbientSoundTrack(
      id: 'forest_ambience',
      title: 'Bosque Silvestre',
      subtitle: 'Fauna tranquila y follaje',
      assetPath: 'assets/sounds/forest_ambience.mp3',
      icon: Icons.forest_rounded,
    ),
    AmbientSoundTrack(
      id: 'forest_birds',
      title: 'Pájaros Cantores',
      subtitle: 'Canto matutino en el bosque',
      assetPath: 'assets/sounds/forest_birds.mp3',
      icon: Icons.flutter_dash_rounded,
    ),
    AmbientSoundTrack(
      id: 'forest_wind',
      title: 'Viento en los Árboles',
      subtitle: 'Brisa suave entre las ramas',
      assetPath: 'assets/sounds/forest_wind.mp3',
      icon: Icons.air_rounded,
    ),
    AmbientSoundTrack(
      id: 'river_sounds',
      title: 'Corriente de Río',
      subtitle: 'Flujo de agua constante',
      assetPath: 'assets/sounds/river_sounds.mp3',
      icon: Icons.water_rounded,
    ),
    AmbientSoundTrack(
      id: 'nature_ambience',
      title: 'Naturaleza Profunda',
      subtitle: 'Inmersión acústica orgánica',
      assetPath: 'assets/sounds/nature_ambience.mp3',
      icon: Icons.eco_rounded,
    ),
  ];
}

/// Daily block template item for the daily planner.
class DailyBlockItem {
  const DailyBlockItem({
    required this.id,
    required this.startTime,
    required this.durationMinutes,
    required this.mode,
    required this.workType,
    required this.label,
    this.isBreak = false,
  });

  final String id;
  final String startTime;
  final int durationMinutes;
  final PomodoroTimerMode mode;
  final WorkType workType;
  final String label;
  final bool isBreak;
}
