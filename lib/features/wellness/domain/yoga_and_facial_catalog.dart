import 'challenge_data.dart';

/// Item representing a posture or exercise in the master catalog.
class CatalogItem {
  final String title;
  final String category;
  final String description;
  final int defaultDurationSeconds;

  const CatalogItem({
    required this.title,
    required this.category,
    required this.description,
    this.defaultDurationSeconds = 40,
  });

  ExerciseStep toExerciseStep({int? durationSeconds, int preparationSeconds = 10}) {
    return ExerciseStep(
      title: title,
      category: category,
      instructions: description,
      durationSeconds: durationSeconds ?? defaultDurationSeconds,
      preparationSeconds: preparationSeconds,
    );
  }
}

/// Master database and session builder for Yoga (150 Asanas) and Face Yoga (50 Exercises).
class YogaAndFacialCatalog {
  // =========================================================================
  // 150 POSTURAS DE YOGA (Ejercicios de Yoga.md)
  // =========================================================================

  static const List<CatalogItem> yogaFuerza = [
    CatalogItem(
      title: 'Utkatasana (Silla Clásica)',
      category: 'Fuerza',
      description: 'Flexión de rodillas a 90 grados, pelvis en retroversión neutra y brazos elevados. 5 ciclos respiratorios (4s inhalar, 4s exhalar).',
      defaultDurationSeconds: 40,
    ),
    CatalogItem(
      title: 'Parivrtta Utkatasana (Silla en Torsión)',
      category: 'Fuerza',
      description: 'Rodillas alineadas, codo bloqueado contra el exterior del muslo opuesto.',
      defaultDurationSeconds: 40,
    ),
    CatalogItem(
      title: 'Virabhadrasana I (Guerrero 1)',
      category: 'Fuerza',
      description: 'Zancada profunda, pelvis encuadrada al frente, extensión torácica.',
      defaultDurationSeconds: 40,
    ),
    CatalogItem(
      title: 'Virabhadrasana II (Guerrero 2)',
      category: 'Fuerza',
      description: 'Zancada amplia lateral, abducción horizontal de brazos paralelos al suelo.',
      defaultDurationSeconds: 40,
    ),
    CatalogItem(
      title: 'Virabhadrasana III (Guerrero 3)',
      category: 'Fuerza',
      description: 'Bisagra de cadera unipodal formando una línea recta entre talón, tronco y dedos.',
      defaultDurationSeconds: 40,
    ),
    CatalogItem(
      title: 'Viparita Virabhadrasana (Guerrero Invertido Activo)',
      category: 'Fuerza',
      description: 'Retención isométrica de zancada con flexión lateral profunda del tronco.',
      defaultDurationSeconds: 40,
    ),
    CatalogItem(
      title: 'Phalakasana (Plancha Alta)',
      category: 'Fuerza',
      description: 'Muñecas bajo hombros, protracción escapular activa y core en máxima tensión.',
      defaultDurationSeconds: 40,
    ),
    CatalogItem(
      title: 'Chaturanga Dandasana (Plancha Baja a Cuatro Apoyos)',
      category: 'Fuerza',
      description: 'Codos a 90 grados rozando los costados, suspensión milimétrica del tapete.',
      defaultDurationSeconds: 30,
    ),
    CatalogItem(
      title: 'Vasisthasana (Plancha Lateral Estricta)',
      category: 'Fuerza',
      description: 'Apoyo sobre una sola muñeca, piernas apiladas, elevación continua de cadera.',
      defaultDurationSeconds: 40,
    ),
    CatalogItem(
      title: 'Vasisthasana con Pierna en Árbol',
      category: 'Fuerza',
      description: 'Plancha lateral insertando la planta superior en el muslo interno.',
      defaultDurationSeconds: 40,
    ),
    CatalogItem(
      title: 'Bakasana (El Cuervo)',
      category: 'Fuerza',
      description: 'Rodillas encajadas en axilas, codos rectos, peso transferido totalmente a las muñecas.',
      defaultDurationSeconds: 30,
    ),
    CatalogItem(
      title: 'Kakasana (El Cuervo con Codos Flexionados)',
      category: 'Fuerza',
      description: 'Brazos actuando como soporte angular para las espinillas.',
      defaultDurationSeconds: 30,
    ),
    CatalogItem(
      title: 'Navasana (El Barco Completo)',
      category: 'Fuerza',
      description: 'Equilibrio sobre isquiones, rodillas extendidas a 45 grados, columna recta.',
      defaultDurationSeconds: 40,
    ),
    CatalogItem(
      title: 'Ardha Navasana (Medio Barco)',
      category: 'Fuerza',
      description: 'Sacro y escápulas a 5 cm del suelo, tensión isométrica de la pared abdominal.',
      defaultDurationSeconds: 40,
    ),
    CatalogItem(
      title: 'Purvottanasana (Plancha Invertida)',
      category: 'Fuerza',
      description: 'Extensión total de cadera empujando plantas y talones al suelo.',
      defaultDurationSeconds: 40,
    ),
    CatalogItem(
      title: 'Setu Bandha Sarvangasana Dinámico',
      category: 'Fuerza',
      description: 'Elevación pélvica unipodal sin rotación de crestas ilíacas.',
      defaultDurationSeconds: 40,
    ),
    CatalogItem(
      title: 'Utkata Konasana (La Diosa)',
      category: 'Fuerza',
      description: 'Sentadilla estática piernas abiertas, fémures paralelos al suelo y torso vertical.',
      defaultDurationSeconds: 45,
    ),
    CatalogItem(
      title: 'Garudasana (El Águila)',
      category: 'Fuerza',
      description: 'Pierna entrelazada con flexión estática unipodal profunda.',
      defaultDurationSeconds: 40,
    ),
    CatalogItem(
      title: 'Ardha Chandrasana (Media Luna Activa)',
      category: 'Fuerza',
      description: 'Equilibrio unipodal con elevación del talón trasero a nivel de cadera.',
      defaultDurationSeconds: 40,
    ),
    CatalogItem(
      title: 'Salabhasana (El Saltamontes Completo)',
      category: 'Fuerza',
      description: 'Contracción de erectores espinales despegando muslos y pecho sin tocar el piso.',
      defaultDurationSeconds: 40,
    ),
    CatalogItem(
      title: 'Dolphin Pose (El Delfín)',
      category: 'Fuerza',
      description: 'Apoyo en antebrazos empujando la cintura escapular lejos del tapete en "V".',
      defaultDurationSeconds: 40,
    ),
    CatalogItem(
      title: 'Lolasana (Postura Colgante)',
      category: 'Fuerza',
      description: 'Empuje vertical máximo de manos elevando rodillas y pies en el aire.',
      defaultDurationSeconds: 30,
    ),
    CatalogItem(
      title: 'Tolasana (La Balanza)',
      category: 'Fuerza',
      description: 'Apoyo de palmas junto a caderas para suspender el torso en posición de loto.',
      defaultDurationSeconds: 30,
    ),
    CatalogItem(
      title: 'Mayurasana (El Pavo Real)',
      category: 'Fuerza',
      description: 'Apoyo sobre muñecas con codos al ombligo y cuerpo suspendido horizontal.',
      defaultDurationSeconds: 25,
    ),
    CatalogItem(
      title: 'Pincha Mayurasana (Inversión sobre Antebrazos)',
      category: 'Fuerza',
      description: 'Retención vertical apoyada en codos y antebrazos paralelos.',
      defaultDurationSeconds: 30,
    ),
    CatalogItem(
      title: 'Adho Mukha Vrksasana (Parada de Manos)',
      category: 'Fuerza',
      description: 'Alineación vertical estricta muñeca-hombro-cadera-tobillos.',
      defaultDurationSeconds: 30,
    ),
    CatalogItem(
      title: 'Sirsasana I (Parada de Cabeza Trípode Antebrazos)',
      category: 'Fuerza',
      description: 'Inversión sostenida por hombros y cuello neutro.',
      defaultDurationSeconds: 40,
    ),
    CatalogItem(
      title: 'Sirsasana II (Parada de Cabeza Trípode Abierto)',
      category: 'Fuerza',
      description: 'Manos y coronilla en triángulo equilátero, codos en 90 grados.',
      defaultDurationSeconds: 30,
    ),
    CatalogItem(
      title: 'Astavakrasana (Ocho Ángulos)',
      category: 'Fuerza',
      description: 'Balanza de brazos lateral con tobillos cruzados y piernas extendidas al costado.',
      defaultDurationSeconds: 30,
    ),
    CatalogItem(
      title: 'Eka Pada Koundinyasana I',
      category: 'Fuerza',
      description: 'Torsión con piernas separadas en tijera suspendidas sobre los brazos.',
      defaultDurationSeconds: 30,
    ),
    CatalogItem(
      title: 'Eka Pada Koundinyasana II',
      category: 'Fuerza',
      description: 'Pierna delantera extendida sobre el tríceps y trasera suspendida en línea recta.',
      defaultDurationSeconds: 30,
    ),
    CatalogItem(
      title: 'Titibasana (La Luciérnaga)',
      category: 'Fuerza',
      description: 'Aducción de muslos contra la espalda externa de los brazos, pies elevados.',
      defaultDurationSeconds: 30,
    ),
    CatalogItem(
      title: 'Parsva Bakasana (Cuervo Lateral)',
      category: 'Fuerza',
      description: 'Piernas compactadas sobre un solo tríceps mediante rotación axial del tronco.',
      defaultDurationSeconds: 30,
    ),
    CatalogItem(
      title: 'Bhujapidasana',
      category: 'Fuerza',
      description: 'Brazos entrelazados por dentro de las piernas sosteniendo el cuerpo con los pies cruzados al frente.',
      defaultDurationSeconds: 30,
    ),
    CatalogItem(
      title: 'Kukkutasana',
      category: 'Fuerza',
      description: 'Manos insertadas entre los muslos en loto empujando para levitar la base del cuerpo.',
      defaultDurationSeconds: 30,
    ),
    CatalogItem(
      title: 'Eka Pada Galavasana (Paloma Voladora)',
      category: 'Fuerza',
      description: 'Espinilla cruzada sobre ambos tríceps extendiendo la otra pierna hacia atrás.',
      defaultDurationSeconds: 30,
    ),
    CatalogItem(
      title: 'Dwi Pada Koundinyasana',
      category: 'Fuerza',
      description: 'Ambas piernas juntas y estiradas al lateral apoyadas en un solo brazo.',
      defaultDurationSeconds: 30,
    ),
    CatalogItem(
      title: 'Kumbhakasana a Tres Apoyos',
      category: 'Fuerza',
      description: 'Plancha alta con un pie despegado en línea horizontal con el glúteo.',
      defaultDurationSeconds: 40,
    ),
    CatalogItem(
      title: 'Chaturanga con Elevación Unipodal',
      category: 'Fuerza',
      description: 'Plancha baja retenida sobre tres puntos de contacto.',
      defaultDurationSeconds: 30,
    ),
    CatalogItem(
      title: 'Utthita Hasta Padangusthasana',
      category: 'Fuerza',
      description: 'Mantener la pierna extendida a 90 grados solo con la fuerza del psoas y cuádriceps.',
      defaultDurationSeconds: 40,
    ),
    CatalogItem(
      title: 'Urdhva Dandasana',
      category: 'Fuerza',
      description: 'Descenso de piernas a 90 grados desde la parada de cabeza sin perder la vertical torácica.',
      defaultDurationSeconds: 30,
    ),
    CatalogItem(
      title: 'Simhasana Activo (El León en Tensión)',
      category: 'Fuerza',
      description: 'Flexión de muñecas y descarga isométrica de cuello, cara y suelo pélvico.',
      defaultDurationSeconds: 40,
    ),
    CatalogItem(
      title: 'Viparita Dandasana (Bastón Invertido Activo)',
      category: 'Fuerza',
      description: 'Extensión de espalda alta sobre antebrazos con tracción glútea.',
      defaultDurationSeconds: 40,
    ),
    CatalogItem(
      title: 'Ganda Bherundasana',
      category: 'Fuerza',
      description: 'Suspensión invertida apoyando mentón y hombros mientras la espalda se arquea vertical.',
      defaultDurationSeconds: 25,
    ),
    CatalogItem(
      title: 'Vasisthasana Elevando Dedo Gordo',
      category: 'Fuerza',
      description: 'Plancha lateral con tracción de la pierna superior a la vertical.',
      defaultDurationSeconds: 35,
    ),
    CatalogItem(
      title: 'Utthita Parsvakonasana Activo',
      category: 'Fuerza',
      description: 'Zancada lateral con el torso en diagonal sosteniendo una pelota imaginaria entre las manos.',
      defaultDurationSeconds: 40,
    ),
    CatalogItem(
      title: 'Tadasana en Relevé con Empuje Superior',
      category: 'Fuerza',
      description: 'Bloqueo de tobillos elevando talones al máximo mientras se empujan hombros arriba.',
      defaultDurationSeconds: 40,
    ),
    CatalogItem(
      title: 'Anantasana Activo',
      category: 'Fuerza',
      description: 'Equilibrio lateral sobre el costado sin desplome pélvico, despegando ambas piernas del suelo.',
      defaultDurationSeconds: 40,
    ),
    CatalogItem(
      title: 'Urdhva Prasarita Padasana',
      category: 'Fuerza',
      description: 'Elevaciones controladas de piernas rectas a 30, 60 y 90 grados desde el tapete.',
      defaultDurationSeconds: 45,
    ),
    CatalogItem(
      title: 'Brahmacharyasana',
      category: 'Fuerza',
      description: 'Elevación completa del cuerpo sentado desde Dandasana usando solo palmas planas en el suelo.',
      defaultDurationSeconds: 30,
    ),
  ];

