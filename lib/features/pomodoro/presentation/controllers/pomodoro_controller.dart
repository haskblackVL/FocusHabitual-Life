import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/gamification/gamification_controller.dart';
import '../../../habits/data/habit_repository.dart';

enum PomodoroMode {
  focus(25 * 60, 'Enfoque'),
  shortBreak(5 * 60, 'Descanso Corto'),
  longBreak(15 * 60, 'Descanso Largo');

  const PomodoroMode(this.totalSeconds, this.displayName);
  final int totalSeconds;
  final String displayName;
}

enum PomodoroStatus {
  idle,
  running,
  paused,
}

class PomodoroState {
  const PomodoroState({
    required this.mode,
    required this.status,
    required this.secondsRemaining,
    required this.selectedTag,
    required this.completedSessionsToday,
  });

  final PomodoroMode mode;
  final PomodoroStatus status;
  final int secondsRemaining;
  final String selectedTag;
  final int completedSessionsToday;

  double get progress => 1.0 - (secondsRemaining / mode.totalSeconds);

  String get formattedTime {
    final m = (secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final s = (secondsRemaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  PomodoroState copyWith({
    PomodoroMode? mode,
    PomodoroStatus? status,
    int? secondsRemaining,
    String? selectedTag,
    int? completedSessionsToday,
  }) {
    return PomodoroState(
      mode: mode ?? this.mode,
      status: status ?? this.status,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      selectedTag: selectedTag ?? this.selectedTag,
      completedSessionsToday: completedSessionsToday ?? this.completedSessionsToday,
    );
  }
}

final pomodoroProvider =
    NotifierProvider<PomodoroNotifier, PomodoroState>(PomodoroNotifier.new);

class PomodoroNotifier extends Notifier<PomodoroState> {
  Timer? _timer;
  final _repo = HabitRepository();

  @override
  PomodoroState build() {
    ref.onDispose(() => _timer?.cancel());
    return const PomodoroState(
      mode: PomodoroMode.focus,
      status: PomodoroStatus.idle,
      secondsRemaining: 25 * 60,
      selectedTag: 'Investigación',
      completedSessionsToday: 0,
    );
  }

  void setMode(PomodoroMode mode) {
    _timer?.cancel();
    state = state.copyWith(
      mode: mode,
      status: PomodoroStatus.idle,
      secondsRemaining: mode.totalSeconds,
    );
  }

  void setTag(String tag) {
    state = state.copyWith(selectedTag: tag);
  }

  void start() {
    if (state.status == PomodoroStatus.running) return;

    state = state.copyWith(status: PomodoroStatus.running);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.secondsRemaining > 0) {
        state = state.copyWith(secondsRemaining: state.secondsRemaining - 1);
      } else {
        _onSessionCompleted();
      }
    });
  }

  void pause() {
    _timer?.cancel();
    state = state.copyWith(status: PomodoroStatus.paused);
  }

  void reset() {
    _timer?.cancel();
    state = state.copyWith(
      status: PomodoroStatus.idle,
      secondsRemaining: state.mode.totalSeconds,
    );
  }

  Future<void> _onSessionCompleted() async {
    _timer?.cancel();

    if (state.mode == PomodoroMode.focus) {
      // Record completed Pomodoro session in DB and credit +25 XP
      final durationMins = state.mode.totalSeconds ~/ 60;
      await _repo.recordPomodoroSession(
        durationMinutes: durationMins,
        taskTag: state.selectedTag,
      );
      ref.read(gamificationProvider.notifier).refresh();
    }

    state = state.copyWith(
      status: PomodoroStatus.idle,
      secondsRemaining: state.mode.totalSeconds,
      completedSessionsToday: state.completedSessionsToday + 1,
    );
  }
}
