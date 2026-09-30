import 'package:flutter/foundation.dart';
import '../../../core/local_db/database.dart';
import '../domain/thinker.dart';
import 'thinkers_catalog.dart';

/// Repository for retrieving and managing philosophical thinkers and reflections.
class ThinkersRepository extends ChangeNotifier {
  ThinkersRepository({this.currentUserId});

  final String? currentUserId;
  String get _activeUserId => currentUserId ?? 'local_user';

  /// Retrieves all thinkers, with optional category filtering and religious sensitivity filter.
  List<Thinker> getThinkers({
    String? category,
    bool includeReligious = true,
  }) {
    try {
      final rows = AppDatabase.getThinkers(
        userId: _activeUserId,
        category: category,
        includeReligious: includeReligious,
      );

      if (rows.isNotEmpty) {
        return rows.map((r) {
          final isFav = (r['is_favorite'] == 1 || r['is_favorite'] == true);
          return Thinker.fromMap(r, isFavorite: isFav);
        }).toList();
      }
    } catch (e) {
      if (kDebugMode) {
        print('[ThinkersRepository] Error fetching from SQLite, using catalog: $e');
      }
    }

    // Fallback directly to in-memory ThinkersCatalog
    return ThinkersCatalog.all.where((t) {
      if (!includeReligious && t.requiresReligious) return false;
      if (category != null && category.isNotEmpty && category != 'all') {
        return t.category == category;
      }
      return true;
    }).toList();
  }

  /// Retrieves the rotating Thinker of the Day based on the current calendar date.
  Thinker getDailyThinker({bool includeReligious = true}) {
    final list = getThinkers(includeReligious: includeReligious);
    if (list.isEmpty) {
      return ThinkersCatalog.all.first;
    }
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final index = dayOfYear % list.length;
    return list[index];
  }

  /// Toggles favorite status for a thinker.
  Future<void> toggleFavorite({
    required String thinkerId,
    required bool isFavorite,
  }) async {
    AppDatabase.toggleThinkerFavorite(
      userId: _activeUserId,
      thinkerId: thinkerId,
      isFavorite: isFavorite,
    );
    notifyListeners();
  }

  /// Searches thinkers by name, core idea, origin, or key work.
  List<Thinker> searchThinkers(
    String query, {
    String? category,
    bool includeReligious = true,
  }) {
    final all = getThinkers(category: category, includeReligious: includeReligious);
    if (query.trim().isEmpty) return all;

    final q = query.trim().toLowerCase();
    return all.where((t) {
      final nameMatches = t.name.toLowerCase().contains(q);
      final ideaMatches = t.keyIdea.toLowerCase().contains(q);
      final originMatches = t.origin?.toLowerCase().contains(q) ?? false;
      final workMatches = t.keyWork?.toLowerCase().contains(q) ?? false;
      return nameMatches || ideaMatches || originMatches || workMatches;
    }).toList();
  }
}
