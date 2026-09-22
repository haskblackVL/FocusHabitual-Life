import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/config/env.dart';
import 'core/local_db/database.dart';
import 'core/supabase/supabase_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables (.env)
  await AppEnv.init();

  // Initialize SQLite Local Database (Offline-first)
  await AppDatabase.init();

  // Initialize Supabase client
  await SupabaseService.init();

  runApp(
    const ProviderScope(
      child: FocusHabitualApp(),
    ),
  );
}
