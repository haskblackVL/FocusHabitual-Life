import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/local_db/database.dart';
import '../domain/user_profile.dart';

/// Repository for 100% offline local authentication and profile management.
class AuthRepository extends ChangeNotifier {
  AuthRepository() {
    _restoreActiveSession();
  }

  bool _isGuestMode = false;
  bool get isGuestMode => _isGuestMode;

  AuthUser? _currentUser;
  AuthUser? get currentUser => _currentUser;

  /// Whether a user or guest is currently signed in.
  bool get isAuthenticated => _isGuestMode || _currentUser != null;

  void _restoreActiveSession() {
    try {
      final activeId = AppDatabase.getSetting('active_user_id');
      if (activeId != null && activeId.isNotEmpty && activeId != 'local_user') {
        final profile = AppDatabase.getLocalProfile(activeId);
        if (profile != null) {
          _currentUser = AuthUser(
            id: activeId,
            email: profile['email'] as String? ?? 'usuario@focushabitual.local',
            userMetadata: {
              'full_name': profile['full_name'] ?? 'Usuario FocusHabitual',
            },
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[AuthRepository] Error restoring session: $e');
      }
    }
  }

  /// Enables guest mode to use the app completely offline without authentication.
  void setGuestMode(bool value) {
    _isGuestMode = value;
    if (value) {
      _currentUser = null;
      AppDatabase.setSetting('active_user_id', 'local_user');
    }
    notifyListeners();
  }

  /// Registers a new user locally with email, password, and full name.
  Future<AuthUser> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final existing = AppDatabase.findLocalProfileByEmail(cleanEmail);
    if (existing != null) {
      throw StateError('Ya existe una cuenta registrada con este correo electrónico.');
    }

    final newId = 'usr_${DateTime.now().millisecondsSinceEpoch}';
    final cleanName = fullName.trim().isNotEmpty ? fullName.trim() : 'Usuario FocusHabitual';

    AppDatabase.saveLocalProfile(
      id: newId,
      email: cleanEmail,
      passwordHash: password, // Stored locally on encrypted device SQLite
      fullName: cleanName,
      gender: 'male',
      isReligious: false,
      onboardingCompleted: false,
      provider: 'local',
    );

    AppDatabase.setSetting('active_user_id', newId);
    AppDatabase.setSetting('profile_full_name_$newId', cleanName);

    _isGuestMode = false;
    _currentUser = AuthUser(
      id: newId,
      email: cleanEmail,
      userMetadata: {'full_name': cleanName},
    );

    notifyListeners();
    return _currentUser!;
  }

  /// Authenticates an existing user locally with email and password.
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final profile = AppDatabase.findLocalProfileByEmail(cleanEmail);

    if (profile == null) {
      throw StateError('No se encontró ninguna cuenta con el correo "$cleanEmail". Regístrate primero.');
    }

    final storedPassword = profile['password_hash'] as String?;
    if (storedPassword != null && storedPassword.isNotEmpty && storedPassword != password) {
      throw StateError('Contraseña incorrecta. Por favor intenta de nuevo.');
    }

    final id = profile['id'] as String;
    final fullName = profile['full_name'] as String? ?? 'Usuario FocusHabitual';

    AppDatabase.setSetting('active_user_id', id);

    _isGuestMode = false;
    _currentUser = AuthUser(
      id: id,
      email: cleanEmail,
      userMetadata: {'full_name': fullName},
    );

    notifyListeners();
    return _currentUser!;
  }

  /// Authenticates using a 100% offline Google account simulation.
  Future<bool> signInWithGoogle() async {
    const googleId = 'google_user_local';
    const googleEmail = 'usuario.google@focushabitual.local';
    const googleName = 'Usuario Google';

    AppDatabase.saveLocalProfile(
      id: googleId,
      email: googleEmail,
      fullName: googleName,
      provider: 'google',
      onboardingCompleted: true,
    );

    AppDatabase.setSetting('active_user_id', googleId);
    AppDatabase.setSetting('profile_full_name_$googleId', googleName);

    _isGuestMode = false;
    _currentUser = const AuthUser(
      id: googleId,
      email: googleEmail,
      userMetadata: {'full_name': googleName},
    );

    notifyListeners();
    return true;
  }