  static const List<CatalogItem> yogaFlexibilidad = [
    CatalogItem(
      title: 'Paschimottanasana (La Pinza Sentada)',
      category: 'Flexibilidad',
      description: 'Flexión completa de cadera hacia piernas extendidas con tracción plantar. 10s activo, 60s pasivo.',
      defaultDurationSeconds: 70,
    ),
    CatalogItem(
      title: 'Uttanasana (Pinza de Pie)',
      category: 'Flexibilidad',
      description: 'Gravedad asistiendo el alargamiento total de la cadena miofascial posterior.',
      defaultDurationSeconds: 60,
    ),
    CatalogItem(
      title: 'Prasarita Padottanasana A',
      category: 'Flexibilidad',
      description: 'Flexión profunda con piernas abiertas a 1.5 metros, palmas planas al piso.',
      defaultDurationSeconds: 60,
    ),
    CatalogItem(
      title: 'Prasarita Padottanasana C',
      category: 'Flexibilidad',
      description: 'Misma apertura de piernas con manos entrelazadas proyectando los puños hacia el piso.',
      defaultDurationSeconds: 60,
    ),
    CatalogItem(
      title: 'Baddha Konasana (La Mariposa Activa)',
      category: 'Flexibilidad',
      description: 'Abducción de cadera empujando activamente las rodillas hacia el suelo.',
      defaultDurationSeconds: 60,
    ),
    CatalogItem(
      title: 'Upavistha Konasana',
      category: 'Flexibilidad',
      description: 'Apertura de piernas en split angular sentado, llevando esternón y barbilla al tapete.',
      defaultDurationSeconds: 70,
    ),
    CatalogItem(
      title: 'Hanumanasana (Split Frontal Completo)',
      category: 'Flexibilidad',
      description: '180 grados de separación sagital de cadera con pelvis encuadrada.',
      defaultDurationSeconds: 60,
    ),
    CatalogItem(
      title: 'Samakonasana (Split Frontal Transversal)',
      category: 'Flexibilidad',
      description: '180 grados de abducción horizontal de piernas alineadas con la pelvis.',
      defaultDurationSeconds: 60,
    ),
    CatalogItem(
      title: 'Anjaneyasana (Zancada Baja Profunda)',
      category: 'Flexibilidad',
      description: 'Elongación de psoas y flexores de cadera con arqueo torácico.',
      defaultDurationSeconds: 60,
    ),
    CatalogItem(
      title: 'Kapotasana (La Paloma Espinal)',
      category: 'Flexibilidad',
      description: 'Flexión posterior de rodillas buscando los pies con las manos detrás de la cabeza.',
      defaultDurationSeconds: 60,
    ),
    CatalogItem(
      title: 'Eka Pada Rajakapotasana I',
      category: 'Flexibilidad',
      description: 'Rotación externa del muslo frontal con tracción dorsal del tobillo posterior.',
      defaultDurationSeconds: 60,
    ),
    CatalogItem(
      title: 'Gomukhasana (Cara de Vaca)',
      category: 'Flexibilidad',
      description: 'Aducción cruzada de caderas y rotación interna/externa profunda de hombros.',
      defaultDurationSeconds: 60,
    ),
    CatalogItem(
      title: 'Ustrasana (El Camello)',
      category: 'Flexibilidad',
      description: 'Extensión dorsal máxima tocando talones con manos desde apoyo en rodillas.',
      defaultDurationSeconds: 50,
    ),
    CatalogItem(
      title: 'Chakrasana / Urdhva Dhanurasana (La Rueda)',
      category: 'Flexibilidad',
      description: 'Arco completo abriendo hombros, pectoral, abdomen y flexores femorales.',
      defaultDurationSeconds: 50,
    ),
    CatalogItem(
      title: 'Dhanurasana (El Arco)',
      category: 'Flexibilidad',
      description: 'Tracción de tobillos separando cuádriceps del piso por tensión de la cadena anterior.',
      defaultDurationSeconds: 50,
    ),
    CatalogItem(
      title: 'Bhujangasana (La Cobra Estricta)',
      category: 'Flexibilidad',
      description: 'Hiperextensión de la columna conservando el hueso púbico enraizado al tapete.',
      defaultDurationSeconds: 50,
    ),
    CatalogItem(
      title: 'Matsyasana (El Pez Clásico)',
      category: 'Flexibilidad',
      description: 'Apertura torácica y flexibilización de cuello apoyando coronilla en el suelo.',
      defaultDurationSeconds: 60,
    ),
    CatalogItem(
      title: 'Supta Virasana',
      category: 'Flexibilidad',
      description: 'Flexibilización de cuádriceps y tobillos reclinando la espalda plana entre los pies.',
      defaultDurationSeconds: 70,
    ),
    CatalogItem(
      title: 'Supta Baddha Konasana',
      category: 'Flexibilidad',
      description: 'Mariposa decúbito supino para extensión pasiva de aductores y suelo pélvico.',
      defaultDurationSeconds: 70,
    ),
    CatalogItem(
      title: 'Supta Padangusthasana A',
      category: 'Flexibilidad',
      description: 'Flexión sagital unipodal sostenida por cinta o mano con la otra pierna bloqueada en suelo.',
      defaultDurationSeconds: 60,
    ),
    CatalogItem(
      title: 'Supta Padangusthasana B',
      category: 'Flexibilidad',
      description: 'Apertura lateral de la pierna sostenida sin despegar el glúteo contrario del piso.',
      defaultDurationSeconds: 60,
    ),
    CatalogItem(
      title: 'Trikonasana (El Triángulo Clásico)',
      category: 'Flexibilidad',
      description: 'Estiramiento miofascial lateral de oblicuos, dorsal y peroneos.',
      defaultDurationSeconds: 60,
    ),
    CatalogItem(
      title: 'Parsvottanasana (La Pirámide)',
      category: 'Flexibilidad',
      description: 'Estiramiento focalizado en bíceps femoral de la pierna anterior con manos en Namasté invertido.',
      defaultDurationSeconds: 60,
    ),
    CatalogItem(
      title: 'Parivrtta Trikonasana',
      category: 'Flexibilidad',
      description: 'Rotación de columna torácica combinada con tracción isquiotibial severa.',
      defaultDurationSeconds: 60,
    ),
    CatalogItem(
      title: 'Ardha Matsyendrasana',
      category: 'Flexibilidad',
      description: 'Torsión axial sentada descomprimiendo articulaciones intervertebrales.',
      defaultDurationSeconds: 60,
    ),
    CatalogItem(
      title: 'Marichyasana A',
      category: 'Flexibilidad',
      description: 'Flexión hacia una pierna con atadura de brazos envolviendo la espinilla doblada.',
      defaultDurationSeconds: 60,
    ),
    CatalogItem(
      title: 'Marichyasana C',
      category: 'Flexibilidad',
      description: 'Torsión profunda abrazando o cruzando el tríceps por el exterior de la rodilla flexionada.',
      defaultDurationSeconds: 60,
    ),
    CatalogItem(
      title: 'Anahatasana (Cachorro / Corazón al Suelo)',
      category: 'Flexibilidad',
      description: 'Descarga de flexión de hombros apoyando barbilla y esternón en el suelo.',
      defaultDurationSeconds: 60,
    ),
    CatalogItem(
      title: 'Malasana (Sentadilla Profunda Asistida)',
      category: 'Flexibilidad',
      description: 'Flexión máxima de tobillos (dorsiflexión) y apertura articular coxofemoral.',
      defaultDurationSeconds: 60,
    ),
    CatalogItem(
      title: 'Virasana',
      category: 'Flexibilidad',
      description: 'Apertura ligamentosa de rodillas y empeines apoyando glúteos directamente en el suelo.',
      defaultDurationSeconds: 60,
    ),
    CatalogItem(
      title: 'Janu Sirsasana A',
      category: 'Flexibilidad',
      description: 'Flexión asimétrica anterior llevando la frente a la tibia extendida.',
      defaultDurationSeconds: 60,
    ),
    CatalogItem(
      title: 'Parivrtta Janu Sirsasana',
      category: 'Flexibilidad',
      description: 'Torsión lateral profunda hacia el pie con apertura costal superior completa.',
      defaultDurationSeconds: 60,
    ),
    CatalogItem(
      title: 'Skandasana',
      category: 'Flexibilidad',
      description: 'Movilidad de aductores y tobillos en cuclillas asimétrica sobre un solo pie apoyado.',
      defaultDurationSeconds: 50,
    ),
    CatalogItem(
      title: 'Krounchasana (La Garza)',
      category: 'Flexibilidad',
      description: 'Estiramiento vertical de isquiotibial aproximando la espinilla al rostro sentado.',
      defaultDurationSeconds: 50,
    ),
    CatalogItem(
      title: 'Triang Mukaekapada Paschimottanasana',
      category: 'Flexibilidad',
      description: 'Flexión sentada con una pierna en Pinza y la otra en Virasana.',
      defaultDurationSeconds: 60,
    ),
    CatalogItem(
      title: 'Bhekasana (La Rana)',
      category: 'Flexibilidad',
      description: 'Boca abajo, presión de palmas sobre empeines forzando los talones directo al piso junto a la cadera.',
      defaultDurationSeconds: 50,
    ),
    CatalogItem(
      title: 'Ardha Baddha Padma Paschimottanasana',
      category: 'Flexibilidad',
      description: 'Flexión anterior con un pie colocado en medio loto en el pliegue inguinal.',
      defaultDurationSeconds: 60,
    ),
    CatalogItem(
      title: 'Garudasana de Brazos',
      category: 'Flexibilidad',
      description: 'Estiramiento de romboides y deltoides posteriores mediante cruce biomecánico estricto.',
      defaultDurationSeconds: 50,
    ),
    CatalogItem(
      title: 'Purna Matsyendrasana (Torsión Completa)',
      category: 'Flexibilidad',
      description: 'Torsión con base en Padmasana cruzando el brazo opuesto hasta el pie.',
      defaultDurationSeconds: 60,
    ),
    CatalogItem(
      title: 'Yoganidrasana (El Sueño del Yogui)',
      category: 'Flexibilidad',
      description: 'Flexión lumbar y de cadera extrema colocando ambos pies tras la nuca.',
      defaultDurationSeconds: 40,
    ),
    CatalogItem(
      title: 'Dwi Pada Sirsasana',
      category: 'Flexibilidad',
      description: 'Sentado con ambas piernas cruzadas y aseguradas detrás de la cabeza.',
      defaultDurationSeconds: 40,
    ),
    CatalogItem(
      title: 'Eka Pada Sirsasana',
      category: 'Flexibilidad',
      description: 'Unipodal llevando un solo tobillo detrás del cuello manteniendo el tronco erguido.',
      defaultDurationSeconds: 40,
    ),
    CatalogItem(
      title: 'Vrischikasana (El Escorpión)',
      category: 'Flexibilidad',
      description: 'Extensión dorsal extrema en antebrazos hasta tocar la coronilla con los dedos de los pies.',
      defaultDurationSeconds: 30,
    ),
    CatalogItem(
      title: 'Natarajasana (Danza de Shiva)',
      category: 'Flexibilidad',
      description: 'Extensión de cadera en flexión hacia atrás con agarre de codos sobre la cabeza.',
      defaultDurationSeconds: 50,
    ),
    CatalogItem(
      title: 'Utthita Tadasana con Extensión Lateral',
      category: 'Flexibilidad',
      description: 'Elongación fascial lateral completa de pie con pies anchos y brazos extendidos.',
      defaultDurationSeconds: 50,
    ),
    CatalogItem(
      title: 'Kandharasana',
      category: 'Flexibilidad',
      description: 'Flexibilización cervical e interescapular empujando el mentón al pecho con pelvis elevada.',
      defaultDurationSeconds: 50,
    ),
    CatalogItem(
      title: 'Supta Trivikramasana',
      category: 'Flexibilidad',
      description: 'Tumbado de espaldas llevando una pierna estirada al suelo por detrás de la cabeza.',
      defaultDurationSeconds: 50,
    ),
    CatalogItem(
      title: 'Mandukasana (La Rana Sentada)',
      category: 'Flexibilidad',
      description: 'Apertura biomecánica de aductores con rodillas y tobillos flexionados a 90 grados en suelo.',
      defaultDurationSeconds: 60,
    ),
    CatalogItem(
      title: 'Kurmasana (La Tortuga)',
      category: 'Flexibilidad',
      description: 'Brazos extendidos bajo las rodillas deslizando el pecho y hombros hacia el suelo plano.',
      defaultDurationSeconds: 60,
    ),
    CatalogItem(
      title: 'Supta Kurmasana',
      category: 'Flexibilidad',
      description: 'Brazos entrelazados sobre la espalda lumbar desde la flexión máxima de Kurmasana.',
      defaultDurationSeconds: 50,
    ),
  ];

