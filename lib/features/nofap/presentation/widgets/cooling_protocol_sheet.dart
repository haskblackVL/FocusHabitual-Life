import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme.dart';
import '../controllers/nofap_controller.dart';

/// Interactive 5-Step Emergency Cooling & Panic Protocol Sheet (SOS).
///
/// Steps:
/// 1. Guided 4-4-6 Tactical Breathing (with 15s lock to prevent impulsive dismissal)
/// 2. Cognitive Anchors (Personal reasons from nofap_reasons or defaults)
/// 3. Visual Streak & Progress (Reminder of what is at stake)
/// 4. Physical Replacement Actions (Walk, workout, call, cold water) + Success check-in (+15 XP)
/// 5. Honest Relapse Logging & Rebuilding (Non-judgmental reset with reason & trigger identification)
class CoolingProtocolSheet extends ConsumerStatefulWidget {
  const CoolingProtocolSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (_) => const CoolingProtocolSheet(),
    );
  }

  @override
  ConsumerState<CoolingProtocolSheet> createState() => _CoolingProtocolSheetState();
}

class _CoolingProtocolSheetState extends ConsumerState<CoolingProtocolSheet> {
  int _currentStep = 1;

  // Step 1: 4-4-6 Breathing (14-second cycle)
  static const int _breathCycleDuration = 14;
  int _elapsedBreathSeconds = 0;
  Timer? _breathTimer;
  bool _isBreathRunning = true;

  // Step 4: Selected replacement action
  int _selectedActionIndex = 0;
  bool _isSuccessCompleted = false;

  // Step 5: Honest relapse form
  String _selectedRelapseReason = 'both';
  String _selectedTrigger = 'Aburrimiento';
  final _noteController = TextEditingController();

  static const _defaultReasons = [
    'Quiero recuperar mi máxima claridad mental, energía y enfoque diario.',
    'Deseo gobernar mis impulsos en lugar de que un hábito automático me controle.',
    'Mi tiempo, dignidad y relaciones reales valen más que un atajo momentáneo.',
    'Construir la identidad de un hombre con dominio propio inquebrantable.',
  ];

  static const _replacementActions = [
    (
      icon: Icons.directions_walk_rounded,
      title: 'Caminar 5 minutos',
      subtitle: 'Sal de la habitación, cambia de entorno y respira aire fresco.',
    ),
    (
      icon: Icons.fitness_center_rounded,
      title: '20 flexiones o sentadillas',
      subtitle: 'Descarga física inmediata para transformar la energía motora.',
    ),
    (
      icon: Icons.chat_bubble_outline_rounded,
      title: 'Mensajear o llamar a alguien',
      subtitle: 'Conexión humana real para romper el aislamiento del impulso.',
    ),
    (
      icon: Icons.water_drop_rounded,
      title: 'Lavarse la cara con agua fría',
      subtitle: 'Choque térmico en el nervio vago para inducir calma fisiológica.',
    ),
  ];

  static const _relapseReasons = [
    ('masturbation', 'Solo masturbación (sin pornografía)'),
    ('porn', 'Consumo de pornografía'),
    ('both', 'Ambos (pornografía y masturbación)'),
  ];

  static const _commonTriggers = [
    'Aburrimiento',
    'Estrés / Ansiedad',
    'Soledad',
    'Cansancio / Insomnio',
    'Celular en la cama',
  ];

  @override
  void initState() {
    super.initState();
    _startBreathTimer();
  }

  @override
  void dispose() {
    _breathTimer?.cancel();
    _noteController.dispose();
    super.dispose();
  }

