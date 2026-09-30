import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/brand_logo.dart';
import '../../../core/gamification/gamification_controller.dart';
import '../../../core/gamification/presentation/my_progress_sheet.dart';
import '../../../core/local_db/sync_engine.dart';
import '../../auth/domain/user_profile.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../../habits/domain/challenge_21_data.dart';
import '../../habits/domain/habit.dart';
import '../../habits/presentation/controllers/habits_controller.dart';
import '../../nofap/presentation/controllers/nofap_controller.dart';
import '../../nofap/presentation/widgets/cooling_protocol_sheet.dart';
import '../../pomodoro/presentation/controllers/pomodoro_controller.dart';
import '../../cycle/presentation/controllers/cycle_controller.dart';
import '../../finance/presentation/controllers/finance_controller.dart';
import '../../gratitude/domain/gratitude_model.dart';
import '../../gratitude/presentation/controllers/gratitude_controller.dart';
import '../../wellness/presentation/widgets/water_tracker_card.dart';
import '../../../core/security/discreet_mode.dart';
import '../../../core/security/security_controller.dart';

/// Executive Precision Launcher Screen.
/// Faithfully designed according to Documentos adicionales (hombre_disciplina_foco & herramientas_h_bitos).
class LauncherScreen extends ConsumerWidget {
  const LauncherScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamification = ref.watch(gamificationProvider);
    final syncStatus = ref.watch(syncStatusProvider);
    final habitsAsync = ref.watch(habitsControllerProvider);
    final pomodoro = ref.watch(pomodoroProvider);
    final profile = ref.watch(userProfileControllerProvider).value;
    final user = ref.watch(authControllerProvider).value;
    final security = ref.watch(securityControllerProvider);

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
                        security.discreetModeEnabled ? security.discreetAppAlias : 'FocusHabitual',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      Text(
                        security.discreetModeEnabled ? 'MODO DISCRETO ACTIVO' : 'FocusHabitual Life',
                        style: AppTheme.labelCaps(
                          fontSize: 10,
                          color: security.discreetModeEnabled
                              ? AppTheme.primaryContainer
                              : AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),

                  // Sync Status Cloud Indicator
                  IconButton(
                    onPressed: () {
                      ref.read(syncEngineProvider).syncNow();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Estado de sincronización: ${syncStatus.label}'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    tooltip: syncStatus.label,
                    icon: syncStatus == SyncStatus.syncing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            syncStatus == SyncStatus.offline
                                ? Icons.cloud_off_rounded
                                : (syncStatus == SyncStatus.error
                                    ? Icons.sync_problem_rounded
                                    : Icons.cloud_done_rounded),
                            size: 20,
                            color: syncStatus == SyncStatus.synced
                                ? AppTheme.accentEmerald
                                : AppTheme.onSurfaceVariant,
                          ),
                  ),

                  // Notification Bell
                  IconButton(
                    onPressed: () => context.push('/settings'),
                    icon: const Icon(Icons.notifications_none_rounded),
                    color: AppTheme.onSurfaceVariant,
                    iconSize: 22,
                  ),

                  // Avatar
                  GestureDetector(
                    onTap: () => context.push('/settings'),
                    child: Container(
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
              _buildExecutiveGreetingHeader(context, profile, user, gamification),
              const SizedBox(height: 16),

              // 1b. Mi Progreso & Medallas (Gamificación Unificada)
              _buildMyProgressCard(context, gamification),
              const SizedBox(height: 16),

              // 2. Biblical Wisdom & Principle Rector Card (Conditional on spiritual module)
              if (profile?.isReligious ?? false) ...[
                _buildBiblicalPrincipleCard(context),
                const SizedBox(height: 16),
              ],

              // 3. Reto 21 Días de Constancia (Card Destacada)
              _build21DaysChallengeCard(context, ref),
              const SizedBox(height: 16),

              // 4. Dominio Personal & Vitalidad (NoFap / Autodominio para hombres)
              if (profile?.gender != 'female') ...[
                _buildSelfMasteryCounterCard(context, ref),
                const SizedBox(height: 16),
              ],

              // 4b. Ciclo Biológico & Neuroquímica (Para mujeres)
              if (profile?.gender == 'female') ...[
                _buildFemaleCycleCard(context, ref),
                const SizedBox(height: 16),
              ],

              // 5. Today's Priority Habits (Checklist Atómico)
              _buildTodayHabitsCard(context, ref, habits, completedToday, totalHabits),
              const SizedBox(height: 16),

              // 6. Deep Work Pomodoro Quick Launch Card
              _buildPomodoroQuickCard(context, pomodoro),
              const SizedBox(height: 16),

              // 7. Reflexión Estoica & Diario de Gratitud
              _buildGratitudeStoicCard(context, ref),
              const SizedBox(height: 16),

              // 7b. Biblioteca de Sabios (100 Sabios y Pensadores)
              _buildThinkersLibraryCard(context),
              const SizedBox(height: 16),

              // 8. Dominio Financiero & Presupuesto
              _buildFinanceQuickCard(context, ref),
              const SizedBox(height: 16),

              // 9. Salud & Bienestar Integral (Hidratación, Nutrición, Mente)
              _buildWellnessQuickCard(context, ref),
              const SizedBox(height: 16),

              // 10. Catálogo Maestro de 50 Hábitos
              _buildMasterCatalogCard(context),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildExecutiveGreetingHeader(
    BuildContext context,
    UserProfile? profile,
    AuthUser? user,
    GamificationState gamification,
  ) {
    final now = DateTime.now();
    const dayNames = ['LUNES', 'MARTES', 'MIÉRCOLES', 'JUEVES', 'VIERNES', 'SÁBADO', 'DOMINGO'];
    const monthNames = [
      'ENERO', 'FEBRERO', 'MARZO', 'ABRIL', 'MAYO', 'JUNIO',
      'JULIO', 'AGOSTO', 'SEPTIEMBRE', 'OCTUBRE', 'NOVIEMBRE', 'DICIEMBRE'
    ];
    final dateStr = '${dayNames[now.weekday - 1]}, ${now.day} DE ${monthNames[now.month - 1]}';

    final hour = now.hour;
    final timeGreeting = hour < 12
        ? 'Buenos días'
        : hour < 19
            ? 'Buenas tardes'
            : 'Buenas noches';

    final rawName = (profile?.fullName != null && profile!.fullName!.trim().isNotEmpty)
        ? profile.fullName!.trim()
        : (user?.userMetadata?['full_name'] as String? ?? '').trim();

    final displayName = rawName.isNotEmpty ? rawName.split(' ').first : 'Focus';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              dateStr,
              style: AppTheme.labelCaps(
                fontSize: 11,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            InkWell(
              onTap: () => MyProgressSheet.show(context),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.surfaceContainerHighest),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF59E0B),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Nvl ${gamification.level} · ${gamification.totalXp} XP',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '$timeGreeting, $displayName',
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

  Widget _buildMyProgressCard(BuildContext context, GamificationState gamification) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.surfaceContainerHigh),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => MyProgressSheet.show(context),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.military_tech_rounded, size: 20, color: Color(0xFFD97706)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MI PROGRESO & MEDALLAS',
                            style: AppTheme.labelCaps(
                              color: AppTheme.onSurfaceVariant,
                              letterSpacing: 0.08,
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            'Nvl ${gamification.level} · ${gamification.levelTitle}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryContainer.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bolt_rounded, size: 14, color: AppTheme.primaryContainer),
                          const SizedBox(width: 3),
                          Text(
                            '${gamification.totalXp} XP',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // XP Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: gamification.levelProgress,
                    minHeight: 6,
                    backgroundColor: AppTheme.surfaceContainerHigh,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progreso de nivel',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.outline),
                    ),
                    Text(
                      '${(gamification.levelProgress * 100).toInt()}% · Faltan ${gamification.xpRemainingToNextLevel} XP para Nvl ${gamification.level + 1}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Last 3 Medals Preview
                Row(
                  children: [
                    Text(
                      'ÚLTIMAS MEDALLAS:',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: AppTheme.outline,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${gamification.totalUnlockedCount} de ${gamification.totalAvailableCount} desbloqueadas',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (gamification.recentAchievements.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.stars_outlined, size: 18, color: AppTheme.outline),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Completa tus primeros hábitos, sesiones o retos para desbloquear medallas.',
                            style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppTheme.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Row(
                    children: gamification.recentAchievements.map((unlocked) {
                      final def = unlocked.definition;
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: def.tier.color.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(colors: def.tier.gradientColors),
                                ),
                                child: Center(
                                  child: Icon(def.icon, size: 14, color: Colors.black),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  def.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Ver vitrina de logros y medallas',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded, size: 14, color: AppTheme.primary),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBiblicalPrincipleCard(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => context.push('/religion'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.menu_book_rounded,
                          size: 18,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'PRINCIPIO RECTOR • PROVERBIOS 16:3',
                            style: AppTheme.labelCaps(
                              fontSize: 11,
                              color: AppTheme.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
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
                  Expanded(
                    child: Text(
                      'Pilar cognitivo para ejecución limpia',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppTheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => context.push('/religion'),
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
      ),
    );
  }

  Widget _build21DaysChallengeCard(BuildContext context, WidgetRef ref) {
    final challengeAsync = ref.watch(challenge21ControllerProvider);

    return challengeAsync.when(
      data: (challenge) {
        if (challenge == null) {
          return const SizedBox.shrink();
        }

        final habit = challenge.habit;
        final currentDay = challenge.currentDayNumber;
        final isCompletedToday = challenge.isCompletedToday;
        final percent = challenge.progressPercent;
        final progressVal = challenge.progress;
        final streak = challenge.streakCount;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
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
                          Expanded(
                            child: Column(
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
                                  habit.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
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
                        '$percent%',
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
                      'Progreso acumulado',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      'Día $currentDay de 21 (${challenge.totalDaysCompleted} completados)',
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
                  child: LinearProgressIndicator(
                    value: progressVal,
                    minHeight: 7,
                    backgroundColor: AppTheme.surfaceContainerHigh,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                  ),
                ),
                const SizedBox(height: 16),

                // Mini Nodos Interactivos de la Semana (L M X J V S D)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: challenge.weekNodes.map((node) {
                    return _buildInteractiveWeekNode(node, () {
                      if (node.isToday) {
                        ref.read(challenge21ControllerProvider.notifier).toggleToday();
                      }
                    });
                  }).toList(),
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
                          '$streak días',
                          style: AppTheme.numeric(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () {
                        ref.read(challenge21ControllerProvider.notifier).toggleToday();
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isCompletedToday
                              ? AppTheme.accentEmerald.withValues(alpha: 0.12)
                              : AppTheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isCompletedToday
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              size: 15,
                              color: isCompletedToday ? AppTheme.accentEmerald : Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isCompletedToday ? 'Completado hoy' : 'Completar hoy (+10 XP)',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: isCompletedToday ? AppTheme.accentEmerald : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildInteractiveWeekNode(ChallengeDayNode node, VoidCallback onTodayTap) {
    final isDone = node.isDone;
    final isToday = node.isToday;

    return GestureDetector(
      onTap: isToday ? onTodayTap : null,
      child: Column(
        children: [
          Text(
            node.dayLabel,
            style: AppTheme.labelCaps(
              fontSize: 10,
              color: isToday ? AppTheme.primary : AppTheme.outline,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isDone
                  ? AppTheme.primary
                  : (isToday
                      ? AppTheme.primary.withValues(alpha: 0.08)
                      : AppTheme.surfaceContainerLow),
              borderRadius: BorderRadius.circular(8),
              border: isToday && !isDone
                  ? Border.all(color: AppTheme.primary, width: 1.5)
                  : null,
            ),
            alignment: Alignment.center,
            child: isDone
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text(
                    node.challengeDayNumber != null ? '${node.challengeDayNumber}' : '',
                    style: AppTheme.numeric(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isToday ? AppTheme.primary : AppTheme.outline,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelfMasteryCounterCard(BuildContext context, WidgetRef ref) {
    final nofap = ref.watch(nofapControllerProvider);

    return DiscreetMaskWidget(
      title: 'NoFap & Autocontrol',
      subtitle: 'Toca para revelar el contador de días limpios',
      child: Card(
        child: InkWell(
          onTap: () => context.push('/nofap'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.verified_user_rounded,
                    size: 20,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Dominio Personal & Vitalidad',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.school_outlined, size: 19, color: AppTheme.primary),
                    tooltip: 'Centro Educativo & Mitos',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => context.push('/nofap-education'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 18, color: AppTheme.outline),
                    tooltip: 'Reiniciar contador / Registrar recaída',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _showRelapseConfirmation(context, ref),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: AppTheme.outline),
                ],
              ),
            const SizedBox(height: 16),

            // 4 Live Real-Time Counter Blocks
            Row(
              children: [
                Expanded(child: _buildCounterBlock(nofap.daysDisplay, 'DÍAS', isHighlight: false)),
                const SizedBox(width: 8),
                Expanded(child: _buildCounterBlock(nofap.hoursDisplay, 'HORAS', isHighlight: false)),
                const SizedBox(width: 8),
                Expanded(child: _buildCounterBlock(nofap.minutesDisplay, 'MIN', isHighlight: false)),
                const SizedBox(width: 8),
                Expanded(child: _buildCounterBlock(nofap.secondsDisplay, 'SEG', isHighlight: true)),
              ],
            ),
            const SizedBox(height: 16),

            // Milestone bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Meta de 90 Días',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurface,
                  ),
                ),
                Text(
                  '${nofap.days} de 90 días (${nofap.percent90Days}%)',
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
              child: LinearProgressIndicator(
                value: nofap.progress90Days,
                minHeight: 8,
                backgroundColor: AppTheme.surfaceContainerHigh,
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('0 días', style: AppTheme.numeric(fontSize: 11, color: AppTheme.outline)),
                Text('45 días', style: AppTheme.numeric(fontSize: 11, color: AppTheme.outline)),
                Text('90 días', style: AppTheme.numeric(fontSize: 11, color: AppTheme.outline)),
              ],
            ),
            const SizedBox(height: 14),

            // SOS Cooling Button & Educational Hub Button
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => CoolingProtocolSheet.show(context),
                    icon: const Icon(Icons.air_rounded, color: AppTheme.primary, size: 18),
                    label: const Text('Protocolo SOS (3 min)'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppTheme.surfaceContainerHigh,
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => context.push('/nofap-education'),
                  icon: const Icon(Icons.menu_book_rounded, color: AppTheme.onSurface, size: 16),
                  label: const Text('Guía'),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppTheme.surfaceContainerHigh,
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                    textStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  ),
);
}

  Widget _buildFemaleCycleCard(BuildContext context, WidgetRef ref) {
    final cycleAsync = ref.watch(cycleControllerProvider);
    final cycleInfo = cycleAsync.value;

    final phaseLabel = cycleInfo?.phase.displayName.toUpperCase() ?? 'FASE FOLICULAR';
    final dayNum = cycleInfo?.currentCycleDay ?? 1;
    final cycleLen = cycleInfo?.cycleLength ?? 28;
    final cognitiveTip = cycleInfo?.phase.productivityAdvice ??
        'Ventana de máxima claridad hormonal: Momento idóneo para diseño de proyectos y aprendizaje.';
    final energyLevel = cycleInfo?.phase.energyLevel ?? 'Alta Creatividad';

    return DiscreetMaskWidget(
      title: 'Salud & Ciclos Femeninos',
      subtitle: 'Toca para revelar fase y predicción fértil',
      child: Card(
        child: InkWell(
          onTap: () => context.push('/cycle'),
        borderRadius: BorderRadius.circular(16),
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
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppTheme.secondary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.water_drop_rounded,
                          color: AppTheme.secondary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'CICLO BIOLÓGICO & NEUROQUÍMICA',
                        style: AppTheme.labelCaps(
                          fontSize: 10.5,
                          color: AppTheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.secondary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      phaseLabel,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.secondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$dayNum',
                    style: AppTheme.numeric(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'DÍA DE $cycleLen',
                    style: AppTheme.labelCaps(
                      fontSize: 12,
                      color: AppTheme.outline,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bolt_rounded, size: 14, color: AppTheme.secondary),
                        const SizedBox(width: 4),
                        Text(
                          energyLevel,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                cognitiveTip,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppTheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pulsa para ver predicción y registrar síntomas',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.secondary,
                    ),
                  ),
                  const Icon(Icons.arrow_forward_rounded, size: 14, color: AppTheme.secondary),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  void _showRelapseConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          '¿Reiniciar contador?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Reconocer una recaída con total honestidad es el primer paso para reconstruir el dominio propio.\n\nEl contador se reiniciará a 0.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(nofapControllerProvider.notifier).recordRelapse();
            },
            child: const Text('Reiniciar a 0'),
          ),
        ],
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

  Widget _buildGratitudeStoicCard(BuildContext context, WidgetRef ref) {
    final todayGratitudeAsync = ref.watch(todayGratitudeProvider);
    final streakAsync = ref.watch(gratitudeStreakProvider);
    final todayEntry = todayGratitudeAsync.value;
    final streak = streakAsync.value ?? 0;
    final stoicQuote = StoicQuote.forDate(DateTime.now());

    return Card(
      child: InkWell(
        onTap: () => context.push('/gratitude'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.self_improvement_rounded,
                            color: Colors.purple,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PRÁCTICA ESTOICA DIARIA',
                                style: AppTheme.labelCaps(
                                  fontSize: 10,
                                  color: AppTheme.onSurfaceVariant,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Diario de Gratitud',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.onSurface,
                                ),
                              ),
                            ],
                          ),
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
                      'RACHA: $streak DÍAS',
                      style: AppTheme.numeric(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.purple,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (todayEntry != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Colors.purple, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Completado hoy: "${todayEntry.item1}"',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '+15 XP',
                        style: AppTheme.numeric(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.format_quote_rounded,
                        size: 16,
                        color: Colors.purple,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '"${stoicQuote.quote}" — ${stoicQuote.author}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: AppTheme.onSurfaceVariant,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '3 Agradecimientos pendientes • +15 XP',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      'Escribir >',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThinkersLibraryCard(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.outlineVariant),
      ),
      color: AppTheme.surfaceContainerLowest,
      child: InkWell(
        onTap: () => context.push('/thinkers'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.auto_stories_rounded,
                            color: Color(0xFF6366F1),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '100 MAESTROS DE DISCIPLINA',
                                style: AppTheme.labelCaps(
                                  fontSize: 10,
                                  color: const Color(0xFF6366F1),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Biblioteca de Sabios',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '100 FIGURAS',
                      style: AppTheme.numeric(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF6366F1),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 16,
                      color: AppTheme.accentAmber,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Estoicos, Grecia Clásica, Guerreros, Místicos y Contemporáneos para tu autodominio diario.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppTheme.onSurfaceVariant,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Explorar sabiduría milenaria',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'Ver Biblioteca',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF6366F1),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 11,
                        color: Color(0xFF6366F1),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinanceQuickCard(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(financeOverviewProvider);
    final overview = overviewAsync.value;
    final netWorth = overview?.netWorth ?? 0.0;
    final cashFlow = overview?.monthCashFlow ?? 0.0;
    final cashFlowPositive = cashFlow >= 0;

    return Card(
      child: InkWell(
        onTap: () => context.push('/finance'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: Color(0xFF10B981),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DOMINIO FINANCIERO',
                                style: AppTheme.labelCaps(
                                  fontSize: 10,
                                  color: AppTheme.onSurfaceVariant,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Finanzas & Presupuesto',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (cashFlowPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${cashFlowPositive ? '+' : ''}\$${cashFlow.toStringAsFixed(0)} MXN',
                      style: AppTheme.numeric(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: cashFlowPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Patrimonio Neto',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '\$${netWorth.toStringAsFixed(2)} MXN',
                        style: AppTheme.numeric(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () => context.push('/finance'),
                    icon: const Icon(Icons.pie_chart_outline_rounded, size: 16),
                    label: const Text('Regla 50/30/20'),
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
      ),
    );
  }

  Widget _buildWellnessQuickCard(BuildContext context, WidgetRef ref) {
    return WaterTrackerCard(
      showHeader: true,
      onOpenDetails: () => context.push('/wellness'),
    );
  }

  Widget _buildMasterCatalogCard(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => context.push('/habits-catalog'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_stories_rounded,
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
                      '50 Hábitos FocusHabitual',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Catálogo con justificación neurocientífica en 5 áreas.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppTheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.outline,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
