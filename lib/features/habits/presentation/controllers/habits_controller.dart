import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../core/gamification/gamification_controller.dart';
import '../../data/habit_repository.dart';
import '../../domain/challenge_21_data.dart';
import '../../domain/habit.dart';
import '../../../wellness/presentation/controllers/wellness_controller.dart';

/// Provider for HabitRepository.
final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  final user = ref.watch(authControllerProvider).value;
  return HabitRepository(currentUserId: user?.id);
});

/// Controller managing the active 21-Day Challenge.
final challenge21ControllerProvider =
    AsyncNotifierProvider<Challenge21Controller, Challenge21Data?>(
  Challenge21Controller.new,
);

class Challenge21Controller extends AsyncNotifier<Challenge21Data?> {
  HabitRepository get _repo => ref.read(habitRepositoryProvider);

  @override
  FutureOr<Challenge21Data?> build() async {
    ref.watch(habitRepositoryProvider);
    return _repo.getChallenge21Data();
  }

  /// Toggles today's completion for the active 21-Day Challenge.
  Future<void> toggleToday() async {
    final current = state.value;
    if (current == null) return;

    await _repo.toggleHabitCompletion(current.habit.id);
    ref.read(gamificationProvider.notifier).refresh();
    ref.invalidate(habitsControllerProvider);
    state = AsyncData(await _repo.getChallenge21Data());
  }
}

/// Controller managing the list of active habits and their completion statuses.
final habitsControllerProvider =
    AsyncNotifierProvider<HabitsController, List<HabitWithStatus>>(
  HabitsController.new,
);

class HabitsController extends AsyncNotifier<List<HabitWithStatus>> {
  HabitRepository get _repo => ref.read(habitRepositoryProvider);

  @override
  FutureOr<List<HabitWithStatus>> build() async {
    ref.watch(habitRepositoryProvider);
    return _repo.getHabitsWithStatus();
  }

  /// Toggles today's completion status of a habit with optimistic UI update.
  Future<void> toggleHabit(String habitId) async {
    final currentList = state.value;
    if (currentList == null) return;

    final targetHabit = currentList.firstWhere(
      (item) => item.habit.id == habitId,
      orElse: () => currentList.first,
    );
    final willComplete = !targetHabit.isCompletedToday;

    // Optimistic UI update
    state = AsyncData(
      currentList.map((item) {
        if (item.habit.id == habitId) {
          final isNowCompleted = !item.isCompletedToday;
          return item.copyWith(
            isCompletedToday: isNowCompleted,
            streakCount: isNowCompleted
                ? item.streakCount + 1
                : (item.streakCount > 0 ? item.streakCount - 1 : 0),
          );
        }
        return item;
      }).toList(),
    );

    // Persist in SQLite
    await _repo.toggleHabitCompletion(habitId);

    // Synchronize hydration if this is a water/hydration habit
    final lowerTitle = targetHabit.habit.title.toLowerCase();
    if (lowerTitle.contains('agua') || lowerTitle.contains('water')) {
      if (willComplete) {
        ref.read(waterControllerProvider.notifier).logWater(250);
      } else {
        ref.read(waterControllerProvider.notifier).undoLastLog();
      }
    }

    // Refresh gamification (XP and level)
    ref.read(gamificationProvider.notifier).refresh();

    // Invalidate challenge controller if this was a challenge habit
    ref.invalidate(challenge21ControllerProvider);

    // Reload from source to ensure complete consistency
    final updated = await _repo.getHabitsWithStatus();
    state = AsyncData(updated);
  }

  /// Creates a new habit and refreshes the list.
  Future<void> createHabit({
    required String title,
    String? description,
    HabitCategory category = HabitCategory.general,
    String frequency = 'daily',
    int targetCount = 1,
  }) async {
    await _repo.addHabit(
      title: title,
      description: description,
      category: category,
      frequency: frequency,
      targetCount: targetCount,
    );
    final updated = await _repo.getHabitsWithStatus();
    state = AsyncData(updated);
  }

  /// Archives / deletes a habit.
  Future<void> deleteHabit(String habitId) async {
    await _repo.deleteHabit(habitId);
    final updated = await _repo.getHabitsWithStatus();
    state = AsyncData(updated);
  }
}
