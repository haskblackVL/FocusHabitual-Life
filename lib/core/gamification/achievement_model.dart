import 'package:flutter/material.dart';

/// Module categories for unified gamification achievements.
enum AchievementModule {
  habits(key: 'habits', displayName: 'Hábitos & Rutinas', icon: Icons.check_circle_outline_rounded),
  pomodoro(key: 'pomodoro', displayName: 'Enfoque & Pomodoro', icon: Icons.timer_outlined),
  wellness(key: 'wellness', displayName: 'Salud & Vitalidad', icon: Icons.water_drop_outlined),
  challenges(key: 'challenges', displayName: 'Retos 21D (Yoga/Facial)', icon: Icons.self_improvement_rounded),
  nofap(key: 'nofap', displayName: 'Autodominio', icon: Icons.shield_outlined),
  cycle(key: 'cycle', displayName: 'Ciclo & Armonía', icon: Icons.spa_outlined),
  religion(key: 'religion', displayName: 'Espiritualidad', icon: Icons.church_outlined),
  finance(key: 'finance', displayName: 'Finanzas Ejecutivas', icon: Icons.account_balance_wallet_outlined),
  gratitude(key: 'gratitude', displayName: 'Gratitud Estoica', icon: Icons.auto_awesome_outlined),
  polymath(key: 'polymath', displayName: 'Nivel Focus', icon: Icons.military_tech_rounded);

  final String key;
  final String displayName;
  final IconData icon;

  const AchievementModule({
    required this.key,
    required this.displayName,
    required this.icon,
  });

  static AchievementModule fromKey(String key) {
    return AchievementModule.values.firstWhere(
      (m) => m.key == key,
      orElse: () => AchievementModule.habits,
    );
  }
}

/// Tier/Rarity of the medal.
enum AchievementTier {
  bronze(
    displayName: 'Bronce',
    color: Color(0xFFCD7F32),
    gradientColors: [Color(0xFF8C5325), Color(0xFFD49B6A)],
    badgeBg: Color(0xFF2A1F18),
  ),
  silver(
    displayName: 'Plata',
    color: Color(0xFFC0C0C0),
    gradientColors: [Color(0xFF7A8288), Color(0xFFE2E7EA)],
    badgeBg: Color(0xFF1E2328),
  ),
  gold(
    displayName: 'Oro',
    color: Color(0xFFFFD700),
    gradientColors: [Color(0xFFB8860B), Color(0xFFFFE066)],
    badgeBg: Color(0xFF2C2508),
  ),
  platinum(
    displayName: 'Platino',
    color: Color(0xFF00E5FF),
    gradientColors: [Color(0xFF00838F), Color(0xFF80DEEA)],
    badgeBg: Color(0xFF09252B),
  );

  final String displayName;
  final Color color;
  final List<Color> gradientColors;
  final Color badgeBg;

  const AchievementTier({
    required this.displayName,
    required this.color,
    required this.gradientColors,
    required this.badgeBg,
  });
}

/// Definition of an achievement in the Master Catalog.
class AchievementDefinition {
  final String key;
  final String title;
  final String description;
  final String requirement;
  final AchievementModule module;
  final AchievementTier tier;
  final int xpReward;
  final IconData icon;

  const AchievementDefinition({
    required this.key,
    required this.title,
    required this.description,
    required this.requirement,
    required this.module,
    required this.tier,
    required this.xpReward,
    required this.icon,
  });
}

/// An achievement that has been unlocked by the user.
class UnlockedAchievement {
  final AchievementDefinition definition;
  final DateTime unlockedAt;

  const UnlockedAchievement({
    required this.definition,
    required this.unlockedAt,
  });

  String get formattedDate {
    return '${unlockedAt.day.toString().padLeft(2, '0')}/${unlockedAt.month.toString().padLeft(2, '0')}/${unlockedAt.year}';
  }
}

/// Master catalog containing all unified achievements for FocusHabitual Life.
class MasterAchievements {
  MasterAchievements._();

