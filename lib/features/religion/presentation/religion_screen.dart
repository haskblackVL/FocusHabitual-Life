import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme.dart';
import '../domain/prayer_request.dart';
import '../domain/religion_content.dart';
import 'controllers/religion_controller.dart';
import 'widgets/add_prayer_sheet.dart';
import 'widgets/prayer_answered_dialog.dart';

class ReligionScreen extends ConsumerStatefulWidget {
  const ReligionScreen({super.key});

  @override
  ConsumerState<ReligionScreen> createState() => _ReligionScreenState();
}

class _ReligionScreenState extends ConsumerState<ReligionScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _reflectionNotesController = TextEditingController();
  bool _isEditingReflection = false;
  bool _isSavingReflection = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _reflectionNotesController.dispose();
    super.dispose();
  }

  void _showAddPrayerSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddPrayerSheet(),
    );
  }

  Future<void> _submitReflection(String contentId, bool isFavorite) async {
    final notes = _reflectionNotesController.text.trim();
    if (notes.isEmpty) return;

    setState(() => _isSavingReflection = true);

    final success = await ref.read(religionControllerProvider).saveReflection(
          contentId: contentId,
          notes: notes,
          isFavorite: isFavorite,
        );

    if (mounted) {
      setState(() {
        _isSavingReflection = false;
        _isEditingReflection = false;
      });
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '¡Reflexión completada! Has ganado +15 XP',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final devotionalAsync = ref.watch(dailyDevotionalProvider);
    final statsAsync = ref.watch(spiritualStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Religión & Espiritualidad',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            Text(
              'Pilar rector, discernimiento y oración',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(104),
          child: Column(
            children: [
              // Executive Summary Stats Row
              _buildStatsRow(statsAsync),
              const SizedBox(height: 6),

              // Segmented TabBar
              TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.primary,
                indicatorWeight: 3,
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.onSurfaceVariant,
                labelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                tabs: const [
                  Tab(icon: Icon(Icons.menu_book_rounded, size: 18), text: 'Devocional'),
                  Tab(icon: Icon(Icons.favorite_rounded, size: 18), text: 'Oración'),
                  Tab(icon: Icon(Icons.library_books_rounded, size: 18), text: 'Biblioteca'),
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, child) {
          if (_tabController.index == 1) {
            return FloatingActionButton.extended(
              onPressed: _showAddPrayerSheet,
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                'Nueva Petición (+10 XP)',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Tab Devocional Diario
          _buildDevotionalTab(devotionalAsync),

          // 2. Tab Diario de Oración
          _buildPrayerTab(),

          // 3. Tab Biblioteca de Sabiduría
          _buildWisdomLibraryTab(),
        ],
      ),
    );
  }

  Widget _buildStatsRow(AsyncValue<Map<String, int>> statsAsync) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: statsAsync.when(
        data: (stats) {
          final reflections = stats['reflectionsCount'] ?? 0;
          final activePrayers = stats['activePrayersCount'] ?? 0;
          final answeredPrayers = stats['answeredPrayersCount'] ?? 0;

          return Row(
            children: [
              _buildStatPill(
                icon: Icons.check_circle_outline_rounded,
                value: '$reflections',
                label: 'Reflexiones',
                color: AppTheme.primary,
              ),
              const SizedBox(width: 8),
              _buildStatPill(
                icon: Icons.hourglass_top_rounded,
                value: '$activePrayers',
                label: 'En Oración',
                color: const Color(0xFF6366F1),
              ),
              const SizedBox(width: 8),
              _buildStatPill(
                icon: Icons.verified_rounded,
                value: '$answeredPrayers',
                label: 'Respondidas',
                color: const Color(0xFF10B981),
              ),
            ],
          );
        },
        loading: () => const SizedBox(height: 32),
        error: (_, _) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildStatPill({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(
              value,
              style: AppTheme.numeric(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: DEVOCIONAL DIARIO
  // ---------------------------------------------------------------------------
  Widget _buildDevotionalTab(AsyncValue<DailyDevotional> devotionalAsync) {
    return devotionalAsync.when(
      data: (devotional) {
        final content = devotional.content;
        final userLog = devotional.userLog;
        final isCompleted = devotional.isCompleted;
        final isFavorite = devotional.isFavorite;

        if (_reflectionNotesController.text.isEmpty && userLog?.reflectionNotes != null) {
          _reflectionNotesController.text = userLog!.reflectionNotes!;
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Hero Scripture Card
            _buildHeroScriptureCard(content, isFavorite),
            const SizedBox(height: 16),

            // Executive Reflection Commentary
            _buildExecutiveReflectionCard(content),
            const SizedBox(height: 16),

            // Practical Daily Action Box
            if (content.practicalAction != null) ...[
              _buildPracticalActionCard(content.practicalAction!),
              const SizedBox(height: 16),
            ],

            // Personal Reflection Journaling Box
            _buildJournalReflectionCard(content.id, isCompleted, userLog, isFavorite),
            const SizedBox(height: 24),

            // Thematic Reading Paths Carousel
            _buildThematicPathsSection(),
            const SizedBox(height: 40),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.red, size: 36),
              const SizedBox(height: 12),
              Text('Error al cargar pasaje diario: $e'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroScriptureCard(ReligionContent content, bool isFavorite) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppTheme.outline.withValues(alpha: 0.2)),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              AppTheme.surfaceContainerLowest,
              AppTheme.surfaceContainerLow.withValues(alpha: 0.5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Theme Badge + Favorite & Share Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome_rounded, size: 12, color: AppTheme.primary),
                      const SizedBox(width: 5),
                      Text(
                        content.theme.toUpperCase(),
                        style: AppTheme.labelCaps(
                          fontSize: 10,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                        color: isFavorite ? Colors.amber : AppTheme.onSurfaceVariant,
                        size: 22,
                      ),
                      onPressed: () {
                        ref.read(religionControllerProvider).toggleFavorite(content.id);
                      },
                      tooltip: isFavorite ? 'Quitar de favoritos' : 'Marcar favorito',
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 18, color: AppTheme.onSurfaceVariant),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: '«${content.verseText}» — ${content.verseRef}'),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Pasaje copiado al portapapeles',
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                            ),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      tooltip: 'Copiar versículo',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Verse Citation
            Text(
              content.verseRef,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 10),

            // Verse Text
            Text(
              '«${content.verseText}»',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
                height: 1.5,
                color: AppTheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExecutiveReflectionCard(ReligionContent content) {
    if (content.reflection == null || content.reflection!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.outline.withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology_outlined, size: 18, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text(
                  'DISCERNIMIENTO & ANÁLISIS ESTRATÉGICO',
                  style: AppTheme.labelCaps(
                    fontSize: 10,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              content.reflection!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                height: 1.6,
                fontWeight: FontWeight.w500,
                color: AppTheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPracticalActionCard(String action) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.explore_rounded,
              color: Color(0xFFF59E0B),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PRINCIPIO EN ACCIÓN HOY',
                  style: AppTheme.labelCaps(
                    fontSize: 10,
                    color: const Color(0xFFD97706),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  action,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                    color: AppTheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJournalReflectionCard(
    String contentId,
    bool isCompleted,
    ReligionUserLog? userLog,
    bool isFavorite,
  ) {
    if (isCompleted && !_isEditingReflection) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF10B981), width: 1.2),
        ),
        color: const Color(0xFF10B981).withValues(alpha: 0.04),
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
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'REFLEXIÓN COMPLETADA HOY',
                        style: AppTheme.labelCaps(
                          fontSize: 10,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '+15 XP',
                      style: AppTheme.numeric(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (userLog?.reflectionNotes != null && userLog!.reflectionNotes!.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    userLog.reflectionNotes!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      height: 1.5,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() => _isEditingReflection = true);
                  },
                  icon: const Icon(Icons.edit_note_rounded, size: 16),
                  label: const Text('Editar notas personales'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    textStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.outline.withValues(alpha: 0.2)),
      ),
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
                    const Icon(Icons.edit_note_rounded, color: AppTheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'DIARIO DE REFLEXIÓN PERSONAL',
                      style: AppTheme.labelCaps(
                        fontSize: 10,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '+15 XP',
                    style: AppTheme.numeric(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '¿Cómo aplicarás este principio en tus decisiones y liderazgo de hoy?',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reflectionNotesController,
              decoration: InputDecoration(
                hintText: 'Escribe aquí tu aprendizaje, oración o compromiso concreto...',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              style: GoogleFonts.plusJakartaSans(fontSize: 13),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_isEditingReflection)
                  TextButton(
                    onPressed: () => setState(() => _isEditingReflection = false),
                    child: Text(
                      'Cancelar',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _isSavingReflection ? null : () => _submitReflection(contentId, isFavorite),
                  icon: _isSavingReflection
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_rounded, size: 18),
                  label: Text(
                    'Completar Reflexión (+15 XP)',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThematicPathsSection() {
    final paths = [
      {
        'title': '31 Días de Proverbios',
        'subtitle': 'Liderazgo, prudencia y discernimiento diario',
        'icon': Icons.account_tree_outlined,
        'color': const Color(0xFF6366F1),
      },
      {
        'title': 'Paz Mental & Confianza',
        'subtitle': 'Salmos para desterrar la ansiedad y reposar',
        'icon': Icons.spa_outlined,
        'color': const Color(0xFF10B981),
      },
      {
        'title': 'Fortaleza en la Prueba',
        'subtitle': 'Valentía y entereza moral ante el caos',
        'icon': Icons.shield_outlined,
        'color': const Color(0xFFF59E0B),
      },
      {
        'title': 'Liderazgo & Excelencia',
        'subtitle': 'Diligencia artesanal e integridad intachable',
        'icon': Icons.military_tech_outlined,
        'color': const Color(0xFFEC4899),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RUTAS DE SABIDURÍA & ESTUDIO',
          style: AppTheme.labelCaps(
            fontSize: 10,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: paths.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final p = paths[index];
              final color = p['color'] as Color;

              return InkWell(
                onTap: () {
                  _tabController.animateTo(2); // Navigate to library
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 220,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.outline.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Icon(p['icon'] as IconData, size: 18, color: color),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              p['title'] as String,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        p['subtitle'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppTheme.onSurfaceVariant,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: DIARIO DE ORACIÓN
  // ---------------------------------------------------------------------------
  Widget _buildPrayerTab() {
    final filter = ref.watch(prayerFilterProvider);
    final prayersAsync = ref.watch(prayerRequestsProvider);

    return Column(
      children: [
        // Subheader with Filter Tabs & Category Filter
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            border: Border(bottom: BorderSide(color: AppTheme.outline.withValues(alpha: 0.1))),
          ),
          child: Column(
            children: [
              // Active vs. Answered Segmented Control
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      selected: filter.status == 'active',
                      onSelected: (val) {
                        if (val) {
                          ref.read(prayerFilterProvider.notifier).setStatus('active');
                        }
                      },
                      avatar: const Icon(Icons.hourglass_top_rounded, size: 16),
                      label: const Center(child: Text('En Intercesión Activa')),
                      labelStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: filter.status == 'active' ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      selected: filter.status == 'answered',
                      onSelected: (val) {
                        if (val) {
                          ref.read(prayerFilterProvider.notifier).setStatus('answered');
                        }
                      },
                      avatar: const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF10B981)),
                      label: const Center(child: Text('Testimonios (Respondidas)')),
                      labelStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: filter.status == 'answered' ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Category Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      selected: filter.category == null,
                      onSelected: (val) {
                        if (val) {
                          ref.read(prayerFilterProvider.notifier).setCategory(null, clearCategory: true);
                        }
                      },
                      label: const Text('Todas'),
                      labelStyle: GoogleFonts.plusJakartaSans(fontSize: 11),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    const SizedBox(width: 6),
                    ...PrayerCategory.values.map((cat) {
                      final isSelected = filter.category == cat.code;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          selected: isSelected,
                          onSelected: (val) {
                            ref
                                .read(prayerFilterProvider.notifier)
                                .setCategory(val ? cat.code : null, clearCategory: !val);
                          },
                          avatar: Icon(cat.icon, size: 14, color: isSelected ? Colors.white : cat.color),
                          label: Text(cat.label),
                          labelStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: isSelected ? Colors.white : AppTheme.onSurface,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                          selectedColor: cat.color,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Prayers List
        Expanded(
          child: prayersAsync.when(
            data: (prayers) {
              if (prayers.isEmpty) {
                return _buildEmptyPrayersState(filter.status);
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: prayers.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final prayer = prayers[index];
                  return _buildPrayerCard(prayer);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }

  Widget _buildPrayerCard(PrayerRequest prayer) {
    final cat = prayer.categoryEnum;

    if (prayer.isAnswered) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF10B981), width: 1.2),
        ),
        color: const Color(0xFF10B981).withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF10B981)),
                        const SizedBox(width: 4),
                        Text(
                          'ORACIÓN RESPONDIDA',
                          style: AppTheme.labelCaps(
                            fontSize: 9,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppTheme.onSurfaceVariant),
                    onSelected: (val) {
                      if (val == 'delete') {
                        ref.read(religionControllerProvider).deletePrayerRequest(prayer.id);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                            SizedBox(width: 8),
                            Text('Eliminar petición'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                prayer.title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                ),
              ),
              if (prayer.description != null && prayer.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  prayer.description!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              // Testimony Notes Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.format_quote_rounded, size: 16, color: Color(0xFF10B981)),
                        const SizedBox(width: 4),
                        Text(
                          'TESTIMONIO & RESOLUCIÓN',
                          style: AppTheme.labelCaps(
                            fontSize: 9,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      prayer.answerNotes ?? 'Respuesta concedida.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.onSurface,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.outline.withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: cat.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(cat.icon, size: 13, color: cat.color),
                      const SizedBox(width: 5),
                      Text(
                        cat.label.toUpperCase(),
                        style: AppTheme.labelCaps(
                          fontSize: 9,
                          color: cat.color,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppTheme.onSurfaceVariant),
                  onSelected: (val) {
                    if (val == 'delete') {
                      ref.read(religionControllerProvider).deletePrayerRequest(prayer.id);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                          SizedBox(width: 8),
                          Text('Eliminar petición'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              prayer.title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurface,
              ),
            ),
            if (prayer.description != null && prayer.description!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                prayer.description!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppTheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'En oración constante',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => PrayerAnsweredDialog(prayer: prayer),
                    );
                  },
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                  label: const Text('Marcar Respondida'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.12),
                    foregroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

  Widget _buildEmptyPrayersState(String status) {
    final isActive = status == 'active';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isActive ? Icons.favorite_border_rounded : Icons.verified_rounded,
                size: 36,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isActive ? 'Sin peticiones activas' : 'Sin testimonios registrados aún',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isActive
                  ? 'Registra tus motivos de oración, familia o proyectos para mantener intención espiritual.'
                  : 'Cuando una petición sea contestada, márcala para atesorar tu historial de gratitud.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppTheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            if (isActive) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _showAddPrayerSheet,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Añadir Primera Petición (+10 XP)'),
                style: FilledButton.styleFrom(backgroundColor: AppTheme.primary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 3: BIBLIOTECA DE SABIDURÍA (TODOS LOS PASAJES)
  // ---------------------------------------------------------------------------
  Widget _buildWisdomLibraryTab() {
    final passagesAsync = ref.watch(allPassagesProvider);

    return passagesAsync.when(
      data: (passages) {
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: passages.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final p = passages[index];
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppTheme.outline.withValues(alpha: 0.15)),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _showPassageDetailModal(p),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            p.verseRef,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              p.theme,
                              style: AppTheme.labelCaps(
                                fontSize: 9,
                                color: AppTheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '«${p.verseText}»',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                          color: AppTheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  void _showPassageDetailModal(ReligionContent content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.outline.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  content.theme.toUpperCase(),
                  style: AppTheme.labelCaps(fontSize: 10, color: AppTheme.primary),
                ),
                const SizedBox(height: 4),
                Text(
                  content.verseRef,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '«${content.verseText}»',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (content.reflection != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Reflexión Ejecutiva:',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    content.reflection!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      height: 1.5,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ],
                if (content.practicalAction != null) ...[
                  const SizedBox(height: 16),
                  _buildPracticalActionCard(content.practicalAction!),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(backgroundColor: AppTheme.primary),
                    child: const Text('Cerrar'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
