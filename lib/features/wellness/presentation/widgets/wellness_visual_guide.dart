import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme.dart';
import '../../domain/challenge_data.dart';

/// Archetypes for visual posture schematics.
enum YogaArchetype {
  warrior,
  plankCore,
  downwardDog,
  backbend,
  balanceTree,
  seatedTwist,
  restChild,
  general,
}

enum FacialZoneArchetype {
  forehead,
  eyes,
  cheeks,
  jawline,
  lips,
  neck,
  general,
}

/// Executive Visual Guide & Anatomical Illustration for Yoga Asanas and Face Yoga routines.
/// Renders custom vector-based anatomical alignment schematics, focus zones,
/// execution checkpoints, and animated breathing cadence.
class WellnessVisualGuideWidget extends StatefulWidget {
  final String title;
  final String category;
  final ChallengeType challengeType;
  final bool compact;

  const WellnessVisualGuideWidget({
    super.key,
    required this.title,
    required this.category,
    required this.challengeType,
    this.compact = false,
  });

  @override
  State<WellnessVisualGuideWidget> createState() => _WellnessVisualGuideWidgetState();
}

class _WellnessVisualGuideWidgetState extends State<WellnessVisualGuideWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  YogaArchetype _detectYogaArchetype(String title, String category) {
    final lower = '$title $category'.toLowerCase();
    if (lower.contains('guerrero') || lower.contains('virabhadrasana') || lower.contains('silla') || lower.contains('utkatasana') || lower.contains('trikonasana')) {
      return YogaArchetype.warrior;
    }
    if (lower.contains('plancha') || lower.contains('phalakasana') || lower.contains('chaturanga') || lower.contains('vasisthasana') || lower.contains('cuervo') || lower.contains('bakasana')) {
      return YogaArchetype.plankCore;
    }
    if (lower.contains('perro') || lower.contains('adho mukha') || lower.contains('delfín') || lower.contains('inversión')) {
      return YogaArchetype.downwardDog;
    }
    if (lower.contains('cobra') || lower.contains('bhujangasana') || lower.contains('puente') || lower.contains('camello') || lower.contains('rueda')) {
      return YogaArchetype.backbend;
    }
    if (lower.contains('árbol') || lower.contains('vrikshasana') || lower.contains('equilibrio') || lower.contains('garuda')) {
      return YogaArchetype.balanceTree;
    }
    if (lower.contains('torsión') || lower.contains('matsyendrasana') || lower.contains('sentad')) {
      return YogaArchetype.seatedTwist;
    }
    if (lower.contains('niño') || lower.contains('balasana') || lower.contains('savasana') || lower.contains('relajación') || lower.contains('descanso')) {
      return YogaArchetype.restChild;
    }
    return YogaArchetype.general;
  }

  FacialZoneArchetype _detectFacialZone(String title, String category) {
    final lower = '$title $category'.toLowerCase();
    if (lower.contains('frente') || lower.contains('entrecejo') || lower.contains('alisado')) {
      return FacialZoneArchetype.forehead;
    }
    if (lower.contains('ojo') || lower.contains('párpado') || lower.contains('mirada') || lower.contains('ojera')) {
      return FacialZoneArchetype.eyes;
    }
    if (lower.contains('pómulo') || lower.contains('mejilla') || lower.contains('lifting') || lower.contains('sonrisa')) {
      return FacialZoneArchetype.cheeks;
    }
    if (lower.contains('mandíbula') || lower.contains('papada') || lower.contains('mentón') || lower.contains('v-line')) {
      return FacialZoneArchetype.jawline;
    }
    if (lower.contains('labio') || lower.contains('beso') || lower.contains('nasogeniano') || lower.contains('boca')) {
      return FacialZoneArchetype.lips;
    }
    if (lower.contains('cuello') || lower.contains('platisma') || lower.contains('escote')) {
      return FacialZoneArchetype.neck;
    }
    return FacialZoneArchetype.general;
  }

  @override
  Widget build(BuildContext context) {
    final isYoga = widget.challengeType == ChallengeType.yoga;
    final isMeditation = widget.challengeType == ChallengeType.meditation;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(widget.compact ? 12 : 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceContainerHigh, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isMeditation
                        ? Icons.self_improvement_rounded
                        : (isYoga ? Icons.accessibility_new_rounded : Icons.face_retouching_natural_rounded),
                    size: 16,
                    color: AppTheme.primaryContainer,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isMeditation
                        ? 'ILUSTRACIÓN DEMOSTRATIVA & ENFOQUE'
                        : (isYoga ? 'GUÍA ANATÓMICA Y POSTURAL' : 'MAPA DE ZONA FACIAL Y LIFTING'),
                    style: AppTheme.labelCaps(
                      color: AppTheme.onSurfaceVariant,
                      letterSpacing: 0.08,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.category.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Central Illustration / Schematic Box
          Container(
            height: isMeditation ? (widget.compact ? 140 : 180) : (widget.compact ? 120 : 155),
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.surfaceContainerLow.withValues(alpha: 0.7),
                  AppTheme.surfaceContainerHighest.withValues(alpha: 0.4),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.6)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  if (isMeditation) ...[
                    // High-resolution Executive Illustration
                    Positioned.fill(
                      child: Image.asset(
                        'assets/images/meditation_guide.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Center(
                          child: Icon(Icons.self_improvement_rounded, size: 64, color: AppTheme.primaryContainer),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.7),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Animated Custom Painter
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: isYoga
                                ? _YogaSchematicPainter(
                                    archetype: _detectYogaArchetype(widget.title, widget.category),
                                    pulse: _pulseController.value,
                                  )
                                : _FacialSchematicPainter(
                                    zone: _detectFacialZone(widget.title, widget.category),
                                    pulse: _pulseController.value,
                                  ),
                          );
                        },
                      ),
                    ),
                  ],

                  // Floating Target Chip on top-left of schematic
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerLowest.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.surfaceContainerHigh),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppTheme.accentEmerald,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isMeditation
                                ? 'ONDAS ALFA · CALMA & CLARIDAD'
                                : (isYoga
                                    ? _getYogaTargetMuscle(_detectYogaArchetype(widget.title, widget.category))
                                    : _getFacialZoneLabel(_detectFacialZone(widget.title, widget.category))),
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Breathing / Cadence badge on bottom-right
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerLowest.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.surfaceContainerHigh),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.air_rounded, size: 12, color: AppTheme.primaryContainer),
                          const SizedBox(width: 4),
                          Text(
                            isMeditation
                                ? 'Inhala 4s · Retén 4s · Exhala 4s'
                                : (isYoga ? 'Ritmo 4s · 4s' : 'Presión suave'),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 3 Executive Alignment / Execution Checkpoints
          if (!widget.compact) ...[
            Text(
              'PUNTOS CLAVE DE EJECUCIÓN TÉCNICA',
              style: AppTheme.labelCaps(
                color: AppTheme.onSurfaceVariant,
                letterSpacing: 0.08,
              ),
            ),
            const SizedBox(height: 8),
            _buildCheckpoints(widget.challengeType),
          ],
        ],
      ),
    );
  }

  Widget _buildCheckpoints(ChallengeType challengeType) {
    final List<String> checkpoints;
    if (challengeType == ChallengeType.meditation) {
      checkpoints = const [
        'Postura de meditación erguida: columna recta, hombros relajados y barbilla recogida.',
        'Atención anclada al ritmo continuo de la respiración diafragmática.',
        'Actitud de observador neutral: reconoce pensamientos sin juzgar ni distraerte.',
        'Regulación del sistema nervioso parasimpático y reducción sostenida de cortisol.',
      ];
    } else if (challengeType == ChallengeType.yoga) {
      checkpoints = _getYogaCheckpoints(_detectYogaArchetype(widget.title, widget.category));
    } else {
      checkpoints = _getFacialCheckpoints(_detectFacialZone(widget.title, widget.category));
    }

    return Column(
      children: checkpoints.map((cp) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 3, right: 8),
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Text(
                  cp,
                  style: GoogleFonts.inter(
                    fontSize: 12,
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
  }

  String _getYogaTargetMuscle(YogaArchetype archetype) {
    return switch (archetype) {
      YogaArchetype.warrior => 'Core & Cuádriceps',
      YogaArchetype.plankCore => 'Core Isométrico & Deltoides',
      YogaArchetype.downwardDog => 'Isquiotibiales & Espalda',
      YogaArchetype.backbend => 'Cadena Posterior & Pectoral',
      YogaArchetype.balanceTree => 'Estabilidad Pélvica & Tobillos',
      YogaArchetype.seatedTwist => 'Columna Torácica & Oblicuos',
      YogaArchetype.restChild => 'Descompresión Lumbar',
      YogaArchetype.general => 'Alineación Global',
    };
  }

  List<String> _getYogaCheckpoints(YogaArchetype archetype) {
    return switch (archetype) {
      YogaArchetype.warrior => [
        'Cadera encuadrada hacia el frente, rodilla delantera a 90° sin sobrepasar tobillo.',
        'Extiende la columna elevando el esternón y relajando los hombros.',
        'Distribuye el peso equitativamente entre ambos pies (arco activo).',
      ],
      YogaArchetype.plankCore => [
        'Muñecas alineadas verticalmente bajo hombros, dedos abiertos firmes en el tapete.',
        'Pelvis neutra sin colapsar zona lumbar; abdomen y glúteos firmes.',
        'Cuello alargado manteniendo mirada diagonal al suelo.',
      ],
      YogaArchetype.downwardDog => [
        'Empuja las caderas hacia arriba y atrás creando una forma en V invertida.',
        'Prioriza alargar la columna vertebral antes de tocar el suelo con talones.',
        'Resta tensión al cuello permitiendo que la cabeza cuelgue relajada.',
      ],
      YogaArchetype.backbend => [
        'Inicia la curvatura desde la zona torácica sin forzar las lumbares.',
        'Contrae glúteos suavemente para proteger la base de la columna.',
        'Hombros rotados hacia atrás y abajo, lejos de los oídos.',
      ],
      YogaArchetype.balanceTree => [
        'Fija la mirada en un punto inmóvil al frente (drishti) para balance.',
        'Presiona la planta del pie levantado contra pantorrilla o muslo (nunca rodilla).',
        'Centro abdominal activo para sostener el eje vertical.',
      ],
      YogaArchetype.seatedTwist => [
        'Inhala alargando la coronilla hacia el techo antes de comenzar a rotar.',
        'Inicia la torsión desde el ombligo, luego costillas, hombros y cuello.',
        'Ambos isquiones permanecen firmemente apoyados en el suelo.',
      ],
      YogaArchetype.restChild => [
        'Caderas descansando sobre los talones, frente suavemente sobre el tapete.',
        'Brazos extendidos al frente o descansando a los lados del torso.',
        'Inhalaciones profundas expandiendo las costillas posteriores.',
      ],
      YogaArchetype.general => [
        'Mantén una respiración rítmica y controlada por la nariz.',
        'Escucha los límites de tu cuerpo; el estiramiento debe ser activo sin dolor punzante.',
        'Sostén la alineación axial con el centro del cuerpo encendido.',
      ],
    };
  }

  String _getFacialZoneLabel(FacialZoneArchetype zone) {
    return switch (zone) {
      FacialZoneArchetype.forehead => 'Zona Frontal & Entrecejo',
      FacialZoneArchetype.eyes => 'Zona Periocular & Párpados',
      FacialZoneArchetype.cheeks => 'Cigomáticos & Pómulos',
      FacialZoneArchetype.jawline => 'Línea Mandibular & Mentón',
      FacialZoneArchetype.lips => 'Zona Peribucal & Labios',
      FacialZoneArchetype.neck => 'Platisma & Esternocleidomastoideo',
      FacialZoneArchetype.general => 'Drenaje Linfático Facial',
    };
  }

  List<String> _getFacialCheckpoints(FacialZoneArchetype zone) {
    return switch (zone) {
      FacialZoneArchetype.forehead => [
        'Desliza los dedos suavemente del centro hacia las sienes sin jalar piel.',
        'Relaja activamente el músculo corrugador del entrecejo.',
        'Mantén la espalda erguida y los hombros abajo para evitar compensaciones.',
      ],
      FacialZoneArchetype.eyes => [
        'Usa únicamente el dedo anular para aplicar una presión delicada.',
        'Realiza toques o movimientos circulares drenando hacia los lagrimales y sienes.',
        'Evita estirar la piel fina del párpado inferior.',
      ],
      FacialZoneArchetype.cheeks => [
        'Aplica movimientos ascendentes desde las comisuras labiales hacia los pómulos.',
        'Contrae suavemente los músculos de la sonrisa manteniendo resistencia con los dedos.',
        'Respira con calma manteniendo la mandíbula relajada.',
      ],
      FacialZoneArchetype.jawline => [
        'Pinza suavemente con los nudillos desde la barbilla hacia los lóbulos de las orejas.',
        'Promueve el drenaje linfático hacia los ganglios retroauriculares.',
        'Mantén la lengua apoyada en el paladar para tonificar el suelo de la boca.',
      ],
      FacialZoneArchetype.lips => [
        'Forma una "O" firme cubriendo los dientes con los labios sin arrugar comisuras.',
        'Presiona suavemente los surcos nasogenianos para suavizar líneas de expresión.',
        'Sostén la contracción isométrica durante el intervalo completo.',
      ],
      FacialZoneArchetype.neck => [
        'Inclina la cabeza ligeramente hacia atrás y proyecta el mentón hacia el techo.',
        'Siente la tensión placentera a lo largo del músculo platisma sin colapsar cervicales.',
        'Desliza las manos hacia las clavículas para completar el drenaje.',
      ],
      FacialZoneArchetype.general => [
        'Piel y manos limpias; se recomienda una gota de aceite facial para deslizamiento.',
        'Aplica presión uniforme y moderada; nunca debe generar dolor ni enrojecimiento severo.',
        'Ejecuta con respiración nasal lenta y consciente.',
      ],
    };
  }
}

/// Custom painter for Yoga Posture vector silhouettes.
class _YogaSchematicPainter extends CustomPainter {
  final YogaArchetype archetype;
  final double pulse;

  _YogaSchematicPainter({required this.archetype, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final basePaint = Paint()
      ..color = AppTheme.primaryContainer.withValues(alpha: 0.85)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = AppTheme.primaryContainer.withValues(alpha: 0.15 + (pulse * 0.15))
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final floorPaint = Paint()
      ..color = AppTheme.surfaceContainerHigh
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Floor baseline
    final floorY = size.height - 18;
    canvas.drawLine(Offset(size.width * 0.15, floorY), Offset(size.width * 0.85, floorY), floorPaint);

    switch (archetype) {
      case YogaArchetype.warrior:
        _drawWarrior(canvas, cx, cy, floorY, basePaint, glowPaint);
        break;
      case YogaArchetype.plankCore:
        _drawPlank(canvas, cx, cy, floorY, basePaint, glowPaint);
        break;
      case YogaArchetype.downwardDog:
        _drawDownwardDog(canvas, cx, cy, floorY, basePaint, glowPaint);
        break;
      case YogaArchetype.backbend:
        _drawCobra(canvas, cx, cy, floorY, basePaint, glowPaint);
        break;
      case YogaArchetype.balanceTree:
        _drawTree(canvas, cx, cy, floorY, basePaint, glowPaint);
        break;
      default:
        _drawWarrior(canvas, cx, cy, floorY, basePaint, glowPaint);
    }
  }

  void _drawWarrior(Canvas canvas, double cx, double cy, double floorY, Paint base, Paint glow) {
    // Head
    canvas.drawCircle(Offset(cx, cy - 35), 8, base..style = PaintingStyle.fill);
    base.style = PaintingStyle.stroke;

    // Torso
    final spine = Path()
      ..moveTo(cx, cy - 27)
      ..lineTo(cx, cy + 10);
    canvas.drawPath(spine, glow);
    canvas.drawPath(spine, base);

    // Arms horizontal
    final arms = Path()
      ..moveTo(cx - 38, cy - 18)
      ..lineTo(cx + 38, cy - 18);
    canvas.drawPath(arms, base);

    // Front bent leg
    final frontLeg = Path()
      ..moveTo(cx, cy + 10)
      ..lineTo(cx + 26, cy + 24)
      ..lineTo(cx + 26, floorY);
    canvas.drawPath(frontLeg, glow);
    canvas.drawPath(frontLeg, base);

    // Back extended leg
    final backLeg = Path()
      ..moveTo(cx, cy + 10)
      ..lineTo(cx - 36, floorY);
    canvas.drawPath(backLeg, base);
  }

  void _drawPlank(Canvas canvas, double cx, double cy, double floorY, Paint base, Paint glow) {
    // Head
    canvas.drawCircle(Offset(cx + 38, cy - 16), 8, base..style = PaintingStyle.fill);
    base.style = PaintingStyle.stroke;

    // Body straight line
    final body = Path()
      ..moveTo(cx + 32, cy - 10)
      ..lineTo(cx - 40, floorY);
    canvas.drawPath(body, glow);
    canvas.drawPath(body, base);

    // Front arms supporting
    final arms = Path()
      ..moveTo(cx + 26, cy - 7)
      ..lineTo(cx + 26, floorY);
    canvas.drawPath(arms, base);
  }

  void _drawDownwardDog(Canvas canvas, double cx, double cy, double floorY, Paint base, Paint glow) {
    // Inverted V shape
    final peak = Offset(cx, cy - 30);
    final hands = Offset(cx + 42, floorY);
    final feet = Offset(cx - 42, floorY);

    // Spine & Arms
    final front = Path()
      ..moveTo(peak.dx, peak.dy)
      ..lineTo(hands.dx, hands.dy);
    canvas.drawPath(front, glow);
    canvas.drawPath(front, base);

    // Back & Legs
    final back = Path()
      ..moveTo(peak.dx, peak.dy)
      ..lineTo(feet.dx, feet.dy);
    canvas.drawPath(back, base);

    // Head
    canvas.drawCircle(Offset(cx + 14, cy - 14), 7, base..style = PaintingStyle.fill);
    base.style = PaintingStyle.stroke;
  }

  void _drawCobra(Canvas canvas, double cx, double cy, double floorY, Paint base, Paint glow) {
    // Head
    canvas.drawCircle(Offset(cx - 24, cy - 32), 8, base..style = PaintingStyle.fill);
    base.style = PaintingStyle.stroke;

    // Arching spine
    final arch = Path()
      ..moveTo(cx - 20, cy - 24)
      ..quadraticBezierTo(cx - 10, cy, cx + 45, floorY);
    canvas.drawPath(arch, glow);
    canvas.drawPath(arch, base);

    // Arm support
    final arms = Path()
      ..moveTo(cx - 16, cy - 10)
      ..lineTo(cx - 16, floorY);
    canvas.drawPath(arms, base);
  }

  void _drawTree(Canvas canvas, double cx, double cy, double floorY, Paint base, Paint glow) {
    // Head
    canvas.drawCircle(Offset(cx, cy - 38), 8, base..style = PaintingStyle.fill);
    base.style = PaintingStyle.stroke;

    // Spine
    final spine = Path()
      ..moveTo(cx, cy - 30)
      ..lineTo(cx, cy + 10);
    canvas.drawPath(spine, glow);
    canvas.drawPath(spine, base);

    // Namaste Arms overhead
    final arms = Path()
      ..moveTo(cx - 16, cy - 18)
      ..lineTo(cx, cy - 50)
      ..lineTo(cx + 16, cy - 18);
    canvas.drawPath(arms, base);

    // Standing straight leg
    final standingLeg = Path()
      ..moveTo(cx, cy + 10)
      ..lineTo(cx, floorY);
    canvas.drawPath(standingLeg, base);

    // Bent tree leg
    final bentLeg = Path()
      ..moveTo(cx, cy + 10)
      ..lineTo(cx + 22, cy + 22)
      ..lineTo(cx, cy + 30);
    canvas.drawPath(bentLeg, glow);
    canvas.drawPath(bentLeg, base);
  }

  @override
  bool shouldRepaint(covariant _YogaSchematicPainter oldDelegate) {
    return oldDelegate.pulse != pulse || oldDelegate.archetype != archetype;
  }
}

/// Custom painter for Face Yoga zone mapping & lifting arrows.
class _FacialSchematicPainter extends CustomPainter {
  final FacialZoneArchetype zone;
  final double pulse;

  _FacialSchematicPainter({required this.zone, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final outlinePaint = Paint()
      ..color = AppTheme.onSurfaceVariant.withValues(alpha: 0.35)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final zoneGlowPaint = Paint()
      ..color = AppTheme.primaryContainer.withValues(alpha: 0.2 + (pulse * 0.25))
      ..style = PaintingStyle.fill;

    final vectorArrowPaint = Paint()
      ..color = AppTheme.accentEmerald
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Face Oval Contour
    final faceRect = Rect.fromCenter(center: Offset(cx, cy - 4), width: 78, height: 104);
    canvas.drawOval(faceRect, outlinePaint);

    // Neck lines
    canvas.drawLine(Offset(cx - 18, cy + 42), Offset(cx - 24, cy + 62), outlinePaint);
    canvas.drawLine(Offset(cx + 18, cy + 42), Offset(cx + 24, cy + 62), outlinePaint);

    // Eyes reference lines
    canvas.drawLine(Offset(cx - 24, cy - 10), Offset(cx - 8, cy - 10), outlinePaint);
    canvas.drawLine(Offset(cx + 8, cy - 10), Offset(cx + 24, cy - 10), outlinePaint);

    // Mouth reference line
    canvas.drawLine(Offset(cx - 14, cy + 24), Offset(cx + 14, cy + 24), outlinePaint);

    // Draw active zone highlight and lifting motion arrows
    switch (zone) {
      case FacialZoneArchetype.forehead:
        final foreheadRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - 30, cy - 48, 60, 24),
          const Radius.circular(8),
        );
        canvas.drawRRect(foreheadRect, zoneGlowPaint);
        _drawLiftingArrow(canvas, Offset(cx - 15, cy - 36), Offset(cx - 32, cy - 44), vectorArrowPaint);
        _drawLiftingArrow(canvas, Offset(cx + 15, cy - 36), Offset(cx + 32, cy - 44), vectorArrowPaint);
        break;

      case FacialZoneArchetype.eyes:
        canvas.drawCircle(Offset(cx - 16, cy - 10), 12, zoneGlowPaint);
        canvas.drawCircle(Offset(cx + 16, cy - 10), 12, zoneGlowPaint);
        _drawLiftingArrow(canvas, Offset(cx - 22, cy - 10), Offset(cx - 34, cy - 16), vectorArrowPaint);
        _drawLiftingArrow(canvas, Offset(cx + 22, cy - 10), Offset(cx + 34, cy - 16), vectorArrowPaint);
        break;

      case FacialZoneArchetype.cheeks:
        canvas.drawOval(Rect.fromLTWH(cx - 32, cy, 22, 22), zoneGlowPaint);
        canvas.drawOval(Rect.fromLTWH(cx + 10, cy, 22, 22), zoneGlowPaint);
        _drawLiftingArrow(canvas, Offset(cx - 20, cy + 12), Offset(cx - 32, cy - 6), vectorArrowPaint);
        _drawLiftingArrow(canvas, Offset(cx + 20, cy + 12), Offset(cx + 32, cy - 6), vectorArrowPaint);
        break;

      case FacialZoneArchetype.jawline:
        final jawPath = Path()
          ..moveTo(cx - 34, cy + 15)
          ..quadraticBezierTo(cx, cy + 50, cx + 34, cy + 15)
          ..quadraticBezierTo(cx, cy + 42, cx - 34, cy + 15);
        canvas.drawPath(jawPath, zoneGlowPaint);
        _drawLiftingArrow(canvas, Offset(cx - 6, cy + 40), Offset(cx - 32, cy + 22), vectorArrowPaint);
        _drawLiftingArrow(canvas, Offset(cx + 6, cy + 40), Offset(cx + 32, cy + 22), vectorArrowPaint);
        break;

      case FacialZoneArchetype.lips:
        canvas.drawCircle(Offset(cx, cy + 24), 16, zoneGlowPaint);
        _drawLiftingArrow(canvas, Offset(cx - 12, cy + 24), Offset(cx - 24, cy + 16), vectorArrowPaint);
        _drawLiftingArrow(canvas, Offset(cx + 12, cy + 24), Offset(cx + 24, cy + 16), vectorArrowPaint);
        break;

      case FacialZoneArchetype.neck:
        final neckRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - 20, cy + 44, 40, 22),
          const Radius.circular(6),
        );
        canvas.drawRRect(neckRect, zoneGlowPaint);
        _drawLiftingArrow(canvas, Offset(cx, cy + 62), Offset(cx, cy + 44), vectorArrowPaint);
        break;

      default:
        canvas.drawOval(faceRect, zoneGlowPaint);
    }
  }

  void _drawLiftingArrow(Canvas canvas, Offset from, Offset to, Paint paint) {
    canvas.drawLine(from, to, paint);
    // Draw arrowhead
    final angle = math.atan2(to.dy - from.dy, to.dx - from.dx);
    const arrowSize = 6.0;
    final p1 = Offset(
      to.dx - arrowSize * math.cos(angle - math.pi / 6),
      to.dy - arrowSize * math.sin(angle - math.pi / 6),
    );
    final p2 = Offset(
      to.dx - arrowSize * math.cos(angle + math.pi / 6),
      to.dy - arrowSize * math.sin(angle + math.pi / 6),
    );
    canvas.drawLine(to, p1, paint);
    canvas.drawLine(to, p2, paint);
  }

  @override
  bool shouldRepaint(covariant _FacialSchematicPainter oldDelegate) {
    return oldDelegate.pulse != pulse || oldDelegate.zone != zone;
  }
}
