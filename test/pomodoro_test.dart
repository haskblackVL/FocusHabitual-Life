import 'package:flutter_test/flutter_test.dart';
import 'package:focus_habitual_life/core/gamification/xp_engine.dart';
import 'package:focus_habitual_life/core/local_db/database.dart';
import 'package:focus_habitual_life/features/analytics/domain/analytics_data.dart';
import 'package:focus_habitual_life/features/habits/data/habit_repository.dart';
import 'package:focus_habitual_life/features/pomodoro/domain/pomodoro_models.dart';
import 'package:focus_habitual_life/features/pomodoro/presentation/controllers/pomodoro_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await AppDatabase.init();
  });

  group('Pomodoro Domain & Timer Modes Tests', () {
    test('Timer modes have correct specifications matching Pomodoro.md', () {
      expect(PomodoroTimerMode.classic.workMinutes, 25);
      expect(PomodoroTimerMode.classic.breakMinutes, 5);

      expect(PomodoroTimerMode.extended.workMinutes, 50);
      expect(PomodoroTimerMode.extended.breakMinutes, 10);
      expect(PomodoroTimerMode.extended.suggestedDailyCap, 6);

      expect(PomodoroTimerMode.ultradian.workMinutes, 90);
      expect(PomodoroTimerMode.ultradian.breakMinutes, 25);
      expect(PomodoroTimerMode.ultradian.suggestedDailyCap, 2);

      expect(PomodoroTimerMode.flowmodoro.isFlowmodoro, isTrue);
      expect(PomodoroTimerMode.flowmodoro.breakRatio, 0.20);
    });

    test('Flowmodoro calculates 20% break duration correctly', () {
      final state = PomodoroState(
        mode: PomodoroTimerMode.flowmodoro,
        workType: WorkType.deepWork,
        status: PomodoroStatus.idle,
        isBreak: false,
        secondsRemaining: 0,
        secondsElapsed: 3000, // 50 minutes elapsed
        selectedTag: 'Desarrollo Core',
        completedSessionsToday: 0,
        currentSessionId: 'sess-1',
        taskObjective: null,
        interruptionNotes: const [],
        lastAwardedXp: 0,
        dndTriggered: true,
      );

      // 3000 * 0.20 = 600 seconds = 10 minutes break
      expect(state.calculatedBreakSeconds, 600);
      expect(state.calculatedBreakMinutes, 10);
    });

    test('Bimodal WorkType recommendation shifts modes appropriately', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(pomodoroProvider.notifier);

      // Default state should be deepWork + extended mode
      expect(container.read(pomodoroProvider).workType, WorkType.deepWork);
      expect(container.read(pomodoroProvider).mode, PomodoroTimerMode.extended);

      // Switching to shallowWork recommends classic mode
      notifier.setWorkType(WorkType.shallowWork);
      expect(container.read(pomodoroProvider).workType, WorkType.shallowWork);
      expect(container.read(pomodoroProvider).mode, PomodoroTimerMode.classic);

      // Switching back to deepWork recommends extended mode
      notifier.setWorkType(WorkType.deepWork);
      expect(container.read(pomodoroProvider).workType, WorkType.deepWork);
      expect(container.read(pomodoroProvider).mode, PomodoroTimerMode.extended);
    });
  });

  group('Pomodoro XP & Persistence Tests', () {
    final repo = HabitRepository();

    test('Shallow work session awards 25 XP', () async {
      final xpEarned = await repo.recordPomodoroSession(
        durationMinutes: 25,
        taskTag: 'Mantenimiento',
        workType: 'shallow_work',
        modeKey: 'classic',
      );

      expect(xpEarned, XpEngine.pomodoroXp);
      expect(xpEarned, 25);
    });

    test('Deep work session awards 38 XP (1.5x bonus)', () async {
      final xpEarned = await repo.recordPomodoroSession(
        durationMinutes: 50,
        taskTag: 'Arquitectura',
        workType: 'deep_work',
        modeKey: 'extended',
        taskObjective: 'Diseñar e implementar persistencia local SQLite',
      );

      expect(xpEarned, XpEngine.deepWorkPomodoroXp);
      expect(xpEarned, 38);
    });

    test('Bloc de Descarga saves interruption note and converts to habit', () async {
      const sessionId = 'test-session-descarga-1';

      // 1. Capture note during active session
      final noteId = await repo.saveInterruptionNote(
        sessionId: sessionId,
        noteText: 'Revisar certificados TLS de producción',
      );
      expect(noteId, isNotEmpty);

      // 2. Fetch notes for this session
      final notes = repo.getInterruptionNotes(sessionId);
      expect(notes.isNotEmpty, isTrue);
      expect(notes.any((n) => n['note_text'] == 'Revisar certificados TLS de producción'), isTrue);

      // 3. Convert note into permanent habit
      final habitId = await repo.convertInterruptionNoteToHabit(
        noteId: noteId,
        title: 'Revisar certificados TLS de producción',
      );
      expect(habitId, isNotEmpty);

      // 4. Verify note is marked as converted
      final updatedNotes = repo.getInterruptionNotes(sessionId);
      final matched = updatedNotes.firstWhere((n) => n['id'] == noteId);
      expect(matched['converted_to_habit_id'], habitId);
    });

    test('Daily planner loads default seed template blocks and can add custom block', () {
      final blocksBefore = AppDatabase.getDefaultDailyBlockItems();
      expect(blocksBefore.length, greaterThanOrEqualTo(5));

      final firstBlock = blocksBefore.first;
      expect(firstBlock['mode_key'], 'ultradian');
      expect(firstBlock['work_type'], 'deep_work');
      expect(firstBlock['duration_minutes'], 90);

      // Add custom block
      AppDatabase.addDailyBlockItem(
        startTime: '15:00',
        durationMinutes: 45,
        modeKey: 'extended',
        workType: 'deep_work',
        label: 'Testing de integración',
      );

      final blocksAfter = AppDatabase.getDefaultDailyBlockItems();
      expect(blocksAfter.length, equals(blocksBefore.length + 1));
      expect(blocksAfter.any((b) => b['label'] == 'Testing de integración'), isTrue);
    });

    test('BimodalFocusStats tracks Deep Work vs Shallow Work correctly', () {
      const stats = BimodalFocusStats(
        deepWorkMinutes: 140,
        shallowWorkMinutes: 25,
        deepWorkSessions: 2,
        shallowWorkSessions: 1,
        classicSessions: 1,
        extendedSessions: 1,
        ultradianSessions: 1,
        flowmodoroSessions: 0,
      );

      expect(stats.totalMinutes, 165);
      expect(stats.totalSessions, 3);
      expect(stats.deepWorkRatio, closeTo(140 / 165, 0.01));
      expect(stats.shallowWorkRatio, closeTo(25 / 165, 0.01));
      expect(stats.formattedDeepWorkTime, '2h 20m');
      expect(stats.formattedShallowWorkTime, '25m');
    });
  });
}
