import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme.dart';
import '../controllers/pomodoro_controller.dart';

/// Radical Cognitive Decoupling view during Pomodoro break phase.
class KinestheticBreakView extends ConsumerStatefulWidget {
  const KinestheticBreakView({super.key});

  @override
  ConsumerState<KinestheticBreakView> createState() => _KinestheticBreakViewState();
}

class _KinestheticBreakViewState extends ConsumerState<KinestheticBreakView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breathController;
  Timer? _phaseTimer;
  int _phaseIndex = 0; // 0: Inhala, 1: Sostén, 2: Exhala
  static const _phaseLabels = ['INHALA (4s)', 'SOSTÉN (4s)', 'EXHALA (4s)'];
  static const _phaseColors = [AppTheme.primary, AppTheme.accentEmerald, AppTheme.secondary];

  int _selectedKinestheticTab = 0; // 0: Respiración, 1: Hidratación, 2: Movilidad, 3: Estiramiento

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _breathController.reverse();
        } else if (status == AnimationStatus.dismissed) {
          _breathController.forward();
        }
      });
    _breathController.forward();

    _phaseTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) {
        setState(() {
          _phaseIndex = (_phaseIndex + 1) % _phaseLabels.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _breathController.dispose();
    _phaseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pomodoroProvider);
    final notifier = ref.read(pomodoroProvider.notifier);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.accentEmerald.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Break Phase Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentEmerald.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.accentEmerald,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'PAUSA ACTIVA DE DESACOPLE',
                      style: AppTheme.labelCaps(
                        fontSize: 10,
                        color: AppTheme.accentEmerald,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Sin pantallas',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Break Chronometer Dial
          Text(
            state.formattedTime,
            style: AppTheme.numeric(
              fontSize: 52,
              fontWeight: FontWeight.w800,
              color: AppTheme.onSurface,
              letterSpacing: -2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Protege tu memoria de trabajo: no abras feeds, correos ni mensajería.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),

          // Kinesthetic Activity Selector Tabs
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildTabButton(0, 'Respiración', Icons.air_rounded),
                _buildTabButton(1, 'Agua', Icons.water_drop_rounded),
                _buildTabButton(2, 'Movilidad', Icons.directions_walk_rounded),
                _buildTabButton(3, 'Estirar', Icons.fitness_center_rounded),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Content of Selected Kinesthetic Activity
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _buildKinestheticContent(_selectedKinestheticTab),
          ),
          const SizedBox(height: 24),

          // Skip Break Action Button
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: notifier.skipBreak,
                  icon: const Icon(Icons.skip_next_rounded, size: 20),
                  label: Text(
                    'Terminar Descanso • Siguiente Bloque',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.outlineVariant),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon) {
    final isSelected = _selectedKinestheticTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedKinestheticTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.surfaceContainerLowest : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? AppTheme.accentEmerald : AppTheme.onSurfaceVariant,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppTheme.accentEmerald : AppTheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKinestheticContent(int tabIndex) {
    switch (tabIndex) {
      case 0:
        // Guided Breathing Visualizer (reused from calming protocol)
        return Column(
          key: const ValueKey(0),
          children: [
            AnimatedBuilder(
              animation: _breathController,
              builder: (context, child) {
                final scale = 0.8 + (_breathController.value * 0.4);
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _phaseColors[_phaseIndex].withValues(alpha: 0.12),
                      border: Border.all(
                        color: _phaseColors[_phaseIndex].withValues(alpha: 0.4),
                        width: 3,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _phaseLabels[_phaseIndex],
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _phaseColors[_phaseIndex],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Text(
              'Respiración táctica 4-4-4: baja la frecuencia cardíaca y reinicia la corteza prefrontal.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ],
        );

      case 1:
        // Water Hydration Prompt
        return Container(
          key: const ValueKey(1),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.water_drop_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bebe 250 ml de agua fresca',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'La deshidratación de apenas un 1% reduce la agudeza mental y velocidad de procesamiento.',
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
        );

      case 2:
        // Movement Walk Prompt
        return Container(
          key: const ValueKey(2),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppTheme.accentEmerald,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.directions_walk_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Caminata corta de 2 minutos',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Levántate, mira por una ventana a la distancia para relajar los músculos ciliares oculares.',
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
        );

      default:
        // Stretch Prompt
        return Container(
          key: const ValueKey(3),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppTheme.secondary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.self_improvement_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Descompresión de cuello y hombros',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Rueda los hombros hacia atrás 5 veces y extiende los brazos hacia arriba abriendo el pecho.',
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
        );
    }
  }
}
