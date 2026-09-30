import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:uuid/uuid.dart';
import '../../features/wellness/domain/challenge_catalog.dart';
import '../../features/philosophy/data/thinkers_catalog.dart';

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
      _migratePomodoroSchema(_db!);
      _migrateDataIsolation(_db!);
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
      _migratePomodoroSchema(_db!);
      _migrateDataIsolation(_db!);
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
        mode_key TEXT NOT NULL DEFAULT 'classic',
        work_type TEXT NOT NULL DEFAULT 'shallow_work',
        task_objective TEXT,
        notes_count INTEGER NOT NULL DEFAULT 0,
        dnd_triggered INTEGER NOT NULL DEFAULT 0,
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

    db.execute('''
      CREATE TABLE IF NOT EXISTS nofap_log (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL DEFAULT 'local_user',
        event_type TEXT NOT NULL,
        occurred_at TEXT NOT NULL,
        relapse_reason TEXT,
        note TEXT,
        client_id TEXT NOT NULL UNIQUE
      );
    ''');

    db.execute('''
      CREATE TABLE IF NOT EXISTS nofap_reasons (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL DEFAULT 'local_user',
        reason_text TEXT NOT NULL,
        created_at TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1
      );
    ''');

    db.execute('''
      CREATE TABLE IF NOT EXISTS app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      );
    ''');

    db.execute('''
      CREATE TABLE IF NOT EXISTS cycle_log (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        period_start TEXT NOT NULL,
        period_length INTEGER NOT NULL DEFAULT 5,
        cycle_length INTEGER NOT NULL DEFAULT 28,
        symptoms TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        client_id TEXT NOT NULL UNIQUE,
        client_updated_at TEXT NOT NULL
      );
    ''');

    db.execute('''
      CREATE TABLE IF NOT EXISTS ovulation_log (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        logged_date TEXT NOT NULL,
        basal_body_temp REAL,
        cervical_mucus TEXT,
        ovulation_test_result TEXT,
        notes TEXT,
        client_id TEXT NOT NULL UNIQUE,
        client_updated_at TEXT NOT NULL
      );
    ''');

    db.execute('''
      CREATE TABLE IF NOT EXISTS pregnancy_log (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        estimated_conception_date TEXT,
        due_date TEXT,
        current_week INTEGER,
        is_active INTEGER NOT NULL DEFAULT 1,
        notes TEXT,
        created_at TEXT NOT NULL,
        client_id TEXT NOT NULL UNIQUE,
        client_updated_at TEXT NOT NULL
      );
    ''');

    db.execute('''
      CREATE TABLE IF NOT EXISTS fertility_awareness_log (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        logged_date TEXT NOT NULL,
        method TEXT NOT NULL DEFAULT 'symptothermal',
        fertile_window_status TEXT,
        partner_shared INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        client_id TEXT NOT NULL UNIQUE,
        client_updated_at TEXT NOT NULL
      );
    ''');

    db.execute('''
      CREATE TABLE IF NOT EXISTS cycle_symptoms_log (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        logged_date TEXT NOT NULL,
        symptoms TEXT NOT NULL DEFAULT '',
        flow_level TEXT DEFAULT 'none',
        cramps_level INTEGER DEFAULT 0,
        mood TEXT DEFAULT 'calm',
        notes TEXT,
        client_id TEXT NOT NULL UNIQUE,
        client_updated_at TEXT NOT NULL
      );
    ''');

    db.execute('''
      CREATE TABLE IF NOT EXISTS gratitude_entries (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        entry_date TEXT NOT NULL,
        item1 TEXT NOT NULL,
        item2 TEXT,
        item3 TEXT,
        reflection TEXT,
        prompt_used TEXT,
        created_at TEXT NOT NULL,
        client_id TEXT NOT NULL UNIQUE,
        client_updated_at TEXT NOT NULL
      );
    ''');

    db.execute('''
      CREATE TABLE IF NOT EXISTS finance_accounts (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'bank',
        currency TEXT NOT NULL DEFAULT 'MXN',
        initial_balance REAL NOT NULL DEFAULT 0.0,
        created_at TEXT NOT NULL,
        client_id TEXT NOT NULL UNIQUE,
        client_updated_at TEXT NOT NULL
      );
    ''');

    db.execute('''
      CREATE TABLE IF NOT EXISTS finance_transactions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        account_id TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT 'general',
        to_account_id TEXT,
        occurred_at TEXT NOT NULL,
        note TEXT,
        created_at TEXT NOT NULL,
        client_id TEXT NOT NULL UNIQUE,
        client_updated_at TEXT NOT NULL
      );
    ''');

    db.execute('''
      CREATE TABLE IF NOT EXISTS finance_budgets (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        month_year TEXT NOT NULL,
        category TEXT NOT NULL,
        monthly_limit REAL NOT NULL,
        created_at TEXT NOT NULL,
        client_id TEXT NOT NULL UNIQUE,
        client_updated_at TEXT NOT NULL,
        UNIQUE (user_id, month_year, category)
      );
    ''');

    db.execute('''
      CREATE TABLE IF NOT EXISTS religion_content (
        id TEXT PRIMARY KEY,
        verse_ref TEXT NOT NULL,
        verse_text TEXT NOT NULL,
        reflection TEXT,
        date_assigned TEXT,
        language TEXT NOT NULL DEFAULT 'es',
        theme TEXT NOT NULL DEFAULT 'Sabiduría & Liderazgo',
        practical_action TEXT,
        reading_path TEXT DEFAULT 'proverbios_31'
      );
    ''');

    db.execute('''
      CREATE TABLE IF NOT EXISTS religion_user_log (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        content_id TEXT NOT NULL,
        read_at TEXT NOT NULL,
        reflection_notes TEXT,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        client_id TEXT NOT NULL UNIQUE,
        client_updated_at TEXT NOT NULL
      );
    ''');

    db.execute('''
      CREATE TABLE IF NOT EXISTS prayer_requests (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        category TEXT NOT NULL DEFAULT 'personal',
        status TEXT NOT NULL DEFAULT 'active',
        answered_at TEXT,
        answer_notes TEXT,
        created_at TEXT NOT NULL,
        client_id TEXT NOT NULL UNIQUE,
        client_updated_at TEXT NOT NULL
      );
    ''');

    db.execute('''
      CREATE TABLE IF NOT EXISTS water_settings (
        user_id TEXT PRIMARY KEY,
        daily_goal_ml INTEGER NOT NULL DEFAULT 2000,
        reminder_interval_minutes INTEGER NOT NULL DEFAULT 90,
        wake_time TEXT NOT NULL DEFAULT '07:00',
        sleep_time TEXT NOT NULL DEFAULT '22:30',
        reminders_enabled INTEGER NOT NULL DEFAULT 1,
        client_updated_at TEXT NOT NULL
      );

      CREATE TABLE IF NOT EXISTS water_log (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        amount_ml INTEGER NOT NULL,
        logged_at TEXT NOT NULL,
        client_id TEXT NOT NULL UNIQUE,
        client_updated_at TEXT NOT NULL
      );

      CREATE TABLE IF NOT EXISTS nutrition_settings (
        user_id TEXT PRIMARY KEY,
        breakfast_time TEXT DEFAULT '08:00',
        lunch_time TEXT DEFAULT '14:00',
        dinner_time TEXT DEFAULT '20:00',
        reminders_enabled INTEGER NOT NULL DEFAULT 1,
        client_updated_at TEXT NOT NULL
      );

      CREATE TABLE IF NOT EXISTS nutrition_log (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        meal_type TEXT NOT NULL,
        title TEXT,
        note TEXT,
        logged_at TEXT NOT NULL,
        client_id TEXT NOT NULL UNIQUE,
        client_updated_at TEXT NOT NULL
      );

      CREATE TABLE IF NOT EXISTS nutrition_tips (
        id TEXT PRIMARY KEY,
        tip_text TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT 'general'
      );

      CREATE TABLE IF NOT EXISTS affirmations (
        id TEXT PRIMARY KEY,
        text TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT 'general',
        author TEXT,
        language TEXT NOT NULL DEFAULT 'es'
      );

      CREATE TABLE IF NOT EXISTS affirmation_log (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        affirmation_id TEXT NOT NULL,
        shown_at TEXT NOT NULL,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        client_id TEXT NOT NULL UNIQUE,
        client_updated_at TEXT NOT NULL
      );

      CREATE TABLE IF NOT EXISTS wellness_challenges (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        challenge_type TEXT NOT NULL,
        total_days INTEGER NOT NULL DEFAULT 21,
        started_at TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        client_id TEXT NOT NULL UNIQUE,
        client_updated_at TEXT NOT NULL
      );

      CREATE TABLE IF NOT EXISTS wellness_challenge_progress (
        id TEXT PRIMARY KEY,
        challenge_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        day_number INTEGER NOT NULL,
        completed_at TEXT NOT NULL,
        client_id TEXT NOT NULL UNIQUE,
        client_updated_at TEXT NOT NULL,
        UNIQUE (challenge_id, day_number)
      );

      CREATE TABLE IF NOT EXISTS wellness_exercises (
        id TEXT PRIMARY KEY,
        challenge_type TEXT NOT NULL,
        day_number INTEGER NOT NULL,
        title TEXT NOT NULL,
        tip TEXT,
        instructions TEXT,
        video_url TEXT,
        duration_minutes INTEGER NOT NULL DEFAULT 5,
        UNIQUE (challenge_type, day_number)
      );

      CREATE TABLE IF NOT EXISTS ambient_sounds (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT 'nature',
        audio_url TEXT NOT NULL,
        loopable INTEGER NOT NULL DEFAULT 1
      );

      CREATE TABLE IF NOT EXISTS sync_queue (
        id TEXT PRIMARY KEY,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        action TEXT NOT NULL,
        payload TEXT NOT NULL,
        created_at TEXT NOT NULL,
        attempts INTEGER NOT NULL DEFAULT 0,
        last_error TEXT
      );

      CREATE TABLE IF NOT EXISTS achievements (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL DEFAULT 'local_user',
        achievement_key TEXT NOT NULL,
        module TEXT NOT NULL,
        unlocked_at TEXT NOT NULL,
        UNIQUE (user_id, achievement_key)
      );

      CREATE TABLE IF NOT EXISTS xp_events (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL DEFAULT 'local_user',
        source_module TEXT NOT NULL,
        xp_amount INTEGER NOT NULL,
        occurred_at TEXT NOT NULL
      );

      CREATE TABLE IF NOT EXISTS local_profiles (
        id TEXT PRIMARY KEY,
        email TEXT UNIQUE,
        password_hash TEXT,
        full_name TEXT,
        gender TEXT NOT NULL DEFAULT 'male',
        is_religious INTEGER NOT NULL DEFAULT 0,
        onboarding_completed INTEGER NOT NULL DEFAULT 0,
        provider TEXT NOT NULL DEFAULT 'local',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );

      CREATE TABLE IF NOT EXISTS thinkers (
        id TEXT PRIMARY KEY,
        slug TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        era_label TEXT NOT NULL,
        origin TEXT,
        key_idea TEXT NOT NULL,
        key_work TEXT,
        requires_religious INTEGER NOT NULL DEFAULT 0,
        unlock_xp INTEGER NOT NULL DEFAULT 0
      );

      CREATE TABLE IF NOT EXISTS user_thinker_unlocks (
        user_id TEXT NOT NULL,
        thinker_id TEXT NOT NULL,
        unlocked_at TEXT NOT NULL,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (user_id, thinker_id)
      );

      CREATE TABLE IF NOT EXISTS pomodoro_interruption_notes (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        note_text TEXT NOT NULL,
        captured_at TEXT NOT NULL,
        converted_to_habit_id TEXT
      );

      CREATE TABLE IF NOT EXISTS daily_block_templates (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL DEFAULT 'Plan de Implementación Inmediata',
        is_default INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      );

      CREATE TABLE IF NOT EXISTS daily_block_template_items (
        id TEXT PRIMARY KEY,
        template_id TEXT NOT NULL,
        start_time TEXT NOT NULL,
        duration_minutes INTEGER NOT NULL,
        mode_key TEXT NOT NULL,
        work_type TEXT NOT NULL,
        label TEXT,
        sort_order INTEGER NOT NULL DEFAULT 0
      );
    ''');
  }

  /// Migrates Pomodoro schema by adding missing columns to existing local tables.
  static void _migratePomodoroSchema(Database db) {
    try {
      final columns = db.select("PRAGMA table_info(pomodoro_sessions)");
      final names = columns.map((r) => r['name'] as String).toSet();
      if (!names.contains('mode_key')) {
        db.execute("ALTER TABLE pomodoro_sessions ADD COLUMN mode_key TEXT NOT NULL DEFAULT 'classic'");
      }
      if (!names.contains('work_type')) {
        db.execute("ALTER TABLE pomodoro_sessions ADD COLUMN work_type TEXT NOT NULL DEFAULT 'shallow_work'");
      }
      if (!names.contains('task_objective')) {
        db.execute("ALTER TABLE pomodoro_sessions ADD COLUMN task_objective TEXT");
      }
      if (!names.contains('notes_count')) {
        db.execute("ALTER TABLE pomodoro_sessions ADD COLUMN notes_count INTEGER NOT NULL DEFAULT 0");
      }
      if (!names.contains('dnd_triggered')) {
        db.execute("ALTER TABLE pomodoro_sessions ADD COLUMN dnd_triggered INTEGER NOT NULL DEFAULT 0");
      }
    } catch (e) {
      if (kDebugMode) print('[AppDatabase] Pomodoro column migration error: $e');
    }
  }

  /// Enqueues an operation to be synced to Supabase when connected.
  static void enqueueSync({
    required String tableName,
    required String recordId,
    required String action,
    required Map<String, dynamic> payload,
  }) {
    try {
      final id = _uuid.v4();
      final now = DateTime.now().toIso8601String();
      instance.execute('''
        INSERT INTO sync_queue (id, table_name, record_id, action, payload, created_at, attempts)
        VALUES (?, ?, ?, ?, ?, ?, 0)
      ''', [id, tableName, recordId, action, jsonEncode(payload), now]);
    } catch (e) {
      if (kDebugMode) {
        print('[AppDatabase] Error enqueuing sync for $tableName: $e');
      }
    }
  }

  /// Retrieves up to [limit] pending sync actions from the queue.
  static List<Map<String, dynamic>> getPendingSync({int limit = 50}) {
    try {
      final rows = instance.select('''
        SELECT id, table_name, record_id, action, payload, created_at, attempts
        FROM sync_queue
        ORDER BY created_at ASC
        LIMIT ?
      ''', [limit]);

      return rows.map((r) => Map<String, dynamic>.from(r)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('[AppDatabase] Error getting pending sync: $e');
      }
      return [];
    }
  }

  /// Removes an item from the sync queue after successful sync.
  static void removeSync(String id) {
    try {
      instance.execute('DELETE FROM sync_queue WHERE id = ?', [id]);
    } catch (e) {
      if (kDebugMode) {
        print('[AppDatabase] Error removing sync item $id: $e');
      }
    }
  }

  /// Increments attempts and stores last error on sync failure.
  static void updateSyncError(String id, String error) {
    try {
      instance.execute('''
        UPDATE sync_queue
        SET attempts = attempts + 1, last_error = ?
        WHERE id = ?
      ''', [error, id]);
    } catch (_) {}
  }

  /// Sets a persistent key-value configuration in local SQLite.
  static void setSetting(String key, String value) {
    try {
      instance.execute('''
        INSERT INTO app_settings (key, value)
        VALUES (?, ?)
        ON CONFLICT(key) DO UPDATE SET value = excluded.value
      ''', [key, value]);
    } catch (e) {
      if (kDebugMode) {
        print('[AppDatabase] Error setting $key: $e');
      }
    }
  }

  /// Reads a persistent key-value configuration from local SQLite.
  static String? getSetting(String key) {
    try {
      final rows = instance.select('SELECT value FROM app_settings WHERE key = ?', [key]);
      if (rows.isNotEmpty) {
        return rows.first['value'] as String?;
      }
    } catch (e) {
      if (kDebugMode) {
        print('[AppDatabase] Error getting $key: $e');
      }
    }
    return null;
  }

  /// One-time data isolation migration:
  /// Assigns orphan records (where user_id IS NULL or user_id = '')
  /// to the primary existing registered user if one exists (e.g. Victor Luna 602d34fc-e6d2-4bbb-84f7-58cb8520b520).
  /// This ensures Victor keeps his data, while any secondary or new account starts completely clean and isolated.
  static void _migrateDataIsolation(Database db) {
    try {
      final migrated = getSetting('data_isolation_v1_migrated');
      if (migrated == 'true') return;

      // Detect if there is a primary registered user in nofap_log or cycle_log
      String? primaryUserId;
      final nofapUser = db.select(
        "SELECT user_id FROM nofap_log WHERE user_id != 'local_user' AND user_id IS NOT NULL AND user_id != '' LIMIT 1",
      );
      if (nofapUser.isNotEmpty) {
        primaryUserId = nofapUser.first['user_id'] as String;
      } else {
        final cycleUser = db.select(
          "SELECT user_id FROM cycle_log WHERE user_id != 'local_user' AND user_id IS NOT NULL AND user_id != '' LIMIT 1",
        );
        if (cycleUser.isNotEmpty) {
          primaryUserId = cycleUser.first['user_id'] as String;
        }
      }

      if (primaryUserId != null && primaryUserId.isNotEmpty) {
        // 1. Assign orphan habits to primary user
        db.execute(
          "UPDATE habits SET user_id = ? WHERE user_id IS NULL OR user_id = ''",
          [primaryUserId],
        );
        // 2. Assign orphan habit_logs to primary user
        db.execute(
          "UPDATE habit_logs SET user_id = ? WHERE user_id IS NULL OR user_id = ''",
          [primaryUserId],
        );
        // 3. Assign orphan pomodoro_sessions to primary user
        db.execute(
          "UPDATE pomodoro_sessions SET user_id = ? WHERE user_id IS NULL OR user_id = ''",
          [primaryUserId],
        );

        // 4. Migrate local_user XP to primaryUserId if primary user has no XP row yet
        final primaryXp = db.select('SELECT total_xp FROM user_xp WHERE user_id = ?', [primaryUserId]);
        if (primaryXp.isEmpty) {
          final localXp = db.select("SELECT total_xp, level FROM user_xp WHERE user_id = 'local_user'");
          if (localXp.isNotEmpty) {
            final tx = localXp.first['total_xp'] as int;
            final lvl = localXp.first['level'] as int;
            final now = DateTime.now().toIso8601String();
            db.execute('''
              INSERT OR REPLACE INTO user_xp (user_id, total_xp, level, updated_at)
              VALUES (?, ?, ?, ?)
            ''', [primaryUserId, tx, lvl, now]);
          }
        }

        // 5. Migrate water logs & settings
        db.execute(
          "UPDATE water_log SET user_id = ? WHERE user_id = 'local_user'",
          [primaryUserId],
        );
        final primaryWater = db.select('SELECT user_id FROM water_settings WHERE user_id = ?', [primaryUserId]);
        if (primaryWater.isEmpty) {
          db.execute(
            "UPDATE water_settings SET user_id = ? WHERE user_id = 'local_user'",
            [primaryUserId],
          );
        }

        // 6. Migrate nutrition logs & settings
        db.execute(
          "UPDATE nutrition_log SET user_id = ? WHERE user_id = 'local_user'",
          [primaryUserId],
        );
        final primaryNutri = db.select('SELECT user_id FROM nutrition_settings WHERE user_id = ?', [primaryUserId]);
        if (primaryNutri.isEmpty) {
          db.execute(
            "UPDATE nutrition_settings SET user_id = ? WHERE user_id = 'local_user'",
            [primaryUserId],
          );
        }

        // 7. Migrate wellness challenges & progress
        db.execute(
          "UPDATE wellness_challenges SET user_id = ? WHERE user_id = 'local_user'",
          [primaryUserId],
        );
        db.execute(
          "UPDATE wellness_challenge_progress SET user_id = ? WHERE user_id = 'local_user'",
          [primaryUserId],
        );

        // 8. Migrate achievements & XP events
        db.execute(
          "UPDATE achievements SET user_id = ? WHERE user_id = 'local_user'",
          [primaryUserId],
        );
        db.execute(
          "UPDATE xp_events SET user_id = ? WHERE user_id = 'local_user'",
          [primaryUserId],
        );

        // 9. Migrate religion user log & prayer requests
        db.execute(
          "UPDATE religion_user_log SET user_id = ? WHERE user_id = 'local_user'",
          [primaryUserId],
        );
        db.execute(
          "UPDATE prayer_requests SET user_id = ? WHERE user_id = 'local_user'",
          [primaryUserId],
        );

        // 10. Migrate profile settings
        final globalName = getSetting('profile_full_name');
        if (globalName != null) {
          setSetting('profile_full_name_$primaryUserId', globalName);
        }
        final globalGender = getSetting('profile_gender');
        if (globalGender != null) {
          setSetting('profile_gender_$primaryUserId', globalGender);
        }
        final globalReligious = getSetting('profile_is_religious');
        if (globalReligious != null) {
          setSetting('profile_is_religious_$primaryUserId', globalReligious);
        }
        final globalOnboarding = getSetting('profile_onboarding_completed');
        if (globalOnboarding != null) {
          setSetting('profile_onboarding_completed_$primaryUserId', globalOnboarding);
        }
      }

      setSetting('data_isolation_v1_migrated', 'true');
      if (kDebugMode) {
        print('[AppDatabase] Data isolation migration applied for primary user: $primaryUserId');
      }
    } catch (e, st) {
      if (kDebugMode) {
        print('[AppDatabase] Data isolation migration error: $e\n$st');
      }
    }
  }

  static void _seedInitialData(Database db) {
    _seedNofapData(db);
    _seedFinanceData(db);
    _seedReligionData(db);
    _seedWellnessData(db);
    _seedThinkersData(db);

    // Clean up obsolete generic placeholder checklists if present
    db.execute("DELETE FROM habits WHERE title IN ('Checklist Matutino (AM)', 'Checklist Nocturno (PM)')");

    final now = DateTime.now().toIso8601String();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final in21Days = DateTime.now().add(const Duration(days: 21)).toIso8601String().substring(0, 10);

    // Master default habits list for guest mode (customizable & deletable)
    final defaultHabits = [
      // 1. RUTINA MATUTINA (7 Hábitos Predeterminados)
      {
        'title': 'Despertar sin posponer la alarma (snooze)',
        'description': 'Activación inmediata del ritmo circadiano sin fragmentar el descanso.',
        'category': 'checklist_am',
        'frequency': 'daily',
        'target_count': 1,
      },
      {
        'title': 'Beber un vaso de agua',
        'description': 'Rehidratación celular y reactivación metabólica al despertar.',
        'category': 'checklist_am',
        'frequency': 'daily',
        'target_count': 1,
      },
      {
        'title': 'Hacer la cama',
        'description': 'Primer logro del día que ordena el entorno y despeja la mente.',
        'category': 'checklist_am',
        'frequency': 'daily',
        'target_count': 1,
      },
      {
        'title': '5 - 10 min de movimiento (estiramiento)',
        'description': 'Movilidad articular, activación neuromuscular y oxigenación.',
        'category': 'checklist_am',
        'frequency': 'daily',
        'target_count': 1,
      },
      {
        'title': 'Higiene personal',
        'description': 'Cuidado dermatológico, dental y preparación limpia para el día.',
        'category': 'checklist_am',
        'frequency': 'daily',
        'target_count': 1,
      },
      {
        'title': 'Desayuno consciente (Sin pantalla)',
        'description': 'Nutrición atenta y digestión óptima sin estímulos dopaminérgicos.',
        'category': 'checklist_am',
        'frequency': 'daily',
        'target_count': 1,
      },
      {
        'title': 'Revisar las 3 prioridades',
        'description': 'Claridad estratégica y alineación de objetivos de alto impacto.',
        'category': 'checklist_am',
        'frequency': 'daily',
        'target_count': 1,
      },

      // 2. GENERAL / RETO 21 DÍAS
      {
        'title': 'Reto 21 Días: Enfoque Sin Distracciones',
        'description': 'Cero redes sociales ni multitarea durante bloques de trabajo profundo.',
        'category': 'challenge_21',
        'frequency': 'daily',
        'target_count': 1,
        'end_date': in21Days,
      },
      {
        'title': 'Lectura Estratégica & Análisis',
        'description': '30 minutos dedicados a una disciplina complementaria.',
        'category': 'general',
        'frequency': 'daily',
        'target_count': 1,
      },
      {
        'title': 'Entrenamiento Físico & Postura',
        'description': 'Fuerza, movilidad o caminata activa para soporte neurológico.',
        'category': 'general',
        'frequency': 'daily',
        'target_count': 1,
      },

      // 3. RUTINA NOCTURNA (7 Hábitos Predeterminados)
      {
        'title': 'Revisar cumplimientos de las 3 prioridades',
        'description': 'Auditoría honesta de ejecución y recalibración de tareas.',
        'category': 'checklist_pm',
        'frequency': 'daily',
        'target_count': 1,
      },
      {
        'title': 'Preparar ropa / materiales para mañana',
        'description': 'Eliminación de fricción matutina y fatiga de decisión.',
        'category': 'checklist_pm',
        'frequency': 'daily',
        'target_count': 1,
      },
      {
        'title': 'Apagar pantallas 30 min antes de dormir',
        'description': 'Reducción de luz azul para permitir la secreción de melatonina.',
        'category': 'checklist_pm',
        'frequency': 'daily',
        'target_count': 1,
      },
      {
        'title': '3 líneas de Diario de Gratitud',
        'description': 'Anclaje estoico de apreciación y desescalada de estrés.',
        'category': 'checklist_pm',
        'frequency': 'daily',
        'target_count': 1,
      },
      {
        'title': 'Lectura breve (10 - 15 min)',
        'description': 'Inducción cognitiva hacia ondas alfa antes del sueño.',
        'category': 'checklist_pm',
        'frequency': 'daily',
        'target_count': 1,
      },
      {
        'title': 'Rutina higiene nocturna',
        'description': 'Limpieza facial, cepillado y preparación para el descanso.',
        'category': 'checklist_pm',
        'frequency': 'daily',
        'target_count': 1,
      },
      {
        'title': 'Hora fija de apagar la luz',
        'description': 'Consolidación estricta de la ventana de sueño reparador.',
        'category': 'checklist_pm',
        'frequency': 'daily',
        'target_count': 1,
      },
    ];

    // Idempotent insertion: only insert default habits for guest mode (local_user)
    for (final h in defaultHabits) {
      final existingRows = db.select(
        "SELECT count(*) as count FROM habits WHERE title = ? AND (user_id = 'local_user' OR user_id = ?)",
        [h['title'], 'local_user'],
      );
      final exists = existingRows.first['count'] as int;
      if (exists == 0) {
        db.execute('''
          INSERT INTO habits (id, user_id, title, description, category, frequency, target_count, start_date, end_date, created_at, updated_at, client_updated_at)
          VALUES (?, 'local_user', ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', [
          _uuid.v4(),
          h['title'],
          h['description'],
          h['category'],
          h['frequency'],
          h['target_count'],
          today,
          h['end_date'],
          now,
          now,
          now,
        ]);
      }
    }

    // Seed default user XP record
    db.execute('''
      INSERT OR IGNORE INTO user_xp (user_id, total_xp, level, updated_at)
      VALUES ('local_user', 0, 1, ?)
    ''', [now]);

    _seedFinanceData(db);
  }

  static void _seedFinanceData(Database db) {
    try {
      final rows = db.select('SELECT count(*) as count FROM finance_accounts');
      final count = rows.first['count'] as int;
      if (count == 0) {
        final now = DateTime.now().toIso8601String();
        final defaultAccounts = [
          {
            'name': 'Cuenta Principal',
            'type': 'bank',
            'balance': 0.0,
          },
          {
            'name': 'Efectivo / Cartera',
            'type': 'cash',
            'balance': 0.0,
          },
          {
            'name': 'Fondo de Ahorro / Inversión',
            'type': 'investment',
            'balance': 0.0,
          },
        ];

        for (final acc in defaultAccounts) {
          final id = _uuid.v4();
          db.execute('''
            INSERT INTO finance_accounts (id, user_id, name, type, currency, initial_balance, created_at, client_id, client_updated_at)
            VALUES (?, 'local_user', ?, ?, 'MXN', ?, ?, ?, ?)
          ''', [
            id,
            acc['name'],
            acc['type'],
            acc['balance'],
            now,
            id,
            now,
          ]);
        }
      }
    } catch (_) {}
  }

  static void _seedNofapData(Database db) {
    try {
      final rows = db.select('SELECT count(*) as count FROM nofap_log');
      final count = rows.first['count'] as int;
      if (count == 0) {
        final initialStreakStart = DateTime.now().toIso8601String();

        db.execute('''
          INSERT INTO nofap_log (id, user_id, event_type, occurred_at, client_id)
          VALUES (?, 'local_user', 'checkin', ?, ?)
        ''', [_uuid.v4(), initialStreakStart, _uuid.v4()]);
      }
    } catch (_) {}

    try {
      final reasonRows = db.select('SELECT count(*) as count FROM nofap_reasons');
      final reasonCount = reasonRows.first['count'] as int;
      if (reasonCount == 0) {
        final now = DateTime.now().toIso8601String();
        final seedReasons = [
          'Quiero recuperar mi máxima claridad mental, energía y enfoque diario.',
          'Deseo gobernar mis impulsos en lugar de que un hábito automático me controle.',
          'Mi tiempo, dignidad y relaciones reales valen más que un atajo momentáneo.',
          'Construir la identidad de un hombre con dominio propio inquebrantable.',
        ];
        for (final text in seedReasons) {
          db.execute('''
            INSERT INTO nofap_reasons (id, user_id, reason_text, created_at, is_active)
            VALUES (?, 'local_user', ?, ?, 1)
          ''', [_uuid.v4(), text, now]);
        }
      }
    } catch (_) {
      // Table might still be initializing in some testing environments
    }
  }

  static void _seedReligionData(Database db) {
    try {
      final rows = db.select('SELECT count(*) as count FROM religion_content');
      final count = rows.first['count'] as int;
      if (count > 0) return;

      final passages = [
        {
          'id': 'rel-prov-16-3',
          'verse_ref': 'Proverbios 16:3',
          'verse_text': 'Encomienda al Señor tus obras, y tus pensamientos serán afirmados.',
          'reflection': 'La verdadera soberanía interior no nace de la soberbia ni de la ilusión de control absoluto, sino de consagrar la intención y el propósito de cada proyecto a una causa más alta. Cuando alineas tu labor profesional y personal con la rectitud moral, el ruido de la incertidumbre se disipa y tu mente se asienta en serenidad estratégica.',
          'theme': 'Sabiduría & Liderazgo',
          'practical_action': 'Antes de iniciar tu jornada de trabajo, consagra mentalmente tus prioridades del día y renuncia a la ansiedad por el resultado.',
          'reading_path': 'proverbios_31',
        },
        {
          'id': 'rel-prov-3-5',
          'verse_ref': 'Proverbios 3:5-6',
          'verse_text': 'Fíate de Jehová de todo tu corazón, y no te apoyes en tu propia prudencia. Reconócelo en todos tus caminos, y él enderezará tus veredas.',
          'reflection': 'El intelecto humano es una herramienta potente pero miope si carece de anclaje trascendente. Apoyarse únicamente en el propio entendimiento produce rigidez y soberbia. Reconocer la guía divina en cada encrucijada abre espacio para la flexibilidad, la humildad y la verdadera agudeza mental.',
          'theme': 'Sabiduría & Liderazgo',
          'practical_action': 'Ante una decisión compleja hoy, no te apresures; pide sabiduría en silencio antes de emitir tu juicio definitivo.',
          'reading_path': 'proverbios_31',
        },
        {
          'id': 'rel-prov-4-23',
          'verse_ref': 'Proverbios 4:23',
          'verse_text': 'Sobre toda cosa guardada, guarda tu corazón; porque de él mana la vida.',
          'reflection': 'El corazón en la tradición sapiencial es el centro de las decisiones, los afectos y la voluntad. Blindar este núcleo contra la amargura, los impulsos reactivos, la pornografía, la codicia y las distracciones digitales no es represión, sino higiene mental y preservación de tu potencia vital.',
          'theme': 'Dominio Propio & Fortaleza',
          'practical_action': 'Audita durante 5 minutos los contenidos, conversaciones y estímulos que permitiste entrar hoy a tu mente.',
          'reading_path': 'proverbios_31',
        },
        {
          'id': 'rel-fil-4-6',
          'verse_ref': 'Filipenses 4:6-7',
          'verse_text': 'Por nada estéis afanosos, sino sean conocidas vuestras peticiones delante de Dios en toda oración y ruego, con acción de gracias. Y la paz de Dios, que sobrepasa todo entendimiento, guardará vuestros corazones y vuestros pensamientos en Cristo Jesús.',
          'reflection': 'La ansiedad crónica es una parálisis del espíritu que consume energía vital sin resolver problemas futuros. El antídoto no es la indiferencia, sino la entrega deliberada mediante la oración agradecida. La paz que sobrepasa el entendimiento actúa como un centinela que custodia tu capacidad de discernir con lucidez.',
          'theme': 'Paz Mental & Confianza',
          'practical_action': 'Escribe en tu Diario de Oración la preocupación que más te inquieta hoy y conviértela en una petición con gratitud previa.',
          'reading_path': 'paz_y_confianza',
        },
        {
          'id': 'rel-col-3-23',
          'verse_ref': 'Colosenses 3:23',
          'verse_text': 'Y todo lo que hagáis, hacedlo de corazón, como para el Señor y no para los hombres.',
          'reflection': 'Trabajar para la validación humana o el aplauso de terceros produce dependencia y mediocridad. Trabajar como si tu obra fuera presentada ante el Supremo Creador eleva el estándar de calidad al máximo nivel posible de excelencia artesanal.',
          'theme': 'Diligencia & Excelencia',
          'practical_action': 'Elige la tarea más monótona de tu lista de hoy y ejecútala con la máxima pulcritud, atención al detalle y gratitud.',
          'reading_path': 'liderazgo_y_excelencia',
        },
        {
          'id': 'rel-stg-1-5',
          'verse_ref': 'Santiago 1:5',
          'verse_text': 'Y si alguno de vosotros tiene falta de sabiduría, pídala a Dios, el cual da a todos abundantemente y sin reproche, y le será dada.',
          'reflection': 'El conocimiento acumula datos y técnicas; la sabiduría sabe qué hacer con ellos con sentido ético y justicia. Admitir que no posees todas las respuestas es el primer paso hacia la verdadera sabiduría. La sabiduría se concede a quien la busca con humildad activa y perseverancia.',
          'theme': 'Sabiduría & Liderazgo',
          'practical_action': 'Identifica un área de tu vida donde te sientas estancado y pide discernimiento específico en lugar de una solución rápida.',
          'reading_path': 'sabiduria_y_liderazgo',
        },
        {
          'id': 'rel-prov-21-5',
          'verse_ref': 'Proverbios 21:5',
          'verse_text': 'Los pensamientos del diligente ciertamente tienden a la abundancia; mas todo el que se apresura alocadamente, de cierto va a la pobreza.',
          'reflection': 'La prosperidad duradera no es fruto de la suerte ni de esquemas de enriquecimiento rápido, sino de la planificación metódica, la disciplina de ahorro y la ejecución paciente. La prisa desordenada destruye el patrimonio y socava la estabilidad.',
          'theme': 'Diligencia & Excelencia',
          'practical_action': 'Revisa tu presupuesto de este mes en el Módulo de Finanzas y asegura que tus decisiones sigan un plan y no un impulso.',
          'reading_path': 'proverbios_31',
        },
        {
          'id': 'rel-sal-46-10',
          'verse_ref': 'Salmo 46:10',
          'verse_text': 'Estad quietos, y conoced que yo soy Dios; seré exaltado entre las naciones; enaltecido seré en la tierra.',
          'reflection': 'En un mundo saturado de hiperactividad neurótica, la quietud es un acto de valentía y fe radical. Estar quieto no significa holgazanería; significa silenciar el ego que cree que el universo colapsará si se detiene por 10 minutos.',
          'theme': 'Paz Mental & Confianza',
          'practical_action': 'Dedica 5 minutos de silencio absoluto antes del almuerzo, respirando con calma y reconociendo la soberanía divina sobre tu tiempo.',
          'reading_path': 'paz_y_confianza',
        },
        {
          'id': 'rel-jos-1-9',
          'verse_ref': 'Josué 1:9',
          'verse_text': 'Mira que te mando que te esfuerces y seas valiente; no temas ni desmayes, porque Jehová tu Dios estará contigo en dondequiera que vayas.',
          'reflection': 'La valentía no es la ausencia de temor, sino el mandato de avanzar a pesar de él. El liderazgo exige asumir riesgos éticos, defender la verdad cuando es impopular y no abandonar el timón en medio de la tormenta.',
          'theme': 'Dominio Propio & Fortaleza',
          'practical_action': 'Afronta hoy esa conversación difícil o ese proyecto postergado que te causa fricción o incomodidad.',
          'reading_path': 'fortaleza_en_la_prueba',
        },
        {
          'id': 'rel-prov-27-17',
          'verse_ref': 'Proverbios 27:17',
          'verse_text': 'Hierro con hierro se aguza; y así el hombre aguza el rostro de su amigo.',
          'reflection': 'El crecimiento personal y espiritual no ocurre en el aislamiento complaciente. Requieres relaciones sólidas, mentores exigentes y compañeros de camino que tengan el coraje de señalar tus puntos ciegos y afilar tu carácter.',
          'theme': 'Sabiduría & Liderazgo',
          'practical_action': 'Agradece hoy a un mentor, colega o amigo que te exige un estándar más elevado de integridad y rendimiento.',
          'reading_path': 'proverbios_31',
        },
        {
          'id': 'rel-gal-6-9',
          'verse_ref': 'Gálatas 6:9',
          'verse_text': 'No nos cansemos, pues, de hacer bien; porque a su tiempo segaremos, si no desmayamos.',
          'reflection': 'La ley de la siembra y la cosecha opera con desfase temporal. Entre la semilla del esfuerzo honesto y el fruto visible existe un período de oscuridad donde parece que nada ocurre. Mantener el ritmo sin desmayar es la esencia de la constancia heroica.',
          'theme': 'Diligencia & Excelencia',
          'practical_action': 'Continúa tu racha de hábitos hoy aun si no sientes la motivación emocional inmediata; confía en el proceso acumulativo.',
          'reading_path': 'liderazgo_y_excelencia',
        },
        {
          'id': 'rel-rom-12-2',
          'verse_ref': 'Romanos 12:2',
          'verse_text': 'No os conforméis a este siglo, sino transformaos por medio de la renovación de vuestro entendimiento, para que comprobéis cuál sea la buena voluntad de Dios, agradable y perfecta.',
          'reflection': 'La cultura masiva promueve el consumo compulsivo, la gratificación instantánea y la fragilidad emocional. Resistir ese molde exige una metanoia: una reprogramación consciente de tus esquemas mentales a la luz de principios eternos.',
          'theme': 'Sabiduría & Liderazgo',
          'practical_action': 'Sustituye 30 minutos de redes sociales o noticias vacías por lectura profunda, estudio o contemplación espiritual.',
          'reading_path': 'sabiduria_y_liderazgo',
        },
        {
          'id': 'rel-prov-25-28',
          'verse_ref': 'Proverbios 25:28',
          'verse_text': 'Como ciudad derribada y sin muro es el hombre cuyo espíritu no tiene rienda.',
          'reflection': 'En la antigüedad, una ciudad sin murallas estaba a merced de cualquier asaltante. Una persona sin templanza ni dominio propio es vulnerable a cada impulso momentáneo, adicción o arranque de ira, destruyendo en minutos lo que tardó años en construir.',
          'theme': 'Dominio Propio & Fortaleza',
          'practical_action': 'Aplica autodominio riguroso en una pequeña tentación hoy: alimentación, navegación web o respuesta verbal impulsiva.',
          'reading_path': 'proverbios_31',
        },
        {
          'id': 'rel-sal-90-12',
          'verse_ref': 'Salmo 90:12',
          'verse_text': 'Enséñanos de tal modo a contar nuestros días, que traigamos al corazón sabiduría.',
          'reflection': 'El memento mori bíblico: recordar la brevedad y finitud de nuestra existencia terrenal no busca generar pesimismo, sino lucidez. Saber que los días son limitados otorga una gravedad sagrada a cada hora invertida y elimina la procrastinación frívola.',
          'theme': 'Sabiduría & Liderazgo',
          'practical_action': 'Organiza tu bloque de enfoque Pomodoro de hoy como si fuera el testimonio más digno de tu vocación terrenal.',
          'reading_path': 'sabiduria_y_liderazgo',
        },
        {
          'id': 'rel-mat-6-33',
          'verse_ref': 'Mateo 6:33-34',
          'verse_text': 'Mas buscad primeramente el reino de Dios y su justicia, y todas estas cosas os serán añadidas. Así que, no os afanéis por el día de mañana, porque el día de mañana traerá su afán. Basta a cada día su propio mal.',
          'reflection': 'El orden de prioridades determina la salud mental. Cuando colocas la rectitud moral, el servicio y la fidelidad divina en primer lugar, las necesidades materiales encuentran su justo equilibrio. Vive anclado en la exigencia del presente sin cargar con fantasmas del futuro.',
          'theme': 'Paz Mental & Confianza',
          'practical_action': 'Concéntrate exclusivamente en cumplir con fidelidad las tareas de hoy sin rumiar sobre los desafíos de la próxima semana.',
          'reading_path': 'paz_y_confianza',
        },
        {
          'id': 'rel-prov-13-20',
          'verse_ref': 'Proverbios 13:20',
          'verse_text': 'El que anda con sabios, sabio será; mas el que se junta con necios será quebrantado.',
          'reflection': 'Somos permeables al entorno social y cultural que toleramos. Las ideas, el vocabulario, las aspiraciones y los hábitos de tu círculo íntimo te moldearán de manera inexorable. Elige conscientemente a quienes alimentan tu crecimiento.',
          'theme': 'Sabiduría & Liderazgo',
          'practical_action': 'Evalúa con sobriedad la influencia de tus amistades y contenidos más frecuentes; decide rodearte de personas que eleven tu estándar.',
          'reading_path': 'proverbios_31',
        },
        {
          'id': 'rel-isa-40-29',
          'verse_ref': 'Isaías 40:29-31',
          'verse_text': 'Él da esfuerzo al cansado, y multiplica las fuerzas al que no tiene ningunas... los que esperan a Jehová tendrán nuevas fuerzas; levantarán alas como las águilas; correrán, y no se cansarán; caminarán, y no se fatigarán.',
          'reflection': 'La fuerza de voluntad biológica tiene límites metabólicos; tarde o temprano experimenta fatiga de decisión. Cuando tus reservas físicas flaqueen, la oración y la esperanza en Dios renuevan el vigor interior desde una fuente inagotable.',
          'theme': 'Dominio Propio & Fortaleza',
          'practical_action': 'Si te sientes agotado a media tarde, no recurras a estimulantes artificiales; tómate una pausa de recogimiento espiritual y respiración consciente.',
          'reading_path': 'fortaleza_en_la_prueba',
        },
        {
          'id': 'rel-ecl-3-1',
          'verse_ref': 'Eclesiastés 3:1',
          'verse_text': 'Todo tiene su tiempo, y todo lo que se quiere debajo del cielo tiene su hora.',
          'reflection': 'Querer cosechar cuando es momento de arar la tierra produce frustración patológica. Aceptar los ciclos y estaciones de la vida permite tolerar los inviernos de preparación sin desesperar por los veranos de fruto.',
          'theme': 'Paz Mental & Confianza',
          'practical_action': 'Identifica la estación actual en tu carrera o vida personal y abraza sus exigencias sin forzar atajos.',
          'reading_path': 'sabiduria_y_liderazgo',
        },
        {
          'id': 'rel-prov-14-29',
          'verse_ref': 'Proverbios 14:29',
          'verse_text': 'El que tarda en airarse es grande de entendimiento; mas el que es impaciente de espíritu enaltece la necedad.',
          'reflection': 'La templanza frente a la provocación es el sello distintivo de un estratega maduro. La reacción impulsiva transfiere el control de la situación al adversario o a la circunstancia externa.',
          'theme': 'Dominio Propio & Fortaleza',
          'practical_action': 'Si recibes una crítica o mensaje irritante hoy, aplica la regla de los 10 minutos antes de redactar o emitir cualquier respuesta.',
          'reading_path': 'proverbios_31',
        },
        {
          'id': 'rel-sal-23-1',
          'verse_ref': 'Salmo 23:1-3',
          'verse_text': 'Jehová es mi pastor; nada me faltará. En lugares de delicados pastos me hará descansar; junto a aguas de reposo me pastoreará. Confortará mi alma.',
          'reflection': 'La mentalidad de escasez y codicia nace del miedo al desamparo. Reconocer el cuidado fiel del Creador desarraiga el temor existencial y devuelve el alma a su estado natural de gratitud y suficiencia serena.',
          'theme': 'Paz Mental & Confianza',
          'practical_action': 'Haz una lista mental de tres provisiones fundamentales que hoy tienes garantizadas y da gracias por ellas.',
          'reading_path': 'paz_y_confianza',
        },
        {
          'id': 'rel-prov-22-29',
          'verse_ref': 'Proverbios 22:29',
          'verse_text': '¿Has visto hombre solícito en su trabajo? Delante de los reyes estará; no estará delante de los de baja condición.',
          'reflection': 'El término solícito denota prontitud, destreza técnica, precisión y confiabilidad. La excelencia profesional silenciosa abre puertas que la autopromoción ruidosa jamás logrará sostener.',
          'theme': 'Diligencia & Excelencia',
          'practical_action': 'Perfecciona un detalle técnico o estético de tu trabajo de hoy que normalmente dejarías pasar.',
          'reading_path': 'proverbios_31',
        },
        {
          'id': 'rel-2tim-1-7',
          'verse_ref': '2 Timoteo 1:7',
          'verse_text': 'Porque no nos ha dado Dios espíritu de cobardía, sino de poder, de amor y de dominio propio.',
          'reflection': 'El diseño original del ser humano no está condicionado por la parálisis tímida ni por la agresividad egoísta, sino por una tríada de virtudes supremas: poder moral para ejecutar, amor para servir, y dominio propio para gobernarse a sí mismo.',
          'theme': 'Dominio Propio & Fortaleza',
          'practical_action': 'Rechaza cualquier pensamiento derrotista que justifique la mediocridad; asume tu responsabilidad con entereza.',
          'reading_path': 'fortaleza_en_la_prueba',
        },
        {
          'id': 'rel-prov-15-1',
          'verse_ref': 'Proverbios 15:1',
          'verse_text': 'La blanda respuesta quita la ira; mas la palabra áspera hace subir el furor.',
          'reflection': 'La suavidad al hablar no es debilidad; es poder bajo absoluto control. Desactivar un conflicto mediante la sobriedad verbal requiere infinitamente más fuerza interior que dejarse arrastrar por el grito.',
          'theme': 'Dominio Propio & Fortaleza',
          'practical_action': 'En cualquier discrepancia hoy en el hogar o trabajo, modula el tono de tu voz y responde con serenidad empática.',
          'reading_path': 'proverbios_31',
        },
        {
          'id': 'rel-sal-37-4',
          'verse_ref': 'Salmo 37:4-5',
          'verse_text': 'Deléitate asimismo en Jehová, y él te concederá las peticiones de tu corazón. Encomienda a Jehová tu camino, y confía en él; y él hará.',
          'reflection': 'Deleitarse en el bien purifica los anhelos del corazón: ya no deseas cosas que dañan tu alma o perjudican a otros. Cuando confías plenamente en el plan divino, cesa la fricción interna y se abre paso la acción fecunda.',
          'theme': 'Paz Mental & Confianza',
          'practical_action': 'Examina los motivos profundos detrás de tu mayor meta actual: ¿busca glorificar a Dios y servir, o inflar el ego?',
          'reading_path': 'paz_y_confianza',
        },
        {
          'id': 'rel-prov-12-15',
          'verse_ref': 'Proverbios 12:15',
          'verse_text': 'El camino del necio es derecho en su opinión; mas el que obedece al consejo es sabio.',
          'reflection': 'La infalibilidad es una fantasía infantil del ego. Los mejores gobernantes, empresarios y estrategas de la historia se distinguieron por buscar deliberadamente la contradicción inteligente y el consejo prudente antes de actuar.',
          'theme': 'Sabiduría & Liderazgo',
          'practical_action': 'Pide la opinión honesta de alguien capacitado antes de cerrar un compromiso relevante hoy.',
          'reading_path': 'proverbios_31',
        },
        {
          'id': 'rel-ecl-9-10',
          'verse_ref': 'Eclesiastés 9:10',
          'verse_text': 'Todo lo que te viniere a la mano para hacer, hazlo según tus fuerzas; porque en el Seol, adonde vas, no hay obra, ni trabajo, ni ciencia, ni sabiduría.',
          'reflection': 'La oportunidad de actuar, crear, amar y edificar pertenece exclusivamente a este instante presente en la tierra. La procrastinación es un desprecio al regalo de la vida consciente.',
          'theme': 'Diligencia & Excelencia',
          'practical_action': 'Ejecuta con total presencia y compromiso la actividad en la que te encuentres, sin dispersar tu mente en otras pantallas.',
          'reading_path': 'liderazgo_y_excelencia',
        },
        {
          'id': 'rel-prov-19-21',
          'verse_ref': 'Proverbios 19:21',
          'verse_text': 'Muchos pensamientos hay en el corazón del hombre; mas el consejo de Jehová permanecerá.',
          'reflection': 'Podemos trazar planes minuciosos y estrategias impecables, pero la soberanía última sobre el destino le pertenece a Dios. La verdadera sabiduría consiste en planificar con rigor mientras mantienes un espíritu flexible y dócil a la providencia.',
          'theme': 'Sabiduría & Liderazgo',
          'practical_action': 'Si un plan se tuerce hoy, no te llenes de ira; busca qué aprendizaje o redirección providencial encierra el cambio de rumbo.',
          'reading_path': 'proverbios_31',
        },
        {
          'id': 'rel-sal-119-105',
          'verse_ref': 'Salmo 119:105',
          'verse_text': 'Lámpara es a mis pies tu palabra, y lumbrera a mi camino.',
          'reflection': 'Una lámpara de aceite en la noche antigua no iluminaba la colina completa a kilómetros de distancia; alumbraba únicamente el siguiente paso para no tropezar. Dios no siempre revela el mapa completo de tu vida, pero siempre concede luz suficiente para el deber inmediato.',
          'theme': 'Sabiduría & Liderazgo',
          'practical_action': 'No te angusties por el horizonte lejano; concéntrate en dar con rectitud el paso moral que te corresponde en la próxima hora.',
          'reading_path': 'sabiduria_y_liderazgo',
        },
        {
          'id': 'rel-prov-28-1',
          'verse_ref': 'Proverbios 28:1',
          'verse_text': 'Huye el impío sin que nadie lo persiga; mas el justo está confiado como un león.',
          'reflection': 'La culpa no resuelta y los engaños secretos generan una paranoia constante que corroe la tranquilidad del alma. La rectitud de conciencia, en cambio, confiere una audacia inquebrantable: no tienes nada que ocultar ni temer.',
          'theme': 'Dominio Propio & Fortaleza',
          'practical_action': 'Resuelve cualquier falta de transparencia o pequeña deuda moral pendiente para recuperar la serenidad del justo.',
          'reading_path': 'proverbios_31',
        },
        {
          'id': 'rel-rom-8-28',
          'verse_ref': 'Romanos 8:28',
          'verse_text': 'Y sabemos que a los que aman a Dios, todas las cosas les ayudan a bien, esto es, a los que conforme a su propósito son llamados.',
          'reflection': 'El principio supremo del amor fati cristiano: los fracasos aparentes, las demoras, las pérdidas y las dificultades no son accidentes caóticos, sino materia prima que la Providencia orquesta para forjar tu carácter, tu humildad y tu misión.',
          'theme': 'Paz Mental & Confianza',
          'practical_action': 'Reinterpreta una adversidad reciente no como una tragedia, sino como un entrenamiento indispensable para tu vocación.',
          'reading_path': 'fortaleza_en_la_prueba',
        },
        {
          'id': 'rel-prov-16-9',
          'verse_ref': 'Proverbios 16:9',
          'verse_text': 'El corazón del hombre piensa su camino; mas Jehová endereza sus pasos.',
          'reflection': 'La disciplina y la estrategia son tu responsabilidad indelegable; la dirección soberana y el fruto final le corresponden al Creador. Esta alianza entre la diligencia humana y la fe descansada es el secreto de los líderes con paz duradera.',
          'theme': 'Sabiduría & Liderazgo',
          'practical_action': 'Agradece al terminar este día por los pasos que pudiste dar y descansa con la confianza de estar en manos fieles.',
          'reading_path': 'proverbios_31',
        },
      ];

      for (final p in passages) {
        db.execute('''
          INSERT INTO religion_content (id, verse_ref, verse_text, reflection, language, theme, practical_action, reading_path)
          VALUES (?, ?, ?, ?, 'es', ?, ?, ?)
        ''', [
          p['id'],
          p['verse_ref'],
          p['verse_text'],
          p['reflection'],
          p['theme'],
          p['practical_action'],
          p['reading_path'],
        ]);
      }
    } catch (_) {
      // Table might not be ready yet
    }
  }

  static void _seedWellnessData(Database db) {
    try {
      final now = DateTime.now().toIso8601String();

      // 1. Initial Water Settings
      final waterSettingsCount = db.select('SELECT count(*) as count FROM water_settings').first['count'] as int;
      if (waterSettingsCount == 0) {
        db.execute('''
          INSERT INTO water_settings (user_id, daily_goal_ml, reminder_interval_minutes, wake_time, sleep_time, reminders_enabled, client_updated_at)
          VALUES ('local_user', 2000, 90, '07:00', '22:30', 1, ?)
        ''', [now]);
      }

      // 2. Initial Nutrition Settings
      final nutritionSettingsCount = db.select('SELECT count(*) as count FROM nutrition_settings').first['count'] as int;
      if (nutritionSettingsCount == 0) {
        db.execute('''
          INSERT INTO nutrition_settings (user_id, breakfast_time, lunch_time, dinner_time, reminders_enabled, client_updated_at)
          VALUES ('local_user', '08:00', '14:00', '20:00', 1, ?)
        ''', [now]);
      }

      // 3. Seed Nutrition Tips (15 curated executive tips)
      final tipsCount = db.select('SELECT count(*) as count FROM nutrition_tips').first['count'] as int;
      if (tipsCount == 0) {
        final tips = [
          {'id': 'tip-1', 'category': 'foco', 'tip_text': 'Hidratación matutina previa: Bebe 500 ml de agua templada al despertar para reactivar tu metabolismo y limpiar cortisol residual antes de consumir cafeína.'},
          {'id': 'tip-2', 'category': 'foco', 'tip_text': 'Desayuno rico en proteínas: Iniciar el día con huevos, frutos secos o proteína magra previene los picos de glucosa que generan niebla mental a media mañana.'},
          {'id': 'tip-3', 'category': 'energia', 'tip_text': 'Regla del 80% (Hara Hachi Bu): Detén tu comida cuando sientas saciedad al 80%. Esto preserva energía mitocondrial para tus proyectos en lugar de fatiga digestiva.'},
          {'id': 'tip-4', 'category': 'energia', 'tip_text': 'Carbohidratos complejos y fibra: Opta por cereales enteros, legumbres y tubérculos para una liberación sostenida de energía durante tus bloques de Deep Work.'},
          {'id': 'tip-5', 'category': 'recuperacion', 'tip_text': 'Cena temprana para sueño profundo: Concluye tu última ingesta 2.5 a 3 horas antes de dormir para permitir que tu cuerpo active la autofagia y la fase REM.'},
          {'id': 'tip-6', 'category': 'recuperacion', 'tip_text': 'Magnesio y descanso: Incluye semillas de calabaza, espinacas o almendras por la tarde para favorecer la relajación muscular y del sistema nervioso.'},
          {'id': 'tip-7', 'category': 'general', 'tip_text': 'El plato arcoíris: Incorpora al menos 3 colores vegetales distintos en tu comida principal para nutrir una microbiota diversa, base de tu inmunidad y ánimo.'},
          {'id': 'tip-8', 'category': 'foco', 'tip_text': 'Grasas saludables para tu cerebro: El aguacate, aceite de oliva virgen extra y omega-3 nutren las membranas neuronales y la velocidad de procesamiento cognitivo.'},
          {'id': 'tip-9', 'category': 'energia', 'tip_text': 'Cuidado con los azúcares ocultos: Evita refrescos y aderezos ultraprocesados; los bajones de energía a las 3:00 PM casi siempre son rebotes hipoglucémicos.'},
          {'id': 'tip-10', 'category': 'foco', 'tip_text': 'Té verde o matcha para foco calmado: La combinación de cafeína moderada con L-teanina promueve ondas alfa cerebrales de concentración sin agitación.'},
          {'id': 'tip-11', 'category': 'general', 'tip_text': 'Masticación consciente: Masticar cada bocado con calma no solo optimiza la absorción de nutrientes sino que estimula la respuesta parasimpática de calma.'},
          {'id': 'tip-12', 'category': 'energia', 'tip_text': 'Snacks estratégicos: Un puñado de nueces y chocolate oscuro (+75% cacao) aporta flavonoides antioxidantes y energía estable para tardes exigentes.'},
          {'id': 'tip-13', 'category': 'foco', 'tip_text': 'Evita comidas copiosas antes de reuniones críticas: Si necesitas agudeza mental, mantén una comida ligera y reserva alimentos más densos para la tarde.'},
          {'id': 'tip-14', 'category': 'recuperacion', 'tip_text': 'Electrolitos en días intensos: Añade una pizca de sal marina o limón a tu agua si has entrenado o sudado para mantener la conductividad celular óptima.'},
          {'id': 'tip-15', 'category': 'general', 'tip_text': 'Alimentos de ingrediente único: Basa el 80% de tu dieta en alimentos que no tengan etiqueta de ingredientes: carne, pescado, huevos, verduras, frutas y semillas.'},
        ];

        for (final t in tips) {
          db.execute('''
            INSERT INTO nutrition_tips (id, tip_text, category)
            VALUES (?, ?, ?)
          ''', [t['id'], t['tip_text'], t['category']]);
        }
      }

      // 4. Seed Affirmations (25 curated stoic & executive affirmations)
      final affCount = db.select('SELECT count(*) as count FROM affirmations').first['count'] as int;
      if (affCount == 0) {
        final affirmations = [
          {'id': 'aff-disc-1', 'category': 'disciplina', 'text': 'Mi enfoque no depende de mis emociones momentáneas; ejecuto con precisión y determinación.', 'author': 'Principio Focus'},
          {'id': 'aff-disc-2', 'category': 'disciplina', 'text': 'Hago lo necesario incluso cuando no tengo ganas; ahí reside mi verdadera ventaja competitiva.', 'author': 'Marco Aurelio'},
          {'id': 'aff-disc-3', 'category': 'disciplina', 'text': 'El autodominio es la llave de mi libertad y de mi soberanía personal.', 'author': 'Epicteto'},
          {'id': 'aff-disc-4', 'category': 'disciplina', 'text': 'No negocio con la pereza; cada compromiso conmigo mismo es un pacto sagrado e inquebrantable.', 'author': 'Séneca'},
          {'id': 'aff-disc-5', 'category': 'disciplina', 'text': 'Gobierno mis impulsos y dirijo mi atención hacia aquello que genera impacto trascendente.', 'author': 'FocusHabitual'},
          {'id': 'aff-auto-1', 'category': 'autoestima', 'text': 'Poseo la capacidad intelectual y el carácter templado para resolver cualquier desafío que se presente.', 'author': 'Claridad Ejecutiva'},
          {'id': 'aff-auto-2', 'category': 'autoestima', 'text': 'Mi valor intrínseco no fluctúa con la opinión ajena; confío en mi preparación, ética y constancia.', 'author': 'Séneca'},
          {'id': 'aff-auto-3', 'category': 'autoestima', 'text': 'Merezco los frutos de mi esfuerzo honesto y acepto mi crecimiento sin reservas ni complejos.', 'author': 'Mentalidad de Crecimiento'},
          {'id': 'aff-auto-4', 'category': 'autoestima', 'text': 'Tengo la valentía y el discernimiento de decir no a lo trivial para proteger con celo lo esencial.', 'author': 'Esencialismo'},
          {'id': 'aff-abun-1', 'category': 'abundancia', 'text': 'El valor genuino que creo de forma consistente regresa a mi vida multiplicado en oportunidades y prosperidad.', 'author': 'Estrategia Patrimonial'},
          {'id': 'aff-abun-2', 'category': 'abundancia', 'text': 'Gestiono mis recursos con maestría y prudencia; construyo un patrimonio sólido que brinda libertad a mi familia.', 'author': 'Dominio Financiero'},
          {'id': 'aff-abun-3', 'category': 'abundancia', 'text': 'La prosperidad es el resultado natural de resolver problemas difíciles con excelencia sostenida.', 'author': 'Visión Focus'},
          {'id': 'aff-abun-4', 'category': 'abundancia', 'text': 'Veo posibilidades donde otros ven límites; mi mente está calibrada para generar abundancia duradera.', 'author': 'Pensamiento Estratégico'},
          {'id': 'aff-salud-1', 'category': 'salud', 'text': 'Nutro mi cuerpo con agua pura, alimento vivo y descanso profundo; es el instrumento fundamental de mi ejecución.', 'author': 'Vitalidad Biológica'},
          {'id': 'aff-salud-2', 'category': 'salud', 'text': 'Mi energía física es el combustible indispensable para mi claridad estratégica y mi agudeza mental.', 'author': 'Biohacking Focus'},
          {'id': 'aff-salud-3', 'category': 'salud', 'text': 'Respeto los ritmos biológicos de mi organismo y optimizo conscientemente mi recuperación cada día.', 'author': 'Ciencia del Sueño'},
          {'id': 'aff-salud-4', 'category': 'salud', 'text': 'Trato a mi salud como mi activo patrimonial más valioso e insustituible.', 'author': 'Longevidad & Foco'},
          {'id': 'aff-fe-1', 'category': 'fe', 'text': 'Encomiendo mi esfuerzo a un propósito superior y descanso en la serenidad de hacer siempre lo recto.', 'author': 'Proverbios 16:3'},
          {'id': 'aff-fe-2', 'category': 'fe', 'text': 'En medio de la incertidumbre mantengo una paz inquebrantable; todo obra para mi crecimiento y fortaleza.', 'author': 'Romanos 8:28'},
          {'id': 'aff-fe-3', 'category': 'fe', 'text': 'La fe no elimina el trabajo arduo; lo dota de sentido, rectitud moral y bendición trascendente.', 'author': 'Sabiduría Bíblica'},
          {'id': 'aff-lid-1', 'category': 'liderazgo', 'text': 'Lidero con la coherencia de mis actos antes que con la mera elocuencia de mis palabras.', 'author': 'Liderazgo por Ejemplo'},
          {'id': 'aff-lid-2', 'category': 'liderazgo', 'text': 'Escucho con profundidad reflexiva, decido con criterio independiente y actúo con templanza.', 'author': 'Juicio Crítico'},
          {'id': 'aff-lid-3', 'category': 'liderazgo', 'text': 'Mi estándar de excelencia personal eleva e inspira la calidad de quienes colaboran conmigo.', 'author': 'Impacto Focus'},
          {'id': 'aff-disc-6', 'category': 'disciplina', 'text': 'La paciencia estratégica combinada con la urgencia táctica garantiza victorias duraderas.', 'author': 'Estrategia Clásica'},
          {'id': 'aff-auto-5', 'category': 'autoestima', 'text': 'Hoy elijo la compostura serena, la claridad mental y el avance firme e inalterable en mis metas.', 'author': 'Foco Diario'},
        ];

        for (final a in affirmations) {
          db.execute('''
            INSERT INTO affirmations (id, text, category, author, language)
            VALUES (?, ?, ?, ?, 'es')
          ''', [a['id'], a['text'], a['category'], a['author']]);
        }
      }

      // 5. Seed Ambient Sounds (7 natural audio files)
      final soundsCount = db.select('SELECT count(*) as count FROM ambient_sounds').first['count'] as int;
      if (soundsCount == 0) {
        for (final s in ChallengeCatalog.allSounds) {
          db.execute('''
            INSERT INTO ambient_sounds (id, name, category, audio_url, loopable)
            VALUES (?, ?, ?, ?, ?)
          ''', [s.id, s.name, s.category, s.audioUrl, s.loopable ? 1 : 0]);
        }
      }

      // 6. Seed Wellness Exercises (63 total: 21 meditation, 21 yoga, 21 yoga facial)
      final exercisesCount = db.select('SELECT count(*) as count FROM wellness_exercises').first['count'] as int;
      if (exercisesCount == 0) {
        for (final ex in ChallengeCatalog.allExercises) {
          db.execute('''
            INSERT INTO wellness_exercises (id, challenge_type, day_number, title, tip, instructions, video_url, duration_minutes)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
          ''', [ex.id, ex.challengeType.key, ex.dayNumber, ex.title, ex.tip, ex.instructions, ex.videoUrl, ex.durationMinutes]);
        }
      }

      // 7. Initialize default active challenges for local_user
      final challengesCount = db.select('SELECT count(*) as count FROM wellness_challenges WHERE user_id = ?', ['local_user']).first['count'] as int;
      if (challengesCount == 0) {
        final challengeTypes = ['meditation', 'yoga', 'yoga_facial'];
        for (final cType in challengeTypes) {
          final cid = 'chal-$cType-local';
          db.execute('''
            INSERT INTO wellness_challenges (id, user_id, challenge_type, total_days, started_at, is_active, client_id, client_updated_at)
            VALUES (?, 'local_user', ?, 21, ?, 1, ?, ?)
          ''', [cid, cType, now, cid, now]);
        }
      }

      // 8. Seed Default Daily Block Template (Plan de Implementación Inmediata)
      final templateCount = db.select('SELECT count(*) as count FROM daily_block_templates').first['count'] as int;
      if (templateCount == 0) {
        const templateId = 'template-default-immediate';
        db.execute('''
          INSERT INTO daily_block_templates (id, user_id, name, is_default, created_at)
          VALUES (?, 'local_user', 'Plan de Implementación Inmediata', 1, ?)
        ''', [templateId, now]);

        final blocks = [
          {'start_time': '08:00', 'duration_minutes': 90, 'mode_key': 'ultradian', 'work_type': 'deep_work', 'label': 'Deep Work — estudio técnico denso o desarrollo core', 'sort': 1},
          {'start_time': '09:30', 'duration_minutes': 30, 'mode_key': 'classic', 'work_type': 'shallow_work', 'label': 'Pausa activa — desconexión analógica total', 'sort': 2},
          {'start_time': '10:00', 'duration_minutes': 50, 'mode_key': 'extended', 'work_type': 'deep_work', 'label': 'Deep Work — depuración, testing, implementación', 'sort': 3},
          {'start_time': '10:50', 'duration_minutes': 10, 'mode_key': 'classic', 'work_type': 'shallow_work', 'label': 'Pausa activa — hidratación y movilidad', 'sort': 4},
          {'start_time': '11:00', 'duration_minutes': 25, 'mode_key': 'classic', 'work_type': 'shallow_work', 'label': 'Shallow Work — revisión de notas, commits, logística', 'sort': 5},
        ];

        for (final b in blocks) {
          db.execute('''
            INSERT INTO daily_block_template_items (id, template_id, start_time, duration_minutes, mode_key, work_type, label, sort_order)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
          ''', [
            _uuid.v4(),
            templateId,
            b['start_time'],
            b['duration_minutes'],
            b['mode_key'],
            b['work_type'],
            b['label'],
            b['sort'],
          ]);
        }
      }
    } catch (_) {
      // Table might not be ready yet
    }
  }

  /// Retrieves all unlocked achievements for a user.
  static List<Map<String, dynamic>> getUnlockedAchievements({String userId = 'local_user'}) {
    try {
      final results = instance.select('''
        SELECT id, user_id, achievement_key, module, unlocked_at
        FROM achievements
        WHERE user_id = ?
        ORDER BY unlocked_at DESC
      ''', [userId]);
      return results.map((row) => Map<String, dynamic>.from(row)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Unlocks an achievement if not already unlocked. Returns true if newly unlocked.
  static bool unlockAchievement({
    required String achievementKey,
    required String module,
    String userId = 'local_user',
  }) {
    try {
      final existing = instance.select('''
        SELECT count(*) as count FROM achievements WHERE user_id = ? AND achievement_key = ?
      ''', [userId, achievementKey]);
      if ((existing.first['count'] as int) > 0) {
        return false;
      }

      final now = DateTime.now().toIso8601String();
      final id = _uuid.v4();
      instance.execute('''
        INSERT INTO achievements (id, user_id, achievement_key, module, unlocked_at)
        VALUES (?, ?, ?, ?, ?)
      ''', [id, userId, achievementKey, module, now]);

      enqueueSync(
        tableName: 'achievements',
        recordId: id,
        action: 'insert',
        payload: {
          'id': id,
          'user_id': userId,
          'achievement_key': achievementKey,
          'module': module,
          'unlocked_at': now,
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Checks if an achievement is already unlocked.
  static bool isAchievementUnlocked(String achievementKey, {String userId = 'local_user'}) {
    try {
      final existing = instance.select('''
        SELECT count(*) as count FROM achievements WHERE user_id = ? AND achievement_key = ?
      ''', [userId, achievementKey]);
      return (existing.first['count'] as int) > 0;
    } catch (_) {
      return false;
    }
  }

  /// Records an XP event.
  static void recordXpEvent({
    required String sourceModule,
    required int xpAmount,
    String userId = 'local_user',
  }) {
    try {
      final now = DateTime.now().toIso8601String();
      final id = _uuid.v4();
      instance.execute('''
        INSERT INTO xp_events (id, user_id, source_module, xp_amount, occurred_at)
        VALUES (?, ?, ?, ?, ?)
      ''', [id, userId, sourceModule, xpAmount, now]);
    } catch (_) {}
  }

  /// Retrieves recent XP events for the user.
  static List<Map<String, dynamic>> getRecentXpEvents({String userId = 'local_user', int limit = 20}) {
    try {
      final results = instance.select('''
        SELECT id, user_id, source_module, xp_amount, occurred_at
        FROM xp_events
        WHERE user_id = ?
        ORDER BY occurred_at DESC
        LIMIT ?
      ''', [userId, limit]);
      return results.map((row) => Map<String, dynamic>.from(row)).toList();
    } catch (_) {
      return [];
    }
  }

  static void _seedThinkersData(Database db) {
    try {
      final rows = db.select('SELECT count(*) as count FROM thinkers');
      final count = rows.first['count'] as int;
      if (count == 0) {
        for (final t in ThinkersCatalog.all) {
          db.execute('''
            INSERT OR IGNORE INTO thinkers (id, slug, name, category, era_label, origin, key_idea, key_work, requires_religious, unlock_xp)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''', [
            t.id,
            t.slug,
            t.name,
            t.category,
            t.eraLabel,
            t.origin,
            t.keyIdea,
            t.keyWork,
            t.requiresReligious ? 1 : 0,
            t.unlockXp,
          ]);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[AppDatabase] Error seeding thinkers: $e');
      }
    }
  }

  /// Retrieves a local user profile by ID.
  static Map<String, dynamic>? getLocalProfile(String id) {
    try {
      final rows = instance.select('SELECT * FROM local_profiles WHERE id = ?', [id]);
      if (rows.isNotEmpty) {
        return Map<String, dynamic>.from(rows.first);
      }
    } catch (e) {
      if (kDebugMode) {
        print('[AppDatabase] Error getting local profile: $e');
      }
    }
    return null;
  }

  /// Finds a local profile by email.
  static Map<String, dynamic>? findLocalProfileByEmail(String email) {
    try {
      final rows = instance.select('SELECT * FROM local_profiles WHERE LOWER(email) = ?', [email.trim().toLowerCase()]);
      if (rows.isNotEmpty) {
        return Map<String, dynamic>.from(rows.first);
      }
    } catch (e) {
      if (kDebugMode) {
        print('[AppDatabase] Error finding profile by email: $e');
      }
    }
    return null;
  }

  /// Inserts or updates a local user profile.
  static void saveLocalProfile({
    required String id,
    required String email,
    String? passwordHash,
    String? fullName,
    String gender = 'male',
    bool isReligious = false,
    bool onboardingCompleted = false,
    String provider = 'local',
  }) {
    try {
      final now = DateTime.now().toIso8601String();
      instance.execute('''
        INSERT INTO local_profiles (id, email, password_hash, full_name, gender, is_religious, onboarding_completed, provider, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET
          email = excluded.email,
          password_hash = COALESCE(excluded.password_hash, local_profiles.password_hash),
          full_name = COALESCE(excluded.full_name, local_profiles.full_name),
          gender = excluded.gender,
          is_religious = excluded.is_religious,
          onboarding_completed = excluded.onboarding_completed,
          provider = excluded.provider,
          updated_at = excluded.updated_at
      ''', [
        id,
        email.trim().toLowerCase(),
        passwordHash,
        fullName,
        gender,
        isReligious ? 1 : 0,
        onboardingCompleted ? 1 : 0,
        provider,
        now,
        now,
      ]);
    } catch (e) {
      if (kDebugMode) {
        print('[AppDatabase] Error saving local profile: $e');
      }
    }
  }

  /// Returns list of thinkers from SQLite with unlock & favorite status.
  static List<Map<String, dynamic>> getThinkers({String? userId, String? category, bool includeReligious = true}) {
    try {
      final uid = userId ?? 'local_user';
      final buffer = StringBuffer('''
        SELECT t.*, 
               COALESCE(u.is_favorite, 0) as is_favorite,
               COALESCE(u.unlocked_at, '') as unlocked_at
        FROM thinkers t
        LEFT JOIN user_thinker_unlocks u ON t.id = u.thinker_id AND u.user_id = ?
        WHERE 1=1
      ''');
      final params = <dynamic>[uid];

      if (!includeReligious) {
        buffer.write(' AND t.requires_religious = 0');
      }

      if (category != null && category.isNotEmpty && category != 'all') {
        buffer.write(' AND t.category = ?');
        params.add(category);
      }

      buffer.write(' ORDER BY CAST(SUBSTR(t.id, 9) AS INTEGER) ASC');

      final rows = instance.select(buffer.toString(), params);
      return rows.map((r) => Map<String, dynamic>.from(r)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('[AppDatabase] Error getting thinkers: $e');
      }
      return [];
    }
  }

  /// Toggles favorite status for a thinker.
  static void toggleThinkerFavorite({required String userId, required String thinkerId, required bool isFavorite}) {
    try {
      final now = DateTime.now().toIso8601String();
      instance.execute('''
        INSERT INTO user_thinker_unlocks (user_id, thinker_id, unlocked_at, is_favorite)
        VALUES (?, ?, ?, ?)
        ON CONFLICT(user_id, thinker_id) DO UPDATE SET
          is_favorite = excluded.is_favorite
      ''', [userId, thinkerId, now, isFavorite ? 1 : 0]);
    } catch (e) {
      if (kDebugMode) {
        print('[AppDatabase] Error toggling thinker favorite: $e');
      }
    }
  }

  /// Records a note in the Interruption Sheet during an active focus session.
  static void saveInterruptionNote({
    required String id,
    required String sessionId,
    required String userId,
    required String noteText,
    required DateTime capturedAt,
  }) {
    try {
      instance.execute('''
        INSERT INTO pomodoro_interruption_notes (id, session_id, user_id, note_text, captured_at)
        VALUES (?, ?, ?, ?, ?)
      ''', [id, sessionId, userId, noteText, capturedAt.toIso8601String()]);

      enqueueSync(
        tableName: 'pomodoro_interruption_notes',
        recordId: id,
        action: 'INSERT',
        payload: {
          'id': id,
          'session_id': sessionId,
          'user_id': userId,
          'note_text': noteText,
          'captured_at': capturedAt.toIso8601String(),
        },
      );
    } catch (e) {
      if (kDebugMode) print('[AppDatabase] Error saving interruption note: $e');
    }
  }

  /// Retrieves notes captured for a specific Pomodoro session.
  static List<Map<String, dynamic>> getInterruptionNotesForSession(String sessionId) {
    try {
      final rows = instance.select('''
        SELECT id, session_id, user_id, note_text, captured_at, converted_to_habit_id
        FROM pomodoro_interruption_notes
        WHERE session_id = ?
        ORDER BY captured_at ASC
      ''', [sessionId]);
      return rows.map((r) => Map<String, dynamic>.from(r)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Marks an interruption note as converted into a habit.
  static void markInterruptionNoteConverted(String noteId, String habitId) {
    try {
      instance.execute('''
        UPDATE pomodoro_interruption_notes
        SET converted_to_habit_id = ?
        WHERE id = ?
      ''', [habitId, noteId]);
    } catch (_) {}
  }

  /// Retrieves default daily block template items for the active user.
  static List<Map<String, dynamic>> getDefaultDailyBlockItems() {
    try {
      final rows = instance.select('''
        SELECT i.id, i.start_time, i.duration_minutes, i.mode_key, i.work_type, i.label, i.sort_order
        FROM daily_block_template_items i
        JOIN daily_block_templates t ON i.template_id = t.id
        WHERE t.is_default = 1
        ORDER BY i.sort_order ASC
      ''');
      return rows.map((r) => Map<String, dynamic>.from(r)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Adds a custom daily block item to the default template.
  static void addDailyBlockItem({
    required String startTime,
    required int durationMinutes,
    required String modeKey,
    required String workType,
    required String label,
  }) {
    try {
      final defaultTpl = instance.select('SELECT id FROM daily_block_templates WHERE is_default = 1 LIMIT 1');
      if (defaultTpl.isEmpty) return;
      final templateId = defaultTpl.first['id'] as String;
      final id = _uuid.v4();
      final maxSort = instance.select(
        'SELECT coalesce(max(sort_order), 0) + 1 as next_sort FROM daily_block_template_items WHERE template_id = ?',
        [templateId],
      );
      final nextSort = (maxSort.first['next_sort'] as int?) ?? 1;

      instance.execute('''
        INSERT INTO daily_block_template_items (id, template_id, start_time, duration_minutes, mode_key, work_type, label, sort_order)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ''', [id, templateId, startTime, durationMinutes, modeKey, workType, label, nextSort]);
    } catch (_) {}
  }
}