  static const List<CatalogItem> yogaRelajacion = [
    CatalogItem(
      title: 'Savasana',
      category: 'Relajación',
      description: 'Relajación neuromuscular en decúbito supino con brazos a 45 grados y palmas al cielo. Silencio y respiración calma.',
      defaultDurationSeconds: 90,
    ),
    CatalogItem(
      title: 'Balasana (El Niño Tradicional)',
      category: 'Relajación',
      description: 'Glúteos a talones, frente apoyada, brazos relajados al costado del torso.',
      defaultDurationSeconds: 90,
    ),
    CatalogItem(
      title: 'Uttana Shishosana Suave',
      category: 'Relajación',
      description: 'Flexión pasiva de columna dorsal con frente o mejilla descansando en el tapete.',
      defaultDurationSeconds: 90,
    ),
    CatalogItem(
      title: 'Viparita Karani',
      category: 'Relajación',
      description: 'Retorno venoso asistido manteniendo las piernas verticales apoyadas en un muro.',
      defaultDurationSeconds: 90,
    ),
    CatalogItem(
      title: 'Supta Matsyendrasana',
      category: 'Relajación',
      description: 'Caída lateral libre de ambas rodillas juntas desbloqueando la fascia toracolumbar.',
      defaultDurationSeconds: 80,
    ),
    CatalogItem(
      title: 'Ananda Balasana (Bebé Feliz Pasivo)',
      category: 'Relajación',
      description: 'Flexión suave traccionando las plantas hacia el suelo con la espalda plana.',
      defaultDurationSeconds: 80,
    ),
    CatalogItem(
      title: 'Makarasana (El Cocodrilo)',
      category: 'Relajación',
      description: 'Apoyo prono con piernas abiertas y talones hacia adentro para aliviar la tensión lumbosacra.',
      defaultDurationSeconds: 90,
    ),
    CatalogItem(
      title: 'Matsyasana con Bloque (Pez Restaurativo)',
      category: 'Relajación',
      description: 'Bloque bajo escápulas y otro bajo la nuca para apertura pectoral pasiva.',
      defaultDurationSeconds: 90,
    ),
    CatalogItem(
      title: 'Setu Bandha con Soporte Sacro',
      category: 'Relajación',
      description: 'Pelvis sostenida sobre un bloque de yoga a altura media o baja.',
      defaultDurationSeconds: 90,
    ),
    CatalogItem(
      title: 'Balasana con Bolster',
      category: 'Relajación',
      description: 'Rodillas abiertas y tronco reposando sobre un cojín alargado con respiración diafragmática.',
      defaultDurationSeconds: 90,
    ),
    CatalogItem(
      title: 'Supta Baddha Konasana Asistida',
      category: 'Relajación',
      description: 'Soporte bajo la espalda y mantas enrolladas bajo los muslos para evitar tensión inguinal.',
      defaultDurationSeconds: 90,
    ),
    CatalogItem(
      title: 'Giro Espinal Asistido',
      category: 'Relajación',
      description: 'Rodillas descansando sobre mantas gruesas para anular el esfuerzo de rotación del torso.',
      defaultDurationSeconds: 80,
    ),
    CatalogItem(
      title: 'Dandasana Contra la Pared',
      category: 'Relajación',
      description: 'Descarga de musculatura paravertebral manteniendo el ángulo pélvico recto asistido.',
      defaultDurationSeconds: 80,
    ),
    CatalogItem(
      title: 'Padmasana Relajado (Respiración Inmóvil)',
      category: 'Relajación',
      description: 'Postura sentada simétrica apoyando muñecas sin esfuerzo sobre las rodillas.',
      defaultDurationSeconds: 90,
    ),
    CatalogItem(
      title: 'Siddhasana',
      category: 'Relajación',
      description: 'Asiento de quietud con talones alineados para canalización vegetativa y disminución del pulso.',
      defaultDurationSeconds: 90,
    ),
    CatalogItem(
      title: 'Sukhasana con Respaldo',
      category: 'Relajación',
      description: 'Sentado sobre manta con espalda apoyada para liberación de diafragma y hombros.',
      defaultDurationSeconds: 90,
    ),
    CatalogItem(
      title: 'Apanasana (Postura de Liberación del Viento)',
      category: 'Relajación',
      description: 'Tracción intermitente suave de rodillas al abdomen al compás respiratorio.',
      defaultDurationSeconds: 80,
    ),
    CatalogItem(
      title: 'Eka Pada Apanasana',
      category: 'Relajación',
      description: 'Rodilla abrazada al pecho con descarga pasiva del psoas de la pierna opuesta.',
      defaultDurationSeconds: 80,
    ),
    CatalogItem(
      title: 'Parsva Savasana (Posición Fetal Derecha)',
      category: 'Relajación',
      description: 'Flexión lateral suave reduciendo la presión en el retorno cardíaco.',
      defaultDurationSeconds: 90,
    ),
    CatalogItem(
      title: 'Salamba Balasana Frontal',
      category: 'Relajación',
      description: 'Frente sobre puños apilados reduciendo la tensión muscular cervical posterior.',
      defaultDurationSeconds: 80,
    ),
    CatalogItem(
      title: 'Viparita Karani con Elevación Pélvica',
      category: 'Relajación',
      description: 'Manta gruesa bajo el sacro intensificando el drenaje linfático periférico.',
      defaultDurationSeconds: 90,
    ),
    CatalogItem(
      title: 'Supta Gomukhasana Relajada',
      category: 'Relajación',
      description: 'Piernas cruzadas hacia el pecho sin tracción manual activa de brazos.',
      defaultDurationSeconds: 80,
    ),
    CatalogItem(
      title: 'Pavanmuktasana Estática',
      category: 'Relajación',
      description: 'Retención pasiva con respiración abdominal profunda masajeando vísceras.',
      defaultDurationSeconds: 80,
    ),
    CatalogItem(
      title: 'Savasana Prono (Boca Abajo)',
      category: 'Relajación',
      description: 'Todo el peso descargado sobre el vientre con cabeza girada a un lado.',
      defaultDurationSeconds: 90,
    ),
    CatalogItem(
      title: 'Ardha Kurmasana Descendente',
      category: 'Relajación',
      description: 'Descenso suave desde Virasana con los brazos extendidos y apoyados sobre cojines.',
      defaultDurationSeconds: 80,
    ),
    CatalogItem(
      title: 'Supta Baddha Konasana con Cinto',
      category: 'Relajación',
      description: 'Correa fija entre pelvis y pies eliminando el esfuerzo de retención muscular.',
      defaultDurationSeconds: 90,
    ),
    CatalogItem(
      title: 'Balasana con Flexión Lateral Asistida',
      category: 'Relajación',
      description: 'Respiración dirigida al espacio intercostal estirando el cuadrado lumbar pasivamente.',
      defaultDurationSeconds: 80,
    ),
    CatalogItem(
      title: 'Descompresión Suboccipital con Bloque',
      category: 'Relajación',
      description: 'Base del cráneo reposando en la arista de un bloque para descarga del nervio vago.',
      defaultDurationSeconds: 90,
    ),
    CatalogItem(
      title: 'Savasana con Soporte Poplíteo',
      category: 'Relajación',
      description: 'Cojín cilíndrico bajo rodillas para aplanar y relajar el psoas mayor.',
      defaultDurationSeconds: 90,
    ),
    CatalogItem(
      title: 'Savasana en Silla (Ángulo Cero)',
      category: 'Relajación',
      description: 'Pantorrillas sobre el asiento descargando totalmente la presión lumbosacra.',
      defaultDurationSeconds: 90,
    ),
    CatalogItem(
      title: 'Torsión Torácica con Cojín entre Rodillas',
      category: 'Relajación',
      description: 'Mantenimiento de alineación de caderas mientras la cintura escapular cede al suelo.',
      defaultDurationSeconds: 80,
    ),
    CatalogItem(
      title: 'Apertura de Pecho Longitudinal',
      category: 'Relajación',
      description: 'Columna alineada sobre un bolster colocado verticalmente desde el sacro hasta la coronilla.',
      defaultDurationSeconds: 90,
    ),
    CatalogItem(
      title: 'Descarga de Psoas en Mesa',
      category: 'Relajación',
      description: 'Muslos apoyados en elevación horizontal, tronco extendido en el suelo.',
      defaultDurationSeconds: 80,
    ),
    CatalogItem(
      title: 'Relajación de Muñecas en Balasana Invertida',
      category: 'Relajación',
      description: 'Palmas mirando al techo junto a los tobillos descargando flexores del antebrazo.',
      defaultDurationSeconds: 80,
    ),
    CatalogItem(
      title: 'Supta Virasana con Tres Bloques',
      category: 'Relajación',
      description: 'Soporte piramidal en espalda evitando sobretensión en rodillas.',
      defaultDurationSeconds: 90,
    ),
    CatalogItem(
      title: 'Supta Sukhasana',
      category: 'Relajación',
      description: 'Espalda apoyada sobre almohadón con piernas en cruce simple suelto.',
      defaultDurationSeconds: 90,
    ),
    CatalogItem(
      title: 'Descarga Lumbar en Pared (Pelvis en Elevación)',
      category: 'Relajación',
      description: 'Apoyo de pies en la pared en 90 grados con sacro sobre manta.',
      defaultDurationSeconds: 90,
    ),
    CatalogItem(
      title: 'Baddha Konasana Sentado con Apoyo de Frente',
      category: 'Relajación',
      description: 'Frente apoyada sobre el borde de un bloque colocado sobre los pies.',
      defaultDurationSeconds: 80,
    ),
    CatalogItem(
      title: 'Plegaria Invertida Relajada',
      category: 'Relajación',
      description: 'Tendido boca abajo con palmas juntas tocando la nuca, relajando tríceps.',
      defaultDurationSeconds: 80,
    ),
    CatalogItem(
      title: 'Descarga Fascial Plantar en Vajrasana Asistido',
      category: 'Relajación',
      description: 'Bloque colocado entre pantorrillas y muslos para descargar tendón de Aquiles.',
      defaultDurationSeconds: 80,
    ),
    CatalogItem(
      title: 'Torsión Prona sobre Cojín',
      category: 'Relajación',
      description: 'Vientre y pecho girados sobre un almohadón largo con cabeza rotada suavemente.',
      defaultDurationSeconds: 80,
    ),
    CatalogItem(
      title: 'Upavistha Konasana con Apoyo de Torso',
      category: 'Relajación',
      description: 'Frente y esternón descansando sobre una torre de mantas entre las piernas.',
      defaultDurationSeconds: 90,
    ),
    CatalogItem(
      title: 'Savasana con Ojos Cubiertos',
      category: 'Relajación',
      description: 'Apoyo de almohadilla ocular para inducir el reflejo oculocardíaco parasimpático.',
      defaultDurationSeconds: 90,
    ),
    CatalogItem(
      title: 'Estiramiento Lateral de Plátano (Bananasana)',
      category: 'Relajación',
      description: 'Tumbado supino curvando pies y brazos a un lado sin despegar caderas.',
      defaultDurationSeconds: 80,
    ),
    CatalogItem(
      title: 'Relajación Escapular en Decúbito Lateral',
      category: 'Relajación',
      description: 'Apoyo de hombro en tapete con brazo libre cayendo hacia atrás por gravedad.',
      defaultDurationSeconds: 80,
    ),
    CatalogItem(
      title: 'Mariposa en Pared',
      category: 'Relajación',
      description: 'Pies juntos con rodillas cayendo abiertas hacia los laterales mientras los talones tocan el muro.',
      defaultDurationSeconds: 90,
    ),
    CatalogItem(
      title: 'Descarga Pélvica en Esfinge Pasiva',
      category: 'Relajación',
      description: 'Codos sobre almohada con zona lumbar relajada por completo.',
      defaultDurationSeconds: 90,
    ),
    CatalogItem(
      title: 'Postura del Puente Flotante Pasivo',
      category: 'Relajación',
      description: 'Pelvis sostenida por dos bloques alineados verticalmente bajo el hueso sacro.',
      defaultDurationSeconds: 90,
    ),
    CatalogItem(
      title: 'Postura de la Oruga (Yin Yoga)',
      category: 'Relajación',
      description: 'Flexión anterior suave de espalda redonda sin tirar con los brazos, dejando colgar la cabeza.',
      defaultDurationSeconds: 90,
    ),
    CatalogItem(
      title: 'Savasana Pesado',
      category: 'Relajación',
      description: 'Manta con peso doblada sobre la pelvis y muslos para grounding propioceptivo.',
      defaultDurationSeconds: 90,
    ),
  ];

