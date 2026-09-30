import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/gamification/gamification_controller.dart';
import '../../../../core/notifications/notification_controller.dart';
import '../../../../core/security/security_controller.dart';
import '../../../habits/data/habit_repository.dart';
import '../../domain/pomodoro_models.dart';
import 'ambient_sound_controller.dart';

enum PomodoroStatus {
  idle,
  running,
  paused,
}

class PomodoroState {
  const PomodoroState({
    required this.mode,
    required this.workType,
    required this.status,
    required this.isBreak,
    required this.secondsRemaining,
    required this.secondsElapsed,
    required this.selectedTag,
    required this.completedSessionsToday,
    required this.currentSessionId,
    required this.taskObjective,
    required this.interruptionNotes,
    required this.lastAwardedXp,
    required this.dndTriggered,
    this.sessionCompletedDialogPending = false,
  });

  final PomodoroTimerMode mode;
  final WorkType workType;
  final PomodoroStatus status;
  final bool isBreak;
  final int secondsRemaining;
  final int secondsElapsed;
  final String selectedTag;
  final int completedSessionsToday;
  final String currentSessionId;
  final String? taskObjective;
  final List<InterruptionNote> interruptionNotes;
  final int lastAwardedXp;
  final bool dndTriggered;
  final bool sessionCompletedDialogPending;

  /// Progress value (0.0 to 1.0) for UI chronometer dials.
  double get progress {
    if (mode.isFlowmodoro && !isBreak) {
      // Flowmodoro is an ascending stopwatch; cycle dial per minute
      return ((secondsElapsed % 60) / 60.0).clamp(0.0, 1.0);
    }
    if (isBreak) {
      final total = calculatedBreakSeconds;
      if (total <= 0) return 1.0;
      return (1.0 - (secondsRemaining / total)).clamp(0.0, 1.0);
    }
    final total = mode.totalWorkSeconds;
    if (total <= 0) return 0.0;
    return (1.0 - (secondsRemaining / total)).clamp(0.0, 1.0);
  }

  /// Formatted representation: MM:SS or HH:MM:SS.
  String get formattedTime {
    final secs = mode.isFlowmodoro && !isBreak ? secondsElapsed : secondsRemaining;
    final h = secs ~/ 3600;
    final m = (secs % 3600) ~/ 60;
    final s = secs % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// Break duration in seconds (fixed or 20% of worked time for Flowmodoro).
  int get calculatedBreakSeconds {
    if (mode.isFlowmodoro) {
      final breakSecs = (secondsElapsed * (mode.breakRatio ?? 0.20)).round();
      return breakSecs < 60 ? 60 : breakSecs;
    }
    return mode.totalBreakSeconds > 0 ? mode.totalBreakSeconds : 5 * 60;
  }

  /// Break duration in whole minutes.
  int get calculatedBreakMinutes => (calculatedBreakSeconds / 60).ceil();

  PomodoroState copyWith({
    PomodoroTimerMode? mode,
    WorkType? workType,
    PomodoroStatus? status,
    bool? isBreak,
    int? secondsRemaining,
    int? secondsElapsed,
    String? selectedTag,
    int? completedSessionsToday,
    String? currentSessionId,
    String? taskObjective,
    List<InterruptionNote>? interruptionNotes,
    int? lastAwardedXp,
    bool? dndTriggered,
    bool? sessionCompletedDialogPending,
  }) {
    return PomodoroState(
      mode: mode ?? this.mode,
      workType: workType ?? this.workType,
      status: status ?? this.status,
      isBreak: isBreak ?? this.isBreak,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      secondsElapsed: secondsElapsed ?? this.secondsElapsed,
      selectedTag: selectedTag ?? this.selectedTag,
      completedSessionsToday: completedSessionsToday ?? this.completedSessionsToday,
      currentSessionId: currentSessionId ?? this.currentSessionId,
      taskObjective: taskObjective ?? this.taskObjective,
      interruptionNotes: interruptionNotes ?? this.interruptionNotes,
      lastAwardedXp: lastAwardedXp ?? this.lastAwardedXp,
      dndTriggered: dndTriggered ?? this.dndTriggered,
      sessionCompletedDialogPending: sessionCompletedDialogPending ?? this.sessionCompletedDialogPending,
    );
  }
}

final pomodoroProvider =
    NotifierProvider<PomodoroNotifier, PomodoroState>(PomodoroNotifier.new);

class PomodoroNotifier extends Notifier<PomodoroState> {
  Timer? _timer;
  final _repo = HabitRepository();
  static const _uuid = Uuid();

