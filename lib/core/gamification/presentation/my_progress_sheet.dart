import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme.dart';
import '../../../app/widgets/brand_logo.dart';
import '../achievement_model.dart';
import '../gamification_controller.dart';

/// Full Executive Precision "Mi Progreso & Medallas" Bottom Sheet.
/// Presents total XP, Polymath Level progression, and unified achievements across all modules.
class MyProgressSheet extends ConsumerStatefulWidget {
  const MyProgressSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const MyProgressSheet(),
    );
  }

  @override
  ConsumerState<MyProgressSheet> createState() => _MyProgressSheetState();
}

class _MyProgressSheetState extends ConsumerState<MyProgressSheet> {
  AchievementModule? _selectedModule; // null means 'Todas'

  @override
  Widget build(BuildContext context) {
    final gamification = ref.watch(gamificationProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filteredAchievements = _selectedModule == null
        ? MasterAchievements.all
        : MasterAchievements.byModule(_selectedModule!);

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBackground : AppTheme.surfaceContainerLowest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF262D3D) : AppTheme.surfaceContainerHigh,
            width: 1.5,
          ),
        ),
      ),
      child: Column(
        children: [
          // 1. Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4.5,
            decoration: BoxDecoration(
              color: AppTheme.outlineVariant.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 12),

          // 2. Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const FocusHabitualLogo(size: 28),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mi Progreso & Logros',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    Text(
                      'FOCUSHABITUAL LIFE · GAMIFICACIÓN UNIFICADA',
                      style: AppTheme.labelCaps(
                        color: AppTheme.primary,
                        fontSize: 9.5,
                        letterSpacing: 0.08,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 22),
                  onPressed: () => Navigator.of(context).pop(),
                  color: AppTheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 3. Scrollable Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              children: [
                // A. Executive Level & XP Card
                _buildExecutiveLevelCard(context, gamification),
                const SizedBox(height: 20),

                // B. Category Filter Chips
                _buildCategoryFilterChips(),
                const SizedBox(height: 18),

                // C. Medals Grid Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedModule == null
                          ? 'TODAS LAS MEDALLAS (${filteredAchievements.length})'
                          : '${_selectedModule!.displayName.toUpperCase()} (${filteredAchievements.length})',
                      style: AppTheme.labelCaps(
                        color: AppTheme.onSurfaceVariant,
                        letterSpacing: 0.08,
                      ),
                    ),
                    Text(
                      '${gamification.totalUnlockedCount} Desbloqueadas',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // D. Achievements List
                ...filteredAchievements.map((def) {
                  final isUnlocked = gamification.isUnlocked(def.key);
                  final unlockedInfo = isUnlocked
                      ? gamification.unlockedAchievements.firstWhere(
                          (u) => u.definition.key == def.key,
                        )
                      : null;

                  return _buildAchievementCard(
                    context,
                    def: def,
                    isUnlocked: isUnlocked,
                    unlockedInfo: unlockedInfo,
                  );
                }),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExecutiveLevelCard(BuildContext context, GamificationState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Level Badge Circle
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'NVL',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.black.withValues(alpha: 0.8),
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        '${state.level}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Title and XP
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.levelTitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.bolt_rounded, size: 16, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 4),
                        Text(
                          '${state.totalXp} XP Acumulados',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFE2E8F0),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: state.levelProgress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
            ),
          ),
          const SizedBox(height: 10),

          // Progress Telemetry
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nivel ${state.level} (${state.currentLevelMinXp} XP)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              Text(
                'Faltan ${state.xpRemainingToNextLevel} XP para Nvl ${state.level + 1}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Color(0xFF334155), height: 1),
          const SizedBox(height: 12),

          // Global Completion Counter
          Row(
            children: [
              const Icon(Icons.military_tech_rounded, size: 18, color: Color(0xFF38BDF8)),
              const SizedBox(width: 8),
              Text(
                'Medallas Desbloqueadas:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFCBD5E1),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                ),
                child: Text(
                  '${state.totalUnlockedCount} / ${state.totalAvailableCount} (${(state.completionPercentage * 100).toInt()}%)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF38BDF8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilterChips() {
    final modules = [
      null, // Todas
      AchievementModule.habits,
      AchievementModule.pomodoro,
      AchievementModule.wellness,
      AchievementModule.challenges,
      AchievementModule.nofap,
      AchievementModule.cycle,
      AchievementModule.religion,
      AchievementModule.finance,
      AchievementModule.gratitude,
      AchievementModule.polymath,
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: modules.map((m) {
          final isSelected = _selectedModule == m;
          final label = m == null ? 'Todas' : m.displayName;
          final icon = m?.icon ?? Icons.grid_view_rounded;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              showCheckmark: false,
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 14,
                    color: isSelected ? Colors.black : AppTheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? Colors.black : AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              backgroundColor: AppTheme.surfaceContainerLow,
              selectedColor: AppTheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: isSelected ? AppTheme.primary : AppTheme.surfaceContainerHigh,
                ),
              ),
              onSelected: (_) => setState(() => _selectedModule = m),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAchievementCard(
    BuildContext context, {
    required AchievementDefinition def,
    required bool isUnlocked,
    UnlockedAchievement? unlockedInfo,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isUnlocked
            ? (isDark ? const Color(0xFF1E293B) : Colors.white)
            : (isDark ? const Color(0xFF141A28) : AppTheme.surfaceContainerLow),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isUnlocked
              ? def.tier.color.withValues(alpha: 0.5)
              : (isDark ? const Color(0xFF262D3D) : AppTheme.surfaceContainerHigh),
          width: isUnlocked ? 1.5 : 1,
        ),
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: def.tier.color.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _showAchievementDetailModal(context, def, isUnlocked, unlockedInfo),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Medal Badge Icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isUnlocked
                        ? LinearGradient(
                            colors: def.tier.gradientColors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isUnlocked ? null : Colors.black.withValues(alpha: 0.06),
                    border: Border.all(
                      color: isUnlocked
                          ? Colors.white.withValues(alpha: 0.4)
                          : AppTheme.outlineVariant.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      isUnlocked ? def.icon : Icons.lock_outline_rounded,
                      size: 24,
                      color: isUnlocked ? Colors.black : AppTheme.outlineVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Texts
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              def.title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: isUnlocked ? AppTheme.onSurface : AppTheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: def.tier.color.withValues(alpha: isUnlocked ? 0.15 : 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              def.tier.displayName.toUpperCase(),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: def.tier.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isUnlocked ? def.description : def.requirement,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: isUnlocked ? AppTheme.onSurfaceVariant : AppTheme.outline,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Status row
                      Row(
                        children: [
                          if (isUnlocked && unlockedInfo != null) ...[
                            Icon(Icons.check_circle_rounded, size: 14, color: AppTheme.accentEmerald),
                            const SizedBox(width: 4),
                            Text(
                              'Desbloqueada el ${unlockedInfo.formattedDate}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.accentEmerald,
                              ),
                            ),
                          ] else ...[
                            Icon(Icons.lock_clock_rounded, size: 13, color: AppTheme.outline),
                            const SizedBox(width: 4),
                            Text(
                              'Bloqueada',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.outline,
                              ),
                            ),
                          ],
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '+${def.xpReward} XP',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFD97706),
                              ),
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
        ),
      ),
    );
  }

  void _showAchievementDetailModal(
    BuildContext context,
    AchievementDefinition def,
    bool isUnlocked,
    UnlockedAchievement? unlockedInfo,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Large Icon Badge
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isUnlocked
                    ? LinearGradient(
                        colors: def.tier.gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isUnlocked ? null : AppTheme.surfaceContainerHigh,
                border: Border.all(
                  color: def.tier.color.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: Center(
                child: Icon(
                  isUnlocked ? def.icon : Icons.lock_outline_rounded,
                  size: 38,
                  color: isUnlocked ? Colors.black : AppTheme.outline,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tier Tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: def.tier.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'MEDALLA DE ${def.tier.displayName.toUpperCase()}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: def.tier.color,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Title
            Text(
              def.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              def.module.displayName,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 16),

            // Lore / Description
            Text(
              def.description,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                color: AppTheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),

            // Requirement Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.surfaceContainerHigh),
              ),
              child: Row(
                children: [
                  const Icon(Icons.track_changes_rounded, size: 18, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Requisito: ${def.requirement}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Reward
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.bolt_rounded, size: 20, color: Color(0xFFF59E0B)),
                const SizedBox(width: 6),
                Text(
                  '+${def.xpReward} XP de Recompensa',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFD97706),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Status message
            if (isUnlocked && unlockedInfo != null)
              Text(
                '✓ Desbloqueada el ${unlockedInfo.formattedDate}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accentEmerald,
                ),
              )
            else
              Text(
                '🔒 Sigue avanzando en tus rutinas para desbloquearla',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppTheme.outline,
                ),
              ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  'Entendido',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