  // =========================================================================
  // 50 EJERCICIOS DE YOGA FACIAL (Yoga Facial.md)
  // =========================================================================

  static const List<CatalogItem> facialFrente = [
    CatalogItem(
      title: 'El Alisador Frontal',
      category: 'Frente y Entrecejo',
      description: 'Apoyar las yemas de todos los dedos en el centro de la frente y deslizar lateralmente hacia las sienes con presión moderada mientras se intenta elevar las cejas.',
      defaultDurationSeconds: 30,
    ),
    CatalogItem(
      title: 'Resistencia de Cejas',
      category: 'Frente y Entrecejo',
      description: 'Bloquear el músculo frontal apoyando ambas palmas planas sobre la frente; intentar elevar las cejas al máximo contra la resistencia de las manos.',
      defaultDurationSeconds: 30,
    ),
    CatalogItem(
      title: 'Pellizco Descompresor del Entrecejo',
      category: 'Frente y Entrecejo',
      description: 'Sujetar el músculo corrugador (inicio interno de las cejas) con índice y pulgar; presionar y soltar avanzando hacia el arco externo.',
      defaultDurationSeconds: 30,
    ),
    CatalogItem(
      title: 'V Invertida en el Entrecejo',
      category: 'Frente y Entrecejo',
      description: 'Colocar los dedos índices en forma de tijera sobre el entrecejo para inmovilizar la piel; fruncir el ceño activamente contra los dedos.',
      defaultDurationSeconds: 30,
    ),
    CatalogItem(
      title: 'Elevación Unilateral de Ceja',
      category: 'Frente y Entrecejo',
      description: 'Sostener una ceja firme hacia abajo con una mano mientras se intenta levantar únicamente la ceja contraria de forma aislada.',
      defaultDurationSeconds: 30,
    ),
    CatalogItem(
      title: 'Deslizamiento con Nudillos',
      category: 'Frente y Entrecejo',
      description: 'Cerrar los puños y usar los nudillos medios para trazar líneas ascendentes desde las cejas hasta el nacimiento del cabello.',
      defaultDurationSeconds: 30,
    ),
    CatalogItem(
      title: 'Punto Yintang Isométrico',
      category: 'Frente y Entrecejo',
      description: 'Presionar el punto medio entre las cejas con el dedo medio mientras se cierran los ojos con fuerza durante 10 segundos.',
      defaultDurationSeconds: 30,
    ),
    CatalogItem(
      title: 'Anclaje Temporal',
      category: 'Frente y Entrecejo',
      description: 'Colocar las palmas en las sienes, estirar la piel suavemente hacia arriba y atrás, y cerrar los párpados lentamente sintiendo la tracción en el músculo temporal.',
      defaultDurationSeconds: 30,
    ),
    CatalogItem(
      title: 'Bipestaneo de Resistencia Frontal',
      category: 'Frente y Entrecejo',
      description: 'Abrir los ojos al máximo sin arrugar la frente, manteniendo los dedos índice presionando la parte superior de las cejas para anular su movimiento.',
      defaultDurationSeconds: 30,
    ),
    CatalogItem(
      title: 'Amasamiento Suave de Frente',
      category: 'Frente y Entrecejo',
      description: 'Realizar movimientos circulares con los dedos a lo largo de las fibras horizontales del frontal para liberar adherencias miofasciales.',
      defaultDurationSeconds: 30,
    ),
  ];

