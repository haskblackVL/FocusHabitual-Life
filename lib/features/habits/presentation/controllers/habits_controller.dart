import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/gamification/gamification_controller.dart';
import '../../data/habit_repository.dart';
import '../../domain/habit.dart';

/// Provider for HabitRepository.
final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  return HabitRepository();
});

/// Controller managing the list of active habits and their completion statuses.
final habitsControllerProvider =
    AsyncNotifierProvider<HabitsController, List<HabitWithStatus>>(
  HabitsController.new,
);

class HabitsController extends AsyncNotifier<List<HabitWithStatus>> {
  late final HabitRepository _repo;

  @override
  FutureOr<List<HabitWithStatus>> build() async {
    _repo = ref.watch(habitRepositoryProvider);
    return _repo.getHabitsWithStatus();
  }

  /// Toggles today's completion status of a habit with optimistic UI update.
  Future<void> toggleHabit(String habitId) async {
    final currentList = state.value;
    if (currentList == null) return;

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

    // Refresh gamification (XP and level)
    ref.read(gamificationProvider.notifier).refresh();

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
