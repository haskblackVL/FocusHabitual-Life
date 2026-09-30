import 'package:uuid/uuid.dart';
import '../../../core/gamification/xp_engine.dart';
import '../../../core/local_db/database.dart';
import '../domain/nofap_models.dart';

/// SQLite Data Access for self-mastery & NoFap logs with offline sync.
class NofapRepository {
  NofapRepository({this.currentUserId});

  final String? currentUserId;
  static const _uuid = Uuid();

  String get _activeUserId => currentUserId ?? 'local_user';

  /// Gets the start timestamp of the current streak.
  Future<DateTime> getCurrentStreakStart() async {
    final db = AppDatabase.instance;

    // Check for last relapse
    final relapseRows = db.select('''
      SELECT occurred_at FROM nofap_log
      WHERE user_id = ? AND event_type = 'relapse'
      ORDER BY occurred_at DESC
      LIMIT 1
    ''', [_activeUserId]);

    if (relapseRows.isNotEmpty) {
      return DateTime.parse(relapseRows.first['occurred_at'] as String);
    }

    // If no relapse, find earliest checkin
    final checkinRows = db.select('''
      SELECT occurred_at FROM nofap_log
      WHERE user_id = ?
      ORDER BY occurred_at ASC
      LIMIT 1
    ''', [_activeUserId]);

    if (checkinRows.isNotEmpty) {
      return DateTime.parse(checkinRows.first['occurred_at'] as String);
    }

    // Fallback: seed now
    final now = DateTime.now();
    final nowIso = now.toIso8601String();
    final clientId = _uuid.v4();
    final logId = _uuid.v4();

    db.execute('''
      INSERT INTO nofap_log (id, user_id, event_type, occurred_at, client_id)
      VALUES (?, ?, 'checkin', ?, ?)
    ''', [logId, _activeUserId, nowIso, clientId]);

    AppDatabase.enqueueSync(
      tableName: 'nofap_log',
      recordId: logId,
      action: 'INSERT',
      payload: {
        'id': logId,
        'user_id': _activeUserId,
        'event_type': 'checkin',
        'occurred_at': nowIso,
        'client_id': clientId,
      },
    );

    return now;
  }

  /// Returns the total count of relapses recorded.
  Future<int> getTotalRelapses() async {
    final db = AppDatabase.instance;
    final rows = db.select('''
      SELECT count(*) as count FROM nofap_log WHERE user_id = ? AND event_type = 'relapse'
    ''', [_activeUserId]);
    if (rows.isEmpty) return 0;
    return (rows.first['count'] as int?) ?? 0;
  }

  /// Returns historical relapse events ordered by date descending.
  Future<List<NofapRelapseItem>> getRelapseHistory() async {
    final db = AppDatabase.instance;
    final rows = db.select('''
      SELECT id, occurred_at, relapse_reason, note, client_id
      FROM nofap_log
      WHERE user_id = ? AND event_type = 'relapse'
      ORDER BY occurred_at DESC
      LIMIT 25
    ''', [_activeUserId]);
    return rows.map((r) => NofapRelapseItem.fromRow(r)).toList();
  }

  /// Returns the active reasons saved by the user.
  Future<List<NofapReason>> getReasons() async {
    final db = AppDatabase.instance;
    final rows = db.select('''
      SELECT id, reason_text, created_at, is_active 
      FROM nofap_reasons 
      WHERE user_id = ? AND is_active = 1
      ORDER BY created_at ASC
    ''', [_activeUserId]);
    return rows.map((r) => NofapReason.fromRow(r)).toList();
  }

