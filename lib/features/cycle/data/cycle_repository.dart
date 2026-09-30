import 'package:uuid/uuid.dart';
import '../../../core/local_db/database.dart';
import '../domain/cycle_models.dart';

/// SQLite Data Access for menstrual cycle tracking & symptom logs.
class CycleRepository {
  CycleRepository({this.currentUserId});

  final String? currentUserId;
  static const _uuid = Uuid();

  String get _activeUserId => currentUserId ?? 'local_user';

  /// Retrieves the most recent cycle record.
  Future<CycleLog?> getLatestCycle() async {
    final db = AppDatabase.instance;
    final rows = db.select('''
      SELECT id, user_id, period_start, period_length, cycle_length, symptoms, notes, created_at, client_id
      FROM cycle_log
      WHERE user_id = ?
      ORDER BY period_start DESC
      LIMIT 1
    ''', [_activeUserId]);

    if (rows.isEmpty) {
      // Seed default baseline (10 days ago = Day 11)
      final now = DateTime.now();
      final baselineStart = now.subtract(const Duration(days: 10));
      return recordPeriodStart(baselineStart);
    }

    return CycleLog.fromRow(rows.first);
  }

  /// Retrieves previous recorded cycles for history view.
  Future<List<CycleLog>> getCycleHistory() async {
    final db = AppDatabase.instance;
    final rows = db.select('''
      SELECT id, user_id, period_start, period_length, cycle_length, symptoms, notes, created_at, client_id
      FROM cycle_log
      WHERE user_id = ?
      ORDER BY period_start DESC
      LIMIT 12
    ''', [_activeUserId]);
    return rows.map((r) => CycleLog.fromRow(r)).toList();
  }

