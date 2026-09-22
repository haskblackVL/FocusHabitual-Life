import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized environment configuration.
/// Safely retrieves variables defined in the `.env` file.
class AppEnv {
  AppEnv._();

  /// Loads the environment file. Falls back silently if missing or empty.
  static Future<void> init() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // In tests or if .env is missing, fallback defaults will be used.
    }
  }

  static String get supabaseUrl =>
      dotenv.env['SUPABASE_URL'] ?? 'https://placeholder.supabase.co';

  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ?? 'placeholder-anon-key';

  static bool get isConfigured =>
      supabaseUrl != 'https://placeholder.supabase.co' &&
      supabaseAnonKey != 'placeholder-anon-key';
}