  @override
  PomodoroState build() {
    ref.onDispose(() => _timer?.cancel());
    final initialSessionId = _uuid.v4();

    return PomodoroState(
      mode: PomodoroTimerMode.extended,
      workType: WorkType.deepWork,
      status: PomodoroStatus.idle,
      isBreak: false,
      secondsRemaining: PomodoroTimerMode.extended.totalWorkSeconds,
      secondsElapsed: 0,
      selectedTag: 'Desarrollo Core',
      completedSessionsToday: 0,
      currentSessionId: initialSessionId,
      taskObjective: null,
      interruptionNotes: const [],
      lastAwardedXp: 0,
      dndTriggered: true,
    );
  }

  /// Selects work type with smart mode recommendation.
  void setWorkType(WorkType type) {
    if (state.status == PomodoroStatus.running) return;

    PomodoroTimerMode newMode = state.mode;
    if (type == WorkType.shallowWork) {
      if (state.mode == PomodoroTimerMode.ultradian ||
          state.mode == PomodoroTimerMode.extended) {
        newMode = PomodoroTimerMode.classic;
      }
    } else {
      if (state.mode == PomodoroTimerMode.classic) {
        newMode = PomodoroTimerMode.extended;
      }
    }

    state = state.copyWith(
      workType: type,
      mode: newMode,
      secondsRemaining: newMode.totalWorkSeconds,
      secondsElapsed: 0,
      isBreak: false,
    );
  }

  /// Sets the active timer mode.
  void setMode(PomodoroTimerMode mode) {
    _timer?.cancel();
    state = state.copyWith(
      mode: mode,
      status: PomodoroStatus.idle,
      isBreak: false,
      secondsRemaining: mode.totalWorkSeconds,
      secondsElapsed: 0,
    );
  }

  /// Sets the task vector or tag.
  void setTag(String tag) {
    state = state.copyWith(selectedTag: tag);
  }

  /// Sets the verified task objective from the startup checklist.
  void setTaskObjective(String objective) {
    state = state.copyWith(taskObjective: objective);
  }

  /// Toggles simulated / actual DND state.
  void toggleDnd(bool enabled) {
    state = state.copyWith(dndTriggered: enabled);
  }

