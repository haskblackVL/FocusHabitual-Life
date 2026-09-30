import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/gamification/xp_engine.dart';
import '../../../core/local_db/database.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../domain/prayer_request.dart';
import '../domain/religion_content.dart';

final religionRepositoryProvider = Provider<ReligionRepository>((ref) {
  final user = ref.watch(authControllerProvider).value;
  return ReligionRepository(currentUserId: user?.id);
});

class ReligionRepository {
  ReligionRepository({this.currentUserId});

  final String? currentUserId;
  final _uuid = const Uuid();

  String get _activeUserId => currentUserId ?? 'local_user';

  /// Gets the deterministic devotional passage for a given date.
  Future<DailyDevotional> getDailyPassage({DateTime? date}) async {
    final targetDate = date ?? DateTime.now();
    final db = AppDatabase.instance;

    // Fetch all passages
    final rows = db.select('SELECT * FROM religion_content ORDER BY id ASC');
    if (rows.isEmpty) {
      // Fallback in case seeding is delayed
      return DailyDevotional(
        content: const ReligionContent(
          id: 'rel-prov-16-3',
          verseRef: 'Proverbios 16:3',
          verseText: 'Encomienda al Señor tus obras, y tus pensamientos serán afirmados.',
          reflection: 'La verdadera soberanía interior no nace de la soberbia ni de la ilusión de control absoluto, sino de consagrar la intención y el propósito de cada proyecto a una causa más alta.',
          theme: 'Sabiduría & Liderazgo',
          practicalAction: 'Antes de iniciar tu jornada de trabajo, consagra mentalmente tus prioridades del día.',
        ),
      );
    }

    // Deterministic selection based on day of year
    final startOfYear = DateTime(targetDate.year, 1, 1);
    final dayIndex = targetDate.difference(startOfYear).inDays;
    final selectedRow = rows[dayIndex % rows.length];
    final content = ReligionContent.fromMap(selectedRow);

    // Fetch user log for this content
    final logRows = db.select(
      'SELECT * FROM religion_user_log WHERE content_id = ? AND user_id = ?',
      [content.id, _activeUserId],
    );

    final userLog = logRows.isNotEmpty ? ReligionUserLog.fromMap(logRows.first) : null;

    return DailyDevotional(
      content: content,
      userLog: userLog,
    );
  }

  /// Gets all scripture passages in the wisdom library, optionally filtered by theme or reading path.
  Future<List<ReligionContent>> getAllPassages({String? theme, String? readingPath}) async {
    final db = AppDatabase.instance;
    String query = 'SELECT * FROM religion_content';
    final params = <dynamic>[];

    if (theme != null && readingPath != null) {
      query += ' WHERE theme = ? AND reading_path = ?';
      params.addAll([theme, readingPath]);
    } else if (theme != null) {
      query += ' WHERE theme = ?';
      params.add(theme);
    } else if (readingPath != null) {
      query += ' WHERE reading_path = ?';
      params.add(readingPath);
    }

    query += ' ORDER BY id ASC';
    final rows = db.select(query, params);
    return rows.map((r) => ReligionContent.fromMap(r)).toList();
  }

  /// Saves or updates a devotional reflection journal entry.
  /// Awards +15 XP when completed for the first time.
  Future<ReligionUserLog> saveReflection({
    required String contentId,
    required String notes,
    bool isFavorite = false,
  }) async {
    final db = AppDatabase.instance;
    final now = DateTime.now();
    final nowIso = now.toIso8601String();

    final existingRows = db.select(
      'SELECT * FROM religion_user_log WHERE content_id = ? AND user_id = ?',
      [contentId, _activeUserId],
    );

    if (existingRows.isEmpty) {
      final id = _uuid.v4();
      final clientId = _uuid.v4();

      final newLog = ReligionUserLog(
        id: id,
        userId: _activeUserId,
        contentId: contentId,
        readAt: now,
        reflectionNotes: notes,
        isFavorite: isFavorite,
        createdAt: now,
        clientId: clientId,
        clientUpdatedAt: now,
      );

      db.execute('''
        INSERT INTO religion_user_log (
          id, user_id, content_id, read_at, reflection_notes, is_favorite,
          created_at, client_id, client_updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''', [
        id,
        _activeUserId,
        contentId,
        nowIso,
        notes,
        isFavorite ? 1 : 0,
        nowIso,
        clientId,
        nowIso,
      ]);

      // Award +15 XP for completing daily reflection
      await _adjustXp(XpEngine.devotionalReflectionXp);

      // Enqueue sync
      AppDatabase.enqueueSync(
        tableName: 'religion_user_log',
        recordId: id,
        action: 'INSERT',
        payload: newLog.toMap(),
      );

      return newLog;
    } else {
      final existing = ReligionUserLog.fromMap(existingRows.first);
      final updated = existing.copyWith(
        reflectionNotes: notes,
        isFavorite: isFavorite,
        readAt: now,
        clientUpdatedAt: now,
      );

      db.execute('''
        UPDATE religion_user_log
        SET reflection_notes = ?, is_favorite = ?, read_at = ?, client_updated_at = ?
        WHERE id = ?
      ''', [
        notes,
        isFavorite ? 1 : 0,
        nowIso,
        nowIso,
        existing.id,
      ]);

      AppDatabase.enqueueSync(
        tableName: 'religion_user_log',
        recordId: existing.id,
        action: 'UPDATE',
        payload: updated.toMap(),
      );

      return updated;
    }
  }

