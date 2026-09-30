import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'core/config/env.dart';
import 'core/local_db/database.dart';
import 'core/notifications/local_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Intl date formatting for all locales
  await initializeDateFormatting();

  // Load environment variables (.env) if present
  await AppEnv.init();

  // Initialize SQLite Local Database (100% Local & Offline-First)
  await AppDatabase.init();

  // Initialize Local Notifications & Timezone Channels
  await LocalNotificationService().initialize();

  runApp(
    const ProviderScope(
      child: FocusHabitualApp(),
    ),
  );
}