  static const List<CatalogItem> facialOjos = [
    CatalogItem(
      title: 'La "V" para Bolsas',
      category: 'Contorno de Ojos',
      description: 'Colocar el dedo medio en la comisura interna del ojo y el índice en la externa; mirar al techo e intentar entrecerrar únicamente el párpado inferior sintiendo el temblor muscular.',
      defaultDurationSeconds: 30,
    ),
    CatalogItem(
      title: 'Aleteo de Párpados',
      category: 'Contorno de Ojos',
      description: 'Entrecerrar los párpados superiores al 90% y hacer pulsos rápidos de contracción sin apretar completamente los ojos.',
      defaultDurationSeconds: 30,
    ),
    CatalogItem(
      title: 'Gafas Isométricas',
      category: 'Contorno de Ojos',
      description: 'Formar círculos con dedos índice y pulgar alrededor de la cuenca ocular presionando el hueso; abrir los ojos al máximo contra la tensión de los dedos.',
      defaultDurationSeconds: 30,
    ),
    CatalogItem(
      title: 'Elevación del Párpado Caído',
      category: 'Contorno de Ojos',
      description: 'Colocar las puntas de los índices justo debajo de las cejas empujando hacia arriba; cerrar los párpados despacio venciendo la fuerza contraria.',
      defaultDurationSeconds: 30,
    ),
    CatalogItem(
      title: 'Parpadeo con Resistencia Externa',
      category: 'Contorno de Ojos',
      description: 'Fijar las comisuras externas (patas de gallo) con los dedos índice; cerrar los ojos con fuerza evitando que la piel forme pliegues laterales.',
      defaultDurationSeconds: 30,
    ),
    CatalogItem(
      title: 'Drenaje Lagrimal a Sienes',
      category: 'Contorno de Ojos',
      description: 'Deslizar con toque mínimo el dedo anular desde la esquina interna de la ojera, contorneando el pómulo superior hasta la sien.',
      defaultDurationSeconds: 40,
    ),
    CatalogItem(
      title: 'Cierre Compresivo de Párpados',
      category: 'Contorno de Ojos',
      description: 'Cerrar los ojos con el 100% de fuerza muscular durante 5 segundos y abrir repentinamente relajando la mirada.',
      defaultDurationSeconds: 30,
    ),
    CatalogItem(
      title: 'Mirada en Ocho Horizontal',
      category: 'Contorno de Ojos',
      description: 'Mantener la cabeza fija y trazar ochos continuos con los globos oculares en su rango máximo articular.',
      defaultDurationSeconds: 30,
    ),
    CatalogItem(
      title: 'Bolsas Elevadas con Oclusión',
      category: 'Contorno de Ojos',
      description: 'Mirar al cielo con la boca abierta en "O" pequeña y forzar el párpado inferior a subir sin mover el resto del rostro.',
      defaultDurationSeconds: 30,
    ),
    CatalogItem(
      title: 'Punto Taiyang',
      category: 'Contorno de Ojos',
      description: 'Presión circular estática en la depresión lateral de las sienes mientras se parpadea de forma continua y suave.',
      defaultDurationSeconds: 30,
    ),
  ];

