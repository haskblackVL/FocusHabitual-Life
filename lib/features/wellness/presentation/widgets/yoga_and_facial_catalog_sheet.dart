import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme.dart';
import '../../domain/challenge_data.dart';
import '../../domain/yoga_and_facial_catalog.dart';
import 'exercise_timer_widget.dart';

/// Interactive modal sheet to explore all 150 Yoga Asanas and 50 Face Yoga exercises,
/// with search, category filtering, and immediate practice launch with 10s preparation.
class YogaAndFacialCatalogSheet extends StatefulWidget {
  final ChallengeType initialType;

  const YogaAndFacialCatalogSheet({
    super.key,
    this.initialType = ChallengeType.yoga,
  });

  static Future<void> show(
    BuildContext context, {
    ChallengeType initialType = ChallengeType.yoga,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => YogaAndFacialCatalogSheet(initialType: initialType),
    );
  }

  @override
  State<YogaAndFacialCatalogSheet> createState() => _YogaAndFacialCatalogSheetState();
}

class _YogaAndFacialCatalogSheetState extends State<YogaAndFacialCatalogSheet> {
  late bool _isYogaSelected;
  String _selectedCategory = 'Todas';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isYogaSelected = widget.initialType != ChallengeType.yogaFacial;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _currentCategories {
    if (_isYogaSelected) {
      return ['Todas', 'Fuerza (50)', 'Flexibilidad (50)', 'Relajación (50)'];
    } else {
      return [
        'Todos',
        'Frente (10)',
        'Ojos (10)',
        'Pómulos (10)',
        'Labios (10)',
        'Mandíbula & Cuello (10)',
      ];
    }
  }

  List<CatalogItem> get _allItems {
    if (_isYogaSelected) {
      return [
        ...YogaAndFacialCatalog.yogaFuerza,
        ...YogaAndFacialCatalog.yogaFlexibilidad,
        ...YogaAndFacialCatalog.yogaRelajacion,
      ];
    } else {
      return [
        ...YogaAndFacialCatalog.facialFrente,
        ...YogaAndFacialCatalog.facialOjos,
        ...YogaAndFacialCatalog.facialPomulos,
        ...YogaAndFacialCatalog.facialLabios,
        ...YogaAndFacialCatalog.facialMandibulaCuello,
      ];
    }
  }

  List<CatalogItem> get _filteredItems {
    final query = _searchQuery.trim().toLowerCase();
    return _allItems.where((item) {
      // Category filter
      if (_isYogaSelected) {
        if (_selectedCategory == 'Fuerza (50)' && item.category != 'Fuerza') return false;
        if (_selectedCategory == 'Flexibilidad (50)' && item.category != 'Flexibilidad') return false;
        if (_selectedCategory == 'Relajación (50)' && item.category != 'Relajación') return false;
      } else {
        if (_selectedCategory == 'Frente (10)' && item.category != 'Frente y Entrecejo') return false;
        if (_selectedCategory == 'Ojos (10)' && item.category != 'Ojos y Párpados') return false;
        if (_selectedCategory == 'Pómulos (10)' && item.category != 'Pómulos y Mejillas') return false;
        if (_selectedCategory == 'Labios (10)' && item.category != 'Labios y Surco Nasogeniano') return false;
        if (_selectedCategory == 'Mandíbula & Cuello (10)' && item.category != 'Mandíbula, Cuello y Papada') return false;
      }

      // Text search query
      if (query.isNotEmpty) {
        final inTitle = item.title.toLowerCase().contains(query);
        final inDesc = item.description.toLowerCase().contains(query);
        final inCat = item.category.toLowerCase().contains(query);
        if (!inTitle && !inDesc && !inCat) return false;
      }

      return true;
    }).toList();
  }