  /// Adds a new personal reason for self-mastery.
  Future<NofapReason> addReason(String text) async {
    final db = AppDatabase.instance;
    final id = _uuid.v4();
    final now = DateTime.now();
    final nowIso = now.toIso8601String();

    db.execute('''
      INSERT INTO nofap_reasons (id, user_id, reason_text, created_at, is_active)
      VALUES (?, ?, ?, ?, 1)
    ''', [id, _activeUserId, text.trim(), nowIso]);

    AppDatabase.enqueueSync(
      tableName: 'nofap_reasons',
      recordId: id,
      action: 'INSERT',
      payload: {
        'id': id,
        'user_id': _activeUserId,
        'reason_text': text.trim(),
        'created_at': nowIso,
        'is_active': true,
      },
    );

    return NofapReason(
      id: id,
      reasonText: text.trim(),
      createdAt: now,
      isActive: true,
    );
  }

  /// Deactivates or removes a reason.
  Future<void> deleteReason(String id) async {
    final db = AppDatabase.instance;
    db.execute('DELETE FROM nofap_reasons WHERE id = ? AND user_id = ?', [id, _activeUserId]);

    AppDatabase.enqueueSync(
      tableName: 'nofap_reasons',
      recordId: id,
      action: 'DELETE',
      payload: {'id': id},
    );
  }

  /// Records a relapse event, immediately resetting the streak to [now].
  Future<DateTime> recordRelapse({String? reason, String? trigger, String? note}) async {
    final db = AppDatabase.instance;
    final now = DateTime.now();
    final nowIso = now.toIso8601String();
    final logId = _uuid.v4();
    final clientId = _uuid.v4();

    final fullNote = trigger != null && trigger.isNotEmpty
        ? (note != null && note.isNotEmpty ? '[$trigger] $note' : 'Disparador: $trigger')
        : note;

    db.execute('''
      INSERT INTO nofap_log (id, user_id, event_type, occurred_at, relapse_reason, note, client_id)
      VALUES (?, ?, 'relapse', ?, ?, ?, ?)
    ''', [logId, _activeUserId, nowIso, reason, fullNote, clientId]);

    AppDatabase.enqueueSync(
      tableName: 'nofap_log',
      recordId: logId,
      action: 'INSERT',
      payload: {
        'id': logId,
        'user_id': _activeUserId,
        'event_type': 'relapse',
        'occurred_at': nowIso,
        'relapse_reason': reason,
        'note': fullNote,
        'client_id': clientId,
      },
    );

    return now;
  }

  /// Records successful checkin / impulse overcome (+15 XP).
  Future<void> recordCheckin({String? note}) async {
    final db = AppDatabase.instance;
    final now = DateTime.now().toIso8601String();
    final logId = _uuid.v4();
    final clientId = _uuid.v4();

    db.execute('''
      INSERT INTO nofap_log (id, user_id, event_type, occurred_at, note, client_id)
      VALUES (?, ?, 'checkin', ?, ?, ?)
    ''', [logId, _activeUserId, now, note ?? 'Impulso superado con éxito', clientId]);

    AppDatabase.enqueueSync(
      tableName: 'nofap_log',
      recordId: logId,
      action: 'INSERT',
      payload: {
        'id': logId,
        'user_id': _activeUserId,
        'event_type': 'checkin',
        'occurred_at': now,
        'note': note ?? 'Impulso superado con éxito',
        'client_id': clientId,
      },
    );

    // Credit +15 XP
    final xpRow = db.select('SELECT total_xp FROM user_xp WHERE user_id = ?', [_activeUserId]);
    final currentXp = xpRow.isNotEmpty ? (xpRow.first['total_xp'] as int) : 0;
    final newXp = currentXp + 15;
    final newLevel = XpEngine.calculateLevel(newXp);

    db.execute('''
      INSERT INTO user_xp (user_id, total_xp, level, updated_at)
      VALUES (?, ?, ?, ?)
      ON CONFLICT(user_id) DO UPDATE SET
        total_xp = excluded.total_xp,
        level = excluded.level,
        updated_at = excluded.updated_at
    ''', [_activeUserId, newXp, newLevel, now]);
  }

  /// Records successful completion of the emergency cooling protocol (+15 XP).
  Future<void> recordCoolingSessionCompleted() async {
    await recordCheckin(note: 'Protocolo SOS de enfriamiento completado');
  }
}
