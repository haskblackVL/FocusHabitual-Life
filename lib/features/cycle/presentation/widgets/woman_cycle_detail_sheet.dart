import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme.dart';
import '../../../../core/local_db/database.dart';

/// Modal bottom sheet displaying detailed biological cycle telemetry and wellness logs.
/// Follows Swiss Neo-Minimalism Executive Precision specifications from mujer_ciclos_bienestar/code.html.
class WomanCycleDetailSheet extends StatefulWidget {
  const WomanCycleDetailSheet({
    super.key,
    this.cycleLength = 28,
    this.periodLength = 5,
    this.currentDay = 11,
  });

  final int cycleLength;
  final int periodLength;
  final int currentDay;

  static Future<void> show(BuildContext context, {int cycleLength = 28, int periodLength = 5, int currentDay = 11}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => WomanCycleDetailSheet(
        cycleLength: cycleLength,
        periodLength: periodLength,
        currentDay: currentDay,
      ),
    );
  }

  @override
  State<WomanCycleDetailSheet> createState() => _WomanCycleDetailSheetState();
}

class _WomanCycleDetailSheetState extends State<WomanCycleDetailSheet> {
  late final Set<String> _selectedChips;

  final List<String> _wellnessChips = [
    'Energía alta',
    'Enfoque óptimo',
    'Calma',
    'Buena hidratación',
    'Claridad mental',
    'Vitalidad física',
  ];

  @override
  void initState() {
    super.initState();
    final savedChips = AppDatabase.getSetting('woman_selected_chips');
    if (savedChips != null && savedChips.isNotEmpty) {
      _selectedChips = savedChips.split(',').toSet();
    } else {
      _selectedChips = {'Energía alta', 'Enfoque óptimo'};
    }
  }

  void _toggleChip(String chip) {
    setState(() {
      if (_selectedChips.contains(chip)) {
        _selectedChips.remove(chip);
      } else {
        _selectedChips.add(chip);
      }
      AppDatabase.setSetting('woman_selected_chips', _selectedChips.join(','));
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return Container(
      constraints: BoxConstraints(maxHeight: media.size.height * 0.9),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.water_drop_rounded,
                    color: AppTheme.secondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ciclo Biológico & Neuroquímica',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      Text(
                        'Sincronización hormonal para alto rendimiento',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          color: AppTheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: AppTheme.outline),
                ),
              ],
            ),
          ),
          const Divider(height: 20, thickness: 1, color: AppTheme.outlineVariant),

          // Scrollable Body
          Flexible(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              children: [
                // Dial & Phase Highlights Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    children: [
                      // Circular Dial
                      SizedBox(
                        width: 90,
                        height: 90,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(
                              size: const Size(90, 90),
                              painter: _CycleDialPainter(
                                currentDay: widget.currentDay,
                                totalDays: widget.cycleLength,
                                progressColor: AppTheme.secondary,
                                backgroundColor: AppTheme.surfaceContainerHigh,
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Día ${widget.currentDay}',
                                  style: AppTheme.numeric(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.onSurface,
                                  ),
                                ),
                                Text(
                                  'de ${widget.cycleLength}d',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.outline,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Phase information
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.secondary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'FASE FOLICULAR ALTA',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: AppTheme.secondary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Pico de Creatividad & Energía',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Niveles ascendentes de estrógeno promueven agilidad verbal y asimilación conceptual acelerada.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                color: AppTheme.onSurfaceVariant,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 3 Performance Metrics Grid
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile('Cognitiva', '92%', 0.92, AppTheme.primaryContainer),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMetricTile('Física', '88%', 0.88, AppTheme.secondary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMetricTile('Calma', '85%', 0.85, AppTheme.secondaryContainer),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Strategic Recommendation Banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryContainer.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.primaryContainer.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_rounded, color: AppTheme.primaryContainer, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'RECOMENDACIÓN ESTRATÉGICA',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: AppTheme.primaryContainer,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ventana de máxima claridad hormonal: 09:00 - 13:30. Momento idóneo para diseño estratégico, oratoria y aprendizaje profundo.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.onSurface,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Quick Wellness Log Chips
                Text(
                  'REGISTRO RÁPIDO DE BIENESTAR',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: AppTheme.outline,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _wellnessChips.map((chip) {
                    final isSelected = _selectedChips.contains(chip);
                    return InkWell(
                      onTap: () => _toggleChip(chip),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primaryContainer : AppTheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppTheme.primaryContainer : AppTheme.outlineVariant,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isSelected ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                              size: 14,
                              color: isSelected ? Colors.white : AppTheme.outline,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              chip,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : AppTheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, double progress, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.outline,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTheme.numeric(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.surfaceContainerHigh,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}

class _CycleDialPainter extends CustomPainter {
  _CycleDialPainter({
    required this.currentDay,
    required this.totalDays,
    required this.progressColor,
    required this.backgroundColor,
  });

  final int currentDay;
  final int totalDays;
  final Color progressColor;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 6;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;

    canvas.drawCircle(center, radius, bgPaint);

    final sweepAngle = (currentDay / totalDays) * 2 * math.pi;

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CycleDialPainter oldDelegate) {
    return oldDelegate.currentDay != currentDay ||
        oldDelegate.totalDays != totalDays ||
        oldDelegate.progressColor != progressColor;
  }
}