  /// Toggles favorite status for a passage.
  Future<bool> toggleFavorite(String contentId) async {
    final db = AppDatabase.instance;
    final now = DateTime.now();
    final nowIso = now.toIso8601String();

    final existingRows = db.select(
      'SELECT * FROM religion_user_log WHERE content_id = ? AND user_id = ?',
      [contentId, _activeUserId],
    );

    if (existingRows.isEmpty) {
      final id = _uuid.v4();
      final clientId = _uuid.v4();

      db.execute('''
        INSERT INTO religion_user_log (
          id, user_id, content_id, read_at, reflection_notes, is_favorite,
          created_at, client_id, client_updated_at
        ) VALUES (?, ?, ?, ?, NULL, 1, ?, ?, ?)
      ''', [
        id,
        _activeUserId,
        contentId,
        nowIso,
        nowIso,
        clientId,
        nowIso,
      ]);

      final payload = {
        'id': id,
        'user_id': _activeUserId,
        'content_id': contentId,
        'read_at': nowIso,
        'reflection_notes': null,
        'is_favorite': 1,
        'created_at': nowIso,
        'client_id': clientId,
        'client_updated_at': nowIso,
      };

      AppDatabase.enqueueSync(
        tableName: 'religion_user_log',
        recordId: id,
        action: 'INSERT',
        payload: payload,
      );

      return true;
    } else {
      final currentFav = (existingRows.first['is_favorite'] as int? ?? 0) == 1;
      final newFav = !currentFav;
      final id = existingRows.first['id'] as String;

      db.execute('''
        UPDATE religion_user_log
        SET is_favorite = ?, client_updated_at = ?
        WHERE id = ?
      ''', [newFav ? 1 : 0, nowIso, id]);

      final payload = Map<String, dynamic>.from(existingRows.first);
      payload['is_favorite'] = newFav ? 1 : 0;
      payload['client_updated_at'] = nowIso;

      AppDatabase.enqueueSync(
        tableName: 'religion_user_log',
        recordId: id,
        action: 'UPDATE',
        payload: payload,
      );

      return newFav;
    }
  }

  /// Gets all prayer requests sorted chronologically.
  Future<List<PrayerRequest>> getPrayerRequests({String? status, String? category}) async {
    final db = AppDatabase.instance;
    String query = 'SELECT * FROM prayer_requests WHERE user_id = ?';
    final params = <dynamic>[_activeUserId];

    if (status != null) {
      query += ' AND status = ?';
      params.add(status);
    }
    if (category != null) {
      query += ' AND category = ?';
      params.add(category);
    }

    query += ' ORDER BY created_at DESC';
    final rows = db.select(query, params);
    return rows.map((r) => PrayerRequest.fromMap(r)).toList();
  }

