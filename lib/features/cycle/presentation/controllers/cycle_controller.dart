import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/local_db/sync_engine.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/cycle_repository.dart';
import '../../domain/cycle_models.dart';

/// Provider for CycleRepository with active user session.
final cycleRepositoryProvider = Provider<CycleRepository>((ref) {
  final user = ref.watch(authControllerProvider).value;
  return CycleRepository(currentUserId: user?.id);
});

/// Provider for live CycleDayInfo.
final cycleControllerProvider =
    AsyncNotifierProvider<CycleNotifier, CycleDayInfo>(
  CycleNotifier.new,
);

class CycleNotifier extends AsyncNotifier<CycleDayInfo> {
  CycleRepository get _repo => ref.read(cycleRepositoryProvider);
  CycleLog? _currentLog;

  @override
  FutureOr<CycleDayInfo> build() async {
    ref.watch(cycleRepositoryProvider);
    _currentLog = await _repo.getLatestCycle();

    if (_currentLog == null) {
      return CycleDayInfo.initial();
    }

    return CycleDayInfo.calculate(
      lastPeriodStart: _currentLog!.periodStart,
      periodLength: _currentLog!.periodLength,
      cycleLength: _currentLog!.cycleLength,
      symptoms: _currentLog!.symptoms,
    );
  }

  /// Records period starting today.
  Future<void> recordPeriodStartToday() async {
    final now = DateTime.now();
    await recordPeriodStartDate(now);
  }

  /// Records period starting on a specific date.
  Future<void> recordPeriodStartDate(DateTime date) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final periodLen = _currentLog?.periodLength ?? 5;
      final cycleLen = _currentLog?.cycleLength ?? 28;

      _currentLog = await _repo.recordPeriodStart(
        date,
        periodLength: periodLen,
        cycleLength: cycleLen,
      );

      ref.invalidate(cycleHistoryProvider);
      ref.read(syncEngineProvider).syncNow();

      return CycleDayInfo.calculate(
        lastPeriodStart: _currentLog!.periodStart,
        periodLength: _currentLog!.periodLength,
        cycleLength: _currentLog!.cycleLength,
        symptoms: _currentLog!.symptoms,
      );
    });
  }

  /// Toggles a symptom for the current cycle.
  Future<void> toggleSymptom(String symptomKey) async {
    if (_currentLog == null) return;

    final currentSymptoms = List<String>.from(_currentLog!.symptoms);
    if (currentSymptoms.contains(symptomKey)) {
      currentSymptoms.remove(symptomKey);
    } else {
      currentSymptoms.add(symptomKey);
    }

    _currentLog = _currentLog!.copyWith(symptoms: currentSymptoms);

    await _repo.updateSymptoms(_currentLog!.id, currentSymptoms);
    ref.read(syncEngineProvider).syncNow();

    state = AsyncData(CycleDayInfo.calculate(
      lastPeriodStart: _currentLog!.periodStart,
      periodLength: _currentLog!.periodLength,
      cycleLength: _currentLog!.cycleLength,
      symptoms: currentSymptoms,
    ));
  }
}

/// Provider for cycle history.
final cycleHistoryProvider = FutureProvider<List<CycleLog>>((ref) async {
  final repo = ref.watch(cycleRepositoryProvider);
  return repo.getCycleHistory();
});

// ==========================================
// MULTI-LAYER CONTROLLERS & PROVIDERS
// ==========================================

/// Notifier controlling which visual layers are currently active on the calendar.
class CycleLayersNotifier extends Notifier<Set<CycleLayer>> {
  @override
  Set<CycleLayer> build() {
    return {
      CycleLayer.period,
      CycleLayer.ovulation,
      CycleLayer.fertility,
      CycleLayer.symptoms,
    };
  }

  void toggleLayer(CycleLayer layer) {
    if (state.contains(layer)) {
      if (state.length > 1) {
        state = Set.from(state)..remove(layer);
      }
    } else {
      state = Set.from(state)..add(layer);
    }
  }

  void setLayer(CycleLayer layer, bool active) {
    if (active) {
      state = Set.from(state)..add(layer);
    } else if (state.length > 1) {
      state = Set.from(state)..remove(layer);
    }
  }

  void showAll() {
    state = CycleLayer.values.toSet();
  }
}

final cycleActiveLayersProvider =
    NotifierProvider<CycleLayersNotifier, Set<CycleLayer>>(
  CycleLayersNotifier.new,
);

/// Notifier for the user's currently selected date on the calendar.
class CycleSelectedDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void selectDate(DateTime date) {
    state = DateTime(date.year, date.month, date.day);
  }
}

final cycleSelectedDateProvider =
    NotifierProvider<CycleSelectedDateNotifier, DateTime>(
  CycleSelectedDateNotifier.new,
);

/// Notifier for the month visible in the calendar grid.
class CycleCalendarMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  void nextMonth() {
    state = DateTime(state.year, state.month + 1, 1);
  }

  void previousMonth() {
    state = DateTime(state.year, state.month - 1, 1);
  }

  void setMonth(DateTime month) {
    state = DateTime(month.year, month.month, 1);
  }
}

final cycleCalendarMonthProvider =
    NotifierProvider<CycleCalendarMonthNotifier, DateTime>(
  CycleCalendarMonthNotifier.new,
);

