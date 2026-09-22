import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/brand_logo.dart';
import 'controllers/pomodoro_controller.dart';

/// Full interactive Pomodoro & Deep Work Screen matching pomodoro_deep_work/code.html.
class PomodoroScreen extends ConsumerStatefulWidget {
  const PomodoroScreen({super.key});

  @override
  ConsumerState<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends ConsumerState<PomodoroScreen> {
  bool _monkMode = true;

  final List<String> _vectors = [
    'Arquitectura de Sistemas',
    'Microeconomía & Finanzas',
    'Filosofía & Ética',
    'Inteligencia Artificial',
    'Estrategia Corporativa',
  ];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pomodoroProvider);
    final notifier = ref.read(pomodoroProvider.notifier);

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
                  Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
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
            // 1. Polymath Vector Selection Ribbon
            _buildVectorRibbon(state, notifier),
            const SizedBox(height: 18),

            // 2. Central Focus Node & Concentric Chronometer Card
            _buildCentralChronometerCard(state),
            const SizedBox(height: 18),

            // 3. Primary Chronometer Control Deck
            _buildControlDeck(state, notifier),
            const SizedBox(height: 18),

            // 4. Mode Presets Selector (Focus 25, Break 5, Long Break 15)
            _buildModePresets(state, notifier),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildVectorRibbon(PomodoroState state, PomodoroNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'VECTOR POLÍMATA ACTIVO',
              style: AppTheme.labelCaps(fontSize: 11, color: AppTheme.onSurfaceVariant),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Nivel IV • 84%',
                style: AppTheme.numeric(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _vectors.map((vec) {
              final isSelected = state.selectedTag == vec;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  avatar: Icon(
                    Icons.account_tree_outlined,
                    size: 15,
                    color: isSelected ? Colors.white : AppTheme.onSurfaceVariant,
                  ),
                  label: Text(vec),
                  selected: isSelected,
                  onSelected: (_) => notifier.setTag(vec),
                  selectedColor: AppTheme.primary,
                  backgroundColor: AppTheme.surfaceContainerLowest,
                  labelStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppTheme.onSurfaceVariant,
                  ),
                  side: BorderSide(
                    color: isSelected ? AppTheme.primary : AppTheme.outlineVariant,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCentralChronometerCard(PomodoroState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Cycle & State Metadata
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
                        decoration: const BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Ciclo 2 de 4',
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
                      '92% Eficiencia',
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
            const SizedBox(height: 24),

            // Concentric Chronometer Dial
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 230,
                  height: 230,
                  child: CircularProgressIndicator(
                    value: state.progress,
                    strokeWidth: 8,
                    backgroundColor: AppTheme.surfaceContainerHigh,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      state.mode == PomodoroMode.focus ? AppTheme.primary : AppTheme.accentEmerald,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'DEEP WORK',
                      style: AppTheme.labelCaps(fontSize: 10, color: AppTheme.onSurfaceVariant),
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.track_changes_rounded, size: 12, color: AppTheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            'Sprints de 50m',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Monk Mode Toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
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
                          'Modo Monje Total',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onSurface,
                          ),
                        ),
                        Text(
                          'Silencia llamadas y bloquea distracciones',
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
                    onChanged: (val) => setState(() => _monkMode = val),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlDeck(PomodoroState state, PomodoroNotifier notifier) {
    return Row(
      children: [
        // Main Primary Cobalt Action Button
        Expanded(
          flex: 3,
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: state.status == PomodoroStatus.running ? notifier.pause : notifier.start,
              icon: Icon(
                state.status == PomodoroStatus.running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 24,
              ),
              label: Text(
                state.status == PomodoroStatus.running ? 'Pausar' : 'Iniciar Enfoque',
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

        // Pause / Secondary Button
        SizedBox(
          height: 52,
          child: OutlinedButton(
            onPressed: state.status == PomodoroStatus.running ? notifier.pause : null,
            style: OutlinedButton.styleFrom(
              backgroundColor: AppTheme.surfaceContainerLowest,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Pausa'),
          ),
        ),
        const SizedBox(width: 10),

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
          ),
        ),
      ],
    );
  }

  Widget _buildModePresets(PomodoroState state, PomodoroNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.outlineVariant),
      ),
      child: Row(
        children: PomodoroMode.values.map((mode) {
          final isSelected = state.mode == mode;
          return Expanded(
            child: InkWell(
              onTap: () => notifier.setMode(mode),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.surfaceContainer : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  mode.displayName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppTheme.primary : AppTheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
