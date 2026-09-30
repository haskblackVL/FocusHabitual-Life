import 'package:flutter/foundation.dart';

/// The 4 biological phases of the menstrual cycle.
enum CyclePhase {
  menstrual,
  follicular,
  ovulatory,
  luteal;

  String get displayName {
    switch (this) {
      case CyclePhase.menstrual:
        return 'Fase Menstrual';
      case CyclePhase.follicular:
        return 'Fase Folicular';
      case CyclePhase.ovulatory:
        return 'Fase Ovulatoria';
      case CyclePhase.luteal:
        return 'Fase Lútea';
    }
  }

  String get energyLevel {
    switch (this) {
      case CyclePhase.menstrual:
        return 'Baja / Introspectiva';
      case CyclePhase.follicular:
        return 'Creciente / Alta Creatividad';
      case CyclePhase.ovulatory:
        return 'Pico Máximo / Comunicación';
      case CyclePhase.luteal:
        return 'Focalizada / Tareas de Cierre';
    }
  }

  String get productivityAdvice {
    switch (this) {
      case CyclePhase.menstrual:
        return 'Ideal para análisis estratégico, evaluación y descanso consciente. Evita reuniones exhaustivas.';
      case CyclePhase.follicular:
        return 'Excelente momento para iniciar nuevos proyectos, lluvias de ideas y planificación integral.';
      case CyclePhase.ovulatory:
        return 'Pico de autoconfianza y elocuencia. Momento óptimo para negociaciones, ventas y presentaciones.';
      case CyclePhase.luteal:
        return 'Máxima capacidad de detalle y ejecución. Excelente para organización, auditorías y tareas pendientes.';
    }
  }

  String get nutritionAdvice {
    switch (this) {
      case CyclePhase.menstrual:
        return 'Alimentos ricos en hierro (espinacas, legumbres), té de jengibre y abundantes líquidos calientes.';
      case CyclePhase.follicular:
        return 'Proteínas ligeras, alimentos fermentados (kéfir, chucrut) y vegetales frescos.';
      case CyclePhase.ovulatory:
        return 'Antioxidantes (frutos rojos), semillas de calabaza y fibra soluble para apoyar la metabolización de estrógenos.';
      case CyclePhase.luteal:
        return 'Magnesio (cacao puro, frutos secos), carbohidratos complejos y alimentos ricos en vitamina B6.';
    }
  }
}

/// A stored cycle record.
@immutable
class CycleLog {
  const CycleLog({
    required this.id,
    required this.userId,
    required this.periodStart,
    this.periodLength = 5,
    this.cycleLength = 28,
    this.symptoms = const [],
    this.notes,
    required this.createdAt,
    this.clientId,
  });

  final String id;
  final String userId;
  final DateTime periodStart;
  final int periodLength;
  final int cycleLength;
  final List<String> symptoms;
  final String? notes;
  final DateTime createdAt;
  final String? clientId;