/// Provider fetching all cycle layer records for the currently selected calendar month.
final cycleMonthDataProvider = FutureProvider<CycleMonthData>((ref) async {
  final repo = ref.watch(cycleRepositoryProvider);
  final month = ref.watch(cycleCalendarMonthProvider);

  final ovulations = await repo.getOvulationLogsForMonth(month);
  final pregnancy = await repo.getActivePregnancy();
  final fertility = await repo.getFertilityLogsForMonth(month);
  final symptoms = await repo.getSymptomsForMonth(month);
  final latestCycle = await repo.getLatestCycle();

  final ovMap = {
    for (final o in ovulations)
      o.loggedDate.toIso8601String().substring(0, 10): o
  };
  final fertMap = {
    for (final f in fertility)
      f.loggedDate.toIso8601String().substring(0, 10): f
  };
  final symMap = {
    for (final s in symptoms)
      s.loggedDate.toIso8601String().substring(0, 10): s
  };

  return CycleMonthData(
    month: month,
    ovulationLogs: ovMap,
    activePregnancy: pregnancy,
    fertilityLogs: fertMap,
    symptomsLogs: symMap,
    activeCycle: latestCycle,
  );
});

/// Provider fetching all layer records for the currently selected day.
final cycleSelectedDayDataProvider =
    FutureProvider<CycleDayRecord>((ref) async {
  final repo = ref.watch(cycleRepositoryProvider);
  final date = ref.watch(cycleSelectedDateProvider);

  final ovulation = await repo.getOvulationLogForDate(date);
  final pregnancy = await repo.getActivePregnancy();
  final fertility = await repo.getFertilityLogForDate(date);
  final symptoms = await repo.getDailySymptomsForDate(date);

  return CycleDayRecord(
    date: date,
    ovulationLog: ovulation,
    pregnancyLog: pregnancy,
    fertilityLog: fertility,
    symptomsLog: symptoms,
  );
});

/// Service / helper provider to save multi-layer day records.
final cycleLoggerProvider = Provider<CycleLoggerService>((ref) {
  return CycleLoggerService(ref);
});

class CycleLoggerService {
  CycleLoggerService(this._ref);

  final Ref _ref;

  CycleRepository get _repo => _ref.read(cycleRepositoryProvider);

  /// Saves or updates details for a specific day across layers.
  Future<void> saveDayRecord({
    required DateTime date,
    // Ovulation & Basal Temp
    double? basalBodyTemp,
    String? cervicalMucus,
    String? ovulationTestResult,
    String? ovulationNotes,
    // Pregnancy
    bool updatePregnancy = false,
    int? pregnancyWeek,
    DateTime? dueDate,
    DateTime? conceptionDate,
    bool isPregnancyActive = true,
    String? pregnancyNotes,
    // Fertility / Natural Planning
    String? fertilityMethod,
    String? fertileWindowStatus,
    bool partnerShared = false,
    String? fertilityNotes,
    // Daily Symptoms
    List<String>? symptoms,
    String? flowLevel,
    int? crampsLevel,
    String? mood,
    String? symptomsNotes,
  }) async {
    // 1. Ovulation / Basal Body Temp
    if (basalBodyTemp != null ||
        cervicalMucus != null ||
        ovulationTestResult != null ||
        (ovulationNotes != null && ovulationNotes.isNotEmpty)) {
      await _repo.logOvulation(
        date: date,
        basalBodyTemp: basalBodyTemp,
        cervicalMucus: cervicalMucus,
        ovulationTestResult: ovulationTestResult,
        notes: ovulationNotes,
      );
    }

    // 2. Pregnancy
    if (updatePregnancy) {
      await _repo.logPregnancy(
        currentWeek: pregnancyWeek,
        dueDate: dueDate,
        estimatedConceptionDate: conceptionDate,
        isActive: isPregnancyActive,
        notes: pregnancyNotes,
      );
    }

    // 3. Fertility Awareness / Prenupcial
    if (fertilityMethod != null ||
        fertileWindowStatus != null ||
        partnerShared ||
        (fertilityNotes != null && fertilityNotes.isNotEmpty)) {
      await _repo.logFertilityAwareness(
        date: date,
        method: fertilityMethod ?? 'symptothermal',
        fertileWindowStatus: fertileWindowStatus,
        partnerShared: partnerShared,
        notes: fertilityNotes,
      );
    }

    // 4. Daily Symptoms
    if (symptoms != null ||
        flowLevel != null ||
        crampsLevel != null ||
        mood != null ||
        (symptomsNotes != null && symptomsNotes.isNotEmpty)) {
      await _repo.logDailySymptoms(
        date: date,
        symptoms: symptoms ?? const [],
        flowLevel: flowLevel ?? 'none',
        crampsLevel: crampsLevel ?? 0,
        mood: mood ?? 'calm',
        notes: symptomsNotes,
      );
    }

    // Refresh live providers
    _ref.invalidate(cycleMonthDataProvider);
    _ref.invalidate(cycleSelectedDayDataProvider);
    _ref.invalidate(cycleControllerProvider);

    _ref.read(syncEngineProvider).syncNow();
  }
}
