import 'package:uuid/uuid.dart';
import '../../../core/gamification/xp_engine.dart';
import '../../../core/local_db/database.dart';
import '../domain/habit.dart';

/// Repository interface and SQLite implementation for Habits.
class HabitRepository {
  HabitRepository();

  static const _uuid = Uuid();

  /// Retrieves all active habits along with today's completion and streak count.
  Future<List<HabitWithStatus>> getHabitsWithStatus() async {
    final db = AppDatabase.instance;
    final today = DateTime.now().toIso8601String().substring(0, 10);

    final habitRows = db.select('''
      SELECT * FROM habits 
      WHERE is_active = 1 AND deleted_at IS NULL
      ORDER BY created_at ASC
    ''');

    final List<HabitWithStatus> result = [];

    for (final row in habitRows) {
      final habitId = row['id'] as String;

      final habit = Habit(
        id: habitId,
        title: row['title'] as String,
        description: row['description'] as String?,
        category: HabitCategory.fromDb(row['category'] as String),
        frequency: row['frequency'] as String,
        targetCount: row['target_count'] as int,
        isActive: (row['is_active'] as int) == 1,
        startDate: DateTime.parse(row['start_date'] as String),
        endDate: row['end_date'] != null ? DateTime.tryParse(row['end_date'] as String) : null,
        createdAt: DateTime.parse(row['created_at'] as String),
      );

      // Check if logged today
      final logsToday = db.select('''
        SELECT count(*) as count FROM habit_logs
        WHERE habit_id = ? AND completed_at LIKE ?
      ''', [habitId, '$today%']);
      final countToday = logsToday.first['count'] as int;

      // Calculate streak: total distinct days logged recently
      final streakRows = db.select('''
        SELECT count(DISTINCT substr(completed_at, 1, 10)) as streak
        FROM habit_logs
        WHERE habit_id = ?
      ''', [habitId]);
      final streakCount = streakRows.first['streak'] as int;

      result.add(
        HabitWithStatus(
          habit: habit,
          isCompletedToday: countToday > 0,
          completedTimesToday: countToday,
          streakCount: streakCount > 0 ? streakCount : (countToday > 0 ? 1 : 0),
        ),
      );
    }

    return result;
  }

  /// Toggles today's completion of a habit.
  /// If completing, adds a log entry and credits +10 XP.
  /// If uncompleting, removes today's log and reverts XP.
  Future<bool> toggleHabitCompletion(String habitId) async {
    final db = AppDatabase.instance;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final now = DateTime.now().toIso8601String();

    final existing = db.select('''
      SELECT id FROM habit_logs 
      WHERE habit_id = ? AND completed_at LIKE ?
    ''', [habitId, '$today%']);

    if (existing.isNotEmpty) {
      // Untoggle: remove log and subtract XP
      final logId = existing.first['id'] as String;
      db.execute('DELETE FROM habit_logs WHERE id = ?', [logId]);
      await _adjustXp(-XpEngine.habitXp);
      return false;
    } else {
      // Toggle complete: insert log and add XP
      final logId = _uuid.v4();
      final clientId = _uuid.v4();
      db.execute('''
        INSERT INTO habit_logs (id, habit_id, completed_at, xp_earned, client_id)
        VALUES (?, ?, ?, ?, ?)
      ''', [logId, habitId, now, XpEngine.habitXp, clientId]);
      await _adjustXp(XpEngine.habitXp);
      return true;
    }
  }

  /// Adds a new habit to the database.
  Future<void> addHabit({
    required String title,
    String? description,
    HabitCategory category = HabitCategory.general,
    String frequency = 'daily',
    int targetCount = 1,
  }) async {
    final db = AppDatabase.instance;
    final now = DateTime.now().toIso8601String();
    final today = now.substring(0, 10);
    final id = _uuid.v4();

    db.execute('''
      INSERT INTO habits (id, title, description, category, frequency, target_count, start_date, created_at, updated_at, client_updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', [
      id,
      title,
      description,
      category.dbValue,
      frequency,
      targetCount,
      today,
      now,
      now,
      now,
    ]);
  }

  /// Deletes a habit (soft delete).
  Future<void> deleteHabit(String habitId) async {
    final db = AppDatabase.instance;
    final now = DateTime.now().toIso8601String();
    db.execute('''
      UPDATE habits SET is_active = 0, deleted_at = ? WHERE id = ?
    ''', [now, habitId]);
  }

  /// Retrieves current user total XP.
  Future<int> getUserXp() async {
    final db = AppDatabase.instance;
    final rows = db.select('SELECT total_xp FROM user_xp WHERE user_id = ?', ['local_user']);
    if (rows.isEmpty) return 0;
    return rows.first['total_xp'] as int;
  }

  /// Records a completed Pomodoro session (+25 XP).
  Future<void> recordPomodoroSession({
    required int durationMinutes,
    String? taskTag,
  }) async {
    final db = AppDatabase.instance;
    final now = DateTime.now().toIso8601String();
    final id = _uuid.v4();

    db.execute('''
      INSERT INTO pomodoro_sessions (id, user_id, duration_minutes, task_tag, started_at, completed_at, was_completed, client_updated_at)
      VALUES (?, 'local_user', ?, ?, ?, ?, 1, ?)
    ''', [id, durationMinutes, taskTag ?? 'General', now, now, now]);

    await _adjustXp(XpEngine.pomodoroXp);
  }

  /// Adjusts user XP and recalculates level.
  Future<void> _adjustXp(int amount) async {
    final db = AppDatabase.instance;
    final now = DateTime.now().toIso8601String();

    final currentXp = await getUserXp();
    final newXp = (currentXp + amount).clamp(0, 9999999);
    final newLevel = XpEngine.calculateLevel(newXp);

    db.execute('''
      UPDATE user_xp 
      SET total_xp = ?, level = ?, updated_at = ?
      WHERE user_id = 'local_user'
    ''', [newXp, newLevel, now]);
  }
}
