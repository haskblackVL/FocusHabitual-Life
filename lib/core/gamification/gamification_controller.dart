import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import 'achievement_engine.dart';
import 'achievement_model.dart';
import 'data/achievement_repository.dart';
import 'xp_engine.dart';

/// State representing unified user gamification, XP progression, and unlocked achievements.
class GamificationState {
  const GamificationState({
    required this.totalXp,
    required this.level,
    required this.levelTitle,
    required this.levelProgress,
    required this.currentLevelMinXp,
    required this.nextLevelMinXp,
    required this.xpInCurrentLevel,
    required this.xpRemainingToNextLevel,
    required this.unlockedAchievements,
    required this.recentAchievements,
    required this.totalUnlockedCount,
    required this.totalAvailableCount,
    required this.completionPercentage,
  });

  final int totalXp;
  final int level;
  final String levelTitle;
  final double levelProgress;
  final int currentLevelMinXp;
  final int nextLevelMinXp;
  final int xpInCurrentLevel;
  final int xpRemainingToNextLevel;
  final List<UnlockedAchievement> unlockedAchievements;
  final List<UnlockedAchievement> recentAchievements;
  final int totalUnlockedCount;
  final int totalAvailableCount;
  final double completionPercentage;

  factory GamificationState.create({
    required int totalXp,
    required List<UnlockedAchievement> unlockedAchievements,
  }) {
    final lvl = XpEngine.calculateLevel(totalXp);
    final int currentMin = lvl == 0 ? 0 : XpEngine.xpForLevel(lvl);
    final int nextMin = lvl == 0 ? 100 : XpEngine.xpForLevel(lvl + 1);
    final inLevel = (totalXp - currentMin).clamp(0, nextMin - currentMin > 0 ? nextMin - currentMin : 100);
    final remaining = (nextMin - totalXp).clamp(0, 9999999);
    final progress = XpEngine.calculateLevelProgress(totalXp);

    final sorted = List<UnlockedAchievement>.from(unlockedAchievements)
      ..sort((a, b) => b.unlockedAt.compareTo(a.unlockedAt));
    final recent = sorted.take(3).toList();

    final totalCount = MasterAchievements.all.length;
    final unlockedCount = unlockedAchievements.length;
    final percentage = totalCount > 0 ? (unlockedCount / totalCount).clamp(0.0, 1.0) : 0.0;

    return GamificationState(
      totalXp: totalXp,
      level: lvl,
      levelTitle: XpEngine.getLevelTitle(lvl),
      levelProgress: progress,
      currentLevelMinXp: currentMin,
      nextLevelMinXp: nextMin,
      xpInCurrentLevel: inLevel,
      xpRemainingToNextLevel: remaining,
      unlockedAchievements: sorted,
      recentAchievements: recent,
      totalUnlockedCount: unlockedCount,
      totalAvailableCount: totalCount,
      completionPercentage: percentage,
    );
  }

  bool isUnlocked(String key) {
    return unlockedAchievements.any((a) => a.definition.key == key);
  }
}

/// Provider managing unified XP, Leveling, and Achievements.
final gamificationProvider =
    NotifierProvider<GamificationNotifier, GamificationState>(
  GamificationNotifier.new,
);

class GamificationNotifier extends Notifier<GamificationState> {
  final _repository = const AchievementRepository();
  final _engine = const AchievementEngine();

  String get _userId => ref.read(authControllerProvider).value?.id ?? 'local_user';

  @override
  GamificationState build() {
    ref.watch(authControllerProvider);
    _loadInitial();
    return GamificationState.create(
      totalXp: 0,
      unlockedAchievements: const [],
    );
  }

  Future<void> _loadInitial() async {
    final uid = _userId;
    final xp = await _repository.getUserXp(userId: uid);
    final unlocked = await _repository.getUnlockedAchievements(userId: uid);
    state = GamificationState.create(
      totalXp: xp,
      unlockedAchievements: unlocked,
    );

    // Initial silent evaluation to catch up on any milestones already met
    await evaluateAchievements();
  }

  /// Refreshes user XP and unlocked achievements from SQLite.
  Future<void> refresh() async {
    final uid = _userId;
    final xp = await _repository.getUserXp(userId: uid);
    final unlocked = await _repository.getUnlockedAchievements(userId: uid);
    state = GamificationState.create(
      totalXp: xp,
      unlockedAchievements: unlocked,
    );
  }

  /// Awards XP from any module, logs the XP event, and evaluates achievements.
  Future<void> awardXp({
    required String sourceModule,
    required int amount,
  }) async {
    final uid = _userId;
    final newXp = await _repository.awardXp(
      sourceModule: sourceModule,
      amount: amount,
      userId: uid,
    );
    final unlocked = await _repository.getUnlockedAchievements(userId: uid);
    state = GamificationState.create(
      totalXp: newXp,
      unlockedAchievements: unlocked,
    );

    // Trigger check for newly satisfied milestones
    await evaluateAchievements();
  }

  /// Evaluates all criteria across modules and unlocks any achieved medals.
  /// Returns the list of newly unlocked achievements for celebratory feedback.
  Future<List<AchievementDefinition>> evaluateAchievements() async {
    final uid = _userId;
    final newlyUnlocked = await _engine.evaluateAll(userId: uid);
    if (newlyUnlocked.isNotEmpty) {
      final updatedXp = await _repository.getUserXp(userId: uid);
      final updatedUnlocked = await _repository.getUnlockedAchievements(userId: uid);
      state = GamificationState.create(
        totalXp: updatedXp,
        unlockedAchievements: updatedUnlocked,
      );
    }
    return newlyUnlocked;
  }

  /// Explicitly unlocks an achievement by key.
  Future<AchievementDefinition?> unlockDirectly(String key) async {
    final uid = _userId;
    final def = await _repository.unlockAchievement(key, userId: uid);
    if (def != null) {
      await refresh();
    }
    return def;
  }
}