  static const List<CatalogItem> facialPomulos = [
    CatalogItem(
      title: 'La "O" Sonriente',
      category: 'Pómulos y Mejillas',
      description: 'Formar una "O" vertical alargada cubriendo los dientes con los labios y elevar las comisuras hacia arriba simulando una sonrisa amplia.',
      defaultDurationSeconds: 30,
    ),
    CatalogItem(
      title: 'La Cara de Pez Activa',
      category: 'Pómulos y Mejillas',
      description: 'Succionar las mejillas hacia adentro de la boca y sostener el vacío mientras se intenta sonreír y parpadear.',
      defaultDurationSeconds: 30,
    ),
    CatalogItem(
      title: 'El Globo de Aire',
      category: 'Pómulos y Mejillas',
      description: 'Llenar la boca de aire y mantener las mejillas hinchadas en máxima tensión isométrica durante 15 segundos sin fugas.',
      defaultDurationSeconds: 30,
    ),
    CatalogItem(
      title: 'Transferencia de Aire',
      category: 'Pómulos y Mejillas',
      description: 'Mover una burbuja de aire de la mejilla derecha a la izquierda de forma continua y con resistencia muscular.',
      defaultDurationSeconds: 35,
    ),
    CatalogItem(
      title: 'Elevación de Cigomáticos con Dedos',
      category: 'Pómulos y Mejillas',
      description: 'Apoyar los índices bajo los pómulos; empujar hacia arriba y sostener mientras se intenta descender los pómulos contrayendo los labios hacia adelante.',
      defaultDurationSeconds: 30,
    ),
    CatalogItem(
      title: 'Sonrisa Oculta de Dientes',
      category: 'Pómulos y Mejillas',
      description: 'Estirar los labios sobre los dientes y arquear las comisuras hacia los lóbulos de las orejas sin arrugar la zona de los ojos.',
      defaultDurationSeconds: 30,
    ),
    CatalogItem(
      title: 'Presión con Nudillos Malar',
      category: 'Pómulos y Mejillas',
      description: 'Colocar los nudillos bajo el hueso malar, empujar suavemente hacia arriba y abrir la boca en forma de "A" sostenida.',
      defaultDurationSeconds: 30,
    ),
    CatalogItem(
      title: 'El Trompetista',
      category: 'Pómulos y Mejillas',
      description: 'Apretar los labios hacia el centro e inflar las mejillas al 50%, manteniendo la tensión en los músculos buccinadores.',
      defaultDurationSeconds: 30,
    ),
    CatalogItem(
      title: 'Sonrisa Asimétrica Aislada',
      category: 'Pómulos y Mejillas',
      description: 'Elevar un solo lado del pómulo y labio de manera unilateral hasta contraer completamente el cigomático; alternar de lado.',
      defaultDurationSeconds: 30,
    ),
    CatalogItem(
      title: 'Golpeteo Miofascial (Tapping)',
      category: 'Pómulos y Mejillas',
      description: 'Percutir de forma rápida y rítmica con la punta de los dedos sobre todo el relieve óseo del pómulo para estimular la microcirculación.',
      defaultDurationSeconds: 35,
    ),
  ];

