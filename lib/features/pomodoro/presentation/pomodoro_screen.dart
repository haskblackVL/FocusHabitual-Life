import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/brand_logo.dart';
import '../domain/pomodoro_models.dart';
import 'controllers/pomodoro_controller.dart';
import 'widgets/ambient_sound_bar.dart';
import 'widgets/daily_blocks_sheet.dart';
import 'widgets/interruption_sheet.dart';
import 'widgets/kinesthetic_break_view.dart';
import 'widgets/post_session_summary_dialog.dart';
import 'widgets/startup_checklist_sheet.dart';

/// Full interactive Executive Pomodoro & Deep Work Screen.
/// Implements Bimodal Focus, Deep Work modes, Flowmodoro, Radical Cognitive Decoupling,
/// Bloc de Descarga (Interruption Sheet), and Natural Ambient Soundscapes.
class PomodoroScreen extends ConsumerStatefulWidget {
  const PomodoroScreen({super.key});

  @override
  ConsumerState<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends ConsumerState<PomodoroScreen> {
  bool _monkMode = true;

  @override
  void initState() {
    super.initState();
    // Listen for session completion to display post-session debrief modal
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSessionDialogPending();
    });
  }

  void _checkSessionDialogPending() {
    final state = ref.read(pomodoroProvider);
    if (state.sessionCompletedDialogPending) {
      PostSessionSummaryDialog.show(context);
    }
  }

  void _handleStart(PomodoroState state, PomodoroNotifier notifier) {
    if (state.status == PomodoroStatus.running) {
      if (state.mode.isFlowmodoro) {
        notifier.stopFlowmodoroAndStartBreak();
      } else {
        notifier.pause();
      }
      return;
    }

    if (state.status == PomodoroStatus.paused) {
      notifier.start();
      return;
    }

    // Starting new session
    if (state.workType.isDeepWork && (state.taskObjective == null || state.taskObjective!.isEmpty)) {
      StartupChecklistSheet.show(context);
    } else {
      notifier.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pomodoroProvider);
    final notifier = ref.read(pomodoroProvider.notifier);

    // Auto-trigger dialog if session completes while on screen
    ref.listen<PomodoroState>(pomodoroProvider, (prev, next) {
      if (next.sessionCompletedDialogPending && !(prev?.sessionCompletedDialogPending ?? false)) {
        PostSessionSummaryDialog.show(context);
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest.withValues(alpha: 0.92),
            border: const Border(
              bottom: BorderSide(color: AppTheme.surfaceContainerHigh, width: 1),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const FocusHabitualLogo(size: 32),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FocusHabitual',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      Text(
                        'DEEP WORK & POMODORO',
                        style: AppTheme.labelCaps(
                          fontSize: 10,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),

                  // Daily Planner Block Template Button
                  IconButton(
                    onPressed: () => DailyBlocksSheet.show(context),
                    icon: const Icon(Icons.calendar_view_day_rounded, size: 22),
                    color: AppTheme.primary,
                    tooltip: 'Planificador de Bloques',
                  ),
                  const SizedBox(width: 4),

                  // Interruption Notes Quick Access Button
                  IconButton(
                    onPressed: () => InterruptionSheet.show(context),
                    icon: Badge(
                      isLabelVisible: state.interruptionNotes.isNotEmpty,
                      label: Text('${state.interruptionNotes.length}'),
                      backgroundColor: AppTheme.primary,
                      child: const Icon(Icons.edit_note_rounded, size: 22),
                    ),
                    color: AppTheme.onSurfaceVariant,
                    tooltip: 'Bloc de Descarga',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. Bimodal Work Type Selector (Deep Work vs Shallow Work)
            if (!state.isBreak) ...[
              _buildBimodalSelector(state, notifier),
              const SizedBox(height: 14),

              // 2. Timer Mode Presets (Classic, Extended, Ultradian, Flowmodoro)
              _buildModeSelector(state, notifier),
              const SizedBox(height: 16),
            ],

            // 3. Central Node: Chronometer Card OR Radical Cognitive Decoupling Break View
            if (state.isBreak)
              const KinestheticBreakView()
            else
              _buildCentralChronometerCard(state, notifier),
            const SizedBox(height: 16),

            // 4. Ambient Natural Soundscape Bar
            const AmbientSoundBar(),
            const SizedBox(height: 16),

            // 5. Primary Control Deck
            if (!state.isBreak) ...[
              _buildControlDeck(state, notifier),
              const SizedBox(height: 16),
            ],

            // 6. Monk Mode & DND status banner
            _buildMonkModeCard(state, notifier),
            const SizedBox(height: 24),
          ],
        ),
      ),
      floatingActionButton: (!state.isBreak && state.status == PomodoroStatus.running)
          ? FloatingActionButton.extended(
              onPressed: () => InterruptionSheet.show(context),
              backgroundColor: AppTheme.surfaceContainerLowest,
              foregroundColor: AppTheme.primary,
              icon: Badge(
                isLabelVisible: state.interruptionNotes.isNotEmpty,
                label: Text('${state.interruptionNotes.length}'),
                backgroundColor: AppTheme.primary,
                child: const Icon(Icons.edit_note_rounded),
              ),
              label: Text(
                'Bloc de Descarga',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                ),
              ),
            )
          : null,
    );
  }

  /// Bimodal selector between Deep Work and Shallow Work.
  Widget _buildBimodalSelector(PomodoroState state, PomodoroNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildBimodalTab(
              title: 'Deep Work',
              subtitle: '1.5x XP • Enfoque Nuclear',
              icon: Icons.psychology_rounded,
              isSelected: state.workType == WorkType.deepWork,
              onTap: () => notifier.setWorkType(WorkType.deepWork),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildBimodalTab(
              title: 'Shallow Work',
              subtitle: '1.0x XP • Mantenimiento',
              icon: Icons.task_alt_rounded,
              isSelected: state.workType == WorkType.shallowWork,
              onTap: () => notifier.setWorkType(WorkType.shallowWork),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBimodalTab({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.surfaceContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppTheme.primary : AppTheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? AppTheme.primary : AppTheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      color: AppTheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 4-mode timer preset switcher.
  Widget _buildModeSelector(PomodoroState state, PomodoroNotifier notifier) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: PomodoroTimerMode.values.map((mode) {
          final isSelected = state.mode == mode;
          final isRunning = state.status == PomodoroStatus.running;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              showCheckmark: false,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    mode.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : AppTheme.onSurfaceVariant,
                    ),
                  ),
                  if (mode.suggestedDailyCap != null) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.2)
                            : AppTheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Máx ${mode.suggestedDailyCap}/d',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : AppTheme.outline,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              selected: isSelected,
              selectedColor: AppTheme.primary,
              backgroundColor: AppTheme.surfaceContainerLowest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: isSelected ? AppTheme.primary : AppTheme.outlineVariant,
                ),
              ),
              onSelected: isRunning ? null : (selected) {
                if (selected) notifier.setMode(mode);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Concentric chronometer dial and cycle node.
  Widget _buildCentralChronometerCard(PomodoroState state, PomodoroNotifier notifier) {
    final isFlowmodoro = state.mode.isFlowmodoro;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Cycle & Telemetry Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: state.workType.isDeepWork ? AppTheme.primary : AppTheme.accentEmerald,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Sesión ${state.completedSessionsToday + 1}',
                        style: AppTheme.labelCaps(fontSize: 10, color: AppTheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.bolt_rounded, size: 16, color: AppTheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      state.workType.isDeepWork ? '+38 XP Deep Work' : '+25 XP Standard',
                      style: AppTheme.numeric(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Concentric Chronometer Dial
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 230,
                  height: 230,
                  child: CircularProgressIndicator(
                    value: isFlowmodoro
                        ? (state.status == PomodoroStatus.running ? state.progress : 1.0)
                        : state.progress,
                    strokeWidth: 8,
                    backgroundColor: AppTheme.surfaceContainerHigh,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      state.workType.isDeepWork ? AppTheme.primary : AppTheme.accentEmerald,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isFlowmodoro
                          ? 'FLOWTIME ASCENDENTE'
                          : (state.workType.isDeepWork ? 'DEEP WORK' : 'SHALLOW WORK'),
                      style: AppTheme.labelCaps(
                        fontSize: 10,
                        color: state.workType.isDeepWork ? AppTheme.primary : AppTheme.accentEmerald,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      state.formattedTime,
                      style: AppTheme.numeric(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.onSurface,
                        letterSpacing: -1.5,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Tag and mode label
                    GestureDetector(
                      onTap: () => _showTagPicker(context, notifier, state.selectedTag),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.label_rounded, size: 12, color: AppTheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              state.selectedTag,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.onSurface,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_drop_down, size: 14, color: AppTheme.outline),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Active Objective Banner (if set from checklist)
            if (state.taskObjective != null && state.taskObjective!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.flag_rounded, size: 16, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.taskObjective!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Flowmodoro Tip / Mode Description
            Text(
              state.mode.description,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Primary control deck with Start/Pause/Reset.
  Widget _buildControlDeck(PomodoroState state, PomodoroNotifier notifier) {
    final isRunning = state.status == PomodoroStatus.running;
    final isPaused = state.status == PomodoroStatus.paused;
    final isFlowmodoro = state.mode.isFlowmodoro;

    return Row(
      children: [
        // Main Action Button
        Expanded(
          flex: 3,
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => _handleStart(state, notifier),
              icon: Icon(
                isRunning
                    ? (isFlowmodoro ? Icons.stop_circle_rounded : Icons.pause_rounded)
                    : Icons.play_arrow_rounded,
                size: 24,
              ),
              label: Text(
                isRunning
                    ? (isFlowmodoro ? 'Terminar y Descansar' : 'Pausar')
                    : (isPaused ? 'Reanudar' : 'Iniciar Enfoque'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Checklist Button (if idle and deep work) OR Secondary Pause
        if (!isRunning && !isPaused && state.workType.isDeepWork)
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () => StartupChecklistSheet.show(context),
              icon: const Icon(Icons.checklist_rounded, size: 20),
              label: const Text('Checklist'),
              style: OutlinedButton.styleFrom(
                backgroundColor: AppTheme.surfaceContainerLowest,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          )
        else ...[
          // Reset Button
          SizedBox(
            height: 52,
            width: 52,
            child: IconButton.outlined(
              onPressed: notifier.reset,
              icon: const Icon(Icons.restart_alt_rounded),
              color: AppTheme.onSurfaceVariant,
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.surfaceContainerLowest,
                side: const BorderSide(color: AppTheme.outlineVariant),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              tooltip: 'Reiniciar Bloque',
            ),
          ),
        ],
      ],
    );
  }

  /// Monk Mode / DND Card.
  Widget _buildMonkModeCard(PomodoroState state, PomodoroNotifier notifier) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.do_not_disturb_on_rounded,
              color: AppTheme.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Modo Monje & Silencio',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurface,
                  ),
                ),
                Text(
                  'Silencia llamadas y bloquea notificaciones externas',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _monkMode,
            activeThumbColor: AppTheme.primary,
            onChanged: (val) {
              setState(() => _monkMode = val);
              notifier.toggleDnd(val);
            },
          ),
        ],
      ),
    );
  }

  void _showTagPicker(BuildContext context, PomodoroNotifier notifier, String currentTag) {
    const tags = [
      'Desarrollo Core',
      'Arquitectura de Software',
      'Depuración & Testing',
      'Estudio Técnico',
      'Investigación',
      'Revisión & Commits',
      'Logística & Tickets',
    ];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selecciona el Vector de Enfoque',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags.map((t) {
                    final isSelected = t == currentTag;
                    return ActionChip(
                      label: Text(t),
                      backgroundColor: isSelected ? AppTheme.primary : AppTheme.surfaceContainerLow,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.onSurface,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                      onPressed: () {
                        notifier.setTag(t);
                        Navigator.pop(ctx);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
