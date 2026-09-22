import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notifier managing active ThemeMode.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.light;

  void setMode(ThemeMode mode) {
    state = mode;
  }
}

/// Provider for application theme mode (defaults to elegant dark).
final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

/// Basic auth state representation for route guards and session management.
enum AuthStatus {
  unauthenticated,
  authenticated,
  guestOffline,
}

/// Notifier managing user authentication status.
class AuthStatusNotifier extends Notifier<AuthStatus> {
  @override
  AuthStatus build() => AuthStatus.guestOffline;

  void setStatus(AuthStatus status) {
    state = status;
  }
}

/// Provider for user authentication status.
final authStatusProvider =
    NotifierProvider<AuthStatusNotifier, AuthStatus>(AuthStatusNotifier.new);
