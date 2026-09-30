import 'package:flutter/material.dart';
import 'habit.dart';

enum MasterHabitCategory {
  clarity,
  biohacking,
  finance,
  selfMastery,
  relationships;

  String get displayName {
    switch (this) {
      case MasterHabitCategory.clarity:
        return 'Claridad & Cognición';
      case MasterHabitCategory.biohacking:
        return 'Biohacking & Energía';
      case MasterHabitCategory.finance:
        return 'Dominio Financiero';
      case MasterHabitCategory.selfMastery:
        return 'Autodominio & Carácter';
      case MasterHabitCategory.relationships:
        return 'Relaciones Estratégicas';
    }
  }

  IconData get icon {
    switch (this) {
      case MasterHabitCategory.clarity:
        return Icons.psychology_outlined;
      case MasterHabitCategory.biohacking:
        return Icons.bolt_outlined;
      case MasterHabitCategory.finance:
        return Icons.account_balance_wallet_outlined;
      case MasterHabitCategory.selfMastery:
        return Icons.shield_outlined;
      case MasterHabitCategory.relationships:
        return Icons.handshake_outlined;
    }
  }

  Color get accentColor {
    switch (this) {
      case MasterHabitCategory.clarity:
        return const Color(0xFF3B82F6); // Blue
      case MasterHabitCategory.biohacking:
        return const Color(0xFF10B981); // Emerald
      case MasterHabitCategory.finance:
        return const Color(0xFFF59E0B); // Amber
      case MasterHabitCategory.selfMastery:
        return const Color(0xFF8B5CF6); // Violet
      case MasterHabitCategory.relationships:
        return const Color(0xFFEC4899); // Rose
    }
  }
}

class MasterHabit {
  const MasterHabit({
    required this.id,
    required this.title,
    required this.shortDescription,
    required this.scientificRationale,
    required this.category,
    this.frequency = 'daily',
    this.targetCount = 1,
    this.unit = 'sesión',
    this.targetDbCategory = HabitCategory.general,
    this.xpReward = 15,
    this.iconName = 'task_alt',
  });

  final String id;
  final String title;
  final String shortDescription;
  final String scientificRationale;
  final MasterHabitCategory category;
  final String frequency;
  final int targetCount;
  final String unit;
  final HabitCategory targetDbCategory;
  final int xpReward;
  final String iconName;
}