  static const List<CatalogItem> facialLabios = [
    CatalogItem(
      title: 'El Beso Resistido',
      category: 'Labios y Surco',
      description: 'Proyectar los labios al frente simulando un beso y presionar los dedos índice y medio firmes contra la boca impidiendo su avance.',
      defaultDurationSeconds: 30,
    ),
    CatalogItem(
      title: 'Inmovilización del Surco Nasogeniano',
      category: 'Labios y Surco',
      description: 'Presionar los laterales de la nariz y comisuras con los dedos índices para evitar arrugas y proyectar los labios en una "O" cerrada.',
      defaultDurationSeconds: 30,
    ),
    CatalogItem(
      title: 'Ocultación Labial Estricta',
      category: 'Labios y Surco',
      description: 'Enrollar ambos labios hacia el interior de la boca sobre los dientes y presionar los bordes con fuerza isométrica durante 10 segundos.',
      defaultDurationSeconds: 30,
    ),
    CatalogItem(
      title: 'Succión de Dedo (Vacío Bucal)',
      category: 'Labios y Surco',
      description: 'Introducir el pulgar limpio en la boca, cerrar los labios ajustados a él y realizar una succión hacia adentro intentando extraer el dedo contra resistencia.',
      defaultDurationSeconds: 30,
    ),
    CatalogItem(
      title: 'Giro del Beso',
      category: 'Labios y Surco',
      description: 'Con los labios apretados en forma de pico, trazar círculos amplios en el sentido de las agujas del reloj y en sentido opuesto.',
      defaultDurationSeconds: 30,
    ),
    CatalogItem(
      title: 'Contracción del Labio Superior',
      category: 'Labios y Surco',
      description: 'Traccionar el labio superior hacia abajo sobre los incisivos mientras con dos dedos se empuja levemente la base de la nariz hacia arriba.',
      defaultDurationSeconds: 30,
    ),
    CatalogItem(
      title: 'La Cuchara de Madera',
      category: 'Labios y Surco',
      description: 'Sostener una cuchara ligera entre los labios horizontales (sin usar los dientes) e intentar elevarla paralelamente al suelo contrayendo la boca.',
      defaultDurationSeconds: 30,
    ),
    CatalogItem(
      title: 'Burbuja bajo el Labio Superior',
      category: 'Labios y Surco',
      description: 'Acumular aire exclusivamente en el espacio entre los dientes frontales superiores y el labio para estirar el surco nasolabial.',
      defaultDurationSeconds: 30,
    ),
    CatalogItem(
      title: 'Burbuja bajo el Labio Inferior',
      category: 'Labios y Surco',
      description: 'Pasar el aire hacia el bolsillo entre la encía inferior y el mentón manteniendo la tensión por 10 segundos.',
      defaultDurationSeconds: 30,
    ),
    CatalogItem(
      title: 'Torsión de Comisuras',
      category: 'Labios y Surco',
      description: 'Tensar los labios en una línea neutra y elevar alternativamente la comisura izquierda y luego la derecha en movimientos cortos y aislados.',
      defaultDurationSeconds: 30,
    ),
  ];

