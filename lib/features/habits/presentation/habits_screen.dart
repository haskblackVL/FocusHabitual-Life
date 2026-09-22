import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/brand_logo.dart';
import 'controllers/habits_controller.dart';
import '../domain/habit.dart';
import 'widgets/add_habit_sheet.dart';

/// Full interactive Habits & Routines screen matching herramientas_h_bitos/code.html.
class HabitsScreen extends ConsumerStatefulWidget {
  const HabitsScreen({super.key});

  @override
  ConsumerState<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends ConsumerState<HabitsScreen> {
  HabitCategory? _selectedFilter;

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitsControllerProvider);

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
                        'HERRAMIENTAS & HÁBITOS',
                        style: AppTheme.labelCaps(
                          fontSize: 10,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => AddHabitSheet.show(context),
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    color: AppTheme.primary,
                    iconSize: 24,
                    tooltip: 'Nuevo Hábito',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AddHabitSheet.show(context),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Nuevo Hábito',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
      ),
      body: habitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (allHabits) {
          final habits = _selectedFilter == null
              ? allHabits
              : allHabits.where((h) => h.habit.category == _selectedFilter).toList();

          final completedToday = allHabits.where((h) => h.isCompletedToday).length;
          final totalHabits = allHabits.length;
          // ignore: unused_local_variable
          final _ = (completedToday, totalHabits);

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            children: [
              // Header Tagline
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'SUITE POLÍMATA V2.4',
                          style: AppTheme.labelCaps(fontSize: 10, color: AppTheme.primary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Suite de Herramientas',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Sistemas de alto rendimiento para dominio cognitivo y hábitos atómicos.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Reto 21 Días de Constancia (Card Destacada)
              _build21DaysCard(),
              const SizedBox(height: 16),

              // Bienestar Digital Widget
              _buildDigitalWellnessCard(),
              const SizedBox(height: 16),

              // Filter Chips
              _buildCategoryFilters(),
              const SizedBox(height: 14),

              // Habit Items
              if (habits.isEmpty)
                _buildEmptyState()
              else
                ...habits.map((item) => _buildHabitCard(item)),

              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }

  Widget _build21DaysCard() {
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
                          style: AppTheme.labelCaps(fontSize: 10, color: AppTheme.onSurfaceVariant),
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

            // Mini Nodos L M X J V S D
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
          style: AppTheme.labelCaps(fontSize: 10, color: AppTheme.outline),
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

  Widget _buildDigitalWellnessCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.secondary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.devices_rounded,
                        color: AppTheme.secondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bienestar Digital',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onSurface,
                          ),
                        ),
                        Text(
                          'Límites y enfoque consciente',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('HOY', style: AppTheme.labelCaps(fontSize: 10)),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TIEMPO ACTIVO',
                        style: AppTheme.labelCaps(fontSize: 9, color: AppTheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '1h 42m',
                        style: AppTheme.numeric(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'META DIARIA',
                        style: AppTheme.labelCaps(fontSize: 9, color: AppTheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Máx. 2h 30m',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    final filters = <(String, HabitCategory?)>[
      ('Todos', null),
      ('Rutina AM', HabitCategory.checklistAm),
      ('Rutina PM', HabitCategory.checklistPm),
      ('Reto 21 Días', HabitCategory.challenge21),
      ('General', HabitCategory.general),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedFilter == f.$2;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(f.$1),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedFilter = f.$2),
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
    );
  }

  Widget _buildHabitCard(HabitWithStatus item) {
    final isDone = item.isCompletedToday;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () {
          ref.read(habitsControllerProvider.notifier).toggleHabit(item.habit.id);
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDone ? AppTheme.surfaceContainerLow : AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDone ? AppTheme.primary.withValues(alpha: 0.3) : AppTheme.outlineVariant,
              width: 1,
            ),
          ),
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
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          item.habit.category.displayName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                        if (item.streakCount > 0) ...[
                          const SizedBox(width: 6),
                          const Text('•', style: TextStyle(color: AppTheme.outline)),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.local_fire_department_rounded,
                            size: 13,
                            color: AppTheme.tertiaryContainer,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${item.streakCount} d',
                            style: AppTheme.numeric(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.tertiaryContainer,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDone ? AppTheme.surfaceContainerHigh : AppTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '+10 XP',
                  style: AppTheme.numeric(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDone ? AppTheme.primary : AppTheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(
            Icons.checklist_rounded,
            size: 40,
            color: AppTheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            'Sin hábitos en esta categoría',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pulsa "Nuevo Hábito" para registrar una meta.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
