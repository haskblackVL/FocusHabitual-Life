import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:uuid/uuid.dart';

/// Local SQLite Database manager.
/// Mirror of critical tables from Supabase schema.sql for offline-first capability.
class AppDatabase {
  AppDatabase._();

  static Database? _db;
  static const _uuid = Uuid();

  /// Retrieves the active SQLite database instance.
  static Database get instance {
    if (_db == null) {
      throw StateError('AppDatabase must be initialized by calling init() first.');
    }
    return _db!;
  }

  /// Initializes the SQLite database file and runs schema migrations.
  static Future<void> init() async {
    if (_db != null) return;

    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final dbPath = p.join(docsDir.path, 'focus_habitual.db');

      _db = sqlite3.open(dbPath);
      _createTables(_db!);
      _seedInitialData(_db!);

      if (kDebugMode) {
        print('[AppDatabase] SQLite local database initialized at: $dbPath');
      }
    } catch (e, st) {
      if (kDebugMode) {
        print('[AppDatabase] Fallback to in-memory SQLite: $e\n$st');
      }
      _db = sqlite3.openInMemory();
      _createTables(_db!);
      _seedInitialData(_db!);
    }
  }

  static void _createTables(Database db) {
    db.execute('''
      CREATE TABLE IF NOT EXISTS habits (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        title TEXT NOT NULL,
        description TEXT,
        category TEXT NOT NULL DEFAULT 'general',
        icon TEXT,
        color TEXT,
        frequency TEXT NOT NULL DEFAULT 'daily',
        target_count INTEGER NOT NULL DEFAULT 1,
        is_active INTEGER NOT NULL DEFAULT 1,
        start_date TEXT NOT NULL,
        end_date TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        client_updated_at TEXT NOT NULL
      );
    ''');

    db.execute('''
      CREATE TABLE IF NOT EXISTS habit_logs (
        id TEXT PRIMARY KEY,
        habit_id TEXT NOT NULL,
        user_id TEXT,
        completed_at TEXT NOT NULL,
        note TEXT,
        xp_earned INTEGER NOT NULL DEFAULT 10,
        client_id TEXT NOT NULL UNIQUE,
        FOREIGN KEY(habit_id) REFERENCES habits(id) ON DELETE CASCADE
      );
    ''');

    db.execute('''
      CREATE TABLE IF NOT EXISTS pomodoro_sessions (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        duration_minutes INTEGER NOT NULL,
        task_tag TEXT,
        started_at TEXT NOT NULL,
        completed_at TEXT,
        was_completed INTEGER NOT NULL DEFAULT 0,
        client_updated_at TEXT NOT NULL
      );
    ''');

    db.execute('''
      CREATE TABLE IF NOT EXISTS user_xp (
        user_id TEXT PRIMARY KEY,
        total_xp INTEGER NOT NULL DEFAULT 0,
        level INTEGER NOT NULL DEFAULT 1,
        updated_at TEXT NOT NULL
      );
    ''');
  }

  static void _seedInitialData(Database db) {
    final count = db.select('SELECT count(*) as count FROM habits').first['count'] as int;
    if (count > 0) return;

    final now = DateTime.now().toIso8601String();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final in21Days = DateTime.now().add(const Duration(days: 21)).toIso8601String().substring(0, 10);

    final seedHabits = [
      {
        'id': _uuid.v4(),
        'title': 'Lectura Estratégica & Análisis',
        'description': '30 minutos dedicados a una disciplina complementaria.',
        'category': 'general',
        'frequency': 'daily',
        'target_count': 1,
        'start_date': today,
      },
      {
        'id': _uuid.v4(),
        'title': 'Checklist Matutino (AM)',
        'description': 'Hidratación, revisión de prioridades del día y silencio reflexivo.',
        'category': 'checklist_am',
        'frequency': 'daily',
        'target_count': 1,
        'start_date': today,
      },
      {
        'id': _uuid.v4(),
        'title': 'Entrenamiento Físico & Postura',
        'description': 'Fuerza, movilidad o caminata activa para soporte neurológico.',
        'category': 'general',
        'frequency': 'daily',
        'target_count': 1,
        'start_date': today,
      },
      {
        'id': _uuid.v4(),
        'title': 'Checklist Nocturno (PM)',
        'description': 'Desconexión de pantallas, revisión de finanzas y gratitud.',
        'category': 'checklist_pm',
        'frequency': 'daily',
        'target_count': 1,
        'start_date': today,
      },
      {
        'id': _uuid.v4(),
        'title': 'Reto 21 Días: Enfoque Sin Distracciones',
        'description': 'Cero redes sociales ni multitarea durante bloques de trabajo.',
        'category': 'challenge_21',
        'frequency': 'daily',
        'target_count': 1,
        'start_date': today,
        'end_date': in21Days,
      },
    ];

    for (final h in seedHabits) {
      db.execute('''
        INSERT INTO habits (id, title, description, category, frequency, target_count, start_date, end_date, created_at, updated_at, client_updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''', [
        h['id'],
        h['title'],
        h['description'],
        h['category'],
        h['frequency'],
        h['target_count'],
        h['start_date'],
        h['end_date'],
        now,
        now,
        now,
      ]);
    }

    // Seed default user XP record
    db.execute('''
      INSERT OR IGNORE INTO user_xp (user_id, total_xp, level, updated_at)
      VALUES ('local_user', 0, 1, ?)
    ''', [now]);
  }
}