  void _startBreathTimer() {
    _breathTimer?.cancel();
    _breathTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _elapsedBreathSeconds++;
      });
    });
  }

  void _toggleBreathPause() {
    setState(() {
      _isBreathRunning = !_isBreathRunning;
      if (_isBreathRunning) {
        _startBreathTimer();
      } else {
        _breathTimer?.cancel();
      }
    });
  }

  // 4-4-6 Breathing: 0..4s Inhale, 4..8s Hold, 8..14s Exhale
  int get _breathTick => _elapsedBreathSeconds % _breathCycleDuration;

  String get _breathingPhaseText {
    if (_breathTick < 4) {
      return 'Inhala profundamente por la nariz (4s)';
    } else if (_breathTick < 8) {
      return 'Retén el aire con serenidad (4s)';
    } else {
      return 'Exhala suave y lento por la boca (6s)';
    }
  }

  double get _breathingScale {
    if (_breathTick < 4) {
      return 1.0 + (_breathTick / 4.0) * 0.28;
    } else if (_breathTick < 8) {
      return 1.28;
    } else {
      return 1.28 - ((_breathTick - 8) / 6.0) * 0.28;
    }
  }

  Color get _breathingPhaseColor {
    if (_breathTick < 4) return AppTheme.primary;
    if (_breathTick < 8) return AppTheme.secondary;
    return AppTheme.accentEmerald;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            // Drag handle
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),

            // Top Header: Step Indicator & Close
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'SOS • PASO $_currentStep DE 5',
                      style: AppTheme.labelCaps(
                        fontSize: 10,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: AppTheme.onSurfaceVariant,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // Progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: _currentStep / 5.0,
                  minHeight: 3,
                  backgroundColor: AppTheme.surfaceContainerHigh,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Flexible Body Content based on _currentStep
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildCurrentStepContent(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStepContent(BuildContext context) {
    switch (_currentStep) {
      case 1:
        return _buildStep1Breathing(context);
      case 2:
        return _buildStep2Reasons(context);
      case 3:
        return _buildStep3Progress(context);
      case 4:
        return _buildStep4Actions(context);
      case 5:
        return _buildStep5HonestRelapse(context);
      default:
        return _buildStep1Breathing(context);
    }
  }

  // ---------------------------------------------------------------------------
  // STEP 1: Tactical Breathing 4-4-6 (with 15s lock)
  // ---------------------------------------------------------------------------
  Widget _buildStep1Breathing(BuildContext context) {
    final canSkip = _elapsedBreathSeconds >= 15;
    final lockRemaining = 15 - _elapsedBreathSeconds;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'RESPIRACIÓN TÁCTICA 4-4-6',
          style: AppTheme.labelCaps(
            fontSize: 11,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '«Esto va a pasar. No tienes que actuar ahora.»',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Baja el ritmo cardíaco y desconecta el impulso automático de tu cerebro.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),

        // Animated Breathing Visualizer
        Stack(
          alignment: Alignment.center,
          children: [
            AnimatedScale(
              scale: _breathingScale,
              duration: const Duration(seconds: 1),
              curve: Curves.easeInOut,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  color: _breathingPhaseColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _breathingPhaseColor.withValues(alpha: 0.35),
                    width: 2,
                  ),
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_elapsedBreathSeconds}s',
                  style: AppTheme.numeric(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'RESPIRANDO',
                  style: AppTheme.labelCaps(
                    fontSize: 9,
                    color: AppTheme.outline,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 22),

        // Phase pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.surfaceContainerHigh),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _breathingPhaseColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _breathingPhaseText,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Action Buttons
        Row(
          children: [
            IconButton.outlined(
              onPressed: _toggleBreathPause,
              icon: Icon(
                _isBreathRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 20,
              ),
              color: AppTheme.onSurface,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: canSkip ? () => setState(() => _currentStep = 2) : null,
                icon: Icon(
                  canSkip ? Icons.arrow_forward_rounded : Icons.lock_clock_rounded,
                  size: 18,
                ),
                label: Text(
                  canSkip
                      ? 'Continuar a mis Razones'
                      : 'Respira ${lockRemaining}s más...',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 2: Personal Reasons (Anclaje Cognitivo)
  // ---------------------------------------------------------------------------
  Widget _buildStep2Reasons(BuildContext context) {
    final reasonsAsync = ref.watch(nofapReasonsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'ANCLAJES COGNITIVOS',
          style: AppTheme.labelCaps(
            fontSize: 11,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '¿Por qué decidiste este camino?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'La motivación racional se debilita en el pico del impulso. Lee tus motivos con atención:',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),

        reasonsAsync.when(
          data: (reasons) {
            final list = reasons.isNotEmpty
                ? reasons.map((r) => r.reasonText).toList()
                : _defaultReasons;

            return Column(
              children: list.take(3).map((text) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.surfaceContainerHigh),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        size: 18,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          text,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onSurface,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (_, _) => Column(
            children: _defaultReasons.map((text) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.surfaceContainerHigh),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, size: 18, color: AppTheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      text,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ),

        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => setState(() => _currentStep = 3),
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: const Text('Siguiente: Ver mi Progreso'),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 3: Current Streak & Progress (Lo que está en juego)
  // ---------------------------------------------------------------------------
  Widget _buildStep3Progress(BuildContext context) {
    final streak = ref.watch(nofapControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'LO QUE HAS CONSTRUIDO',
          style: AppTheme.labelCaps(
            fontSize: 11,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tu tiempo de maestría acumulado',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurface,
          ),
        ),
        const SizedBox(height: 20),

        // Big Numbers Box
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.surfaceContainerHigh),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildProgressUnit(streak.daysDisplay, 'DÍAS'),
              Container(width: 1, height: 36, color: AppTheme.surfaceContainerHigh),
              _buildProgressUnit(streak.hoursDisplay, 'HORAS'),
              Container(width: 1, height: 36, color: AppTheme.surfaceContainerHigh),
              _buildProgressUnit(streak.minutesDisplay, 'MINUTOS'),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // 90-Day Progress
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Meta de Recalibración (90 días)',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurface,
              ),
            ),
            Text(
              '${streak.percent90Days}%',
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
            value: streak.progress90Days,
            minHeight: 8,
            backgroundColor: AppTheme.surfaceContainerHigh,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
          ),
        ),
        const SizedBox(height: 20),

        // Contextual reminder
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '«Llevas ${streak.days} días firmes. El impulso que sientes no es permanente; tiene un pico y descenderá en cuestión de minutos si no lo alimentas.»',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              height: 1.4,
              fontStyle: FontStyle.italic,
              color: AppTheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 22),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => setState(() => _currentStep = 4),
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: const Text('Elegir Acción de Reemplazo'),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildProgressUnit(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: AppTheme.numeric(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppTheme.primary,
          ),
        ),
        Text(
          label,
          style: AppTheme.labelCaps(fontSize: 9, color: AppTheme.outline),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 4: Physical Replacement Action (Interrumpir el patrón)
  // ---------------------------------------------------------------------------
  Widget _buildStep4Actions(BuildContext context) {
    if (_isSuccessCompleted) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: AppTheme.accentEmerald.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              size: 46,
              color: AppTheme.accentEmerald,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '¡Impulso Superado!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Mantuviste el gobierno sobre tu voluntad.\nSe han acreditado +15 XP a tu cuenta.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppTheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Volver al Panel Principal'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'INTERRUMPE EL PATRÓN FÍSICO',
          style: AppTheme.labelCaps(
            fontSize: 11,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Elige una acción de reemplazo',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'El impulso es energía motora acumulada. Desplázala hacia una actividad física concreta:',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),

        // Action selection cards
        ...List.generate(_replacementActions.length, (idx) {
          final action = _replacementActions[idx];
          final isSelected = _selectedActionIndex == idx;

          return GestureDetector(
            onTap: () => setState(() => _selectedActionIndex = idx),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primary.withValues(alpha: 0.05)
                    : AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppTheme.primary : AppTheme.surfaceContainerHigh,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primary.withValues(alpha: 0.12)
                          : AppTheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      action.icon,
                      size: 20,
                      color: isSelected ? AppTheme.primary : AppTheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          action.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onSurface,
                          ),
                        ),
                        Text(
                          action.subtitle,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 20),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 14),

        // Primary: "Ya pasó el impulso"
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentEmerald,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () {
              ref.read(nofapControllerProvider.notifier).recordCoolingCompleted();
              setState(() => _isSuccessCompleted = true);
            },
            icon: const Icon(Icons.sentiment_very_satisfied_rounded, size: 18),
            label: const Text('¡Ya pasó el impulso! (+15 XP)'),
          ),
        ),
        const SizedBox(height: 10),

        // Fallback: "No funcionó / Aún siento la urgencia"
        Center(
          child: TextButton(
            onPressed: () => setState(() => _currentStep = 5),
            style: TextButton.styleFrom(foregroundColor: AppTheme.outline),
            child: Text(
              'Aún siento el impulso / Necesito registrar honestamente',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 5: Honest Relapse & Rebuilding
  // ---------------------------------------------------------------------------
  Widget _buildStep5HonestRelapse(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'RECONOCIMIENTO HONESTO',
          style: AppTheme.labelCaps(
            fontSize: 11,
            color: AppTheme.error,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'El reinicio es parte del aprendizaje',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.surfaceContainerHigh),
          ),
          child: Text(
            '«Reiniciar el contador no borra tu progreso ni el entendimiento acumulado. Identificar qué disparador te afectó te permite blindar tu entorno para la próxima vez.»',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              height: 1.4,
              color: AppTheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 16),

        Text(
          'Motivo principal del evento:',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        ...List.generate(_relapseReasons.length, (i) {
          final item = _relapseReasons[i];
          final isSelected = _selectedRelapseReason == item.$1;

          return InkWell(
            onTap: () => setState(() => _selectedRelapseReason = item.$1),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppTheme.error : AppTheme.outline,
                        width: isSelected ? 5 : 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.$2,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? AppTheme.onSurface : AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 10),

        Text(
          '¿Cuál fue el disparador inmediato?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: _commonTriggers.map((trig) {
            final isSelected = _selectedTrigger == trig;
            return ChoiceChip(
              label: Text(trig),
              selected: isSelected,
              labelStyle: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.white : AppTheme.onSurface,
              ),
              selectedColor: AppTheme.onSurface,
              backgroundColor: AppTheme.surfaceContainerLow,
              onSelected: (_) => setState(() => _selectedTrigger = trig),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),

        TextField(
          controller: _noteController,
          maxLines: 2,
          style: GoogleFonts.plusJakartaSans(fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Nota o reflexión para blindar tu entorno (opcional)',
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppTheme.outline,
            ),
            filled: true,
            fillColor: AppTheme.surfaceContainerLow,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppTheme.surfaceContainerHigh),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep = 4),
                child: const Text('Volver a Intentar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                onPressed: () async {
                  await ref.read(nofapControllerProvider.notifier).recordRelapse(
                        reason: _selectedRelapseReason,
                        trigger: _selectedTrigger,
                        note: _noteController.text.trim(),
                      );
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Contador reiniciado. La maestría se forja en la constancia.'),
                      ),
                    );
                  }
                },
                child: const Text('Reiniciar a 0'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