class MasterHabitsCatalog {
  static const List<MasterHabit> allHabits = [
    // -------------------------------------------------------------------------
    // 1. CLARIDAD & COGNICIÓN (10 Hábitos)
    // -------------------------------------------------------------------------
    MasterHabit(
      id: 'clarity_01',
      title: 'Monotarea en Ventanas Ultradianas (90 min)',
      shortDescription: 'Trabajo profundo continuo sin cambiar de contexto ni revisar notificaciones.',
      scientificRationale: 'Los ritmos ultradianos regulan picos de atención de 90 minutos seguidos de fatiga sináptica.',
      category: MasterHabitCategory.clarity,
      unit: 'minutos',
      targetCount: 90,
      xpReward: 20,
    ),
    MasterHabit(
      id: 'clarity_02',
      title: 'Descarga Mental Nocturna (Brain Dump)',
      shortDescription: 'Anotar pendientes, ideas y fricciones en libreta física antes de dormir.',
      scientificRationale: 'Reduce el efecto Zeigarnik, liberando la memoria de trabajo y minimizando el cortisol nocturno.',
      category: MasterHabitCategory.clarity,
      targetDbCategory: HabitCategory.checklistPm,
      unit: 'páginas',
      targetCount: 1,
      xpReward: 15,
    ),
    MasterHabit(
      id: 'clarity_03',
      title: 'Lectura Técnica Estratégica (20 min)',
      shortDescription: 'Lectura activa de libros de fundamentos, arquitectura, negocios o filosofía.',
      scientificRationale: 'Fomenta la neurogénesis en el hipocampo y la transferencia conceptual cruzada.',
      category: MasterHabitCategory.clarity,
      targetDbCategory: HabitCategory.checklistAm,
      unit: 'minutos',
      targetCount: 20,
      xpReward: 15,
    ),
    MasterHabit(
      id: 'clarity_04',
      title: 'Revisión Semanal de Primeros Principios',
      shortDescription: 'Auditar decisiones semanales descomponiéndolas a verdades fundamentales.',
      scientificRationale: 'Previene trampas heurísticas y el pensamiento por analogía pasiva.',
      category: MasterHabitCategory.clarity,
      frequency: 'weekly',
      unit: 'sesión',
      targetCount: 1,
      xpReward: 30,
    ),
    MasterHabit(
      id: 'clarity_05',
      title: 'Dieta de Cero Noticias Matutinas',
      shortDescription: 'Cero consumo de redes sociales, periódicos o mensajería durante las primeras 2 horas.',
      scientificRationale: 'Protege el lóbulo frontal de estados reactivos inducidos por dopamina espuria.',
      category: MasterHabitCategory.clarity,
      targetDbCategory: HabitCategory.checklistAm,
      unit: 'horas',
      targetCount: 2,
      xpReward: 15,
    ),
    MasterHabit(
      id: 'clarity_06',
      title: 'Técnica de Feynman / Explicación Simple',
      shortDescription: 'Articular un concepto complejo aprendido en palabras comprensibles para un niño.',
      scientificRationale: 'Identifica lagunas cognitivas profundas e indexa conocimiento en redes de largo plazo.',
      category: MasterHabitCategory.clarity,
      unit: 'concepto',
      targetCount: 1,
      xpReward: 15,
    ),
    MasterHabit(
      id: 'clarity_07',
      title: 'Caminata Silenciosa Sin Estímulos (15 min)',
      shortDescription: 'Caminar al aire libre sin música, podcasts ni acompañamiento.',
      scientificRationale: 'Activa la Red Neuronal por Defecto (DMN), permitiendo síntesis subconsciente de ideas.',
      category: MasterHabitCategory.clarity,
      unit: 'minutos',
      targetCount: 15,
      xpReward: 15,
    ),
    MasterHabit(
      id: 'clarity_08',
      title: 'Definición de la Victoria Singular (Prioridad 1)',
      shortDescription: 'Determinar la única tarea que si se completa hoy, hace irrelevante el resto.',
      scientificRationale: 'Alinea la corteza prefrontal sobre el gradiente de meta eliminando la parálisis por análisis.',
      category: MasterHabitCategory.clarity,
      targetDbCategory: HabitCategory.checklistAm,
      unit: 'tarea',
      targetCount: 1,
      xpReward: 15,
    ),
    MasterHabit(
      id: 'clarity_09',
      title: 'Auditoría de Atención y Distracciones',
      shortDescription: 'Registrar cada interrupción y su detonante psicológico durante la jornada laboral.',
      scientificRationale: 'Genera metacognición y eleva el umbral de control inhibitorio frente a pulsiones.',
      category: MasterHabitCategory.clarity,
      unit: 'auditoría',
      targetCount: 1,
      xpReward: 15,
    ),
    MasterHabit(
      id: 'clarity_10',
      title: 'Cierre de Jornada y Apagado Cognitivo',
      shortDescription: 'Cerrar pestañas, definir 3 prioridades de mañana y declarar verbalmente el fin del trabajo.',
      scientificRationale: 'Permite la transición simpática a parasimpática, evitando el agotamiento crónico.',
      category: MasterHabitCategory.clarity,
      targetDbCategory: HabitCategory.checklistPm,
      unit: 'ritual',
      targetCount: 1,
      xpReward: 15,
    ),

    // -------------------------------------------------------------------------
    // 2. BIOHACKING & ENERGÍA (12 Hábitos)
    // -------------------------------------------------------------------------
    MasterHabit(
      id: 'bio_01',
      title: 'Fotobiología Matutina (Luz Solar Temprana)',
      shortDescription: '10 a 15 minutos de luz solar directa en ojos y piel dentro de la 1ª hora tras despertar.',
      scientificRationale: 'Sincroniza el núcleo supraquiasmático (SCN) y optimiza el pulso circadiano de cortisol.',
      category: MasterHabitCategory.biohacking,
      targetDbCategory: HabitCategory.checklistAm,
      unit: 'minutos',
      targetCount: 10,
      xpReward: 15,
    ),
    MasterHabit(
      id: 'bio_02',
      title: 'Retraso de Cafeína a 90-120 Minutos',
      shortDescription: 'Esperar entre hora y media y dos horas tras levantarse antes de consumir café o té.',
      scientificRationale: 'Permite la depuración natural de la adenosina acumulada, erradicando el bajón vespertino.',
      category: MasterHabitCategory.biohacking,
      targetDbCategory: HabitCategory.checklistAm,
      unit: 'minutos',
      targetCount: 90,
      xpReward: 15,
    ),
    MasterHabit(
      id: 'bio_03',
      title: 'Caminata Posprandial (10 min tras comer)',
      shortDescription: 'Caminar suavemente durante 10 a 15 minutos inmediatamente tras comidas principales.',
      scientificRationale: 'Mitiga hasta en un 30% los picos glucémicos y mejora la translocación de GLUT-4 sin insulina.',
      category: MasterHabitCategory.biohacking,
      unit: 'caminatas',
      targetCount: 2,
      xpReward: 15,
    ),
    MasterHabit(
      id: 'bio_04',
      title: 'Hidratación Electrolítica Matutina',
      shortDescription: 'Beber 500ml de agua con una pizca de sal marina integral o electrolitos nada más levantarse.',
      scientificRationale: 'Compensa la deshidratación nocturna y restaura la conductividad iónica en el sistema nervioso.',
      category: MasterHabitCategory.biohacking,
      targetDbCategory: HabitCategory.checklistAm,
      unit: 'vaso',
      targetCount: 1,
      xpReward: 10,
    ),
    MasterHabit(
      id: 'bio_05',
      title: 'Exposición al Frío / Ducha Fría (2 min)',
      shortDescription: 'Finalizar la ducha diaria con 90 a 120 segundos de agua fría constante.',
      scientificRationale: 'Aumenta la norepinefrina plasmática en 250% y eleva la dopamina basal de forma sostenida.',
      category: MasterHabitCategory.biohacking,
      unit: 'minutos',
      targetCount: 2,
      xpReward: 20,
    ),
    MasterHabit(
      id: 'bio_06',
      title: 'Toque de Queda de Luz Azul (1 h antes de dormir)',
      shortDescription: 'Apagar pantallas o usar lentes bloqueadores de luz azul 60 minutos antes de acostarse.',
      scientificRationale: 'Evita la supresión de melatonina y acelera el inicio del sueño de ondas lentas (fase profunda).',
      category: MasterHabitCategory.biohacking,
      targetDbCategory: HabitCategory.checklistPm,
      unit: 'minutos',
      targetCount: 60,
      xpReward: 15,
    ),
    MasterHabit(
      id: 'bio_07',
      title: 'Respiración Fisiológica (Suspiro Cíclico 3 min)',
      shortDescription: 'Doble inhalación nasal rápida seguida de exhalación bucal lenta durante 3 minutos.',
      scientificRationale: 'Colapsa los alvéolos hiperinsuflados y estimula el nervio vago reduciendo la frecuencia cardíaca.',
      category: MasterHabitCategory.biohacking,
      unit: 'minutos',
      targetCount: 3,
      xpReward: 10,
    ),
    MasterHabit(
      id: 'bio_08',
      title: 'Entrenamiento de Resistencia de Alta Densidad',
      shortDescription: 'Sesión de sobrecarga progresiva (pesas o calistenia) enfocada en grandes grupos musculares.',
      scientificRationale: 'Libera mioquinas antiinflamatorias y eleva la sensibilidad celular a la glucosa durante 48h.',
      category: MasterHabitCategory.biohacking,
      unit: 'minutos',
      targetCount: 45,
      xpReward: 25,
    ),
    MasterHabit(
      id: 'bio_09',
      title: 'Descanso No Profundo (NSDR / Yoga Nidra)',
      shortDescription: 'Protocolo de 15 a 20 minutos de relajación guiada y quietud corporal al mediodía.',
      scientificRationale: 'Restaura reservas de dopamina estriatal y reduce la fatiga mental sin alterar el sueño nocturno.',
      category: MasterHabitCategory.biohacking,
      unit: 'minutos',
      targetCount: 20,
      xpReward: 15,
    ),
    MasterHabit(
      id: 'bio_10',
      title: 'Ventana de Alimentación Circadiana (Ayuno Intermitente)',
      shortDescription: 'Consumir alimentos dentro de una ventana fija de 8 a 10 horas, ayunando el resto.',
      scientificRationale: 'Estimula la autofagia celular, normaliza la sensibilidad a la leptina y repara mitocondrias.',
      category: MasterHabitCategory.biohacking,
      unit: 'horas ayuno',
      targetCount: 16,
      xpReward: 20,
    ),
    MasterHabit(
      id: 'bio_11',
      title: 'Optimización de Temperatura del Dormitorio (18-19°C)',
      shortDescription: 'Mantener la habitación fresca, oscura y ventilada para la noche.',
      scientificRationale: 'El cuerpo necesita descender su temperatura central en 1°C para ingresar en sueño REM profundo.',
      category: MasterHabitCategory.biohacking,
      targetDbCategory: HabitCategory.checklistPm,
      unit: 'noche',
      targetCount: 1,
      xpReward: 10,
    ),
    MasterHabit(
      id: 'bio_12',
      title: 'Descompresión Espinal y Movilidad Articular',
      shortDescription: '10 minutos de movilidad de cadera, dorsales y suspensión pasiva en barra.',
      scientificRationale: 'Rehidrata discos intervertebrales y contrarresta el acortamiento postural por sedentarismo.',
      category: MasterHabitCategory.biohacking,
      unit: 'minutos',
      targetCount: 10,
      xpReward: 10,
    ),

    // -------------------------------------------------------------------------
    // 3. DOMINIO FINANCIERO (10 Hábitos)
    // -------------------------------------------------------------------------
    MasterHabit(
      id: 'fin_01',
      title: 'Auditoría de Gastos del Día (Libro Diario)',
      shortDescription: 'Registrar cada egreso e ingreso en la bitácora financiera antes de dormir.',
      scientificRationale: 'Rompe la disociación psicológica del dinero digital y crea hiperconciencia de fuga de capital.',
      category: MasterHabitCategory.finance,
      targetDbCategory: HabitCategory.finance,
      unit: 'registro',
      targetCount: 1,
      xpReward: 15,
    ),
    MasterHabit(
      id: 'fin_02',
      title: 'Regla de Enfriamiento de 72 Horas',
      shortDescription: 'Esperar 3 días completos antes de concretar compras discrecionales no esenciales.',
      scientificRationale: 'Desvanece el secuestro dopaminérgico impulsivo y devuelve la evaluación al córtex racional.',
      category: MasterHabitCategory.finance,
      targetDbCategory: HabitCategory.finance,
      unit: 'compras pausadas',
      targetCount: 1,
      xpReward: 15,
    ),
    MasterHabit(
      id: 'fin_03',
      title: 'Ahorro / Inversión Automatizada Automática',
      shortDescription: 'Separar el porcentaje de ahorro e inversión inmediatamente al recibir un flujo de caja.',
      scientificRationale: 'Aplica el principio de "págate a ti mismo primero", eliminando la dependencia de la fuerza de voluntad.',
      category: MasterHabitCategory.finance,
      targetDbCategory: HabitCategory.finance,
      frequency: 'weekly',
      unit: 'transferencia',
      targetCount: 1,
      xpReward: 25,
    ),
    MasterHabit(
      id: 'fin_04',
      title: 'Auditoría de Suscripciones y Débitos Ocultos',
      shortDescription: 'Revisar extractos bancarios cancelando servicios redundantes o subutilizados.',
      scientificRationale: 'Elimina el sangrado pasivo del patrimonio neto causado por la inercia del usuario.',
      category: MasterHabitCategory.finance,
      targetDbCategory: HabitCategory.finance,
      frequency: 'weekly',
      unit: 'auditoría',
      targetCount: 1,
      xpReward: 20,
    ),
    MasterHabit(
      id: 'fin_05',
      title: 'Cálculo del Costo en Horas de Vida',
      shortDescription: 'Convertir el precio de un bien de consumo en horas de trabajo requeridas antes de comprar.',
      scientificRationale: 'Recontextualiza el gasto bajo el costo de oportunidad más escaso e irrecuperable: el tiempo.',
      category: MasterHabitCategory.finance,
      targetDbCategory: HabitCategory.finance,
      unit: 'evaluaciones',
      targetCount: 1,
      xpReward: 15,
    ),
    MasterHabit(
      id: 'fin_06',
      title: 'Revisión Semanal del Patrimonio Neto (Net Worth)',
      shortDescription: 'Sumar activos líquidos, inversiones y restar pasivos totales cada domingo.',
      scientificRationale: 'Lo que se mide sistemáticamente tiende a optimizarse por retroalimentación cibernética.',
      category: MasterHabitCategory.finance,
      targetDbCategory: HabitCategory.finance,
      frequency: 'weekly',
      unit: 'balance',
      targetCount: 1,
      xpReward: 30,
    ),
    MasterHabit(
      id: 'fin_07',
      title: 'Jornada Cero Gastos Opcionales (No-Spend Day)',
      shortDescription: 'Un día a la semana sin ningún consumo monetario fuera de servicios básicos programados.',
      scientificRationale: 'Entrena la resiliencia voluntaria y desacopla el ocio del gasto de dopamina comercial.',
      category: MasterHabitCategory.finance,
      targetDbCategory: HabitCategory.finance,
      unit: 'día completo',
      targetCount: 1,
      xpReward: 20,
    ),
    MasterHabit(
      id: 'fin_08',
      title: 'Análisis de Rendimiento de Activos (ROI)',
      shortDescription: 'Revisar la asignación de capital y métricas de portafolio o proyectos de negocio.',
      scientificRationale: 'Enfoca la toma de decisiones en el valor esperado matemático y reduce la aversión al riesgo.',
      category: MasterHabitCategory.finance,
      targetDbCategory: HabitCategory.finance,
      frequency: 'weekly',
      unit: 'revisión',
      targetCount: 1,
      xpReward: 25,
    ),
    MasterHabit(
      id: 'fin_09',
      title: 'Educación Financiera Cuantitativa (15 min)',
      shortDescription: 'Estudio de modelos macroeconómicos, valuación corporativa o estructuras fiscales.',
      scientificRationale: 'Expande la sofisticación financiera y detecta asimetrías de información.',
      category: MasterHabitCategory.finance,
      targetDbCategory: HabitCategory.finance,
      unit: 'minutos',
      targetCount: 15,
      xpReward: 15,
    ),
    MasterHabit(
      id: 'fin_10',
      title: 'Alineación de Fondo de Tranquilidad (6 Meses)',
      shortDescription: 'Monitorear que el fondo de emergencia cubra medio año de gastos fijos innegociables.',
      scientificRationale: 'Otorga opcionalidad existencial y disipa la ansiedad biológica ante la incertidumbre.',
      category: MasterHabitCategory.finance,
      targetDbCategory: HabitCategory.finance,
      frequency: 'weekly',
      unit: 'chequeo',
      targetCount: 1,
      xpReward: 20,
    ),

    // -------------------------------------------------------------------------
    // 4. AUTODOMINIO & CARÁCTER (10 Hábitos)
    // -------------------------------------------------------------------------
    MasterHabit(
      id: 'self_01',
      title: 'Práctica Diaria de Gratitud y Reflexión Estoica',
      shortDescription: 'Anotar tres motivos específicos de gratitud y meditar sobre la dicotomía del control.',
      scientificRationale: 'Reconfigura el sesgo de negatividad evolutivo e incrementa la densidad de receptores de oxitocina.',
      category: MasterHabitCategory.selfMastery,
      targetDbCategory: HabitCategory.gratitude,
      unit: 'reflexión',
      targetCount: 1,
      xpReward: 15,
    ),
    MasterHabit(
      id: 'self_02',
      title: 'Doblega el Impulso (Pausa de 10 Segundos)',
      shortDescription: 'Pausar 10 segundos antes de ceder a cualquier antojo, queja o respuesta reactiva.',
      scientificRationale: 'Fortalece la conexión sináptica entre la corteza orbitofrontal y la amígdala basolateral.',
      category: MasterHabitCategory.selfMastery,
      unit: 'pausas',
      targetCount: 3,
      xpReward: 15,
    ),
    MasterHabit(
      id: 'self_03',
      title: 'Incomodidad Voluntaria Diaria',
      shortDescription: 'Elegir deliberadamente una opción más incómoda (escaleras, ayuno breve, postura erguida).',
      scientificRationale: 'Entrena la corteza cingulada anterior media (aMCC), el epicentro neural de la tenacidad y voluntad.',
      category: MasterHabitCategory.selfMastery,
      unit: 'reto',
      targetCount: 1,
      xpReward: 20,
    ),
    MasterHabit(
      id: 'self_04',
      title: 'Premeditatio Malorum (Anticipación de Obstáculos)',
      shortDescription: 'Imaginar los peores escenarios posibles del día y diseñar contramedidas con serenidad.',
      scientificRationale: 'Desensibiliza el impacto psicológico del estrés agudo y neutraliza el pánico en crisis.',
      category: MasterHabitCategory.selfMastery,
      targetDbCategory: HabitCategory.checklistAm,
      unit: 'minutos',
      targetCount: 5,
      xpReward: 15,
    ),
    MasterHabit(
      id: 'self_05',
      title: 'Cero Quejas Verbales durante 24 Horas',
      shortDescription: 'Prohibición absoluta de quejarse sobre factores externos que escapan a tu control directo.',
      scientificRationale: 'La queja crónica atrofia el hipocampo y refuerza redes neuronales de desamparo aprendido.',
      category: MasterHabitCategory.selfMastery,
      unit: 'día limpio',
      targetCount: 1,
      xpReward: 25,
    ),
    MasterHabit(
      id: 'self_06',
      title: 'Examen de Conciencia Nocturno (Pitágoras)',
      shortDescription: '¿En qué fallé hoy? ¿Qué hice bien? ¿Qué dejé sin hacer que debía haber hecho?',
      scientificRationale: 'Cierra bucles de aprendizaje diario y activa la consolidación de memorias autobiográficas.',
      category: MasterHabitCategory.selfMastery,
      targetDbCategory: HabitCategory.checklistPm,
      unit: 'examen',
      targetCount: 1,
      xpReward: 15,
    ),
    MasterHabit(
      id: 'self_07',
      title: 'Protección de Promesas Personales (Integridad 100%)',
      shortDescription: 'Cumplir estrictamente cada microcompromiso hecho contigo mismo sin excepciones.',
      scientificRationale: 'Construye la autoeficacia real: la confianza subconsciente en tu propia palabra y capacidad.',
      category: MasterHabitCategory.selfMastery,
      unit: 'compromisos',
      targetCount: 1,
      xpReward: 20,
    ),
    MasterHabit(
      id: 'self_08',
      title: 'Momento Memento Mori',
      shortDescription: 'Recordar durante 60 segundos la naturaleza finita de la existencia propia.',
      scientificRationale: 'Destruye instantáneamente el ego superficial y jerarquiza lo que es verdaderamente trascendente.',
      category: MasterHabitCategory.selfMastery,
      unit: 'minuto',
      targetCount: 1,
      xpReward: 15,
    ),
    MasterHabit(
      id: 'self_09',
      title: 'Desapego de Validación Externa (Likes/Opiniones)',
      shortDescription: 'No revisar estadísticas de interacción personal ni solicitar aprobación ajena en decisiones clave.',
      scientificRationale: 'Desmantela la búsqueda de estatus mimético protegiendo el locus de control interno.',
      category: MasterHabitCategory.selfMastery,
      unit: 'sesión',
      targetCount: 1,
      xpReward: 15,
    ),
    MasterHabit(
      id: 'self_10',
      title: 'Silencio Estratégico en Discusiones Infructuosas',
      shortDescription: 'Elegir no tener la última palabra en debates triviales o confrontaciones digitales.',
      scientificRationale: 'Preserva la energía glucídica de la corteza prefrontal para proyectos de alta envergadura.',
      category: MasterHabitCategory.selfMastery,
      unit: 'interacciones',
      targetCount: 1,
      xpReward: 15,
    ),

    // -------------------------------------------------------------------------
    // 5. RELACIONES ESTRATÉGICAS (8 Hábitos)
    // -------------------------------------------------------------------------
    MasterHabit(
      id: 'rel_01',
      title: 'Presencia Absoluta Sin Dispositivos en Conversaciones',
      shortDescription: 'Teléfono boca abajo o fuera de la vista al interactuar cara a cara con otra persona.',
      scientificRationale: 'La mera presencia visible de un smartphone reduce la empatía y la capacidad cognitiva percibida.',
      category: MasterHabitCategory.relationships,
      unit: 'conversaciones',
      targetCount: 1,
      xpReward: 15,
    ),
    MasterHabit(
      id: 'rel_02',
      title: 'Mensaje de Valor Desinteresado a 1 Aliado',
      shortDescription: 'Enviar un recurso valioso, artículo o agradecimiento sincero sin pedir nada a cambio.',
      scientificRationale: 'Activa la reciprocidad indirecta y fortalece la densidad del capital social a largo plazo.',
      category: MasterHabitCategory.relationships,
      unit: 'mensaje',
      targetCount: 1,
      xpReward: 15,
    ),
    MasterHabit(
      id: 'rel_03',
      title: 'Escucha Activa de Nivel 3 (Validación Total)',
      shortDescription: 'Parafrasear lo que la otra persona expresó antes de exponer tu propio argumento.',
      scientificRationale: 'Reduce la defensiva amigdalina del interlocutor y crea puentes de confianza duraderos.',
      category: MasterHabitCategory.relationships,
      unit: 'escucha',
      targetCount: 1,
      xpReward: 15,
    ),
    MasterHabit(
      id: 'rel_04',
      title: 'Elogio Específico al Esfuerzo Ajeno',
      shortDescription: 'Reconocer el trabajo o dedicación de un colega, familiar o colaborador con precisión quirúrgica.',
      scientificRationale: 'Estimula el sistema de recompensa prosocial y eleva la cohesión de equipos y proyectos.',
      category: MasterHabitCategory.relationships,
      unit: 'reconocimiento',
      targetCount: 1,
      xpReward: 15,
    ),
    MasterHabit(
      id: 'rel_05',
      title: 'Establecimiento Asertivo de Límites (Decir No)',
      shortDescription: 'Rechazar solicitudes no prioritarias de manera amable, directa y sin excusas prolongadas.',
      scientificRationale: 'Protege la soberanía temporal y establece respeto profesional en jerarquías.',
      category: MasterHabitCategory.relationships,
      unit: 'límite',
      targetCount: 1,
      xpReward: 20,
    ),
    MasterHabit(
      id: 'rel_06',
      title: 'Auditoría de Entorno y Vínculos de Energía',
      shortDescription: 'Evaluar periódicamente si las 5 personas más cercanas suman claridad o amplifican caos.',
      scientificRationale: 'El contagio emocional y de hábitos opera por neuronas espejo de manera subcortical.',
      category: MasterHabitCategory.relationships,
      frequency: 'weekly',
      unit: 'auditoría',
      targetCount: 1,
      xpReward: 25,
    ),
    MasterHabit(
      id: 'rel_07',
      title: 'Puntualidad Impecable (5 Minutos de Margen)',
      shortDescription: 'Llegar o conectarse 5 minutos antes a cualquier reunión o cita acordada.',
      scientificRationale: 'Señaliza respeto de estatus superior, fiabilidad ejecutiva y orden mental interno.',
      category: MasterHabitCategory.relationships,
      unit: 'reuniones',
      targetCount: 1,
      xpReward: 15,
    ),
    MasterHabit(
      id: 'rel_08',
      title: 'Reconexión Semanal con Círculo Íntimo',
      shortDescription: 'Espacio dedicado de calidad (cena, llamada o paseo) sin interrupciones con seres queridos.',
      scientificRationale: 'Estimula la producción de oxitocina reduciendo la inflamación crónica por estrés existencial.',
      category: MasterHabitCategory.relationships,
      frequency: 'weekly',
      unit: 'reunión',
      targetCount: 1,
      xpReward: 25,
    ),
  ];

  static List<MasterHabit> getByCategory(MasterHabitCategory category) {
    return allHabits.where((h) => h.category == category).toList();
  }
}