  /// Signs out from active session.
  Future<void> signOut() async {
    _isGuestMode = false;
    _currentUser = null;
    AppDatabase.setSetting('active_user_id', '');
    notifyListeners();
  }

  /// Fetches the profile for the current user or guest.
  Future<UserProfile> getProfile() async {
    final user = _currentUser;
    final uid = (_isGuestMode || user == null) ? 'local_user' : user.id;

    // 1. Check local_profiles table
    if (uid != 'local_user') {
      final dbRow = AppDatabase.getLocalProfile(uid);
      if (dbRow != null) {
        return UserProfile(
          id: uid,
          fullName: dbRow['full_name'] as String? ?? (user?.userMetadata?['full_name'] as String? ?? 'Usuario FocusHabitual'),
          gender: dbRow['gender'] as String? ?? 'male',
          isReligious: (dbRow['is_religious'] as int? ?? 0) == 1,
          onboardingCompleted: (dbRow['onboarding_completed'] as int? ?? 0) == 1,
        );
      }
    }

    // 2. Fallback to app_settings key-values
    final localName = AppDatabase.getSetting('profile_full_name_$uid') ??
        (uid == 'local_user' ? AppDatabase.getSetting('profile_full_name') : null);
    final localGender = AppDatabase.getSetting('profile_gender_$uid') ??
        (uid == 'local_user' ? AppDatabase.getSetting('profile_gender') : null) ?? 'male';
    final localIsReligious = (AppDatabase.getSetting('profile_is_religious_$uid') ??
        (uid == 'local_user' ? AppDatabase.getSetting('profile_is_religious') : null)) == 'true';
    final localOnboardingDone = (AppDatabase.getSetting('profile_onboarding_completed_$uid') ??
        (uid == 'local_user' ? AppDatabase.getSetting('profile_onboarding_completed') : null)) == 'true';

    return UserProfile(
      id: uid,
      fullName: localName ?? (user?.userMetadata?['full_name'] as String? ?? 'Usuario FocusHabitual'),
      gender: localGender,
      isReligious: localIsReligious,
      onboardingCompleted: localOnboardingDone,
    );
  }

  /// Updates user profile in local SQLite and app settings.
  Future<UserProfile> updateProfile(UserProfile profile) async {
    _cacheProfileLocally(profile);

    AppDatabase.saveLocalProfile(
      id: profile.id,
      email: _currentUser?.email ?? 'usuario@focushabitual.local',
      fullName: profile.fullName,
      gender: profile.gender,
      isReligious: profile.isReligious,
      onboardingCompleted: profile.onboardingCompleted,
    );

    notifyListeners();
    return profile;
  }

  void _cacheProfileLocally(UserProfile profile) {
    final uid = profile.id;
    if (profile.fullName != null) {
      AppDatabase.setSetting('profile_full_name_$uid', profile.fullName!);
      if (uid == 'local_user') {
        AppDatabase.setSetting('profile_full_name', profile.fullName!);
      }
    }
    AppDatabase.setSetting('profile_gender_$uid', profile.gender);
    AppDatabase.setSetting('profile_is_religious_$uid', profile.isReligious ? 'true' : 'false');
    AppDatabase.setSetting('profile_onboarding_completed_$uid', profile.onboardingCompleted ? 'true' : 'false');

    if (uid == 'local_user') {
      AppDatabase.setSetting('profile_gender', profile.gender);
      AppDatabase.setSetting('profile_is_religious', profile.isReligious ? 'true' : 'false');
      AppDatabase.setSetting('profile_onboarding_completed', profile.onboardingCompleted ? 'true' : 'false');
    }
  }
}
