import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env.dart';

/// Service responsible for managing Supabase initialization and client instance.
class SupabaseService {
  SupabaseService._();

  static SupabaseClient? _client;

  /// Returns the active [SupabaseClient]. Throws if not yet initialized.
  static SupabaseClient get client {
    if (_client == null) {
      throw StateError(
        'SupabaseService has not been initialized. Call SupabaseService.init() first.',
      );
    }
    return _client!;
  }

  /// Whether Supabase has been initialized with valid credentials.
  static bool get isInitialized => _client != null && AppEnv.isConfigured;

  /// Initializes Supabase with configured environment variables.
  static Future<void> init() async {
    if (!AppEnv.isConfigured) {
      if (kDebugMode) {
        print(
          '[SupabaseService] Running in offline/mock mode. Set SUPABASE_URL and SUPABASE_ANON_KEY in .env to connect to live backend.',
        );
      }
      return;
    }

    try {
      await Supabase.initialize(
        url: AppEnv.supabaseUrl,
        publishableKey: AppEnv.supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );
      _client = Supabase.instance.client;
    } catch (e, st) {
      if (kDebugMode) {
        print('[SupabaseService] Initialization failed: $e\n$st');
      }
    }
  }
}
