import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme.dart';
import '../../domain/challenge_data.dart';
import '../controllers/challenges_controller.dart';
import 'ambient_sound_player_sheet.dart';
import 'exercise_timer_widget.dart';
import 'wellness_visual_guide.dart';

/// Modal bottom sheet showing full guided instructions, multi-exercise session breakdown,
/// guided timer with 10s preparation between exercises, and day completion.
class ChallengeDayDetailSheet extends ConsumerStatefulWidget {
  final WellnessExercise exercise;
  final String challengeId;
  final bool isCompleted;

  const ChallengeDayDetailSheet({
    super.key,
    required this.exercise,
    required this.challengeId,
    required this.isCompleted,
  });

  static Future<void> show(
    BuildContext context, {
    required WellnessExercise exercise,
    required String challengeId,
    required bool isCompleted,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChallengeDayDetailSheet(
        exercise: exercise,
        challengeId: challengeId,
        isCompleted: isCompleted,
      ),
    );
  }

  @override
  ConsumerState<ChallengeDayDetailSheet> createState() => _ChallengeDayDetailSheetState();
}

class _ChallengeDayDetailSheetState extends ConsumerState<ChallengeDayDetailSheet> {
  int _currentStepIndex = 0;

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(challengesControllerProvider.notifier);
    final exercise = widget.exercise;
    final steps = exercise.effectiveSteps;
    final activeStep = steps.isNotEmpty
        ? steps[_currentStepIndex.clamp(0, steps.length - 1)]
        : null;

    final sessionTypeLabel = exercise.challengeType == ChallengeType.yoga
        ? 'Sesión de Yoga (${steps.length} Asanas)'
        : (exercise.challengeType == ChallengeType.yogaFacial
            ? 'Rutina Facial (${steps.length} Ejercicios)'
            : 'Meditación Consciente');

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppTheme.surfaceContainerHigh, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Handle bar
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge row
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
                            'DÍA ${exercise.dayNumber} DE 21',
                            style: AppTheme.labelCaps(
                              color: AppTheme.primary,
                              letterSpacing: 0.08,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.timer_outlined, size: 13, color: AppTheme.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Text(
                                '${exercise.durationMinutes} min',
                                style: GoogleFonts.inter(fontSize: 11, color: AppTheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        if (widget.isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, size: 14, color: AppTheme.success),
                                const SizedBox(width: 4),
                                Text(
                                  'COMPLETADO',
                                  style: AppTheme.labelCaps(color: AppTheme.success, letterSpacing: 0.06),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Exercise Title & Session Type
                    Text(
                      exercise.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.onSurface,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Preparation Notice Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB300).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFFB300).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.hourglass_top_rounded, color: Color(0xFFFFB300), size: 14),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '$sessionTypeLabel · 10s prep previa',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFFFB300),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Scientific / Anatomical Tip Card
                    if (exercise.tip != null && exercise.tip!.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.surfaceContainerHigh),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.psychology_outlined, color: AppTheme.primary, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                exercise.tip!,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppTheme.onSurface,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Visual Guide / Schematic / Illustration for Meditation, Yoga & Yoga Facial
                    WellnessVisualGuideWidget(
                      title: activeStep?.title ?? exercise.title,
                      category: activeStep?.category ??
                          (exercise.challengeType == ChallengeType.yoga
                              ? 'Yoga'
                              : (exercise.challengeType == ChallengeType.yogaFacial
                                  ? 'Facial'
                                  : 'Meditación')),
                      challengeType: exercise.challengeType,
                    ),
                    const SizedBox(height: 18),

                    // Multi-Step Interactive Timer with 10s preparation
                    ExerciseTimerWidget(
                      initialMinutes: exercise.durationMinutes,
                      steps: steps,
                      initialStepIndex: _currentStepIndex,
                      onStepChanged: (newIdx) {
                        setState(() => _currentStepIndex = newIdx);
                      },
                    ),
                    const SizedBox(height: 18),

                    // Ambient Sounds Shortcut
                    Material(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => AmbientSoundPlayerSheet.show(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.surfaceContainerHigh),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.nature_people_rounded, color: AppTheme.primary, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Sonidos Naturales de Acompañamiento',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.onSurface,
                                      ),
                                    ),
                                    Text(
                                      'Bosque, río silvestre, olas, lluvia suave o viento',
                                      style: GoogleFonts.inter(fontSize: 11, color: AppTheme.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, color: AppTheme.onSurfaceVariant),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Session Breakdown Header & List
                    if (steps.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'DESGLOSE DE LA SESIÓN (${steps.length} EJERCICIOS)',
                            style: AppTheme.labelCaps(
                              color: AppTheme.onSurfaceVariant,
                              letterSpacing: 0.08,
                            ),
                          ),
                          Text(
                            '10s preparación',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFFFFB300),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Sequential Exercise Cards in Session
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: steps.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final stepItem = steps[index];
                          final isSelected = index == _currentStepIndex;

                          return GestureDetector(
                            onTap: () {
                              setState(() => _currentStepIndex = index);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primary.withValues(alpha: 0.08)
                                    : AppTheme.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.primary
                                      : AppTheme.surfaceContainerHigh,
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Step Index Circle
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppTheme.primary
                                          : AppTheme.surfaceContainerHigh,
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${index + 1}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: isSelected ? Colors.black : AppTheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Exercise Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                stepItem.title,
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 13,
                                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                                  color: AppTheme.onSurface,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (stepItem.category.isNotEmpty) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.surfaceContainerHigh,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  stepItem.category,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppTheme.onSurfaceVariant,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          '⏱ ${stepItem.durationSeconds}s activo · 10s prep previa',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: AppTheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  if (isSelected)
                                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.primary),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Step-by-Step Instructions for active step or session
                    Text(
                      activeStep != null
                          ? 'INSTRUCCIONES · ${activeStep.title.toUpperCase()}'
                          : 'INSTRUCCIONES PASO A PASO',
                      style: AppTheme.labelCaps(
                        color: AppTheme.onSurfaceVariant,
                        letterSpacing: 0.08,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.surfaceContainerHigh),
                      ),
                      child: Text(
                        activeStep?.instructions ?? exercise.instructions,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTheme.onSurface,
                          height: 1.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Complete Button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: widget.isCompleted
                            ? null
                            : () async {
                                await controller.completeDay(
                                  type: exercise.challengeType,
                                  challengeId: widget.challengeId,
                                  dayNumber: exercise.dayNumber,
                                );
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: AppTheme.surfaceContainerHigh,
                                      behavior: SnackBarBehavior.floating,
                                      content: Row(
                                        children: [
                                          const Icon(Icons.check_circle, color: AppTheme.success, size: 20),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              '¡Día ${exercise.dayNumber} completado! +15 XP otorgados.',
                                              style: GoogleFonts.inter(
                                                color: AppTheme.onSurface,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: widget.isCompleted ? AppTheme.surfaceContainerHigh : AppTheme.primary,
                          foregroundColor: widget.isCompleted ? AppTheme.onSurfaceVariant : Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: Icon(
                          widget.isCompleted ? Icons.check_circle_rounded : Icons.star_rounded,
                          size: 20,
                        ),
                        label: Text(
                          widget.isCompleted
                              ? '✓ Día Completado'
                              : (exercise.dayNumber == 21
                                  ? 'Completar Reto Día 21 (+65 XP)'
                                  : 'Completar Día ${exercise.dayNumber} (+15 XP)'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
