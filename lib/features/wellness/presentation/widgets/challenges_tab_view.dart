import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme.dart';
import '../../domain/challenge_data.dart';
import '../controllers/challenges_controller.dart';
import 'ambient_sound_player_sheet.dart';
import 'challenge_day_detail_sheet.dart';
import 'yoga_and_facial_catalog_sheet.dart';

/// Full interactive tab view for 21-Day Wellness Challenges (Meditation, Yoga, Facial Yoga).
class ChallengesTabView extends ConsumerWidget {
  const ChallengesTabView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeType = ref.watch(activeChallengeTypeProvider);
    final summaryAsync = ref.watch(challengeSummaryProvider(activeType));
    final playerStateAsync = ref.watch(ambientPlayerStateProvider);
    final playerState = playerStateAsync.value ?? ref.read(ambientAudioServiceProvider).currentState;
    final controller = ref.read(challengesControllerProvider.notifier);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(challengeSummaryProvider(activeType));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Challenge Selector Pills
            _buildTypeSelector(context, ref, activeType),
            const SizedBox(height: 16),

            // 2. Summary & Content
            summaryAsync.when(
              data: (summary) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // A. Progress Hero Card
                    _buildProgressCard(context, summary, activeType),
                    const SizedBox(height: 16),

                    // B. Quick Ambient Sound Bar (Meditation or anytime)
                    _buildAmbientSoundBar(context, playerState, controller),
                    const SizedBox(height: 16),

                    // C. Master Catalog Explorer (150 Yoga Asanas & 50 Face Yoga Exercises)
                    _buildCatalogLibraryBanner(context, activeType),
                    const SizedBox(height: 16),

                    // D. Today's Exercise Card
                    if (summary.currentExercise != null)
                      _buildCurrentExerciseCard(context, summary, controller),
                    const SizedBox(height: 20),

                    // D. 21-Day Interactive Matrix
                    _build21DayMatrix(context, summary),
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Center(
                child: Text('Error al cargar reto: $err', style: const TextStyle(color: AppTheme.error)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector(BuildContext context, WidgetRef ref, ChallengeType activeType) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceContainerHigh),
      ),
      child: Row(
        children: ChallengeType.values.map((type) {
          final isSelected = type == activeType;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                ref.read(activeChallengeTypeProvider.notifier).setType(type);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      type == ChallengeType.meditation
                          ? Icons.self_improvement_rounded
                          : (type == ChallengeType.yoga
                              ? Icons.fitness_center_rounded
                              : Icons.face_retouching_natural_rounded),
                      size: 16,
                      color: isSelected ? Colors.black : AppTheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      type == ChallengeType.meditation
                          ? 'Meditación'
                          : (type == ChallengeType.yoga ? 'Yoga' : 'Facial'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? Colors.black : AppTheme.onSurfaceVariant,
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

  Widget _buildProgressCard(BuildContext context, ChallengeSummary summary, ChallengeType type) {
    final percent = (summary.progressPercent * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.surfaceContainerHigh),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  type == ChallengeType.meditation
                      ? Icons.self_improvement_rounded
                      : (type == ChallengeType.yoga
                          ? Icons.fitness_center_rounded
                          : Icons.face_retouching_natural_rounded),
                  color: AppTheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    Text(
                      type.description,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${summary.completedCount} / 21 DÍAS',
                  style: AppTheme.numeric(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Linear Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: summary.progressPercent,
              minHeight: 8,
              backgroundColor: AppTheme.surfaceContainerHigh,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
          ),
          const SizedBox(height: 10),

          // Subtext
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                '$percent% consolidado',
                style: GoogleFonts.inter(fontSize: 12, color: AppTheme.onSurfaceVariant),
              ),
              Text(
                '+15 XP/día · +50 XP meta',
                style: AppTheme.numeric(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmbientSoundBar(
    BuildContext context,
    dynamic playerState,
    ChallengesController controller,
  ) {
    final isPlaying = playerState.isPlaying;
    final currentSoundName = playerState.currentSound?.name ?? 'Sonidos de la Naturaleza';

    return InkWell(
      onTap: () => AmbientSoundPlayerSheet.show(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPlaying ? AppTheme.primary.withValues(alpha: 0.5) : AppTheme.surfaceContainerHigh,
            width: isPlaying ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isPlaying ? AppTheme.primary : AppTheme.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPlaying ? Icons.graphic_eq_rounded : Icons.nature_rounded,
              color: isPlaying ? Colors.black : AppTheme.onSurfaceVariant,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentSoundName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  isPlaying ? 'Reproduciendo en bucle' : '7 paisajes sonoros disponibles',
                  style: GoogleFonts.inter(fontSize: 11, color: AppTheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (playerState.currentSound != null)
            IconButton(
              icon: Icon(
                isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                color: AppTheme.primary,
                size: 26,
              ),
              onPressed: () => controller.togglePlayPause(),
            ),
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: AppTheme.onSurfaceVariant, size: 20),
            tooltip: 'Selector de sonidos',
            onPressed: () => AmbientSoundPlayerSheet.show(context),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildCatalogLibraryBanner(BuildContext context, ChallengeType activeType) {
    final title = activeType == ChallengeType.yoga
        ? 'Biblioteca de Yoga · 150 Asanas'
        : (activeType == ChallengeType.yogaFacial
            ? 'Biblioteca Facial · 50 Ejercicios'
            : 'Biblioteca Completa (200 Ejercicios)');
    final subtitle = activeType == ChallengeType.yoga
        ? 'Fuerza, Flexibilidad y Relajación con 10s prep previa'
        : (activeType == ChallengeType.yogaFacial
            ? 'Frente, Ojos, Pómulos, Labios y Cuello con 10s prep'
            : '150 Asanas de Yoga y 50 Ejercicios de Yoga Facial');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => YogaAndFacialCatalogSheet.show(
          context,
          initialType: activeType == ChallengeType.yogaFacial
              ? ChallengeType.yogaFacial
              : ChallengeType.yoga,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFB300).withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB300).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_stories_rounded, color: Color(0xFFFFB300), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFFFB300)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentExerciseCard(
    BuildContext context,
    ChallengeSummary summary,
    ChallengesController controller,
  ) {
    final exercise = summary.currentExercise!;
    final isDone = summary.isDayCompleted(exercise.dayNumber);
    final steps = exercise.effectiveSteps;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.surfaceContainerHigh),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'PRÁCTICA RECOMENDADA · DÍA ${exercise.dayNumber}',
                  style: AppTheme.labelCaps(color: AppTheme.primary, letterSpacing: 0.08),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 14, color: AppTheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    '${exercise.durationMinutes} min',
                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
          if (steps.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.layers_rounded, size: 14, color: AppTheme.primary),
                const SizedBox(width: 5),
                Text(
                  '${steps.length} ejercicios en sesión',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.hourglass_top_rounded, size: 13, color: Color(0xFFFFB300)),
                const SizedBox(width: 4),
                Text(
                  '10s preparación c/u',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFFB300),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),

          Text(
            exercise.title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),

          if (exercise.tip != null)
            Text(
              exercise.tip!,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.onSurfaceVariant,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ChallengeDayDetailSheet.show(
                      context,
                      exercise: exercise,
                      challengeId: summary.challenge.id,
                      isCompleted: isDone,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.surfaceContainerHigh),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: Text(
                    'Ver Guía & Timer',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: isDone
                      ? null
                      : () async {
                          await controller.completeDay(
                            type: exercise.challengeType,
                            challengeId: summary.challenge.id,
                            dayNumber: exercise.dayNumber,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppTheme.surfaceContainerHigh,
                                behavior: SnackBarBehavior.floating,
                                content: Row(
                                  children: [
                                    const Icon(Icons.check_circle, color: AppTheme.success, size: 20),
                                    const SizedBox(width: 10),
                                    Text(
                                      '¡Día ${exercise.dayNumber} completado! +15 XP',
                                      style: GoogleFonts.inter(
                                        color: AppTheme.onSurface,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: isDone ? AppTheme.surfaceContainerHigh : AppTheme.primary,
                    foregroundColor: isDone ? AppTheme.onSurfaceVariant : Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: Icon(
                    isDone ? Icons.check_circle_rounded : Icons.check_rounded,
                    size: 18,
                  ),
                  label: Text(
                    isDone ? '✓ Hecho' : '+15 XP',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _build21DayMatrix(BuildContext context, ChallengeSummary summary) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.surfaceContainerHigh),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LÍNEA TEMPORAL DE LOS 21 DÍAS',
                style: AppTheme.labelCaps(
                  color: AppTheme.onSurfaceVariant,
                  letterSpacing: 0.08,
                ),
              ),
              Text(
                'Toca cualquier día',
                style: GoogleFonts.inter(fontSize: 11, color: AppTheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Grid of 21 days (7 columns x 3 rows)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 21,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (context, index) {
              final dayNum = index + 1;
              final isCompleted = summary.isDayCompleted(dayNum);
              final isCurrentTarget = dayNum == summary.nextPendingDay && !summary.isCompleted;

              // Find matching exercise
              final exercise = summary.allExercises.firstWhere(
                (ex) => ex.dayNumber == dayNum,
                orElse: () => WellnessExercise(
                  id: 'ex-$dayNum',
                  challengeType: summary.challenge.challengeType,
                  dayNumber: dayNum,
                  title: 'Día $dayNum',
                  instructions: 'Práctica del día $dayNum.',
                ),
              );

              Color bgColor;
              Color textColor;
              Border? border;

              if (isCompleted) {
                bgColor = AppTheme.success.withValues(alpha: 0.15);
                textColor = AppTheme.success;
                border = Border.all(color: AppTheme.success.withValues(alpha: 0.5), width: 1);
              } else if (isCurrentTarget) {
                bgColor = AppTheme.primary.withValues(alpha: 0.18);
                textColor = AppTheme.primary;
                border = Border.all(color: AppTheme.primary, width: 2);
              } else {
                bgColor = AppTheme.surface;
                textColor = AppTheme.onSurfaceVariant;
                border = Border.all(color: AppTheme.surfaceContainerHigh, width: 1);
              }

              return Material(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    ChallengeDayDetailSheet.show(
                      context,
                      exercise: exercise,
                      challengeId: summary.challenge.id,
                      isCompleted: isCompleted,
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: border,
                    ),
                    alignment: Alignment.center,
                    child: isCompleted
                        ? const Icon(Icons.check_rounded, color: AppTheme.success, size: 16)
                        : Text(
                            '$dayNum',
                            style: AppTheme.numeric(
                              fontSize: 12,
                              fontWeight: isCurrentTarget ? FontWeight.w800 : FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
