import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/brand_logo.dart';
import '../domain/cycle_models.dart';
import 'controllers/cycle_controller.dart';
import 'widgets/cycle_layer_calendar.dart';
import 'widgets/cycle_layer_chips.dart';

/// Full Executive Precision Woman Cycle & Biological Optimization Screen.
class WomanCycleScreen extends ConsumerWidget {
  const WomanCycleScreen({super.key});

  static const _availableSymptoms = [
    {'key': 'cramps', 'label': 'Cólicos', 'icon': Icons.bolt_rounded},
    {'key': 'headache', 'label': 'Dolor de cabeza', 'icon': Icons.psychology_outlined},
    {'key': 'low_energy', 'label': 'Fatiga / Cansancio', 'icon': Icons.battery_2_bar_rounded},
    {'key': 'mood_sensitive', 'label': 'Sensibilidad', 'icon': Icons.favorite_border_rounded},
    {'key': 'bloating', 'label': 'Inflamación', 'icon': Icons.water_drop_outlined},
    {'key': 'calm', 'label': 'Calma & Foco', 'icon': Icons.spa_outlined},
    {'key': 'high_energy', 'label': 'Alta Energía', 'icon': Icons.local_fire_department_rounded},
  ];

  void _confirmPeriodStart(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '¿Registrar inicio del periodo hoy?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Text(
          'Esto recalculará automáticamente tu Día 1, la predicción de tu ventana fértil y las próximas fases del ciclo.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.accentRose),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(cycleControllerProvider.notifier).recordPeriodStartToday();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Periodo registrado. Ciclo actualizado con éxito.'),
                    backgroundColor: AppTheme.accentRose,
                  ),
                );
              }
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cycleAsync = ref.watch(cycleControllerProvider);
    final historyAsync = ref.watch(cycleHistoryProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest.withValues(alpha: 0.94),
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
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => context.pop(),
                  ),
                  const FocusHabitualLogo(size: 30),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ciclo & Bienestar',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      Text(
                        'OPTIMIZACIÓN BIOLÓGICA FEMENINA',
                        style: AppTheme.labelCaps(
                          fontSize: 9,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.accentRose),
                    tooltip: 'Periodo Inició Hoy',
                    onPressed: () => _confirmPeriodStart(context, ref),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: cycleAsync.when(
        data: (cycle) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Phase Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.accentRose.withValues(alpha: 0.08),
                      AppTheme.primary.withValues(alpha: 0.04),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.accentRose.withValues(alpha: 0.25)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.accentRose.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            cycle.phase.displayName.toUpperCase(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.accentRose,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Text(
                          'Día ${cycle.currentCycleDay} de ${cycle.cycleLength}',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Big Day Ring Representation
                    Text(
                      'Día ${cycle.currentCycleDay}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.0,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Próximo periodo en ${cycle.daysUntilNextPeriod} días (${cycle.nextPeriodDate.day.toString().padLeft(2, '0')}/${cycle.nextPeriodDate.month.toString().padLeft(2, '0')})',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 4-Phase Progress Indicator
                    Row(
                      children: [
                        _buildPhaseStep('Menstrual\n(1-5)', cycle.phase == CyclePhase.menstrual),
                        const SizedBox(width: 4),
                        _buildPhaseStep('Folicular\n(6-11)', cycle.phase == CyclePhase.follicular),
                        const SizedBox(width: 4),
                        _buildPhaseStep('Ovulatoria\n(12-16)', cycle.phase == CyclePhase.ovulatory),
                        const SizedBox(width: 4),
                        _buildPhaseStep('Lútea\n(17-28)', cycle.phase == CyclePhase.luteal),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Multi-Layer Calendar & Visual Filter Chips
              const CycleLayerChips(),
              const SizedBox(height: 12),
              const CycleLayerCalendar(),
              const SizedBox(height: 20),

              // Fertility & Natural Planning Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    Icon(
                      cycle.isFertileWindow ? Icons.child_care_rounded : Icons.check_circle_outline_rounded,
                      color: cycle.isFertileWindow ? AppTheme.accentAmber : AppTheme.accentEmerald,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cycle.isFertileWindow
                                ? (cycle.isOvulationDay ? 'Día de Ovulación Máxima' : 'Ventana Fértil Activa')
                                : 'Probabilidad Baja de Fertilidad',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.onSurface,
                            ),
                          ),
                          Text(
                            cycle.isFertileWindow
                                ? 'Fase de alta fecundidad según el método de cálculo biológico.'
                                : 'Fase natural de baja probabilidad de ovulación.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Executive Productivity & Nutrition Guidance
              Text(
                'Guía de Rendimiento & Enfoque',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.outlineVariant),
                ),
                child: Column(
                  children: [
                    _buildGuidanceRow(
                      icon: Icons.battery_charging_full_rounded,
                      title: 'Nivel de Energía',
                      desc: cycle.phase.energyLevel,
                    ),
                    const Divider(height: 20),
                    _buildGuidanceRow(
                      icon: Icons.lightbulb_outline_rounded,
                      title: 'Foco Productivo',
                      desc: cycle.phase.productivityAdvice,
                    ),
                    const Divider(height: 20),
                    _buildGuidanceRow(
                      icon: Icons.restaurant_rounded,
                      title: 'Nutrición Sugerida',
                      desc: cycle.phase.nutritionAdvice,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Daily Symptoms Tracker (Interactive Chips)
              Text(
                'Síntomas Registrados Hoy',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableSymptoms.map((sym) {
                  final key = sym['key'] as String;
                  final label = sym['label'] as String;
                  final icon = sym['icon'] as IconData;
                  final isSelected = cycle.activeSymptoms.contains(key);

                  return FilterChip(
                    avatar: Icon(
                      icon,
                      size: 16,
                      color: isSelected ? Colors.white : AppTheme.onSurfaceVariant,
                    ),
                    label: Text(label),
                    selected: isSelected,
                    selectedColor: AppTheme.accentRose,
                    labelStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : AppTheme.onSurface,
                    ),
                    onSelected: (_) {
                      ref.read(cycleControllerProvider.notifier).toggleSymptom(key);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Period Action Button
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.accentRose,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => _confirmPeriodStart(context, ref),
                icon: const Icon(Icons.water_drop_rounded, size: 20),
                label: const Text('Mi Periodo Comenzó Hoy'),
              ),
              const SizedBox(height: 24),

              // Cycle History Section
              Text(
                'Historial de Periodos',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              historyAsync.when(
                data: (history) {
                  if (history.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.outlineVariant),
                      ),
                      child: Text(
                        'Primer registro en curso. Tu historial se irá completando mes a mes.',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.onSurfaceVariant),
                      ),
                    );
                  }
                  return Column(
                    children: history.map((h) {
                      final startStr = DateFormat('dd/MM/yyyy').format(h.periodStart);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.outlineVariant),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 16, color: AppTheme.accentRose),
                                const SizedBox(width: 10),
                                Text(
                                  startStr,
                                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            Text(
                              '${h.cycleLength} días de ciclo',
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.outline),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => const SizedBox(),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildPhaseStep(String label, bool isActive) {
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: isActive ? AppTheme.accentRose : AppTheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? AppTheme.accentRose : AppTheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuidanceRow({required IconData icon, required String title, required String desc}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.accentRose),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppTheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