  void _launchPractice(CatalogItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: AppTheme.surfaceContainerHigh)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.category.toUpperCase(),
                      style: AppTheme.labelCaps(color: AppTheme.primary, letterSpacing: 0.08),
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.hourglass_top_rounded, size: 14, color: Color(0xFFFFB300)),
                  const SizedBox(width: 4),
                  Text(
                    '10s preparación',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFFFFB300),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                item.title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              ExerciseTimerWidget(
                steps: [
                  item.toExerciseStep(
                    durationSeconds: item.defaultDurationSeconds,
                    preparationSeconds: 10,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'INSTRUCCIONES',
                style: AppTheme.labelCaps(color: AppTheme.onSurfaceVariant, letterSpacing: 0.08),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.surfaceContainerHigh),
                    ),
                    child: Text(
                      item.description,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.onSurface,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredItems;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppTheme.surfaceContainerHigh)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Handle Bar
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

            // Sheet Title & Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Biblioteca de Ejercicios',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.onSurface,
                          ),
                        ),
                        Text(
                          '150 Asanas de Yoga & 50 Ejercicios Faciales con 10s prep',
                          style: GoogleFonts.inter(fontSize: 12, color: AppTheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: AppTheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),

            // Top Module Segmented Switcher (Yoga vs Facial)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.surfaceContainerHigh),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isYogaSelected = true;
                            _selectedCategory = 'Todas';
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _isYogaSelected ? AppTheme.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '🧘‍♀️ Yoga (150 Asanas)',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: _isYogaSelected ? FontWeight.w800 : FontWeight.w600,
                              color: _isYogaSelected ? Colors.black : AppTheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isYogaSelected = false;
                            _selectedCategory = 'Todos';
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: !_isYogaSelected ? AppTheme.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '✨ Facial (50 Ejercicios)',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: !_isYogaSelected ? FontWeight.w800 : FontWeight.w600,
                              color: !_isYogaSelected ? Colors.black : AppTheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: GoogleFonts.inter(color: AppTheme.onSurface, fontSize: 14),
                decoration: InputDecoration(
                  hintText: _isYogaSelected
                      ? 'Buscar entre 150 asanas (ej: Silla, Guerrero, Cobra)...'
                      : 'Buscar entre 50 ejercicios faciales (ej: Pómulos, Frente)...',
                  hintStyle: GoogleFonts.inter(color: AppTheme.onSurfaceVariant, fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.onSurfaceVariant, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppTheme.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.surfaceContainerHigh),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                  ),
                ),
              ),
            ),

            // Filter Chips Carousel
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _currentCategories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final cat = _currentCategories[idx];
                  final isSelected = cat == _selectedCategory;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primary.withValues(alpha: 0.15)
                            : AppTheme.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? AppTheme.primary : AppTheme.surfaceContainerHigh,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        cat,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? AppTheme.primary : AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // Exercise Count Tag
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${filtered.length} DISPONIBLES',
                    style: AppTheme.labelCaps(color: AppTheme.onSurfaceVariant, letterSpacing: 0.08),
                  ),
                  Text(
                    'Prepárate 10s al iniciar',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFFFFB300),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // Exercises List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.search_off_rounded, size: 40, color: AppTheme.onSurfaceVariant),
                          const SizedBox(height: 8),
                          Text(
                            'No se encontraron ejercicios',
                            style: GoogleFonts.inter(color: AppTheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = filtered[index];

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.surfaceContainerHigh),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Category Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      item.category.toUpperCase(),
                                      style: AppTheme.labelCaps(
                                        color: AppTheme.primary,
                                        letterSpacing: 0.06,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  // Duration tag
                                  Row(
                                    children: [
                                      const Icon(Icons.timer_outlined, size: 12, color: AppTheme.onSurfaceVariant),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${item.defaultDurationSeconds}s + 10s prep',
                                        style: GoogleFonts.inter(fontSize: 11, color: AppTheme.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Title
                              Text(
                                item.title,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),

                              // Description
                              Text(
                                item.description,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppTheme.onSurfaceVariant,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Practice Button
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => _launchPractice(item),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AppTheme.surfaceContainerHigh),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                  icon: const Icon(Icons.play_circle_outline_rounded, size: 16, color: AppTheme.primary),
                                  label: Text(
                                    'Practicar (con 10s prep)',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.onSurface,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
