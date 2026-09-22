import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/habits/data/habit_repository.dart';
import 'xp_engine.dart';

/// State of user XP and level progression.
class GamificationState {
  const GamificationState({
    required this.totalXp,
    required this.level,
    required this.levelTitle,
    required this.levelProgress,
  });

  final int totalXp;
  final int level;
  final String levelTitle;
  final double levelProgress;

  factory GamificationState.fromXp(int xp) {
    final lvl = XpEngine.calculateLevel(xp);
    return GamificationState(
      totalXp: xp,
      level: lvl,
      levelTitle: XpEngine.getLevelTitle(lvl),
      levelProgress: XpEngine.calculateLevelProgress(xp),
    );
  }
}

/// Provider managing user XP and level calculations.
final gamificationProvider =
    NotifierProvider<GamificationNotifier, GamificationState>(
  GamificationNotifier.new,
);

class GamificationNotifier extends Notifier<GamificationState> {
  final _repository = HabitRepository();

  @override
  GamificationState build() {
    _loadInitial();
    return GamificationState.fromXp(0);
  }

  Future<void> _loadInitial() async {
    final xp = await _repository.getUserXp();
    state = GamificationState.fromXp(xp);
  }

  Future<void> refresh() async {
    final xp = await _repository.getUserXp();
    state = GamificationState.fromXp(xp);
  }

  void addXpLocal(int amount) {
    final newXp = state.totalXp + amount;
    state = GamificationState.fromXp(newXp);
  }
}
