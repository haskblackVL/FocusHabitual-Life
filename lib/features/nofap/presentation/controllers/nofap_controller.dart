import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/gamification/gamification_controller.dart';
import '../../../../core/local_db/sync_engine.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/nofap_repository.dart';
import '../../domain/nofap_models.dart';

/// Provider for NofapRepository with active user session.
final nofapRepositoryProvider = Provider<NofapRepository>((ref) {
  final user = ref.watch(authControllerProvider).value;
  return NofapRepository(currentUserId: user?.id);
});

/// Riverpod Notifier providing live, second-by-second streak state.
final nofapControllerProvider =
    NotifierProvider<NofapNotifier, NofapStreakState>(
  NofapNotifier.new,
);

class NofapNotifier extends Notifier<NofapStreakState> {
  NofapRepository get _repo => ref.read(nofapRepositoryProvider);
  Timer? _timer;

  @override
  NofapStreakState build() {
    ref.watch(nofapRepositoryProvider);
    final now = DateTime.now();

    // Start 1-second interval ticker for live telemetry
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(now: DateTime.now());
    });

    ref.onDispose(() {
      _timer?.cancel();
    });

    _loadInitial();

    return NofapStreakState(
      streakStartDate: now,
      now: now,
    );
  }

  Future<void> _loadInitial() async {
    final start = await _repo.getCurrentStreakStart();
    final relapses = await _repo.getTotalRelapses();
    state = NofapStreakState(
      streakStartDate: start,
      now: DateTime.now(),
      totalRelapses: relapses,
    );
  }

  /// Records a relapse and resets the live counter to 0 instantly.
  Future<void> recordRelapse({String? reason, String? trigger, String? note}) async {
    final newStart = await _repo.recordRelapse(reason: reason, trigger: trigger, note: note);
    final relapses = await _repo.getTotalRelapses();
    state = NofapStreakState(
      streakStartDate: newStart,
      now: DateTime.now(),
      totalRelapses: relapses,
    );
    ref.invalidate(nofapHistoryProvider);
    ref.read(syncEngineProvider).syncNow();
  }

  /// Records successful checkin / impulse overcome (+15 XP).
  Future<void> recordCheckin({String? note}) async {
    await _repo.recordCheckin(note: note);
    ref.read(gamificationProvider.notifier).refresh();
    ref.read(syncEngineProvider).syncNow();
  }

  /// Records successful completion of the emergency cooling protocol (+15 XP).
  Future<void> recordCoolingCompleted() async {
    await _repo.recordCoolingSessionCompleted();
    ref.read(gamificationProvider.notifier).refresh();
    ref.read(syncEngineProvider).syncNow();
  }
}

/// Provider for user's relapse history.
final nofapHistoryProvider =
    FutureProvider<List<NofapRelapseItem>>((ref) async {
  final repo = ref.watch(nofapRepositoryProvider);
  return repo.getRelapseHistory();
});

/// Provider for user's personal anchor reasons.
final nofapReasonsProvider =
    AsyncNotifierProvider<NofapReasonsNotifier, List<NofapReason>>(
  NofapReasonsNotifier.new,
);

class NofapReasonsNotifier extends AsyncNotifier<List<NofapReason>> {
  @override
  Future<List<NofapReason>> build() async {
    final repo = ref.watch(nofapRepositoryProvider);
    return repo.getReasons();
  }

  Future<void> addReason(String text) async {
    final repo = ref.read(nofapRepositoryProvider);
    await repo.addReason(text);
    ref.invalidateSelf();
    ref.read(syncEngineProvider).syncNow();
  }

  Future<void> deleteReason(String id) async {
    final repo = ref.read(nofapRepositoryProvider);
    await repo.deleteReason(id);
    ref.invalidateSelf();
    ref.read(syncEngineProvider).syncNow();
  }
}

