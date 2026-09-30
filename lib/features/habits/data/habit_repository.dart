import 'package:uuid/uuid.dart';
import '../../../core/gamification/xp_engine.dart';
import '../../../core/local_db/database.dart';
import '../domain/challenge_21_data.dart';
import '../domain/habit.dart';

/// Repository interface and SQLite implementation for Habits.
class HabitRepository {
  HabitRepository({this.currentUserId});

  final String? currentUserId;
  static const _uuid = Uuid();

  String get _activeUserId => currentUserId ?? 'local_user';

  /// Retrieves all active habits along with today's completion and streak count.
  Future<List<HabitWithStatus>> getHabitsWithStatus() async {
    final db = AppDatabase.instance;
    final today = DateTime.now().toIso8601String().substring(0, 10);

    var habitRows = db.select('''
      SELECT * FROM habits 
      WHERE user_id = ? AND is_active = 1 AND deleted_at IS NULL
      ORDER BY created_at ASC
    ''', [_activeUserId]);

    // For new registered users, counts and habits start at 0.
    // Starter habits are only seeded for local guest mode ('local_user').
    if (habitRows.isEmpty && _activeUserId == 'local_user') {
      _seedStarterHabitsForUser(db, _activeUserId);
      habitRows = db.select('''
        SELECT * FROM habits 
        WHERE user_id = ? AND is_active = 1 AND deleted_at IS NULL
        ORDER BY created_at ASC
      ''', [_activeUserId]);
    }

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

      // Check if logged today for THIS user
      final logsToday = db.select('''
        SELECT count(*) as count FROM habit_logs
        WHERE habit_id = ? AND user_id = ? AND completed_at LIKE ?
      ''', [habitId, _activeUserId, '$today%']);
      final countToday = logsToday.first['count'] as int;

      // Calculate streak: total distinct days logged recently by THIS user
      final streakRows = db.select('''
        SELECT count(DISTINCT substr(completed_at, 1, 10)) as streak
        FROM habit_logs
        WHERE habit_id = ? AND user_id = ?
      ''', [habitId, _activeUserId]);
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

  void _seedStarterHabitsForUser(dynamic db, String userId) {
    final now = DateTime.now().toIso8601String();
    final today = now.substring(0, 10);
    final starterHabits = [
      {
        'title': 'Despertar a las 5:00 AM',
        'description': 'Construcción del bloque dorado matutino de alta productividad.',
        'category': 'checklist_am',
        'frequency': 'daily',
        'target_count': 1,
      },
      {
        'title': 'Hidratación Matutina (500 ml)',
        'description': 'Reactiva el metabolismo y favorece la claridad mental al despertar.',
        'category': 'checklist_am',
        'frequency': 'daily',
        'target_count': 1,
      },
      {
        'title': 'Lectura Estratégica (20 min)',
        'description': 'Lectura de biografías, modelos mentales o filosofía estoica.',
        'category': 'general',
        'frequency': 'daily',
        'target_count': 1,
      },
      {
        'title': 'Deep Work sin distracciones',
        'description': 'Bloque ininterrumpido de 90 minutos para avance prioritario.',
        'category': 'general',
        'frequency': 'daily',
        'target_count': 1,
      },
      {
        'title': 'Revisión y Cierre del Día',
        'description': 'Auditoría de hábitos ejecutados, gratitud y preparación del día siguiente.',
        'category': 'checklist_pm',
        'frequency': 'daily',
        'target_count': 1,
      },
    ];

    for (final h in starterHabits) {
      final id = _uuid.v4();
      db.execute('''
        INSERT INTO habits (id, user_id, title, description, category, frequency, target_count, start_date, created_at, updated_at, client_updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''', [
        id,
        userId,
        h['title'],
        h['description'],
        h['category'],
        h['frequency'],
        h['target_count'],
        today,
        now,
        now,
        now,
      ]);
    }
  }

  /// Retrieves the active 21-Day Challenge state and its 7-day week progress nodes.
  Future<Challenge21Data?> getChallenge21Data() async {
    final db = AppDatabase.instance;
    final now = DateTime.now();
    final todayStr = now.toIso8601String().substring(0, 10);
    final todayDate = DateTime(now.year, now.month, now.day);

    final habitRows = db.select('''
      SELECT * FROM habits 
      WHERE user_id = ? AND category = 'challenge_21' AND is_active = 1 AND deleted_at IS NULL
      ORDER BY created_at DESC
      LIMIT 1
    ''', [_activeUserId]);

    if (habitRows.isEmpty) return null;

    final row = habitRows.first;
    final habitId = row['id'] as String;
    final startDate = DateTime.parse(row['start_date'] as String);
    final habit = Habit(
      id: habitId,
      title: row['title'] as String,
      description: row['description'] as String?,
      category: HabitCategory.challenge21,
      frequency: row['frequency'] as String,
      targetCount: row['target_count'] as int,
      isActive: true,
      startDate: startDate,
      endDate: row['end_date'] != null ? DateTime.tryParse(row['end_date'] as String) : null,
      createdAt: DateTime.parse(row['created_at'] as String),
    );

    // Get all completed dates for this challenge by THIS user
    final logRows = db.select('''
      SELECT DISTINCT substr(completed_at, 1, 10) as log_date 
      FROM habit_logs 
      WHERE habit_id = ? AND user_id = ?
    ''', [habitId, _activeUserId]);
    final completedDates = logRows.map((r) => r['log_date'] as String).toSet();

    // Current day number in the challenge (1-based from start date)
    final diffDays = todayDate.difference(DateTime(startDate.year, startDate.month, startDate.day)).inDays;
    final currentDayNumber = (diffDays + 1).clamp(1, 21);

    // Calculate current week nodes (Monday to Sunday)
    final currentWeekday = now.weekday; // 1 = Mon, ..., 7 = Sun
    final monday = todayDate.subtract(Duration(days: currentWeekday - 1));
    final labels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

    final List<ChallengeDayNode> weekNodes = [];
    for (int i = 0; i < 7; i++) {
      final nodeDate = monday.add(Duration(days: i));
      final nodeDateStr = nodeDate.toIso8601String().substring(0, 10);
      final isDone = completedDates.contains(nodeDateStr);
      final isToday = (i + 1 == currentWeekday);
      final isPast = nodeDate.isBefore(todayDate);
      final isFuture = nodeDate.isAfter(todayDate);

      final nodeChallengeDay = nodeDate.difference(DateTime(startDate.year, startDate.month, startDate.day)).inDays + 1;

      weekNodes.add(
        ChallengeDayNode(
          dayLabel: labels[i],
          date: nodeDate,
          challengeDayNumber: (nodeChallengeDay >= 1 && nodeChallengeDay <= 21) ? nodeChallengeDay : null,
          isDone: isDone,
          isToday: isToday,
          isPast: isPast,
          isFuture: isFuture,
        ),
      );
    }

    final isCompletedToday = completedDates.contains(todayStr);

    // Consecutive streak for THIS user
    final streakRows = db.select('''
      SELECT count(DISTINCT substr(completed_at, 1, 10)) as streak
      FROM habit_logs
      WHERE habit_id = ? AND user_id = ?
    ''', [habitId, _activeUserId]);
    final streakCount = streakRows.first['streak'] as int;

    return Challenge21Data(
      habit: habit,
      isCompletedToday: isCompletedToday,
      currentDayNumber: currentDayNumber,
      totalDaysCompleted: completedDates.length,
      streakCount: streakCount > 0 ? streakCount : (isCompletedToday ? 1 : 0),
      weekNodes: weekNodes,
    );
  }

  /// Toggles today's completion of a habit for this user.
  /// If completing, adds a log entry and credits +10 XP.
  /// If uncompleting, removes today's log and reverts XP.
  Future<bool> toggleHabitCompletion(String habitId) async {
    final db = AppDatabase.instance;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final now = DateTime.now().toIso8601String();

    final existing = db.select('''
      SELECT id FROM habit_logs 
      WHERE habit_id = ? AND user_id = ? AND completed_at LIKE ?
    ''', [habitId, _activeUserId, '$today%']);

    if (existing.isNotEmpty) {
      // Untoggle: remove log and subtract XP
      final logId = existing.first['id'] as String;
      db.execute('DELETE FROM habit_logs WHERE id = ? AND user_id = ?', [logId, _activeUserId]);
      AppDatabase.enqueueSync(
        tableName: 'habit_logs',
        recordId: logId,
        action: 'DELETE',
        payload: {'id': logId, 'user_id': _activeUserId},
      );
      await _adjustXp(-XpEngine.habitXp);
      return false;
    } else {
      // Toggle complete: insert log and add XP
      final logId = _uuid.v4();
      final clientId = _uuid.v4();
      db.execute('''
        INSERT INTO habit_logs (id, habit_id, user_id, completed_at, xp_earned, client_id)
        VALUES (?, ?, ?, ?, ?, ?)
      ''', [logId, habitId, _activeUserId, now, XpEngine.habitXp, clientId]);
      AppDatabase.enqueueSync(
        tableName: 'habit_logs',
        recordId: logId,
        action: 'INSERT',
        payload: {
          'id': logId,
          'habit_id': habitId,
          'user_id': _activeUserId,
          'completed_at': now,
          'xp_earned': XpEngine.habitXp,
          'client_id': clientId,
        },
      );
      await _adjustXp(XpEngine.habitXp);
      return true;
    }
  }

  /// Adds a new habit to the database owned by this user.
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
      INSERT INTO habits (id, user_id, title, description, category, frequency, target_count, start_date, created_at, updated_at, client_updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', [
      id,
      _activeUserId,
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

    AppDatabase.enqueueSync(
      tableName: 'habits',
      recordId: id,
      action: 'INSERT',
      payload: {
        'id': id,
        'user_id': _activeUserId,
        'title': title,
        'description': description,
        'category': category.dbValue,
        'frequency': frequency,
        'target_count': targetCount,
        'start_date': today,
        'created_at': now,
        'updated_at': now,
        'client_updated_at': now,
      },
    );
  }

  /// Deletes a habit (soft delete) ensuring user ownership.
  Future<void> deleteHabit(String habitId) async {
    final db = AppDatabase.instance;
    final now = DateTime.now().toIso8601String();
    db.execute('''
      UPDATE habits SET is_active = 0, deleted_at = ? WHERE id = ? AND user_id = ?
    ''', [now, habitId, _activeUserId]);

    AppDatabase.enqueueSync(
      tableName: 'habits',
      recordId: habitId,
      action: 'UPDATE',
      payload: {
        'id': habitId,
        'user_id': _activeUserId,
        'is_active': 0,
        'deleted_at': now,
        'updated_at': now,
        'client_updated_at': now,
      },
    );
  }

  /// Retrieves current user total XP.
  Future<int> getUserXp() async {
    final db = AppDatabase.instance;
    final rows = db.select('SELECT total_xp FROM user_xp WHERE user_id = ?', [_activeUserId]);
    if (rows.isEmpty) return 0;
    return rows.first['total_xp'] as int;
  }

  /// Records a completed Pomodoro session (shallow work: +25 XP, deep work: +38 XP) for this user.
  Future<int> recordPomodoroSession({
    required int durationMinutes,
    String? taskTag,
    String modeKey = 'classic',
    String workType = 'shallow_work',
    String? taskObjective,
    int notesCount = 0,
    bool dndTriggered = false,
    String? sessionId,
  }) async {
    final db = AppDatabase.instance;
    final now = DateTime.now().toIso8601String();
    final id = sessionId ?? _uuid.v4();
    final xpEarned = workType == 'deep_work'
        ? XpEngine.deepWorkPomodoroXp
        : XpEngine.pomodoroXp;

    db.execute('''
      INSERT INTO pomodoro_sessions (
        id, user_id, duration_minutes, task_tag, started_at, completed_at,
        was_completed, mode_key, work_type, task_objective, notes_count,
        dnd_triggered, client_updated_at
      )
      VALUES (?, ?, ?, ?, ?, ?, 1, ?, ?, ?, ?, ?, ?)
    ''', [
      id,
      _activeUserId,
      durationMinutes,
      taskTag ?? 'General',
      now,
      now,
      modeKey,
      workType,
      taskObjective,
      notesCount,
      dndTriggered ? 1 : 0,
      now,
    ]);

    AppDatabase.enqueueSync(
      tableName: 'pomodoro_sessions',
      recordId: id,
      action: 'INSERT',
      payload: {
        'id': id,
        'user_id': _activeUserId,
        'duration_minutes': durationMinutes,
        'task_tag': taskTag ?? 'General',
        'started_at': now,
        'completed_at': now,
        'was_completed': 1,
        'mode_key': modeKey,
        'work_type': workType,
        'task_objective': taskObjective,
        'notes_count': notesCount,
        'dnd_triggered': dndTriggered ? 1 : 0,
        'client_updated_at': now,
      },
    );

    await _adjustXp(xpEarned);
    return xpEarned;
  }

  /// Saves an interruption note captured during an active Pomodoro session.
  Future<String> saveInterruptionNote({
    required String sessionId,
    required String noteText,
  }) async {
    final noteId = _uuid.v4();
    final now = DateTime.now();
    AppDatabase.saveInterruptionNote(
      id: noteId,
      sessionId: sessionId,
      userId: _activeUserId,
      noteText: noteText,
      capturedAt: now,
    );
    return noteId;
  }

  /// Retrieves notes captured during a specific session.
  List<Map<String, dynamic>> getInterruptionNotes(String sessionId) {
    return AppDatabase.getInterruptionNotesForSession(sessionId);
  }

  /// Converts a captured interruption note into a permanent habit or task.
  Future<String> convertInterruptionNoteToHabit({
    required String noteId,
    required String title,
    String category = 'general',
  }) async {
    final habitId = _uuid.v4();
    final now = DateTime.now().toIso8601String();
    final db = AppDatabase.instance;

    db.execute('''
      INSERT INTO habits (id, user_id, title, description, category, frequency, target_count, start_date, created_at, updated_at, client_updated_at)
      VALUES (?, ?, ?, 'Convertido desde Bloc de Descarga Pomodoro', ?, 'daily', 1, ?, ?, ?, ?)
    ''', [habitId, _activeUserId, title, category, now, now, now, now]);

    AppDatabase.enqueueSync(
      tableName: 'habits',
      recordId: habitId,
      action: 'INSERT',
      payload: {
        'id': habitId,
        'user_id': _activeUserId,
        'title': title,
        'category': category,
        'frequency': 'daily',
        'target_count': 1,
        'created_at': now,
      },
    );

    AppDatabase.markInterruptionNoteConverted(noteId, habitId);
    return habitId;
  }

  /// Adjusts user XP and recalculates level for this user.
  Future<void> _adjustXp(int amount) async {
    final db = AppDatabase.instance;
    final now = DateTime.now().toIso8601String();

    final currentXp = await getUserXp();
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
