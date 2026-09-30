import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/gamification/xp_engine.dart';
import '../../../core/local_db/database.dart';
import '../domain/gratitude_model.dart';

/// Repository for managing daily gratitude and stoic reflection records.
class GratitudeRepository {
  GratitudeRepository({this.currentUserId});

  final String? currentUserId;
  static const _uuid = Uuid();

  String get _activeUserId => currentUserId ?? 'local_user';

  static String formatEntryDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// Retrieves today's gratitude entry if one already exists.
  Future<GratitudeEntry?> getTodayEntry() async {
    final todayStr = formatEntryDate(DateTime.now());
    return getEntryByDate(todayStr);
  }

  /// Retrieves entry by date string (YYYY-MM-DD).
  Future<GratitudeEntry?> getEntryByDate(String dateStr) async {
    final db = AppDatabase.instance;
    final results = db.select('''
      SELECT * FROM gratitude_entries
      WHERE user_id = ? AND entry_date = ?
      LIMIT 1
    ''', [_activeUserId, dateStr]);

    if (results.isEmpty) return null;
    return GratitudeEntry.fromRow(results.first);
  }

  /// Saves or updates today's gratitude entry and enqueues cloud sync.
  Future<GratitudeEntry> saveEntry({
    required String item1,
    String? item2,
    String? item3,
    String? reflection,
    String? promptUsed,
    DateTime? targetDate,
  }) async {
    final db = AppDatabase.instance;
    final date = targetDate ?? DateTime.now();
    final dateStr = formatEntryDate(date);
    final now = DateTime.now();
    final nowStr = now.toIso8601String();

    final existing = await getEntryByDate(dateStr);
    final id = existing?.id ?? _uuid.v4();
    final clientId = existing?.clientId ?? 'gratitude_${_activeUserId}_$dateStr';

    final entry = GratitudeEntry(
      id: id,
      userId: _activeUserId,
      entryDate: dateStr,
      item1: item1.trim(),
      item2: item2?.trim(),
      item3: item3?.trim(),
      reflection: reflection?.trim(),
      promptUsed: promptUsed,
      createdAt: existing?.createdAt ?? now,
      clientId: clientId,
      clientUpdatedAt: now,
    );

    db.execute('''
      INSERT INTO gratitude_entries (
        id, user_id, entry_date, item1, item2, item3,
        reflection, prompt_used, created_at, client_id, client_updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        item1 = excluded.item1,
        item2 = excluded.item2,
        item3 = excluded.item3,
        reflection = excluded.reflection,
        prompt_used = excluded.prompt_used,
        client_updated_at = excluded.client_updated_at
    ''', [
      entry.id,
      entry.userId,
      entry.entryDate,
      entry.item1,
      entry.item2,
      entry.item3,
      entry.reflection,
      entry.promptUsed,
      entry.createdAt.toIso8601String(),
      entry.clientId,
      nowStr,
    ]);

    // Enqueue cloud sync with payload matching Supabase schema.sql
    AppDatabase.enqueueSync(
      tableName: 'gratitude_entries',
      recordId: id,
      action: existing == null ? 'INSERT' : 'UPDATE',
      payload: {
        'id': id,
        'user_id': _activeUserId,
        'entry_date': dateStr,
        'content': entry.combinedContent,
        'prompt_used': promptUsed,
        'created_at': entry.createdAt.toIso8601String(),
      },
    );

    // Award +15 XP for new reflection
    if (existing == null) {
      await _adjustXp(15);
    }

    return entry;
  }

  /// Retrieves recent gratitude entries for the history timeline.
  Future<List<GratitudeEntry>> getGratitudeHistory({int limit = 30}) async {
    final db = AppDatabase.instance;
    final results = db.select('''
      SELECT * FROM gratitude_entries
      WHERE user_id = ?
      ORDER BY entry_date DESC
      LIMIT ?
    ''', [_activeUserId, limit]);

    return results.map(GratitudeEntry.fromRow).toList();
  }

  /// Calculates the streak of consecutive days with recorded gratitude.
  Future<int> getGratitudeStreak() async {
    final history = await getGratitudeHistory(limit: 60);
    if (history.isEmpty) return 0;

    final datesSet = history.map((e) => e.entryDate).toSet();
    final now = DateTime.now();

    var streak = 0;
    var checkDate = DateTime(now.year, now.month, now.day);

    // If today is not yet logged, check if yesterday was logged to keep the streak alive
    final todayStr = formatEntryDate(checkDate);
    if (!datesSet.contains(todayStr)) {
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    while (datesSet.contains(formatEntryDate(checkDate))) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  /// Adjusts user XP and recalculates level.
  Future<void> _adjustXp(int amount) async {
    final db = AppDatabase.instance;
    final now = DateTime.now().toIso8601String();
    final row = db.select('SELECT total_xp FROM user_xp WHERE user_id = ?', [_activeUserId]);
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
