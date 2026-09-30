import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/gamification/gamification_controller.dart';
import '../../../../core/local_db/sync_engine.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/gratitude_repository.dart';
import '../../domain/gratitude_model.dart';

/// Provider for GratitudeRepository with current active user.
final gratitudeRepositoryProvider = Provider<GratitudeRepository>((ref) {
  final user = ref.watch(authControllerProvider).value;
  return GratitudeRepository(currentUserId: user?.id);
});

/// Provider for today's Gratitude entry.
final todayGratitudeProvider =
    AsyncNotifierProvider<TodayGratitudeNotifier, GratitudeEntry?>(
  TodayGratitudeNotifier.new,
);

class TodayGratitudeNotifier extends AsyncNotifier<GratitudeEntry?> {
  GratitudeRepository get _repo => ref.read(gratitudeRepositoryProvider);

  @override
  FutureOr<GratitudeEntry?> build() async {
    ref.watch(gratitudeRepositoryProvider);
    return _repo.getTodayEntry();
  }

  /// Saves today's gratitude reflection and refreshes dependents.
  Future<GratitudeEntry> saveEntry({
    required String item1,
    String? item2,
    String? item3,
    String? reflection,
  }) async {
    state = const AsyncLoading();
    final entry = await _repo.saveEntry(
      item1: item1,
      item2: item2,
      item3: item3,
      reflection: reflection,
    );

    state = AsyncData(entry);
    ref.invalidate(gratitudeHistoryProvider);
    ref.invalidate(gratitudeStreakProvider);
    ref.invalidate(gamificationProvider);

    // Trigger instant background sync
    ref.read(syncEngineProvider).syncNow();

    return entry;
  }
}

/// Provider for gratitude entry history list.
final gratitudeHistoryProvider = FutureProvider<List<GratitudeEntry>>((ref) async {
  final repo = ref.watch(gratitudeRepositoryProvider);
  return repo.getGratitudeHistory(limit: 30);
});

/// Provider for consecutive gratitude streak.
final gratitudeStreakProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(gratitudeRepositoryProvider);
  ref.watch(todayGratitudeProvider);
  return repo.getGratitudeStreak();
});