  factory CycleLog.fromRow(Map<String, dynamic> row) {
    List<String> parsedSymptoms = [];
    final rawSym = row['symptoms'];
    if (rawSym is String && rawSym.isNotEmpty) {
      parsedSymptoms = rawSym.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    }

    return CycleLog(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      periodStart: DateTime.parse(row['period_start'] as String),
      periodLength: (row['period_length'] as int?) ?? 5,
      cycleLength: (row['cycle_length'] as int?) ?? 28,
      symptoms: parsedSymptoms,
      notes: row['notes'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      clientId: row['client_id'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': userId,
    'period_start': periodStart.toIso8601String().substring(0, 10),
    'period_length': periodLength,
    'cycle_length': cycleLength,
    'symptoms': symptoms.join(','),
    'notes': notes,
    'created_at': createdAt.toIso8601String(),
    'client_id': clientId ?? id,
    'client_updated_at': DateTime.now().toIso8601String(),
  };

  CycleLog copyWith({
    DateTime? periodStart,
    int? periodLength,
    int? cycleLength,
    List<String>? symptoms,
    String? notes,
  }) {
    return CycleLog(
      id: id,
      userId: userId,
      periodStart: periodStart ?? this.periodStart,
      periodLength: periodLength ?? this.periodLength,
      cycleLength: cycleLength ?? this.cycleLength,
      symptoms: symptoms ?? this.symptoms,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      clientId: clientId,
    );
  }
}

/// Comprehensive cycle status for the active day.
@immutable
class CycleDayInfo {
  const CycleDayInfo({
    required this.currentCycleDay,
    required this.phase,
    required this.nextPeriodDate,
    required this.daysUntilNextPeriod,
    required this.isFertileWindow,
    required this.isOvulationDay,
    required this.lastPeriodStart,
    required this.periodLength,
    required this.cycleLength,
    required this.activeSymptoms,
  });

  final int currentCycleDay;
  final CyclePhase phase;
  final DateTime nextPeriodDate;
  final int daysUntilNextPeriod;
  final bool isFertileWindow;
  final bool isOvulationDay;
  final DateTime lastPeriodStart;
  final int periodLength;
  final int cycleLength;
  final List<String> activeSymptoms;

  /// Default baseline factory for initial load or new profile.
  factory CycleDayInfo.initial() {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 10)); // Day 11 baseline
    return CycleDayInfo.calculate(
      lastPeriodStart: start,
      periodLength: 5,
      cycleLength: 28,
      symptoms: const [],
    );
  }

  /// Calculates phase, day, fertility, and predictions from start date.
  factory CycleDayInfo.calculate({
    required DateTime lastPeriodStart,
    int periodLength = 5,
    int cycleLength = 28,
    List<String> symptoms = const [],
  }) {
    final now = DateTime.now();
    final cleanNow = DateTime(now.year, now.month, now.day);
    final cleanStart = DateTime(lastPeriodStart.year, lastPeriodStart.month, lastPeriodStart.day);

    final rawDiff = cleanNow.difference(cleanStart).inDays;
    final currentDay = (rawDiff % cycleLength) + 1;

    // Phase calculation
    CyclePhase phase;
    if (currentDay <= periodLength) {
      phase = CyclePhase.menstrual;
    } else if (currentDay <= (cycleLength - 14 - 3)) {
      phase = CyclePhase.follicular;
    } else if (currentDay <= (cycleLength - 14 + 2)) {
      phase = CyclePhase.ovulatory;
    } else {
      phase = CyclePhase.luteal;
    }

    final ovulationDay = cycleLength - 14;
    final isOvulation = currentDay == ovulationDay;
    final isFertile = currentDay >= (ovulationDay - 5) && currentDay <= (ovulationDay + 1);

    final nextPeriod = cleanStart.add(Duration(days: ((rawDiff ~/ cycleLength) + 1) * cycleLength));
    final daysUntilNext = nextPeriod.difference(cleanNow).inDays;

    return CycleDayInfo(
      currentCycleDay: currentDay,
      phase: phase,
      nextPeriodDate: nextPeriod,
      daysUntilNextPeriod: daysUntilNext > 0 ? daysUntilNext : cycleLength,
      isFertileWindow: isFertile,
      isOvulationDay: isOvulation,
      lastPeriodStart: lastPeriodStart,
      periodLength: periodLength,
      cycleLength: cycleLength,
      activeSymptoms: symptoms,
    );
  }
}

/// Visual layers that can be toggled on the Cycle Calendar.
enum CycleLayer {
  period,
  ovulation,
  pregnancy,
  fertility,
  symptoms;

  String get label {
    switch (this) {
      case CycleLayer.period:
        return 'Periodo';
      case CycleLayer.ovulation:
        return 'Ovulación & Temp';
      case CycleLayer.pregnancy:
        return 'Embarazo';
      case CycleLayer.fertility:
        return 'Fertilidad / Prenupcial';
      case CycleLayer.symptoms:
        return 'Síntomas';
    }
  }
}

/// Ovulation tracking log with basal body temperature and LH test indicators.
@immutable
class OvulationLog {
  const OvulationLog({
    required this.id,
    required this.userId,
    required this.loggedDate,
    this.basalBodyTemp,
    this.cervicalMucus,
    this.ovulationTestResult,
    this.notes,
    this.clientId,
  });

  final String id;
  final String userId;
  final DateTime loggedDate;
  final double? basalBodyTemp;
  final String? cervicalMucus; // 'dry', 'sticky', 'creamy', 'egg_white'
  final String? ovulationTestResult; // 'negative', 'positive', 'peak'
  final String? notes;
  final String? clientId;