  /// Records a new period start date.
  Future<CycleLog> recordPeriodStart(
    DateTime date, {
    int periodLength = 5,
    int cycleLength = 28,
    List<String> symptoms = const [],
  }) async {
    final db = AppDatabase.instance;
    final id = _uuid.v4();
    final clientId = _uuid.v4();
    final now = DateTime.now();
    final dateStr = date.toIso8601String().substring(0, 10);
    final symptomsStr = symptoms.join(',');

    db.execute('''
      INSERT INTO cycle_log (id, user_id, period_start, period_length, cycle_length, symptoms, created_at, client_id, client_updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', [id, _activeUserId, dateStr, periodLength, cycleLength, symptomsStr, now.toIso8601String(), clientId, now.toIso8601String()]);

    final cycle = CycleLog(
      id: id,
      userId: _activeUserId,
      periodStart: date,
      periodLength: periodLength,
      cycleLength: cycleLength,
      symptoms: symptoms,
      createdAt: now,
      clientId: clientId,
    );

    AppDatabase.enqueueSync(
      tableName: 'cycle_log',
      recordId: id,
      action: 'INSERT',
      payload: cycle.toMap(),
    );

    return cycle;
  }

  /// Updates symptoms for the active cycle log.
  Future<void> updateSymptoms(String cycleId, List<String> symptoms, {String? notes}) async {
    final db = AppDatabase.instance;
    final now = DateTime.now().toIso8601String();
    final symptomsStr = symptoms.join(',');

    db.execute('''
      UPDATE cycle_log
      SET symptoms = ?, notes = ?, client_updated_at = ?
      WHERE id = ? AND user_id = ?
    ''', [symptomsStr, notes, now, cycleId, _activeUserId]);

    AppDatabase.enqueueSync(
      tableName: 'cycle_log',
      recordId: cycleId,
      action: 'UPDATE',
      payload: {
        'id': cycleId,
        'user_id': _activeUserId,
        'symptoms': symptomsStr,
        'notes': notes,
        'client_updated_at': now,
      },
    );
  }

  // ==========================================
  // OVULATION & BASAL BODY TEMPERATURE LAYER
  // ==========================================

  /// Logs or updates ovulation and basal temperature tracking for a specific day.
  Future<OvulationLog> logOvulation({
    required DateTime date,
    double? basalBodyTemp,
    String? cervicalMucus,
    String? ovulationTestResult,
    String? notes,
  }) async {
    final db = AppDatabase.instance;
    final dateStr = date.toIso8601String().substring(0, 10);
    final now = DateTime.now().toIso8601String();

    final existing = db.select('''
      SELECT id, client_id FROM ovulation_log
      WHERE user_id = ? AND logged_date = ?
      LIMIT 1
    ''', [_activeUserId, dateStr]);

    String id;
    String clientId;
    String action;

    if (existing.isNotEmpty) {
      id = existing.first['id'] as String;
      clientId = (existing.first['client_id'] as String?) ?? id;
      action = 'UPDATE';

      db.execute('''
        UPDATE ovulation_log
        SET basal_body_temp = ?, cervical_mucus = ?, ovulation_test_result = ?, notes = ?, client_updated_at = ?
        WHERE id = ?
      ''', [basalBodyTemp, cervicalMucus, ovulationTestResult, notes, now, id]);
    } else {
      id = _uuid.v4();
      clientId = _uuid.v4();
      action = 'INSERT';

      db.execute('''
        INSERT INTO ovulation_log (id, user_id, logged_date, basal_body_temp, cervical_mucus, ovulation_test_result, notes, client_id, client_updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''', [id, _activeUserId, dateStr, basalBodyTemp, cervicalMucus, ovulationTestResult, notes, clientId, now]);
    }

    final log = OvulationLog(
      id: id,
      userId: _activeUserId,
      loggedDate: DateTime.parse(dateStr),
      basalBodyTemp: basalBodyTemp,
      cervicalMucus: cervicalMucus,
      ovulationTestResult: ovulationTestResult,
      notes: notes,
      clientId: clientId,
    );

    AppDatabase.enqueueSync(
      tableName: 'ovulation_log',
      recordId: id,
      action: action,
      payload: log.toMap(),
    );

    return log;
  }

  /// Gets all ovulation logs for a specific month.
  Future<List<OvulationLog>> getOvulationLogsForMonth(DateTime month) async {
    final db = AppDatabase.instance;
    final monthPrefix = '${month.year}-${month.month.toString().padLeft(2, '0')}%';
    final rows = db.select('''
      SELECT id, user_id, logged_date, basal_body_temp, cervical_mucus, ovulation_test_result, notes, client_id
      FROM ovulation_log
      WHERE user_id = ? AND logged_date LIKE ?
      ORDER BY logged_date ASC
    ''', [_activeUserId, monthPrefix]);

    return rows.map((r) => OvulationLog.fromRow(r)).toList();
  }

  /// Gets the ovulation log for a specific date if exists.
  Future<OvulationLog?> getOvulationLogForDate(DateTime date) async {
    final db = AppDatabase.instance;
    final dateStr = date.toIso8601String().substring(0, 10);
    final rows = db.select('''
      SELECT id, user_id, logged_date, basal_body_temp, cervical_mucus, ovulation_test_result, notes, client_id
      FROM ovulation_log
      WHERE user_id = ? AND logged_date = ?
      LIMIT 1
    ''', [_activeUserId, dateStr]);

    if (rows.isEmpty) return null;
    return OvulationLog.fromRow(rows.first);
  }

  // ==========================================
  // PREGNANCY TRACKING LAYER
  // ==========================================

  /// Saves or updates the active pregnancy log.
  Future<PregnancyLog> logPregnancy({
    DateTime? estimatedConceptionDate,
    DateTime? dueDate,
    int? currentWeek,
    bool isActive = true,
    String? notes,
  }) async {
    final db = AppDatabase.instance;
    final now = DateTime.now();
    final nowStr = now.toIso8601String();

    final activeRows = db.select('''
      SELECT id, client_id FROM pregnancy_log
      WHERE user_id = ? AND is_active = 1
      ORDER BY created_at DESC
      LIMIT 1
    ''', [_activeUserId]);

    String id;
    String clientId;
    String action;

    final conceptionStr = estimatedConceptionDate?.toIso8601String().substring(0, 10);
    final dueStr = dueDate?.toIso8601String().substring(0, 10);

    if (activeRows.isNotEmpty) {
      id = activeRows.first['id'] as String;
      clientId = (activeRows.first['client_id'] as String?) ?? id;
      action = 'UPDATE';

      db.execute('''
        UPDATE pregnancy_log
        SET estimated_conception_date = ?, due_date = ?, current_week = ?, is_active = ?, notes = ?, client_updated_at = ?
        WHERE id = ?
      ''', [conceptionStr, dueStr, currentWeek, isActive ? 1 : 0, notes, nowStr, id]);
    } else {
      id = _uuid.v4();
      clientId = _uuid.v4();
      action = 'INSERT';

      db.execute('''
        INSERT INTO pregnancy_log (id, user_id, estimated_conception_date, due_date, current_week, is_active, notes, created_at, client_id, client_updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''', [id, _activeUserId, conceptionStr, dueStr, currentWeek, isActive ? 1 : 0, notes, nowStr, clientId, nowStr]);
    }

    final log = PregnancyLog(
      id: id,
      userId: _activeUserId,
      estimatedConceptionDate: estimatedConceptionDate,
      dueDate: dueDate,
      currentWeek: currentWeek,
      isActive: isActive,
      notes: notes,
      createdAt: now,
      clientId: clientId,
    );

    AppDatabase.enqueueSync(
      tableName: 'pregnancy_log',
      recordId: id,
      action: action,
      payload: log.toMap(),
    );

    return log;
  }

  /// Retrieves the currently active pregnancy log.
  Future<PregnancyLog?> getActivePregnancy() async {
    final db = AppDatabase.instance;
    final rows = db.select('''
      SELECT id, user_id, estimated_conception_date, due_date, current_week, is_active, notes, created_at, client_id
      FROM pregnancy_log
      WHERE user_id = ? AND is_active = 1
      ORDER BY created_at DESC
      LIMIT 1
    ''', [_activeUserId]);

    if (rows.isEmpty) return null;
    return PregnancyLog.fromRow(rows.first);
  }

  // ==========================================
  // FERTILITY AWARENESS (PRENUPCIAL) LAYER
  // ==========================================

  /// Logs or updates natural family planning observations for a specific day.
  Future<FertilityAwarenessLog> logFertilityAwareness({
    required DateTime date,
    String method = 'symptothermal',
    String? fertileWindowStatus,
    bool partnerShared = false,
    String? notes,
  }) async {
    final db = AppDatabase.instance;
    final dateStr = date.toIso8601String().substring(0, 10);
    final now = DateTime.now().toIso8601String();

    final existing = db.select('''
      SELECT id, client_id FROM fertility_awareness_log
      WHERE user_id = ? AND logged_date = ?
      LIMIT 1
    ''', [_activeUserId, dateStr]);

    String id;
    String clientId;
    String action;

    if (existing.isNotEmpty) {
      id = existing.first['id'] as String;
      clientId = (existing.first['client_id'] as String?) ?? id;
      action = 'UPDATE';

      db.execute('''
        UPDATE fertility_awareness_log
        SET method = ?, fertile_window_status = ?, partner_shared = ?, notes = ?, client_updated_at = ?
        WHERE id = ?
      ''', [method, fertileWindowStatus, partnerShared ? 1 : 0, notes, now, id]);
    } else {
      id = _uuid.v4();
      clientId = _uuid.v4();
      action = 'INSERT';

      db.execute('''
        INSERT INTO fertility_awareness_log (id, user_id, logged_date, method, fertile_window_status, partner_shared, notes, client_id, client_updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''', [id, _activeUserId, dateStr, method, fertileWindowStatus, partnerShared ? 1 : 0, notes, clientId, now]);
    }

    final log = FertilityAwarenessLog(
      id: id,
      userId: _activeUserId,
      loggedDate: DateTime.parse(dateStr),
      method: method,
      fertileWindowStatus: fertileWindowStatus,
      partnerShared: partnerShared,
      notes: notes,
      clientId: clientId,
    );

    AppDatabase.enqueueSync(
      tableName: 'fertility_awareness_log',
      recordId: id,
      action: action,
      payload: log.toMap(),
    );

    return log;
  }

  /// Gets all fertility awareness logs for a specific month.
  Future<List<FertilityAwarenessLog>> getFertilityLogsForMonth(DateTime month) async {
    final db = AppDatabase.instance;
    final monthPrefix = '${month.year}-${month.month.toString().padLeft(2, '0')}%';
    final rows = db.select('''
      SELECT id, user_id, logged_date, method, fertile_window_status, partner_shared, notes, client_id
      FROM fertility_awareness_log
      WHERE user_id = ? AND logged_date LIKE ?
      ORDER BY logged_date ASC
    ''', [_activeUserId, monthPrefix]);

    return rows.map((r) => FertilityAwarenessLog.fromRow(r)).toList();
  }

  /// Gets the fertility awareness log for a specific date if exists.
  Future<FertilityAwarenessLog?> getFertilityLogForDate(DateTime date) async {
    final db = AppDatabase.instance;
    final dateStr = date.toIso8601String().substring(0, 10);
    final rows = db.select('''
      SELECT id, user_id, logged_date, method, fertile_window_status, partner_shared, notes, client_id
      FROM fertility_awareness_log
      WHERE user_id = ? AND logged_date = ?
      LIMIT 1
    ''', [_activeUserId, dateStr]);

    if (rows.isEmpty) return null;
    return FertilityAwarenessLog.fromRow(rows.first);
  }

  // ==========================================
  // GRANULAR DAILY SYMPTOMS LAYER
  // ==========================================

  /// Logs or updates granular daily symptoms for a specific day.
  Future<CycleDailySymptoms> logDailySymptoms({
    required DateTime date,
    List<String> symptoms = const [],
    String flowLevel = 'none',
    int crampsLevel = 0,
    String mood = 'calm',
    String? notes,
  }) async {
    final db = AppDatabase.instance;
    final dateStr = date.toIso8601String().substring(0, 10);
    final now = DateTime.now().toIso8601String();
    final symptomsStr = symptoms.join(',');

    final existing = db.select('''
      SELECT id, client_id FROM cycle_symptoms_log
      WHERE user_id = ? AND logged_date = ?
      LIMIT 1
    ''', [_activeUserId, dateStr]);

    String id;
    String clientId;
    String action;

    if (existing.isNotEmpty) {
      id = existing.first['id'] as String;
      clientId = (existing.first['client_id'] as String?) ?? id;
      action = 'UPDATE';

      db.execute('''
        UPDATE cycle_symptoms_log
        SET symptoms = ?, flow_level = ?, cramps_level = ?, mood = ?, notes = ?, client_updated_at = ?
        WHERE id = ?
      ''', [symptomsStr, flowLevel, crampsLevel, mood, notes, now, id]);
    } else {
      id = _uuid.v4();
      clientId = _uuid.v4();
      action = 'INSERT';

      db.execute('''
        INSERT INTO cycle_symptoms_log (id, user_id, logged_date, symptoms, flow_level, cramps_level, mood, notes, client_id, client_updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''', [id, _activeUserId, dateStr, symptomsStr, flowLevel, crampsLevel, mood, notes, clientId, now]);
    }

    final log = CycleDailySymptoms(
      id: id,
      userId: _activeUserId,
      loggedDate: DateTime.parse(dateStr),
      symptoms: symptoms,
      flowLevel: flowLevel,
      crampsLevel: crampsLevel,
      mood: mood,
      notes: notes,
      clientId: clientId,
    );

    AppDatabase.enqueueSync(
      tableName: 'cycle_symptoms_log',
      recordId: id,
      action: action,
      payload: log.toMap(),
    );

    return log;
  }

  /// Gets all daily symptoms logs for a specific month.
  Future<List<CycleDailySymptoms>> getSymptomsForMonth(DateTime month) async {
    final db = AppDatabase.instance;
    final monthPrefix = '${month.year}-${month.month.toString().padLeft(2, '0')}%';
    final rows = db.select('''
      SELECT id, user_id, logged_date, symptoms, flow_level, cramps_level, mood, notes, client_id
      FROM cycle_symptoms_log
      WHERE user_id = ? AND logged_date LIKE ?
      ORDER BY logged_date ASC
    ''', [_activeUserId, monthPrefix]);

    return rows.map((r) => CycleDailySymptoms.fromRow(r)).toList();
  }

  /// Gets daily symptoms for a specific date if exists.
  Future<CycleDailySymptoms?> getDailySymptomsForDate(DateTime date) async {
    final db = AppDatabase.instance;
    final dateStr = date.toIso8601String().substring(0, 10);
    final rows = db.select('''
      SELECT id, user_id, logged_date, symptoms, flow_level, cramps_level, mood, notes, client_id
      FROM cycle_symptoms_log
      WHERE user_id = ? AND logged_date = ?
      LIMIT 1
    ''', [_activeUserId, dateStr]);

    if (rows.isEmpty) return null;
    return CycleDailySymptoms.fromRow(rows.first);
  }
}
