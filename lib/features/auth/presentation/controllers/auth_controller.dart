import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_repository.dart';
import '../../domain/user_profile.dart';

/// Provider for AuthRepository.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Controller managing the authenticated user session (100% Local).
final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthUser?>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<AuthUser?> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  FutureOr<AuthUser?> build() {
    ref.watch(authRepositoryProvider);
    return _repo.currentUser;
  }

  /// Sign in with email and password locally.
  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    try {
      final user = await _repo.signIn(email: email, password: password);
      ref.invalidate(userProfileControllerProvider);
      state = AsyncData(user);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Sign up new user with email, password, and full name locally.
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    state = const AsyncLoading();
    try {
      final user = await _repo.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );
      ref.invalidate(userProfileControllerProvider);
      state = AsyncData(user);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Sign in with local Google account.
  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    try {
      await _repo.signInWithGoogle();
      ref.invalidate(userProfileControllerProvider);
      state = AsyncData(_repo.currentUser);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Continues into the application as a guest (offline mode).
  void continueAsGuest() {
    _repo.setGuestMode(true);
    ref.invalidate(userProfileControllerProvider);
    state = const AsyncData(null);
  }

  /// Signs out the active user session.
  Future<void> signOut() async {
    state = const AsyncLoading();
    await _repo.signOut();
    ref.invalidate(userProfileControllerProvider);
    state = const AsyncData(null);
  }
}

/// Controller managing the current user's profile and onboarding state.
final userProfileControllerProvider =
    AsyncNotifierProvider<UserProfileController, UserProfile>(
  UserProfileController.new,
);

class UserProfileController extends AsyncNotifier<UserProfile> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  FutureOr<UserProfile> build() async {
    ref.watch(authRepositoryProvider);
    return _repo.getProfile();
  }

  /// Completes user onboarding and persists selection.
  Future<void> completeOnboarding({
    required String fullName,
    required String gender,
    required bool isReligious,
  }) async {
    final current = state.value ?? UserProfile.guest();
    final updated = current.copyWith(
      fullName: fullName.trim().isNotEmpty ? fullName.trim() : current.fullName,
      gender: gender,
      isReligious: isReligious,
      onboardingCompleted: true,
      updatedAt: DateTime.now(),
    );

    // If user is not authenticated, enable guest mode
    if (_repo.currentUser == null) {
      _repo.setGuestMode(true);
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return _repo.updateProfile(updated);
    });
  }

  /// Updates user gender in settings (dynamically switches NoFap / Cycle modules).
  Future<void> updateGender(String gender) async {
    final current = state.value;
    if (current == null) return;
    final updated = current.copyWith(gender: gender);
    state = await AsyncValue.guard(() => _repo.updateProfile(updated));
  }

  /// Updates religious preference in settings (switches daily verse module).
  Future<void> updateIsReligious(bool isReligious) async {
    final current = state.value;
    if (current == null) return;
    final updated = current.copyWith(isReligious: isReligious);
    state = await AsyncValue.guard(() => _repo.updateProfile(updated));
  }
}
