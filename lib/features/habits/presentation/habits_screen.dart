import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/brand_logo.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import 'controllers/habits_controller.dart';
import '../domain/challenge_21_data.dart';
import '../domain/habit.dart';
import 'widgets/add_habit_sheet.dart';

enum HabitFilterTab {
  all('Todos', Icons.grid_view_rounded),
  morning('Rutina Matutina', Icons.wb_sunny_rounded),
  general('General / Reto 21 Días', Icons.flag_rounded),
  evening('Rutina Nocturna', Icons.nightlight_round);

  final String label;
  final IconData icon;
  const HabitFilterTab(this.label, this.icon);
}

/// Redesigned Habits screen structured into 3 distinct sections:
/// 1. Rutina Matutina
/// 2. General / Reto 21 Días
/// 3. Rutina Nocturna
class HabitsScreen extends ConsumerStatefulWidget {
  const HabitsScreen({super.key});

  @override
  ConsumerState<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends ConsumerState<HabitsScreen> {
  HabitFilterTab _selectedTab = HabitFilterTab.all;
  bool _isMorningExpanded = true;
  bool _isGeneralExpanded = false;
  bool _isEveningExpanded = false;

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitsControllerProvider);
    final challengeAsync = ref.watch(challenge21ControllerProvider);
    final profileAsync = ref.watch(userProfileControllerProvider);
    final isReligious = profileAsync.value?.isReligious ?? false;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest.withValues(alpha: 0.95),
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
                        'SISTEMA DE HÁBITOS & RUTINAS',
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
          // Categorize habits strictly into the 3 requested sections
          final morningHabits = allHabits
              .where((h) => h.habit.category == HabitCategory.checklistAm)
              .toList();

          final eveningHabits = allHabits
              .where((h) => h.habit.category == HabitCategory.checklistPm)
              .toList();

          final generalHabits = allHabits
              .where((h) =>
                  h.habit.category != HabitCategory.checklistAm &&
                  h.habit.category != HabitCategory.checklistPm)
              .toList();

          final completedToday = allHabits.where((h) => h.isCompletedToday).length;
          final totalHabits = allHabits.length;
          final completionPercent =
              totalHabits > 0 ? (completedToday / totalHabits * 100).round() : 0;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(habitsControllerProvider);
              ref.invalidate(challenge21ControllerProvider);
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                // Top Global Telemetry Banner
                _buildGlobalTelemetryCard(
                  completedCount: completedToday,
                  totalCount: totalHabits,
                  percentage: completionPercent,
                ),
                const SizedBox(height: 14),