  static const List<CatalogItem> facialMandibulaCuello = [
    CatalogItem(
      title: 'Beso al Techo',
      category: 'Mandíbula y Cuello',
      description: 'Inclinar la cabeza hacia atrás mirando el cielo a 45 grados, proyectar la mandíbula inferior hacia adelante y lanzar un beso cerrado sintiendo el platisma tenso.',
      defaultDurationSeconds: 30,
    ),
    CatalogItem(
      title: 'Presión Lingual al Paladar (Tongue Press)',
      category: 'Mandíbula y Cuello',
      description: 'Pegar la totalidad de la lengua contra el paladar blando y duro con la boca cerrada, activando toda la musculatura del suelo de la boca.',
      defaultDurationSeconds: 30,
    ),
    CatalogItem(
      title: 'El Cisne con Giro',
      category: 'Mandíbula y Cuello',
      description: 'Girar la cabeza 45 grados a la derecha, elevar el mentón hacia arriba y sacar la mandíbula inferior hasta tensar el lateral del cuello; alternar al lado izquierdo.',
      defaultDurationSeconds: 30,
    ),
    CatalogItem(
      title: 'Mordida Resistida con Puño',
      category: 'Mandíbula y Cuello',
      description: 'Colocar el puño bajo el mentón haciendo fuerza hacia arriba; intentar abrir la boca empujando hacia abajo contra la resistencia del puño.',
      defaultDurationSeconds: 30,
    ),
    CatalogItem(
      title: 'Lengua a la Punta de la Nariz',
      category: 'Mandíbula y Cuello',
      description: 'Con el cuello estirado hacia arriba, sacar la lengua e intentar tocar la punta de la nariz para fortalecer los músculos suprahioideos.',
      defaultDurationSeconds: 30,
    ),
    CatalogItem(
      title: 'Liberación del Masetero',
      category: 'Mandíbula y Cuello',
      description: 'Abrir ligeramente la boca y realizar círculos firmes con los nudillos en la unión mandibular para reducir la hipertonía por bruxismo.',
      defaultDurationSeconds: 45,
    ),
    CatalogItem(
      title: 'Línea Mandibular en Tijera',
      category: 'Mandíbula y Cuello',
      description: 'Formar una "V" con los dedos índice y medio flexionados en forma de gancho, encajar la mandíbula y deslizar desde la barbilla hasta las orejas.',
      defaultDurationSeconds: 40,
    ),
    CatalogItem(
      title: 'Sonrisa Evertida con Tensión en Platisma',
      category: 'Mandíbula y Cuello',
      description: 'Tensar las comisuras hacia abajo y hacia los lados mostrando los dientes inferiores, haciendo visibles los tendones verticales del cuello.',
      defaultDurationSeconds: 30,
    ),
    CatalogItem(
      title: 'Descompresión Esternocleidomastoideo',
      category: 'Mandíbula y Cuello',
      description: 'Girar la cabeza a un lado, tomar el relieve muscular lateral del cuello con índice y pulgar y amasar suavemente en sentido descendente.',
      defaultDurationSeconds: 40,
    ),
    CatalogItem(
      title: 'Empuje de Doble Mentón (Chin Tuck)',
      category: 'Mandíbula y Cuello',
      description: 'Llevar la cabeza hacia atrás en plano horizontal sin inclinarla, formando papada deliberadamente para activar los flexores profundos cervicales.',
      defaultDurationSeconds: 30,
    ),
  ];

  // =========================================================================
  // GENERADORES DE SESIÓN MULTI-EJERCICIO CON 10s DE PREPARACIÓN
  // =========================================================================

  /// Generates a structured multi-exercise routine session for Face Yoga.
  /// Follows the daily protocol:
  /// - 1 exercise from each of the 5 anatomical zones (Tonificación)
  /// - 2 exercises for drainage / massage release
  /// Every single exercise has 10 seconds of preparation beforehand!
  static List<ExerciseStep> getFacialRoutineForDay(int dayNumber) {
    final idx = (dayNumber - 1);

    final itemFrente = facialFrente[idx % facialFrente.length];
    final itemOjos = facialOjos[idx % facialOjos.length];
    final itemPomulos = facialPomulos[idx % facialPomulos.length];
    final itemLabios = facialLabios[idx % facialLabios.length];
    final itemMandibula = facialMandibulaCuello[idx % facialMandibulaCuello.length];

    // 2 drainage / discharge massage exercises
    final itemDrenaje1 = facialOjos[(idx + 5) % facialOjos.length];
    final itemDrenaje2 = facialMandibulaCuello[(idx + 6) % facialMandibulaCuello.length];

    return [
      itemFrente.toExerciseStep(durationSeconds: 30, preparationSeconds: 10),
      itemOjos.toExerciseStep(durationSeconds: 30, preparationSeconds: 10),
      itemPomulos.toExerciseStep(durationSeconds: 30, preparationSeconds: 10),
      itemLabios.toExerciseStep(durationSeconds: 30, preparationSeconds: 10),
      itemMandibula.toExerciseStep(durationSeconds: 30, preparationSeconds: 10),
      itemDrenaje1.toExerciseStep(durationSeconds: 45, preparationSeconds: 10),
      itemDrenaje2.toExerciseStep(durationSeconds: 45, preparationSeconds: 10),
    ];
  }

  /// Generates a structured multi-exercise flow session for Yoga.
  /// Follows the block protocol:
  /// - 2 Fuerza asanas (40s - 5 breath cycles)
  /// - 2 Flexibilidad asanas (60s - active tension + passive elongation)
  /// - 1 Relajación / Savasana asana (90s - restore with support)
  /// Every single exercise has 10 seconds of preparation beforehand!
  static List<ExerciseStep> getYogaRoutineForDay(int dayNumber) {
    final idx = (dayNumber - 1) * 2;

    final fuerza1 = yogaFuerza[idx % yogaFuerza.length];
    final fuerza2 = yogaFuerza[(idx + 1) % yogaFuerza.length];
    final flex1 = yogaFlexibilidad[idx % yogaFlexibilidad.length];
    final flex2 = yogaFlexibilidad[(idx + 1) % yogaFlexibilidad.length];
    final relax = yogaRelajacion[(dayNumber - 1) % yogaRelajacion.length];

    return [
      fuerza1.toExerciseStep(durationSeconds: 40, preparationSeconds: 10),
      fuerza2.toExerciseStep(durationSeconds: 40, preparationSeconds: 10),
      flex1.toExerciseStep(durationSeconds: 60, preparationSeconds: 10),
      flex2.toExerciseStep(durationSeconds: 60, preparationSeconds: 10),
      relax.toExerciseStep(durationSeconds: 90, preparationSeconds: 10),
    ];
  }

  /// Generates structured meditation stages (Preparation -> Immersion -> Integration).
  static List<ExerciseStep> getMeditationStagesForDay(int dayNumber, String mainTitle, String instructions, int durationMinutes) {
    final totalSecs = durationMinutes * 60;
    final mainSecs = (totalSecs - 60).clamp(120, 900);

    return [
      const ExerciseStep(
        title: 'Calibración Postural y Centramiento',
        category: 'Alineación',
        instructions: 'Adopta una postura digna, columna erguida pero relajada. Cierra los ojos y realiza 3 respiraciones profundas.',
        durationSeconds: 30,
        preparationSeconds: 10,
      ),
      ExerciseStep(
        title: mainTitle,
        category: 'Inmersión Principal',
        instructions: instructions,
        durationSeconds: mainSecs,
        preparationSeconds: 10,
      ),
      const ExerciseStep(
        title: 'Integración y Cierre Consciente',
        category: 'Cierre',
        instructions: 'Regresa suavemente el movimiento a dedos y cuello. Abre los ojos con calma llevando este estado a tu jornada.',
        durationSeconds: 30,
        preparationSeconds: 10,
      ),
    ];
  }
}
