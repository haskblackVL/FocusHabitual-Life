import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/thinkers_repository.dart';
import '../../domain/thinker.dart';

/// Provider for ThinkersRepository scoped to the active user.
final thinkersRepositoryProvider = Provider<ThinkersRepository>((ref) {
  final user = ref.watch(authControllerProvider).value;
  final repo = ThinkersRepository(currentUserId: user?.id);
  return repo;
});

/// Category filter notifier.
class ThinkersCategoryFilterNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  void setCategory(String category) {
    state = category;
  }
}

/// Selected category filter code ('all' or ThinkerCategory.code).
final thinkersCategoryFilterProvider =
    NotifierProvider<ThinkersCategoryFilterNotifier, String>(
  ThinkersCategoryFilterNotifier.new,
);

/// Search query notifier.
class ThinkersSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }
}

/// Search query text in the library.
final thinkersSearchQueryProvider =
    NotifierProvider<ThinkersSearchQueryNotifier, String>(
  ThinkersSearchQueryNotifier.new,
);

/// Filtered list of thinkers respecting category, search query, and user religious settings.
final filteredThinkersProvider = Provider<List<Thinker>>((ref) {
  final repo = ref.watch(thinkersRepositoryProvider);
  final category = ref.watch(thinkersCategoryFilterProvider);
  final query = ref.watch(thinkersSearchQueryProvider);
  final profile = ref.watch(userProfileControllerProvider).value;
  final isReligious = profile?.isReligious ?? false;

  if (query.trim().isNotEmpty) {
    return repo.searchThinkers(
      query,
      category: category,
      includeReligious: isReligious,
    );
  }

  return repo.getThinkers(
    category: category,
    includeReligious: isReligious,
  );
});

/// Rotating daily thinker for contemplation.
final dailyThinkerProvider = Provider<Thinker>((ref) {
  final repo = ref.watch(thinkersRepositoryProvider);
  final profile = ref.watch(userProfileControllerProvider).value;
  final isReligious = profile?.isReligious ?? false;
  return repo.getDailyThinker(includeReligious: isReligious);
});

/// List of favorite thinkers for quick access.
final favoriteThinkersProvider = Provider<List<Thinker>>((ref) {
  final all = ref.watch(filteredThinkersProvider);
  return all.where((t) => t.isFavorite).toList();
});