  /// Starts or resumes the chronometer.
  void start() {
    if (state.status == PomodoroStatus.running) return;

    state = state.copyWith(status: PomodoroStatus.running);

    // Auto-play nature ambient sound if enabled during focus work
    if (!state.isBreak) {
      try {
        ref.read(pomodoroAmbientProvider.notifier).playIfAutoEnabled();
      } catch (_) {}
    }

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.isBreak) {
        // Break countdown
        if (state.secondsRemaining > 0) {
          state = state.copyWith(secondsRemaining: state.secondsRemaining - 1);
        } else {
          _onBreakCompleted();
        }
      } else {
        // Focus mode
        if (state.mode.isFlowmodoro) {
          state = state.copyWith(secondsElapsed: state.secondsElapsed + 1);
        } else {
          state = state.copyWith(secondsElapsed: state.secondsElapsed + 1);
          if (state.secondsRemaining > 0) {
            state = state.copyWith(secondsRemaining: state.secondsRemaining - 1);
          } else {
            _onSessionCompleted();
          }
        }
      }
    });
  }

  /// Pauses the chronometer.
  void pause() {
    _timer?.cancel();
    state = state.copyWith(status: PomodoroStatus.paused);
    try {
      ref.read(pomodoroAmbientProvider.notifier).pause();
    } catch (_) {}
  }

  /// Resets the current block.
  void reset() {
    _timer?.cancel();
    try {
      ref.read(pomodoroAmbientProvider.notifier).pause();
    } catch (_) {}

    state = state.copyWith(
      status: PomodoroStatus.idle,
      isBreak: false,
      secondsRemaining: state.mode.totalWorkSeconds,
      secondsElapsed: 0,
    );
  }

  /// Finishes Flowmodoro when fatigue or distraction occurs, awards XP, and triggers 20% break.
  Future<void> stopFlowmodoroAndStartBreak() async {
    if (!state.mode.isFlowmodoro || state.isBreak) return;
    await _onSessionCompleted();
  }

  /// Captures an interruption note (Bloc de Descarga) without interrupting focus.
  Future<void> addInterruptionNote(String noteText) async {
    final clean = noteText.trim();
    if (clean.isEmpty) return;

    final noteId = await _repo.saveInterruptionNote(
      sessionId: state.currentSessionId,
      noteText: clean,
    );

    final newNote = InterruptionNote(
      id: noteId,
      sessionId: state.currentSessionId,
      userId: 'local_user',
      noteText: clean,
      capturedAt: DateTime.now(),
    );

    state = state.copyWith(
      interruptionNotes: [...state.interruptionNotes, newNote],
    );
  }

  /// Converts an interruption note to a new habit.
  Future<void> convertNoteToHabit(String noteId, String title) async {
    await _repo.convertInterruptionNoteToHabit(
      noteId: noteId,
      title: title,
      category: 'focus',
    );

    final updated = state.interruptionNotes.map((n) {
      if (n.id == noteId) {
        return InterruptionNote(
          id: n.id,
          sessionId: n.sessionId,
          userId: n.userId,
          noteText: n.noteText,
          capturedAt: n.capturedAt,
          convertedToHabitId: 'converted',
        );
      }
      return n;
    }).toList();

    state = state.copyWith(interruptionNotes: updated);
  }

  /// Dismisses post-session summary modal.
  void dismissPostSessionDialog() {
    state = state.copyWith(sessionCompletedDialogPending: false);
  }

  /// Skips break and returns directly to work mode.
  void skipBreak() {
    _timer?.cancel();
    final newSessionId = _uuid.v4();
    state = state.copyWith(
      status: PomodoroStatus.idle,
      isBreak: false,
      secondsRemaining: state.mode.totalWorkSeconds,
      secondsElapsed: 0,
      currentSessionId: newSessionId,
      interruptionNotes: const [],
      taskObjective: null,
      sessionCompletedDialogPending: false,
    );
  }

  Future<void> _onSessionCompleted() async {
    _timer?.cancel();

    // Pause ambient nature sound for break
    try {
      ref.read(pomodoroAmbientProvider.notifier).pause();
    } catch (_) {}

    // Calculate worked minutes (at least 1 min for flowmodoro)
    final durationMins = state.mode.isFlowmodoro
        ? ((state.secondsElapsed / 60).ceil()).clamp(1, 480)
        : (state.mode.totalWorkSeconds ~/ 60);

    // Record session and credit XP (deep_work: +38 XP, shallow_work: +25 XP)
    final xp = await _repo.recordPomodoroSession(
      durationMinutes: durationMins,
      taskTag: state.selectedTag,
      modeKey: state.mode.key,
      workType: state.workType.key,
      taskObjective: state.taskObjective,
      notesCount: state.interruptionNotes.length,
      dndTriggered: state.dndTriggered,
      sessionId: state.currentSessionId,
    );

    ref.read(gamificationProvider.notifier).refresh();

    // Smart notification
    try {
      final notificationSettings = ref.read(notificationControllerProvider);
      if (notificationSettings.pomodoroNotificationsEnabled) {
        final isDiscreet =
            ref.read(securityControllerProvider).discreetModeEnabled;
        ref
            .read(localNotificationServiceProvider)
            .showPomodoroCompletedNotification(
              taskName: state.selectedTag,
              minutesFocused: durationMins,
              isDiscreet: isDiscreet,
            );
      }
    } catch (_) {}

    final breakDuration = state.calculatedBreakSeconds;

    state = state.copyWith(
      status: PomodoroStatus.idle,
      isBreak: true,
      secondsRemaining: breakDuration,
      completedSessionsToday: state.completedSessionsToday + 1,
      lastAwardedXp: xp,
      sessionCompletedDialogPending: true,
    );
  }

  void _onBreakCompleted() {
    _timer?.cancel();
    final newSessionId = _uuid.v4();

    state = state.copyWith(
      status: PomodoroStatus.idle,
      isBreak: false,
      secondsRemaining: state.mode.totalWorkSeconds,
      secondsElapsed: 0,
      currentSessionId: newSessionId,
      interruptionNotes: const [],
      taskObjective: null,
      sessionCompletedDialogPending: false,
    );
  }
}