                // 1. Reto Activo 21 Días (HASTA ARRIBA)
                challengeAsync.when(
                  data: (challengeData) => challengeData != null
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _build21DaysCard(challengeData),
                        )
                      : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),

                // 2. Herramientas de Crecimiento: 50 Hábitos, Gratitud Estoica, Finanzas, etc. (HASTA ARRIBA)
                _buildExecutiveToolsRow(context, isReligious),
                const SizedBox(height: 14),

                // 3. Bienestar Digital (HASTA ARRIBA)
                _buildDigitalWellnessCard(),
                const SizedBox(height: 18),

                // Filtros de navegación por segmento
                _buildSegmentFilter(),
                const SizedBox(height: 16),

                // SECCIONES DE HÁBITOS DESPLEGABLES (PARA NO CONSUMIR SCROLLING)

                // 1. RUTINA MATUTINA (DESPLEGABLE)
                if (_selectedTab == HabitFilterTab.all ||
                    _selectedTab == HabitFilterTab.morning)
                  _buildCollapsibleRoutineSection(
                    title: 'Rutina Matutina',
                    subtitle: 'Activación neuromuscular, hidratación y orden inicial',
                    icon: Icons.wb_sunny_rounded,
                    accentColor: const Color(0xFFD97706), // Warm Amber
                    countLabel:
                        '${morningHabits.where((h) => h.isCompletedToday).length}/${morningHabits.length}',
                    isExpanded: _isMorningExpanded,
                    onToggle: () => setState(() => _isMorningExpanded = !_isMorningExpanded),
                    onAddPressed: () => AddHabitSheet.show(
                      context,
                      initialCategory: HabitCategory.checklistAm,
                    ),
                    emptyState: _buildSectionEmptyState(
                      'No hay hábitos en tu Rutina Matutina.',
                      category: HabitCategory.checklistAm,
                    ),
                    children: morningHabits.map((item) => _buildHabitCard(item)).toList(),
                  ),

                // 2. GENERAL / RETO 21 DÍAS (DESPLEGABLE)
                if (_selectedTab == HabitFilterTab.all ||
                    _selectedTab == HabitFilterTab.general)
                  _buildCollapsibleRoutineSection(
                    title: 'Rutina General / 21 Días',
                    subtitle: 'Enfoque profundo, constancia de 21 días y hábitos base',
                    icon: Icons.flag_rounded,
                    accentColor: AppTheme.primary,
                    countLabel:
                        '${generalHabits.where((h) => h.isCompletedToday).length}/${generalHabits.length}',
                    isExpanded: _isGeneralExpanded,
                    onToggle: () => setState(() => _isGeneralExpanded = !_isGeneralExpanded),
                    onAddPressed: () => AddHabitSheet.show(
                      context,
                      initialCategory: HabitCategory.general,
                    ),
                    emptyState: _buildSectionEmptyState(
                      'No hay hábitos generales activos.',
                      category: HabitCategory.general,
                    ),
                    children: generalHabits.map((item) => _buildHabitCard(item)).toList(),
                  ),

                // 3. RUTINA NOCTURNA (DESPLEGABLE)
                if (_selectedTab == HabitFilterTab.all ||
                    _selectedTab == HabitFilterTab.evening)
                  _buildCollapsibleRoutineSection(
                    title: 'Rutina Nocturna',
                    subtitle: 'Desconexión digital, higiene del sueño y cierre del día',
                    icon: Icons.nightlight_round,
                    accentColor: const Color(0xFF6366F1), // Deep Indigo
                    countLabel:
                        '${eveningHabits.where((h) => h.isCompletedToday).length}/${eveningHabits.length}',
                    isExpanded: _isEveningExpanded,
                    onToggle: () => setState(() => _isEveningExpanded = !_isEveningExpanded),
                    onAddPressed: () => AddHabitSheet.show(
                      context,
                      initialCategory: HabitCategory.checklistPm,
                    ),
                    emptyState: _buildSectionEmptyState(
                      'No hay hábitos en tu Rutina Nocturna.',
                      category: HabitCategory.checklistPm,
                    ),
                    children: eveningHabits.map((item) => _buildHabitCard(item)).toList(),
                  ),

                const SizedBox(height: 70),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Global telemetry banner showing overall daily completion and XP
  Widget _buildGlobalTelemetryCard({
    required int completedCount,
    required int totalCount,
    required int percentage,
  }) {
    final xpEarnedToday = completedCount * 10;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.outline.withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.insights_rounded,
                      color: AppTheme.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PANEL DIARIO DE CUMPLIMIENTO',
                        style: AppTheme.labelCaps(
                          fontSize: 9.5,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        'Progreso Global',
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '+$xpEarnedToday XP Hoy',
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
                '$completedCount de $totalCount hábitos completados',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurface,
                ),
              ),
              Text(
                '$percentage%',
                style: AppTheme.numeric(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: totalCount > 0 ? (completedCount / totalCount).clamp(0.0, 1.0) : 0.0,
              minHeight: 8,
              backgroundColor: AppTheme.surfaceContainerHigh,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  /// Segmented navigation chips to switch between sections or view all
  Widget _buildSegmentFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: HabitFilterTab.values.map((tab) {
          final isSelected = _selectedTab == tab;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => setState(() {
                _selectedTab = tab;
                if (tab == HabitFilterTab.morning) {
                  _isMorningExpanded = true;
                } else if (tab == HabitFilterTab.general) {
                  _isGeneralExpanded = true;
                } else if (tab == HabitFilterTab.evening) {
                  _isEveningExpanded = true;
                }
              }),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary : AppTheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primary
                        : AppTheme.outline.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tab.icon,
                      size: 14,
                      color: isSelected ? Colors.white : AppTheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tab.label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Collapsible Routine Section with animated chevron and unfoldable habit list
  Widget _buildCollapsibleRoutineSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required String countLabel,
    required bool isExpanded,
    required VoidCallback onToggle,
    required VoidCallback onAddPressed,
    required List<Widget> children,
    required Widget emptyState,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isExpanded
                        ? accentColor.withValues(alpha: 0.35)
                        : AppTheme.outline.withValues(alpha: 0.12),
                    width: isExpanded ? 1.4 : 1.0,
                  ),
                  boxShadow: isExpanded
                      ? [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icon,
                        color: accentColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  title,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.onSurface,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: accentColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  countLabel,
                                  style: AppTheme.numeric(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: accentColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isExpanded ? subtitle : '$subtitle • Toca para desplegar',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppTheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: onAddPressed,
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      color: accentColor,
                      iconSize: 22,
                      tooltip: 'Añadir a esta sección',
                      visualDensity: VisualDensity.compact,
                    ),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: isExpanded ? accentColor : AppTheme.onSurfaceVariant,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                children: children.isEmpty ? [emptyState] : children,
              ),
            ),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
        ],
      ),
    );
  }

  /// Interactive habit card with checkmark, streak, and delete option with confirmation modal
  Widget _buildHabitCard(HabitWithStatus item) {
    final isDone = item.isCompletedToday;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: Key('habit_${item.habit.id}'),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) => _confirmDeleteHabit(context, item),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.red.shade600,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
              SizedBox(width: 6),
              Text(
                'Eliminar',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: isDone ? AppTheme.surfaceContainerLow : AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDone
                  ? AppTheme.primary.withValues(alpha: 0.3)
                  : AppTheme.outline.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                // Tappable check & title area
                Expanded(
                  child: InkWell(
                    onTap: () {
                      ref.read(habitsControllerProvider.notifier).toggleHabit(item.habit.id);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          // Swiss Checkbox (22x22, rounded)
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

                          // Habit Title & Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.habit.title,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    decoration: isDone ? TextDecoration.lineThrough : null,
                                    color: isDone ? AppTheme.outline : AppTheme.onSurface,
                                  ),
                                ),
                                if (item.habit.description != null &&
                                    item.habit.description!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    item.habit.description!,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: isDone
                                          ? AppTheme.outline.withValues(alpha: 0.7)
                                          : AppTheme.onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                if (item.streakCount > 0) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.local_fire_department_rounded,
                                        size: 13,
                                        color: AppTheme.tertiaryContainer,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${item.streakCount} días de racha',
                                        style: AppTheme.numeric(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.tertiaryContainer,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // XP Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDone
                        ? AppTheme.primary.withValues(alpha: 0.1)
                        : AppTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '+10 XP',
                    style: AppTheme.numeric(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: isDone ? AppTheme.primary : AppTheme.onSurfaceVariant,
                    ),
                  ),
                ),

                const SizedBox(width: 4),

                // Explicit Delete Button with Confirmation
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _confirmDeleteHabit(context, item),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: Colors.red.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Deletion confirmation modal
  Future<bool> _confirmDeleteHabit(BuildContext context, HabitWithStatus item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.red,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Eliminar Hábito',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          '¿Deseas eliminar "${item.habit.title}"?\n\nPodrás volver a agregarlo en cualquier momento si lo necesitas.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppTheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Eliminar',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(habitsControllerProvider.notifier).deleteHabit(item.habit.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hábito eliminado: "${item.habit.title}"'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return true;
    }
    return false;
  }

  /// Reto 21 Días de Constancia card
  Widget _build21DaysCard(Challenge21Data data) {
    final progress = data.currentDayNumber / 21.0;
    final percentage = (progress * 100).clamp(0, 100).toInt();

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.25),
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.flag_rounded,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RETO ACTIVO',
                        style: AppTheme.labelCaps(
                          fontSize: 9.5,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        data.habit.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$percentage%',
                    style: AppTheme.numeric(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Día ${data.currentDayNumber} de 21',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '${data.totalDaysCompleted} completados',
                  style: AppTheme.numeric(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 7,
                backgroundColor: AppTheme.surfaceContainerHigh,
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
              ),
            ),
            const SizedBox(height: 14),

            // 7-day interactive nodes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: data.weekNodes.map((node) {
                return Column(
                  children: [
                    Text(
                      node.dayLabel,
                      style: AppTheme.labelCaps(
                        fontSize: 10,
                        color: node.isToday ? AppTheme.primary : AppTheme.outline,
                      ),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: node.isToday
                          ? () => ref
                              .read(challenge21ControllerProvider.notifier)
                              .toggleToday()
                          : null,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: node.isDone
                              ? AppTheme.primary
                              : node.isToday
                                  ? AppTheme.surfaceContainerHigh
                                  : AppTheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(8),
                          border: node.isToday
                              ? Border.all(color: AppTheme.primary, width: 1.5)
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: node.isDone
                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                            : Text(
                                node.challengeDayNumber?.toString() ?? '',
                                style: AppTheme.numeric(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: node.isToday
                                      ? AppTheme.primary
                                      : AppTheme.outline,
                                ),
                              ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            const Divider(color: AppTheme.surfaceContainer),
            const SizedBox(height: 6),

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
                      '${data.streakCount} días',
                      style: AppTheme.numeric(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurface,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => ref
                      .read(challenge21ControllerProvider.notifier)
                      .toggleToday(),
                  icon: Icon(
                    data.isCompletedToday
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 16,
                    color: data.isCompletedToday ? AppTheme.primary : AppTheme.outline,
                  ),
                  label: Text(
                    data.isCompletedToday ? 'Completado hoy' : 'Marcar hoy',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: data.isCompletedToday ? AppTheme.primary : AppTheme.outline,
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

  /// Empty state widget for a section
  Widget _buildSectionEmptyState(String message, {required HabitCategory category}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.checklist_rounded,
            size: 32,
            color: AppTheme.outline.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppTheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => AddHabitSheet.show(context, initialCategory: category),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: Text(
              'Añadir Hábito',
              style: GoogleFonts.plusJakartaSans(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// Complementary tools row (50 Hábitos, Gratitud, Finanzas, etc.)
  Widget _buildExecutiveToolsRow(BuildContext context, bool isReligious) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // 50 Hábitos de Alto Rendimiento
          _buildToolCard(
            title: '50 Hábitos',
            subtitle: 'Catálogo maestro',
            icon: Icons.auto_stories_outlined,
            color: AppTheme.primary,
            onTap: () => context.push('/habits-catalog'),
          ),
          const SizedBox(width: 10),

          // Gratitud Estoica
          _buildToolCard(
            title: 'Gratitud Estoica',
            subtitle: '3 Agradecimientos',
            icon: Icons.self_improvement_rounded,
            color: Colors.purple,
            onTap: () => context.push('/gratitude'),
          ),
          const SizedBox(width: 10),

          // Finanzas & Presupuesto
          _buildToolCard(
            title: 'Finanzas',
            subtitle: 'Regla 50 / 30 / 20',
            icon: Icons.account_balance_wallet_rounded,
            color: const Color(0xFF10B981),
            onTap: () => context.push('/finance'),
          ),

          if (isReligious) ...[
            const SizedBox(width: 10),
            // Religión & Espiritualidad
            _buildToolCard(
              title: 'Espiritualidad',
              subtitle: 'Pilar & Oración',
              icon: Icons.menu_book_rounded,
              color: const Color(0xFF6366F1),
              onTap: () => context.push('/religion'),
            ),
          ],

          const SizedBox(width: 10),
          // Salud & Bienestar Integral
          _buildToolCard(
            title: 'Salud & Bienestar',
            subtitle: 'Agua, Nutrición & Mente',
            icon: Icons.water_drop_rounded,
            color: const Color(0xFF0284C7),
            onTap: () => context.push('/wellness'),
          ),
        ],
      ),
    );
  }

  Widget _buildToolCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 150,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.outline.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppTheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDigitalWellnessCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outline.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppTheme.secondary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.devices_rounded,
                      color: AppTheme.secondary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bienestar Digital',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
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
          const SizedBox(height: 12),

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
                      style: AppTheme.labelCaps(
                        fontSize: 9,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '1h 42m',
                      style: AppTheme.numeric(
                        fontSize: 17,
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
                      style: AppTheme.labelCaps(
                        fontSize: 9,
                        color: AppTheme.onSurfaceVariant,
                      ),
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
    );
  }
}