  static const List<AchievementDefinition> all = [
    // -------------------------------------------------------------------------
    // 1. HÁBITOS & RUTINAS
    // -------------------------------------------------------------------------
    AchievementDefinition(
      key: 'habit_first',
      title: 'Primer Paso Focus',
      description: 'Marcaste tu primer hábito registrado en la plataforma.',
      requirement: 'Completar 1 hábito.',
      module: AchievementModule.habits,
      tier: AchievementTier.bronze,
      xpReward: 25,
      icon: Icons.flag_outlined,
    ),
    AchievementDefinition(
      key: 'habit_streak_3',
      title: 'Cadencia Inicial',
      description: 'Mantuviste el cumplimiento de hábitos durante 3 días consecutivos.',
      requirement: 'Racha de 3 días en cualquier hábito.',
      module: AchievementModule.habits,
      tier: AchievementTier.bronze,
      xpReward: 50,
      icon: Icons.electric_bolt_rounded,
    ),
    AchievementDefinition(
      key: 'habit_streak_7',
      title: 'Semana de Hierro',
      description: 'Completaste 7 días ininterrumpidos de disciplina y ejecución.',
      requirement: 'Racha de 7 días consecutivos.',
      module: AchievementModule.habits,
      tier: AchievementTier.silver,
      xpReward: 100,
      icon: Icons.shield_rounded,
    ),
    AchievementDefinition(
      key: 'habit_streak_21',
      title: 'Hábito Consolidado',
      description: 'Superaste el ciclo fundamental de 21 días de neuroplasticidad.',
      requirement: 'Racha de 21 días en el reto de hábitos.',
      module: AchievementModule.habits,
      tier: AchievementTier.gold,
      xpReward: 250,
      icon: Icons.verified_rounded,
    ),
    AchievementDefinition(
      key: 'habit_streak_50',
      title: 'Arquitecto de Rutinas',
      description: '50 días acumulados de ejecución sin fisuras.',
      requirement: 'Completar 50 registros de hábitos en total.',
      module: AchievementModule.habits,
      tier: AchievementTier.platinum,
      xpReward: 500,
      icon: Icons.workspace_premium_rounded,
    ),
    AchievementDefinition(
      key: 'checklist_am_pm',
      title: 'Doble Sello AM/PM',
      description: 'Completaste tanto tu checklist de la mañana como el de la noche.',
      requirement: 'Checklist matutina y nocturna en un día.',
      module: AchievementModule.habits,
      tier: AchievementTier.bronze,
      xpReward: 40,
      icon: Icons.checklist_rounded,
    ),

    // -------------------------------------------------------------------------
    // 2. ENFOQUE & POMODORO (DEEP WORK)
    // -------------------------------------------------------------------------
    AchievementDefinition(
      key: 'pomodoro_first',
      title: 'Enfoque Inicial',
      description: 'Completaste con éxito tu primer bloque de Deep Work.',
      requirement: '1 sesión Pomodoro completada.',
      module: AchievementModule.pomodoro,
      tier: AchievementTier.bronze,
      xpReward: 25,
      icon: Icons.hourglass_top_rounded,
    ),
    AchievementDefinition(
      key: 'pomodoro_5',
      title: 'Inmersión Mental',
      description: '5 sesiones de trabajo profundo sin distracciones.',
      requirement: '5 sesiones Pomodoro completadas.',
      module: AchievementModule.pomodoro,
      tier: AchievementTier.bronze,
      xpReward: 60,
      icon: Icons.psychology_rounded,
    ),
    AchievementDefinition(
      key: 'pomodoro_25',
      title: 'Maestro del Tiempo',
      description: '25 bloques de concentración absoluta acumulados.',
      requirement: '25 sesiones Pomodoro completadas.',
      module: AchievementModule.pomodoro,
      tier: AchievementTier.silver,
      xpReward: 150,
      icon: Icons.access_time_filled_rounded,
    ),
    AchievementDefinition(
      key: 'pomodoro_100',
      title: 'Centurión del Enfoque',
      description: '100 sesiones de enfoque profundo. Control absoluto de la atención.',
      requirement: '100 sesiones Pomodoro completadas.',
      module: AchievementModule.pomodoro,
      tier: AchievementTier.gold,
      xpReward: 400,
      icon: Icons.radar_rounded,
    ),
    AchievementDefinition(
      key: 'deep_work_10_sessions',
      title: 'Maestría Deep Work',
      description: '10 sesiones de trabajo profundo de alta exigencia completadas con blindaje cognitivo.',
      requirement: '10 sesiones etiquetadas como Deep Work.',
      module: AchievementModule.pomodoro,
      tier: AchievementTier.silver,
      xpReward: 120,
      icon: Icons.bolt_rounded,
    ),
    AchievementDefinition(
      key: 'flowmodoro_explorer',
      title: 'Pionero de Flowmodoro',
      description: 'Completaste una sesión en modo flujo continuo sin reloj regresivo.',
      requirement: '1 sesión Flowmodoro completada.',
      module: AchievementModule.pomodoro,
      tier: AchievementTier.bronze,
      xpReward: 50,
      icon: Icons.all_inclusive_rounded,
    ),
    AchievementDefinition(
      key: 'ultradian_master',
      title: 'Maestro Ultradiano',
      description: 'Dominaste los ciclos ultradianos completando 2 bloques profundos de 90 min en un día.',
      requirement: 'Completar 2 bloques ultradianos en un mismo día.',
      module: AchievementModule.pomodoro,
      tier: AchievementTier.gold,
      xpReward: 200,
      icon: Icons.workspace_premium_rounded,
    ),

    // -------------------------------------------------------------------------
    // 3. SALUD & VITALIDAD (AGUA, NUTRICIÓN, AFIRMACIONES)
    // -------------------------------------------------------------------------
    AchievementDefinition(
      key: 'water_first',
      title: 'Primera Hidratación',
      description: 'Registraste tu primera ingesta consciente de agua.',
      requirement: '1 registro de agua.',
      module: AchievementModule.wellness,
      tier: AchievementTier.bronze,
      xpReward: 20,
      icon: Icons.water_drop_outlined,
    ),
    AchievementDefinition(
      key: 'water_goal_1d',
      title: 'Meta Hídrica Cumplida',
      description: 'Alcanzaste el 100% de tu objetivo diario de hidratación.',
      requirement: 'Cumplir la meta de agua del día.',
      module: AchievementModule.wellness,
      tier: AchievementTier.bronze,
      xpReward: 35,
      icon: Icons.local_drink_rounded,
    ),
    AchievementDefinition(
      key: 'water_goal_7d',
      title: 'Fuente de Vitalidad',
      description: '7 días alcanzando tu objetivo diario de hidratación.',
      requirement: 'Meta de agua cumplida 7 veces.',
      module: AchievementModule.wellness,
      tier: AchievementTier.silver,
      xpReward: 120,
      icon: Icons.waves_rounded,
    ),
    AchievementDefinition(
      key: 'nutrition_first',
      title: 'Nutrición Consciente',
      description: 'Registraste tu primer plato saludable del día.',
      requirement: '1 registro de alimentación.',
      module: AchievementModule.wellness,
      tier: AchievementTier.bronze,
      xpReward: 25,
      icon: Icons.restaurant_rounded,
    ),
    AchievementDefinition(
      key: 'nutrition_streak_7',
      title: 'Equilibrio Metabólico',
      description: '7 comidas principales registradas con regularidad.',
      requirement: '7 registros de nutrición.',
      module: AchievementModule.wellness,
      tier: AchievementTier.silver,
      xpReward: 100,
      icon: Icons.eco_rounded,
    ),
    AchievementDefinition(
      key: 'affirmation_first',
      title: 'Decreto Mental',
      description: 'Leíste y asimilaste tu primera afirmación positiva matutina.',
      requirement: '1 afirmación leída.',
      module: AchievementModule.wellness,
      tier: AchievementTier.bronze,
      xpReward: 20,
      icon: Icons.lightbulb_outline_rounded,
    ),
    AchievementDefinition(
      key: 'affirmation_favorite_5',
      title: 'Mente Inquebrantable',
      description: 'Guardaste 5 afirmaciones poderosas en tus favoritas.',
      requirement: 'Guardar 5 afirmaciones favoritas.',
      module: AchievementModule.wellness,
      tier: AchievementTier.bronze,
      xpReward: 40,
      icon: Icons.favorite_rounded,
    ),

    // -------------------------------------------------------------------------
    // 4. RETOS 21 DÍAS (MEDITACIÓN, YOGA, YOGA FACIAL)
    // -------------------------------------------------------------------------
    AchievementDefinition(
      key: 'meditation_first',
      title: 'Silencio Interior',
      description: 'Completaste tu primera sesión de meditación con sonidos de naturaleza.',
      requirement: 'Completar Día 1 de Meditación.',
      module: AchievementModule.challenges,
      tier: AchievementTier.bronze,
      xpReward: 30,
      icon: Icons.self_improvement_rounded,
    ),
    AchievementDefinition(
      key: 'meditation_streak_21',
      title: 'Maestro Zen',
      description: 'Completaste los 21 días de práctica meditativa y presencia.',
      requirement: 'Finalizar los 21 días del reto de Meditación.',
      module: AchievementModule.challenges,
      tier: AchievementTier.gold,
      xpReward: 350,
      icon: Icons.spa_rounded,
    ),
    AchievementDefinition(
      key: 'yoga_first',
      title: 'Alineación & Eje',
      description: 'Completaste tu primera rutina de asanas de yoga con 10s de preparación previa.',
      requirement: 'Completar Día 1 de Yoga.',
      module: AchievementModule.challenges,
      tier: AchievementTier.bronze,
      xpReward: 30,
      icon: Icons.accessibility_new_rounded,
    ),
    AchievementDefinition(
      key: 'yoga_streak_21',
      title: 'Maestro Yogui',
      description: 'Completaste los 21 días del reto de Yoga (Fuerza, Flexibilidad y Relajación).',
      requirement: 'Finalizar los 21 días del reto de Yoga.',
      module: AchievementModule.challenges,
      tier: AchievementTier.gold,
      xpReward: 350,
      icon: Icons.fitness_center_rounded,
    ),
    AchievementDefinition(
      key: 'facial_first',
      title: 'Armonía Facial',
      description: 'Completaste tu primera sesión de tonificación y drenaje linfático facial.',
      requirement: 'Completar Día 1 de Yoga Facial.',
      module: AchievementModule.challenges,
      tier: AchievementTier.bronze,
      xpReward: 30,
      icon: Icons.face_retouching_natural_rounded,
    ),
    AchievementDefinition(
      key: 'facial_streak_21',
      title: 'Lifting Holístico',
      description: 'Completaste los 21 días del reto de Yoga Facial.',
      requirement: 'Finalizar los 21 días de Yoga Facial.',
      module: AchievementModule.challenges,
      tier: AchievementTier.gold,
      xpReward: 350,
      icon: Icons.auto_awesome_rounded,
    ),

    // -------------------------------------------------------------------------
    // 5. AUTODOMINIO (NO FAP)
    // -------------------------------------------------------------------------
    AchievementDefinition(
      key: 'nofap_3d',
      title: 'Punto de Inflexión',
      description: '3 días limpios. Superaste el primer umbral de abstinencia y dopamina.',
      requirement: 'Alcanzar racha de 3 días en NoFap.',
      module: AchievementModule.nofap,
      tier: AchievementTier.bronze,
      xpReward: 50,
      icon: Icons.trending_up_rounded,
    ),
    AchievementDefinition(
      key: 'nofap_7d',
      title: 'Voluntad de Acero',
      description: '7 días continuos de claridad mental y autodominio.',
      requirement: 'Alcanzar racha de 7 días en NoFap.',
      module: AchievementModule.nofap,
      tier: AchievementTier.silver,
      xpReward: 150,
      icon: Icons.security_rounded,
    ),
    AchievementDefinition(
      key: 'nofap_21d',
      title: 'Hábito Trascendido',
      description: '21 días limpios. La neuroplasticidad juega a tu favor.',
      requirement: 'Alcanzar racha de 21 días en NoFap.',
      module: AchievementModule.nofap,
      tier: AchievementTier.gold,
      xpReward: 350,
      icon: Icons.military_tech_rounded,
    ),
    AchievementDefinition(
      key: 'nofap_reboot_90d',
      title: 'Renacimiento Neuroquímico',
      description: '90 días de victoria total. Reseteo dopaminérgico completado.',
      requirement: 'Alcanzar racha de 90 días en NoFap.',
      module: AchievementModule.nofap,
      tier: AchievementTier.platinum,
      xpReward: 1000,
      icon: Icons.diamond_rounded,
    ),

    // -------------------------------------------------------------------------
    // 6. CICLO & BIENESTAR FEMENINO
    // -------------------------------------------------------------------------
    AchievementDefinition(
      key: 'cycle_first_log',
      title: 'Sincronía Biológica',
      description: 'Registraste el inicio de periodo o síntomas para optimizar tu energía.',
      requirement: '1 registro de ciclo.',
      module: AchievementModule.cycle,
      tier: AchievementTier.bronze,
      xpReward: 30,
      icon: Icons.calendar_month_rounded,
    ),
    AchievementDefinition(
      key: 'cycle_tracked_3',
      title: 'Sabiduría Hormonal',
      description: 'Mapeaste 3 ciclos completos conociendo tus fases de productividad.',
      requirement: '3 ciclos registrados.',
      module: AchievementModule.cycle,
      tier: AchievementTier.silver,
      xpReward: 150,
      icon: Icons.insights_rounded,
    ),

    // -------------------------------------------------------------------------
    // 7. ESPIRITUALIDAD & RELIGIÓN
    // -------------------------------------------------------------------------
    AchievementDefinition(
      key: 'devotional_first',
      title: 'Palabra Viva',
      description: 'Leíste un pasaje sagrado y guardaste una reflexión devocional.',
      requirement: '1 reflexión guardada.',
      module: AchievementModule.religion,
      tier: AchievementTier.bronze,
      xpReward: 25,
      icon: Icons.menu_book_rounded,
    ),
    AchievementDefinition(
      key: 'devotional_streak_7',
      title: 'Fe Cotidiana',
      description: '7 reflexiones o pasajes devocionales estudiados.',
      requirement: '7 registros devocionales.',
      module: AchievementModule.religion,
      tier: AchievementTier.silver,
      xpReward: 100,
      icon: Icons.auto_stories_rounded,
    ),
    AchievementDefinition(
      key: 'prayer_warrior',
      title: 'Intercesión Activa',
      description: 'Registraste 5 intenciones u oraciones en tu muro espiritual.',
      requirement: '5 oraciones registradas.',
      module: AchievementModule.religion,
      tier: AchievementTier.bronze,
      xpReward: 50,
      icon: Icons.handshake_outlined,
    ),

    // -------------------------------------------------------------------------
    // 8. FINANZAS & ESTRATEGIA
    // -------------------------------------------------------------------------
    AchievementDefinition(
      key: 'finance_first_tx',
      title: 'Conciencia Financiera',
      description: 'Registraste tu primer ingreso o gasto con disciplina patrimonial.',
      requirement: '1 transacción registrada.',
      module: AchievementModule.finance,
      tier: AchievementTier.bronze,
      xpReward: 25,
      icon: Icons.attach_money_rounded,
    ),
    AchievementDefinition(
      key: 'finance_budget_set',
      title: 'Presupuesto Blindado',
      description: 'Configuraste tus límites presupuestarios del mes.',
      requirement: 'Crear o editar un presupuesto.',
      module: AchievementModule.finance,
      tier: AchievementTier.silver,
      xpReward: 80,
      icon: Icons.pie_chart_outline_rounded,
    ),

    // -------------------------------------------------------------------------
    // 9. GRATITUD ESTOICA
    // -------------------------------------------------------------------------
    AchievementDefinition(
      key: 'gratitude_first',
      title: 'Mirada Apreciativa',
      description: 'Escribiste tus primeros 3 agradecimientos en el diario estoico.',
      requirement: '1 entrada de gratitud.',
      module: AchievementModule.gratitude,
      tier: AchievementTier.bronze,
      xpReward: 25,
      icon: Icons.favorite_border_rounded,
    ),
    AchievementDefinition(
      key: 'gratitude_streak_7',
      title: 'Abundancia Interior',
      description: '7 días registrando motivos de gratitud.',
      requirement: '7 entradas de gratitud.',
      module: AchievementModule.gratitude,
      tier: AchievementTier.silver,
      xpReward: 100,
      icon: Icons.volunteer_activism_rounded,
    ),

    // -------------------------------------------------------------------------
    // 10. PROGRESIÓN FOCUS & NIVELES
    // -------------------------------------------------------------------------
    AchievementDefinition(
      key: 'level_3_polymath',
      title: 'Iniciado en Disciplina',
      description: 'Alcanzaste el Nivel 3 en la Suite FocusHabitual.',
      requirement: 'Llegar a Nivel 3.',
      module: AchievementModule.polymath,
      tier: AchievementTier.bronze,
      xpReward: 50,
      icon: Icons.workspace_premium_outlined,
    ),
    AchievementDefinition(
      key: 'level_5_polymath',
      title: 'Estratega del Enfoque',
      description: 'Alcanzaste el Nivel 5 Focus acumulando victorias cotidianas.',
      requirement: 'Llegar a Nivel 5.',
      module: AchievementModule.polymath,
      tier: AchievementTier.silver,
      xpReward: 150,
      icon: Icons.military_tech_outlined,
    ),
    AchievementDefinition(
      key: 'level_10_polymath',
      title: 'Focus Consolidado',
      description: 'Alcanzaste el Nivel 10. Tu disciplina es integral y multidisciplinaria.',
      requirement: 'Llegar a Nivel 10.',
      module: AchievementModule.polymath,
      tier: AchievementTier.gold,
      xpReward: 400,
      icon: Icons.stars_rounded,
    ),
    AchievementDefinition(
      key: 'level_20_polymath',
      title: 'Élite Omnidisciplinar',
      description: 'Alcanzaste el Nivel 20. Cúspide de la maestría personal y profesional.',
      requirement: 'Llegar a Nivel 20.',
      module: AchievementModule.polymath,
      tier: AchievementTier.platinum,
      xpReward: 1000,
      icon: Icons.auto_awesome_rounded,
    ),
  ];

  static AchievementDefinition? findByKey(String key) {
    try {
      return all.firstWhere((a) => a.key == key);
    } catch (_) {
      return null;
    }
  }

  static List<AchievementDefinition> byModule(AchievementModule module) {
    return all.where((a) => a.module == module).toList();
  }
}