  /// Creates a new prayer request in the personal spiritual journal.
  /// Awards +10 XP for spiritual intentionality.
  Future<PrayerRequest> createPrayerRequest({
    required String title,
    String? description,
    required String category,
  }) async {
    final db = AppDatabase.instance;
    final now = DateTime.now();
    final nowIso = now.toIso8601String();
    final id = _uuid.v4();
    final clientId = _uuid.v4();

    final prayer = PrayerRequest(
      id: id,
      userId: _activeUserId,
      title: title.trim(),
      description: description?.trim().isEmpty == true ? null : description?.trim(),
      category: category,
      status: 'active',
      createdAt: now,
      clientId: clientId,
      clientUpdatedAt: now,
    );

    db.execute('''
      INSERT INTO prayer_requests (
        id, user_id, title, description, category, status,
        answered_at, answer_notes, created_at, client_id, client_updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, NULL, NULL, ?, ?, ?)
    ''', [
      id,
      _activeUserId,
      prayer.title,
      prayer.description,
      prayer.category,
      prayer.status,
      nowIso,
      clientId,
      nowIso,
    ]);

    // Award +10 XP for spiritual discipline
    await _adjustXp(XpEngine.prayerRecordXp);

    // Enqueue sync
    AppDatabase.enqueueSync(
      tableName: 'prayer_requests',
      recordId: id,
      action: 'INSERT',
      payload: prayer.toMap(),
    );

    return prayer;
  }

  /// Marks a prayer request as answered with testimony notes.
  Future<PrayerRequest> markPrayerAnswered({
    required String id,
    required String answerNotes,
  }) async {
    final db = AppDatabase.instance;
    final now = DateTime.now();
    final nowIso = now.toIso8601String();

    final rows = db.select('SELECT * FROM prayer_requests WHERE id = ? AND user_id = ?', [id, _activeUserId]);
    if (rows.isEmpty) {
      throw StateError('Prayer request not found: $id');
    }

    final existing = PrayerRequest.fromMap(rows.first);
    final updated = existing.copyWith(
      status: 'answered',
      answeredAt: now,
      answerNotes: answerNotes.trim(),
      clientUpdatedAt: now,
    );

    db.execute('''
      UPDATE prayer_requests
      SET status = 'answered', answered_at = ?, answer_notes = ?, client_updated_at = ?
      WHERE id = ? AND user_id = ?
    ''', [nowIso, updated.answerNotes, nowIso, id, _activeUserId]);

    AppDatabase.enqueueSync(
      tableName: 'prayer_requests',
      recordId: id,
      action: 'UPDATE',
      payload: updated.toMap(),
    );

    return updated;
  }

  /// Deletes a prayer request.
  Future<void> deletePrayerRequest(String id) async {
    final db = AppDatabase.instance;
    db.execute('DELETE FROM prayer_requests WHERE id = ? AND user_id = ?', [id, _activeUserId]);

    AppDatabase.enqueueSync(
      tableName: 'prayer_requests',
      recordId: id,
      action: 'DELETE',
      payload: {'id': id},
    );
  }

  /// Returns aggregated spiritual metrics.
  Future<Map<String, int>> getSpiritualStats() async {
    final db = AppDatabase.instance;

    int reflectionsCount = 0;
    int favoritesCount = 0;
    try {
      final logRows = db.select(
        "SELECT count(*) as count FROM religion_user_log WHERE user_id = ? AND (reflection_notes IS NOT NULL OR read_at IS NOT NULL)",
        [_activeUserId],
      );
      reflectionsCount = logRows.first['count'] as int;

      final favRows = db.select(
        "SELECT count(*) as count FROM religion_user_log WHERE user_id = ? AND is_favorite = 1",
        [_activeUserId],
      );
      favoritesCount = favRows.first['count'] as int;
    } catch (_) {}

    int activePrayersCount = 0;
    int answeredPrayersCount = 0;
    try {
      final activeRows = db.select(
        "SELECT count(*) as count FROM prayer_requests WHERE user_id = ? AND status = 'active'",
        [_activeUserId],
      );
      activePrayersCount = activeRows.first['count'] as int;

      final answeredRows = db.select(
        "SELECT count(*) as count FROM prayer_requests WHERE user_id = ? AND status = 'answered'",
        [_activeUserId],
      );
      answeredPrayersCount = answeredRows.first['count'] as int;
    } catch (_) {}

    return {
      'reflectionsCount': reflectionsCount,
      'activePrayersCount': activePrayersCount,
      'answeredPrayersCount': answeredPrayersCount,
      'favoritesCount': favoritesCount,
    };
  }

  /// Adjusts user XP and recalculates level.
  Future<void> _adjustXp(int amount) async {
    final db = AppDatabase.instance;
    final now = DateTime.now().toIso8601String();
    final row = db.select("SELECT total_xp FROM user_xp WHERE user_id = ?", [_activeUserId]);
    final currentXp = row.isNotEmpty ? (row.first['total_xp'] as int? ?? 0) : 0;
    final newXp = (currentXp + amount).clamp(0, 9999999);
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
}