  factory OvulationLog.fromRow(Map<String, dynamic> row) {
    return OvulationLog(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      loggedDate: DateTime.parse(row['logged_date'] as String),
      basalBodyTemp: (row['basal_body_temp'] as num?)?.toDouble(),
      cervicalMucus: row['cervical_mucus'] as String?,
      ovulationTestResult: row['ovulation_test_result'] as String?,
      notes: row['notes'] as String?,
      clientId: row['client_id'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': userId,
    'logged_date': loggedDate.toIso8601String().substring(0, 10),
    'basal_body_temp': basalBodyTemp,
    'cervical_mucus': cervicalMucus,
    'ovulation_test_result': ovulationTestResult,
    'notes': notes,
    'client_id': clientId ?? id,
    'client_updated_at': DateTime.now().toIso8601String(),
  };
}

/// Pregnancy gestational tracking log.
@immutable
class PregnancyLog {
  const PregnancyLog({
    required this.id,
    required this.userId,
    this.estimatedConceptionDate,
    this.dueDate,
    this.currentWeek,
    this.isActive = true,
    this.notes,
    required this.createdAt,
    this.clientId,
  });

  final String id;
  final String userId;
  final DateTime? estimatedConceptionDate;
  final DateTime? dueDate;
  final int? currentWeek;
  final bool isActive;
  final String? notes;
  final DateTime createdAt;
  final String? clientId;

  factory PregnancyLog.fromRow(Map<String, dynamic> row) {
    return PregnancyLog(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      estimatedConceptionDate: row['estimated_conception_date'] != null
          ? DateTime.parse(row['estimated_conception_date'] as String)
          : null,
      dueDate: row['due_date'] != null
          ? DateTime.parse(row['due_date'] as String)
          : null,
      currentWeek: row['current_week'] as int?,
      isActive: (row['is_active'] as int? ?? 1) == 1,
      notes: row['notes'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      clientId: row['client_id'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': userId,
    'estimated_conception_date': estimatedConceptionDate?.toIso8601String().substring(0, 10),
    'due_date': dueDate?.toIso8601String().substring(0, 10),
    'current_week': currentWeek,
    'is_active': isActive ? 1 : 0,
    'notes': notes,
    'created_at': createdAt.toIso8601String(),
    'client_id': clientId ?? id,
    'client_updated_at': DateTime.now().toIso8601String(),
  };
}

/// Natural family planning / prenupcial fertility awareness log.
@immutable
class FertilityAwarenessLog {
  const FertilityAwarenessLog({
    required this.id,
    required this.userId,
    required this.loggedDate,
    this.method = 'symptothermal',
    this.fertileWindowStatus,
    this.partnerShared = false,
    this.notes,
    this.clientId,
  });

  final String id;
  final String userId;
  final DateTime loggedDate;
  final String method; // 'symptothermal', 'billings', 'rhythm'
  final String? fertileWindowStatus; // 'fertile', 'infertile', 'uncertain'
  final bool partnerShared;
  final String? notes;
  final String? clientId;

  factory FertilityAwarenessLog.fromRow(Map<String, dynamic> row) {
    return FertilityAwarenessLog(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      loggedDate: DateTime.parse(row['logged_date'] as String),
      method: (row['method'] as String?) ?? 'symptothermal',
      fertileWindowStatus: row['fertile_window_status'] as String?,
      partnerShared: (row['partner_shared'] as int? ?? 0) == 1,
      notes: row['notes'] as String?,
      clientId: row['client_id'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': userId,
    'logged_date': loggedDate.toIso8601String().substring(0, 10),
    'method': method,
    'fertile_window_status': fertileWindowStatus,
    'partner_shared': partnerShared ? 1 : 0,
    'notes': notes,
    'client_id': clientId ?? id,
    'client_updated_at': DateTime.now().toIso8601String(),
  };
}

/// Detailed daily symptoms log.
@immutable
class CycleDailySymptoms {
  const CycleDailySymptoms({
    required this.id,
    required this.userId,
    required this.loggedDate,
    this.symptoms = const [],
    this.flowLevel = 'none',
    this.crampsLevel = 0,
    this.mood = 'calm',
    this.notes,
    this.clientId,
  });

  final String id;
  final String userId;
  final DateTime loggedDate;
  final List<String> symptoms;
  final String flowLevel; // 'none', 'spotting', 'light', 'medium', 'heavy'
  final int crampsLevel; // 0..5
  final String mood; // 'calm', 'energetic', 'sensitive', 'irritable', 'anxious'
  final String? notes;
  final String? clientId;

  factory CycleDailySymptoms.fromRow(Map<String, dynamic> row) {
    List<String> parsedSymptoms = [];
    final rawSym = row['symptoms'];
    if (rawSym is String && rawSym.isNotEmpty) {
      parsedSymptoms = rawSym.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    }

    return CycleDailySymptoms(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      loggedDate: DateTime.parse(row['logged_date'] as String),
      symptoms: parsedSymptoms,
      flowLevel: (row['flow_level'] as String?) ?? 'none',
      crampsLevel: (row['cramps_level'] as int?) ?? 0,
      mood: (row['mood'] as String?) ?? 'calm',
      notes: row['notes'] as String?,
      clientId: row['client_id'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': userId,
    'logged_date': loggedDate.toIso8601String().substring(0, 10),
    'symptoms': symptoms.join(','),
    'flow_level': flowLevel,
    'cramps_level': crampsLevel,
    'mood': mood,
    'notes': notes,
    'client_id': clientId ?? id,
    'client_updated_at': DateTime.now().toIso8601String(),
  };
}

/// Consolidated cycle data for a month across all layers.
@immutable
class CycleMonthData {
  const CycleMonthData({
    required this.month,
    this.ovulationLogs = const {},
    this.activePregnancy,
    this.fertilityLogs = const {},
    this.symptomsLogs = const {},
    this.activeCycle,
  });

  final DateTime month;
  final Map<String, OvulationLog> ovulationLogs; // Key: 'YYYY-MM-DD'
  final PregnancyLog? activePregnancy;
  final Map<String, FertilityAwarenessLog> fertilityLogs; // Key: 'YYYY-MM-DD'
  final Map<String, CycleDailySymptoms> symptomsLogs; // Key: 'YYYY-MM-DD'
  final CycleLog? activeCycle;
}

/// Comprehensive bundle of all layer logs for a single day.
@immutable
class CycleDayRecord {
  const CycleDayRecord({
    required this.date,
    this.ovulationLog,
    this.pregnancyLog,
    this.fertilityLog,
    this.symptomsLog,
  });

  final DateTime date;
  final OvulationLog? ovulationLog;
  final PregnancyLog? pregnancyLog;
  final FertilityAwarenessLog? fertilityLog;
  final CycleDailySymptoms? symptomsLog;
}

