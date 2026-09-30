import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/gamification/gamification_controller.dart';
import '../../../../core/local_db/sync_engine.dart';
import '../../data/religion_repository.dart';
import '../../domain/prayer_request.dart';
import '../../domain/religion_content.dart';

/// Provider for today's devotional scripture + user interaction.
final dailyDevotionalProvider = FutureProvider.autoDispose<DailyDevotional>((ref) async {
  final repo = ref.watch(religionRepositoryProvider);
  return repo.getDailyPassage();
});

/// Filter state for prayer list.
class PrayerFilterState {
  const PrayerFilterState({
    this.status = 'active', // 'active' or 'answered'
    this.category,
  });

  final String status;
  final String? category;

  PrayerFilterState copyWith({
    String? status,
    String? category,
    bool clearCategory = false,
  }) {
    return PrayerFilterState(
      status: status ?? this.status,
      category: clearCategory ? null : (category ?? this.category),
    );
  }
}

class PrayerFilterNotifier extends Notifier<PrayerFilterState> {
  @override
  PrayerFilterState build() => const PrayerFilterState();

  void setStatus(String status) {
    state = state.copyWith(status: status);
  }

  void setCategory(String? category, {bool clearCategory = false}) {
    state = state.copyWith(category: category, clearCategory: clearCategory);
  }
}

final prayerFilterProvider = NotifierProvider<PrayerFilterNotifier, PrayerFilterState>(
  PrayerFilterNotifier.new,
);

/// Provider for prayer requests based on active filter.
final prayerRequestsProvider = FutureProvider.autoDispose<List<PrayerRequest>>((ref) async {
  final repo = ref.watch(religionRepositoryProvider);
  final filter = ref.watch(prayerFilterProvider);
  return repo.getPrayerRequests(
    status: filter.status,
    category: filter.category,
  );
});

/// Provider for the full wisdom library.
final allPassagesProvider = FutureProvider.autoDispose<List<ReligionContent>>((ref) async {
  final repo = ref.watch(religionRepositoryProvider);
  return repo.getAllPassages();
});

/// Provider for spiritual dashboard stats.
final spiritualStatsProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final repo = ref.watch(religionRepositoryProvider);
  return repo.getSpiritualStats();
});

/// Controller for executing religion and prayer mutations.
final religionControllerProvider = Provider<ReligionController>((ref) {
  return ReligionController(ref);
});

class ReligionController {
  ReligionController(this._ref);

  final Ref _ref;

  ReligionRepository get _repo => _ref.read(religionRepositoryProvider);

  Future<bool> saveReflection({
    required String contentId,
    required String notes,
    bool isFavorite = false,
  }) async {
    try {
      await _repo.saveReflection(
        contentId: contentId,
        notes: notes,
        isFavorite: isFavorite,
      );

      // Invalidate relevant providers to refresh UI
      _ref.invalidate(dailyDevotionalProvider);
      _ref.invalidate(spiritualStatsProvider);
      _ref.invalidate(gamificationProvider);

      // Trigger background sync
      _ref.read(syncEngineProvider).syncNow();

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> toggleFavorite(String contentId) async {
    try {
      final res = await _repo.toggleFavorite(contentId);
      _ref.invalidate(dailyDevotionalProvider);
      _ref.invalidate(spiritualStatsProvider);
      _ref.read(syncEngineProvider).syncNow();
      return res;
    } catch (_) {
      return false;
    }
  }

  Future<bool> addPrayerRequest({
    required String title,
    String? description,
    required String category,
  }) async {
    try {
      await _repo.createPrayerRequest(
        title: title,
        description: description,
        category: category,
      );

      _ref.invalidate(prayerRequestsProvider);
      _ref.invalidate(spiritualStatsProvider);
      _ref.invalidate(gamificationProvider);

      _ref.read(syncEngineProvider).syncNow();

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> markPrayerAnswered({
    required String id,
    required String answerNotes,
  }) async {
    try {
      await _repo.markPrayerAnswered(
        id: id,
        answerNotes: answerNotes,
      );

      _ref.invalidate(prayerRequestsProvider);
      _ref.invalidate(spiritualStatsProvider);

      _ref.read(syncEngineProvider).syncNow();

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deletePrayerRequest(String id) async {
    try {
      await _repo.deletePrayerRequest(id);

      _ref.invalidate(prayerRequestsProvider);
      _ref.invalidate(spiritualStatsProvider);

      _ref.read(syncEngineProvider).syncNow();

      return true;
    } catch (_) {
      return false;
    }
  }
}
