import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/brand_logo.dart';
import '../../../core/gamification/gamification_controller.dart';
import '../../habits/domain/habit.dart';
import '../../habits/presentation/controllers/habits_controller.dart';
import '../../pomodoro/presentation/controllers/pomodoro_controller.dart';

/// Executive Precision Launcher Screen.
/// Faithfully designed according to Documentos adicionales (hombre_disciplina_foco & herramientas_h_bitos).
class LauncherScreen extends ConsumerWidget {
  const LauncherScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(gamificationProvider);
    final habitsAsync = ref.watch(habitsControllerProvider);
    final pomodoro = ref.watch(pomodoroProvider);

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
                  const FocusHabitualLogo(size: 34),
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
                        'SUITE POLÍMATA V2.4',
                        style: AppTheme.labelCaps(
                          fontSize: 10,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),

                  // Notification Bell
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.notifications_none_rounded),
                    color: AppTheme.onSurfaceVariant,
                    iconSize: 22,
                  ),

                  // Avatar
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
      body: habitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (habits) {
          final completedToday = habits.where((h) => h.isCompletedToday).length;
          final totalHabits = habits.length;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            children: [
              // 1. Executive Status & Greeting Banner
              _buildExecutiveGreetingHeader(),
              const SizedBox(height: 16),

              // 2. Biblical Wisdom & Principle Rector Card
              _buildBiblicalPrincipleCard(context),
              const SizedBox(height: 16),

              // 3. Reto 21 Días de Constancia (Card Destacada)
              _build21DaysChallengeCard(context),
              const SizedBox(height: 16),

              // 4. Dominio Personal & Vitalidad (NoFap / Autodominio)
              _buildSelfMasteryCounterCard(context),
              const SizedBox(height: 16),

              // 5. Today's Priority Habits (Checklist Atómico)
              _buildTodayHabitsCard(context, ref, habits, completedToday, totalHabits),
              const SizedBox(height: 16),

              // 6. Deep Work Pomodoro Quick Launch Card
              _buildPomodoroQuickCard(context, pomodoro),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildExecutiveGreetingHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'LUNES, 24 DE MAYO',
              style: AppTheme.labelCaps(
                fontSize: 11,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
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
                    'Rendimiento Óptimo',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Buenos días, Martín',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            color: AppTheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Tu claridad mental guía las decisiones estratégicas de hoy.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildBiblicalPrincipleCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.menu_book_rounded,
                      size: 18,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'PRINCIPIO RECTOR • PROVERBIOS 16:3',
                      style: AppTheme.labelCaps(
                        fontSize: 11,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
                const Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: AppTheme.outline,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '«Encomienda al Señor tus obras, y tus pensamientos serán afirmados.»',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.4,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pilar cognitivo para ejecución limpia',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.edit_note_rounded, size: 16),
                  label: const Text('Reflexionar'),
                  style: TextButton.styleFrom(
                    backgroundColor: AppTheme.surfaceContainerLow,
                    foregroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    textStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _build21DaysChallengeCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.flag_rounded,
                        color: AppTheme.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'RETO ACTIVO',
                          style: AppTheme.labelCaps(
                            fontSize: 10,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '21 Días de Constancia',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '66%',
                    style: AppTheme.numeric(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Fase II: Consolidación neuronal',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  'Día 14 de 21',
                  style: AppTheme.numeric(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: const LinearProgressIndicator(
                value: 0.66,
                minHeight: 7,
                backgroundColor: AppTheme.surfaceContainerHigh,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
              ),
            ),
            const SizedBox(height: 16),

            // Mini Nodos de la Semana (L M X J V S D)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildWeekNode('L', isDone: true),
                _buildWeekNode('M', isDone: true),
                _buildWeekNode('X', isDone: true),
                _buildWeekNode('J', isDone: true),
                _buildWeekNode('V', isDone: true),
                _buildWeekNode('S', dayNum: '14', isActive: true),
                _buildWeekNode('D', dayNum: '15', isPending: true),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(color: AppTheme.surfaceContainer),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      size: 18,
                      color: AppTheme.tertiaryContainer,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Racha: ',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '14 días',
                      style: AppTheme.numeric(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurface,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () => context.go('/habits'),
                  child: Row(
                    children: [
                      Text(
                        'Ver progreso',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: AppTheme.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekNode(
    String dayLabel, {
    bool isDone = false,
    bool isActive = false,
    bool isPending = false,
    String? dayNum,
  }) {
    return Column(
      children: [
        Text(
          dayLabel,
          style: AppTheme.labelCaps(
            fontSize: 10,
            color: AppTheme.outline,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isDone
                ? AppTheme.primary
                : isActive
                    ? AppTheme.surfaceContainerHigh
                    : AppTheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: isDone
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : Text(
                  dayNum ?? '',
                  style: AppTheme.numeric(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isActive ? AppTheme.primary : AppTheme.outline,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSelfMasteryCounterCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.verified_user_rounded,
                      size: 20,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Dominio Personal & Vitalidad',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurface,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Fase 2: Consolidación',
                    style: AppTheme.labelCaps(
                      fontSize: 10,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 4 Live Counter Blocks
            Row(
              children: [
                Expanded(child: _buildCounterBlock('42', 'DÍAS', isHighlight: false)),
                const SizedBox(width: 8),
                Expanded(child: _buildCounterBlock('14', 'HORAS', isHighlight: false)),
                const SizedBox(width: 8),
                Expanded(child: _buildCounterBlock('36', 'MIN', isHighlight: false)),
                const SizedBox(width: 8),
                Expanded(child: _buildCounterBlock('22', 'SEG', isHighlight: true)),
              ],
            ),
            const SizedBox(height: 16),

            // Milestone bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Meta de Transmutación Cognitiva',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurface,
                  ),
                ),
                Text(
                  '42 / 90 Días (46.6%)',
                  style: AppTheme.numeric(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: const LinearProgressIndicator(
                value: 0.466,
                minHeight: 8,
                backgroundColor: AppTheme.surfaceContainerHigh,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Día 0', style: AppTheme.labelCaps(fontSize: 10, color: AppTheme.outline)),
                Text('Día 45 (Reset Dopamina)', style: AppTheme.labelCaps(fontSize: 10, color: AppTheme.outline)),
                Text('Día 90 (Maestría)', style: AppTheme.labelCaps(fontSize: 10, color: AppTheme.outline)),
              ],
            ),
            const SizedBox(height: 14),

            // SOS Cooling Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.air_rounded, color: AppTheme.primary, size: 18),
                label: const Text('Protocolo de Enfriamiento Inmediato (3 min)'),
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppTheme.surfaceContainerHigh,
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurface,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterBlock(String value, String label, {required bool isHighlight}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTheme.numeric(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isHighlight ? AppTheme.primary : AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTheme.labelCaps(
              fontSize: 9,
              color: isHighlight ? AppTheme.primary : AppTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayHabitsCard(
    BuildContext context,
    WidgetRef ref,
    List<HabitWithStatus> habits,
    int completed,
    int total,
  ) {
    final previewList = habits.take(4).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HÁBITOS & RUTINAS DE HOY',
                      style: AppTheme.labelCaps(
                        fontSize: 11,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$completed de $total completados',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: completed == total && total > 0
                            ? AppTheme.accentEmerald
                            : AppTheme.primary,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => context.go('/habits'),
                  child: Text(
                    'Ver todos',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            ...previewList.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  if (idx > 0)
                    const Divider(color: AppTheme.surfaceContainer, height: 16),
                  _buildSwissHabitRow(ref, item),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSwissHabitRow(WidgetRef ref, HabitWithStatus item) {
    final isDone = item.isCompletedToday;

    return InkWell(
      onTap: () {
        ref.read(habitsControllerProvider.notifier).toggleHabit(item.habit.id);
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            // Swiss Square Checkbox (18x18, 5px radius)
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isDone ? AppTheme.primary : AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isDone ? AppTheme.primary : AppTheme.outlineVariant,
                  width: 1.5,
                ),
              ),
              child: isDone
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.habit.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                      color: isDone ? AppTheme.outline : AppTheme.onSurface,
                    ),
                  ),
                  Text(
                    item.habit.category.displayName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isDone
                    ? AppTheme.surfaceContainerLow
                    : AppTheme.surfaceContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '+10 XP',
                style: AppTheme.numeric(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isDone ? AppTheme.primary : AppTheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPomodoroQuickCard(BuildContext context, PomodoroState pomodoro) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.hourglass_top_rounded,
                color: AppTheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pomodoro.status == PomodoroStatus.running
                        ? 'Enfoque en Curso (${pomodoro.formattedTime})'
                        : 'Deep Work • Sprint de 25 min',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Vector: ${pomodoro.selectedTag} • +25 XP',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => context.go('/pomodoro'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              child: Text(
                pomodoro.status == PomodoroStatus.running ? 'Ver' : 'Iniciar',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
