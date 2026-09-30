import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/gamification/gamification_controller.dart';
import '../../../../core/local_db/sync_engine.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/wellness_repository.dart';
import '../../domain/affirmation.dart';
import '../../domain/nutrition_data.dart';
import '../../domain/water_data.dart';

final wellnessRepositoryProvider = Provider<WellnessRepository>((ref) {
  final user = ref.watch(authControllerProvider).value;
  return WellnessRepository(currentUserId: user?.id);
});

// -----------------------------------------------------------------------------
// WATER PROVIDERS
// -----------------------------------------------------------------------------

final dailyWaterSummaryProvider = FutureProvider.autoDispose<DailyWaterSummary>((ref) async {
  final repo = ref.watch(wellnessRepositoryProvider);
  return repo.getDailyWaterSummary();
});

final waterControllerProvider = AsyncNotifierProvider<WaterController, void>(() {
  return WaterController();
});

class WaterController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> logWater(int amountMl) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(wellnessRepositoryProvider);
      await repo.logWater(amountMl: amountMl);
      ref.invalidate(dailyWaterSummaryProvider);
      ref.invalidate(gamificationProvider);
      ref.read(syncEngineProvider).syncNow();
    });
  }

  Future<void> updateGoal(int goalMl) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(wellnessRepositoryProvider);
      await repo.updateWaterGoal(goalMl);
      ref.invalidate(dailyWaterSummaryProvider);
      ref.read(syncEngineProvider).syncNow();
    });
  }

  Future<void> deleteWaterLog(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(wellnessRepositoryProvider);
      await repo.deleteWaterLog(id);
      ref.invalidate(dailyWaterSummaryProvider);
      ref.read(syncEngineProvider).syncNow();
    });
  }

  Future<void> undoLastLog() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(wellnessRepositoryProvider);
      await repo.undoLastWaterLog();
      ref.invalidate(dailyWaterSummaryProvider);
      ref.invalidate(gamificationProvider);
      ref.read(syncEngineProvider).syncNow();
    });
  }
}

// -----------------------------------------------------------------------------
// NUTRITION PROVIDERS
// -----------------------------------------------------------------------------

final dailyNutritionSummaryProvider = FutureProvider.autoDispose<DailyNutritionSummary>((ref) async {
  final repo = ref.watch(wellnessRepositoryProvider);
  return repo.getDailyNutritionSummary();
});

final nutritionControllerProvider = AsyncNotifierProvider<NutritionController, void>(() {
  return NutritionController();
});

class NutritionController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> logMeal({
    required MealType mealType,
    String? title,
    String? note,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(wellnessRepositoryProvider);
      await repo.logMeal(mealType: mealType, title: title, note: note);
      ref.invalidate(dailyNutritionSummaryProvider);
      ref.invalidate(gamificationProvider);
      ref.read(syncEngineProvider).syncNow();
    });
  }
}

// -----------------------------------------------------------------------------
// AFFIRMATIONS PROVIDERS
// -----------------------------------------------------------------------------

final todayAffirmationProvider = FutureProvider.autoDispose<Affirmation>((ref) async {
  final repo = ref.watch(wellnessRepositoryProvider);
  return repo.getTodayAffirmation();
});

class AffirmationCategoryFilterNotifier extends Notifier<AffirmationCategory?> {
  @override
  AffirmationCategory? build() => null;

  void selectCategory(AffirmationCategory? cat) => state = cat;
}

final affirmationCategoryFilterProvider =
    NotifierProvider<AffirmationCategoryFilterNotifier, AffirmationCategory?>(() {
  return AffirmationCategoryFilterNotifier();
});

final allAffirmationsProvider = FutureProvider.autoDispose<List<Affirmation>>((ref) async {
  final repo = ref.watch(wellnessRepositoryProvider);
  final category = ref.watch(affirmationCategoryFilterProvider);
  return repo.getAllAffirmations(category: category);
});

final affirmationControllerProvider = AsyncNotifierProvider<AffirmationController, void>(() {
  return AffirmationController();
});

class AffirmationController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> toggleFavorite(String affirmationId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(wellnessRepositoryProvider);
      await repo.toggleFavoriteAffirmation(affirmationId);
      ref.invalidate(todayAffirmationProvider);
      ref.invalidate(allAffirmationsProvider);
      ref.read(syncEngineProvider).syncNow();
    });
  }

  Future<void> logRead(String affirmationId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(wellnessRepositoryProvider);
      await repo.logAffirmationRead(affirmationId);
      ref.invalidate(todayAffirmationProvider);
      ref.invalidate(gamificationProvider);
      ref.read(syncEngineProvider).syncNow();
    });
  }
}
