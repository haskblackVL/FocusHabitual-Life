import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme.dart';
import '../../../app/widgets/brand_logo.dart';
import '../domain/affirmation.dart';
import '../domain/nutrition_data.dart';
import '../domain/water_data.dart';
import 'controllers/challenges_controller.dart';
import 'controllers/wellness_controller.dart';
import 'widgets/ambient_sound_player_sheet.dart';
import 'widgets/challenges_tab_view.dart';
import 'widgets/water_tracker_card.dart';
import 'widgets/log_meal_sheet.dart';

class WellnessScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const WellnessScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  ConsumerState<WellnessScreen> createState() => _WellnessScreenState();
}

class _WellnessScreenState extends ConsumerState<WellnessScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 3),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final waterAsync = ref.watch(dailyWaterSummaryProvider);
    final nutritionAsync = ref.watch(dailyNutritionSummaryProvider);
    final allAffirmationsAsync = ref.watch(allAffirmationsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(68),
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
                  const BackButton(),
                  const FocusHabitualLogo(size: 28),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Salud & Bienestar',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      Text(
                        'AGUA · NUTRICIÓN · RETOS 21D',
                        style: AppTheme.labelCaps(
                          color: AppTheme.primary,
                          letterSpacing: 0.08,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Quick Ambient Audio Button
                  Consumer(
                    builder: (context, ref, child) {
                      final playerState = ref.watch(ambientPlayerStateProvider).value ??
                          ref.read(ambientAudioServiceProvider).currentState;
                      final isPlaying = playerState.isPlaying;

                      return IconButton(
                        icon: Icon(
                          isPlaying ? Icons.graphic_eq_rounded : Icons.nature_people_outlined,
                          color: isPlaying ? AppTheme.primary : AppTheme.onSurfaceVariant,
                          size: 22,
                        ),
                        tooltip: 'Sonidos de la Naturaleza',
                        onPressed: () => AmbientSoundPlayerSheet.show(context),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // 1. Executive Telemetry Row
          _buildTelemetryPills(
            water: waterAsync.value,
            nutrition: nutritionAsync.value,
            affirmations: allAffirmationsAsync.value,
          ),

          // 2. Tab Bar
          Container(
            color: AppTheme.surfaceContainerLowest,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.primary,
              indicatorWeight: 3,
              labelColor: AppTheme.primary,
              unselectedLabelColor: AppTheme.onSurfaceVariant,
              labelPadding: const EdgeInsets.symmetric(horizontal: 2),
              labelStyle: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
              unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
              tabs: const [
                Tab(
                  icon: Icon(Icons.water_drop_outlined, size: 19),
                  text: 'Hidratación',
                ),
                Tab(
                  icon: Icon(Icons.restaurant_outlined, size: 19),
                  text: 'Nutrición',
                ),
                Tab(
                  icon: Icon(Icons.auto_awesome_outlined, size: 19),
                  text: 'Afirmaciones',
                ),
                Tab(
                  icon: Icon(Icons.self_improvement_outlined, size: 19),
                  text: 'Retos 21D',
                ),
              ],
            ),
          ),

          // 3. Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildWaterTab(waterAsync),
                _buildNutritionTab(nutritionAsync),
                _buildAffirmationsTab(),
                const ChallengesTabView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryPills({
    DailyWaterSummary? water,
    DailyNutritionSummary? nutrition,
    List<Affirmation>? affirmations,
  }) {
    final waterPercent = water?.progressPercent ?? 0;
    final mealsCount = nutrition?.mealsLoggedCount ?? 0;
    final favCount = affirmations?.where((a) => a.isFavorite).length ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        border: const Border(bottom: BorderSide(color: AppTheme.surfaceContainerHigh)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _telemetryPill(
            icon: Icons.water_drop_rounded,
            color: const Color(0xFF0284C7),
            label: '$waterPercent% Agua',
          ),
          _telemetryPill(
            icon: Icons.restaurant_rounded,
            color: const Color(0xFF10B981),
            label: '$mealsCount Comidas',
          ),
          _telemetryPill(
            icon: Icons.star_rounded,
            color: const Color(0xFFF59E0B),
            label: '$favCount Favoritas',
          ),
        ],
      ),
    );
  }

  Widget _telemetryPill({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTheme.numeric(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: HIDRATACIÓN (AGUA)
  // ---------------------------------------------------------------------------

  Widget _buildWaterTab(AsyncValue<DailyWaterSummary> waterAsync) {
    return waterAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (summary) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const WaterTrackerCard(showHeader: false),
            const SizedBox(height: 20),

            // Today's Logs Timeline
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'REGISTROS DE HOY (${summary.entries.length})',
                  style: AppTheme.labelCaps(
                    color: AppTheme.onSurfaceVariant,
                    letterSpacing: 0.1,
                  ),
                ),
                if (summary.entries.isNotEmpty)
                  Text(
                    '+5 XP cada toma',
                    style: AppTheme.numeric(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            if (summary.entries.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.surfaceContainerHigh),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.water_drop_outlined, size: 40, color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5)),
                      const SizedBox(height: 8),
                      Text(
                        'Aún no has registrado agua hoy',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Toca un botón de arriba para registrar tu primer vaso',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...summary.entries.map((entry) {
                final time = '${entry.loggedAt.hour.toString().padLeft(2, '0')}:${entry.loggedAt.minute.toString().padLeft(2, '0')}';
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.water_drop_rounded, color: Color(0xFF0284C7), size: 18),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '+${entry.amountMl} ml',
                                style: AppTheme.numeric(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.onSurface,
                                ),
                              ),
                              Text(
                                'Registrado a las $time',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: AppTheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18, color: AppTheme.onSurfaceVariant),
                          onPressed: () {
                            ref.read(waterControllerProvider.notifier).deleteWaterLog(entry.id);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }


  // ---------------------------------------------------------------------------
  // TAB 2: NUTRICIÓN & ENERGÍA
  // ---------------------------------------------------------------------------

  Widget _buildNutritionTab(AsyncValue<DailyNutritionSummary> nutritionAsync) {
    return nutritionAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (summary) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Daily Executive Nutrition Tip
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF10B981).withValues(alpha: 0.12),
                    const Color(0xFF059669).withValues(alpha: 0.04),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.bolt_rounded, size: 18, color: Color(0xFF10B981)),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'BIOHACKING & ALIMENTACIÓN CONSCIENTE',
                                style: AppTheme.labelCaps(
                                  color: const Color(0xFF10B981),
                                  letterSpacing: 0.08,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          summary.dailyTip.category.toUpperCase(),
                          style: AppTheme.numeric(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    summary.dailyTip.tipText,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Meal Checkers
            Text(
              'RITMOS NUTRICIONALES DE HOY',
              style: AppTheme.labelCaps(
                color: AppTheme.onSurfaceVariant,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 10),

            _buildMealItem(
              mealType: MealType.breakfast,
              loggedMeal: summary.mealsToday.where((m) => m.mealType == MealType.breakfast).firstOrNull,
            ),
            _buildMealItem(
              mealType: MealType.lunch,
              loggedMeal: summary.mealsToday.where((m) => m.mealType == MealType.lunch).firstOrNull,
            ),
            _buildMealItem(
              mealType: MealType.dinner,
              loggedMeal: summary.mealsToday.where((m) => m.mealType == MealType.dinner).firstOrNull,
            ),
            _buildMealItem(
              mealType: MealType.snack,
              loggedMeal: summary.mealsToday.where((m) => m.mealType == MealType.snack).firstOrNull,
            ),

            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
              label: Text(
                'Registrar Ingesta Libre (+10 XP)',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
              onPressed: () => _openLogMealSheet(MealType.lunch),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMealItem({
    required MealType mealType,
    required NutritionMealLog? loggedMeal,
  }) {
    final isDone = loggedMeal != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: mealType.color.withValues(alpha: isDone ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                mealType.icon,
                color: isDone ? mealType.color : AppTheme.onSurfaceVariant,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mealType.label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isDone
                        ? (loggedMeal.title ?? 'Registrado exitosamente')
                        : 'Pendiente de registrar',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      color: isDone ? const Color(0xFF10B981) : AppTheme.onSurfaceVariant,
                      fontWeight: isDone ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            if (isDone)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_rounded, size: 14, color: Color(0xFF10B981)),
                    const SizedBox(width: 4),
                    Text(
                      'Listo (+10 XP)',
                      style: AppTheme.numeric(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              )
            else
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: mealType.color,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Registrar'),
                onPressed: () => _openLogMealSheet(mealType),
              ),
          ],
        ),
      ),
    );
  }

  void _openLogMealSheet(MealType type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LogMealSheet(
        initialMealType: type,
        onSave: (mealType, title, note) {
          ref.read(nutritionControllerProvider.notifier).logMeal(
                mealType: mealType,
                title: title,
                note: note,
              );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 3: AFIRMACIONES POSITIVAS
  // ---------------------------------------------------------------------------

  Widget _buildAffirmationsTab() {
    final todayAffAsync = ref.watch(todayAffirmationProvider);
    final allAffAsync = ref.watch(allAffirmationsProvider);
    final selectedCategory = ref.watch(affirmationCategoryFilterProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Daily Hero Affirmation
        todayAffAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (todayAff) {
            return Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.12),
                    AppTheme.primary.withValues(alpha: 0.04),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome_rounded, size: 18, color: AppTheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'AFIRMACIÓN DEL DÍA',
                            style: AppTheme.labelCaps(
                              color: AppTheme.primary,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(
                          todayAff.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                          color: todayAff.isFavorite ? const Color(0xFFF59E0B) : AppTheme.onSurfaceVariant,
                          size: 24,
                        ),
                        onPressed: () {
                          ref.read(affirmationControllerProvider.notifier).toggleFavorite(todayAff.id);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '«${todayAff.text}»',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      height: 1.45,
                      fontStyle: FontStyle.italic,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        todayAff.author ?? 'Principio Rector',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        icon: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                        label: Text(
                          'Decretar (+5 XP)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        onPressed: () {
                          ref.read(affirmationControllerProvider.notifier).logRead(todayAff.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppTheme.surfaceContainerLowest,
                              behavior: SnackBarBehavior.floating,
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                                  const SizedBox(width: 10),
                                  Text(
                                    '¡Afirmación integrada con éxito! +5 XP',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 22),

        // Category Filter Chips
        Text(
          'BIBLIOTECA POR CATEGORÍAS',
          style: AppTheme.labelCaps(
            color: AppTheme.onSurfaceVariant,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  selected: selectedCategory == null,
                  label: const Text('Todas'),
                  onSelected: (val) {
                    ref.read(affirmationCategoryFilterProvider.notifier).selectCategory(null);
                  },
                ),
              ),
              ...AffirmationCategory.values.map((cat) {
                final isSelected = selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    avatar: Icon(cat.icon, size: 14, color: isSelected ? Colors.white : cat.color),
                    label: Text(cat.label),
                    selectedColor: cat.color,
                    labelStyle: GoogleFonts.plusJakartaSans(
                      color: isSelected ? Colors.white : AppTheme.onSurface,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    onSelected: (val) {
                      ref.read(affirmationCategoryFilterProvider.notifier).selectCategory(val ? cat : null);
                    },
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Affirmations List
        allAffAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (affirmations) {
            return Column(
              children: affirmations.map((aff) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: aff.category.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(aff.category.icon, size: 12, color: aff.category.color),
                                  const SizedBox(width: 4),
                                  Text(
                                    aff.category.label,
                                    style: AppTheme.numeric(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: aff.category.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                aff.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                                color: aff.isFavorite ? const Color(0xFFF59E0B) : AppTheme.onSurfaceVariant,
                                size: 20,
                              ),
                              onPressed: () {
                                ref.read(affirmationControllerProvider.notifier).toggleFavorite(aff.id);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '«${aff.text}»',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                            color: AppTheme.onSurface,
                          ),
                        ),
                        if (aff.author != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            aff.author!,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
