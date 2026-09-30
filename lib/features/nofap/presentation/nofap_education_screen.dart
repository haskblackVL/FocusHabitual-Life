import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme.dart';
import 'widgets/cooling_protocol_sheet.dart';

/// Educational Hub for Self-Mastery & NoFap.
///
/// Implements full pedagogical content from documentos adicionales/no fap.md:
/// 1. Fundamentos (Introducción, causas biológicas y conductuales)
/// 2. Qué No Funciona (Errores comunes: solo voluntad, moderación, distracciones)
/// 3. Mitos vs Realidad (Dopamina, estrés, sexualidad, energía mental)
/// 4. Sabiduría Bíblica (Mateo 5:28, 1 Corintios 6:18, Filipenses 4:8, Salmo 51:10)
/// 5. Estrategia Práctica (Surfing the urge, blindaje de entorno, reinicio analítico)
class NofapEducationScreen extends StatefulWidget {
  const NofapEducationScreen({super.key});

  @override
  State<NofapEducationScreen> createState() => _NofapEducationScreenState();
}

class _NofapEducationScreenState extends State<NofapEducationScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(
          'Centro de Autodominio',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurface,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: AppTheme.surfaceContainerLowest,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: AppTheme.primary,
              unselectedLabelColor: AppTheme.onSurfaceVariant,
              indicatorColor: AppTheme.primary,
              indicatorWeight: 2.5,
              labelStyle: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(text: 'Fundamentos'),
                Tab(text: 'Qué No Funciona'),
                Tab(text: 'Mitos vs Realidad'),
                Tab(text: 'Principios Bíblicos'),
                Tab(text: 'Estrategia de Éxito'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFundamentosTab(),
          _buildQueNoFuncionaTab(),
          _buildMitosTab(),
          _buildBiblicalTab(),
          _buildEstrategiaTab(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppTheme.surfaceContainerHigh)),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => CoolingProtocolSheet.show(context),
                  icon: const Icon(Icons.air_rounded, color: AppTheme.primary, size: 18),
                  label: const Text('Botón SOS de Pánico'),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppTheme.surfaceContainerLow,
                    side: const BorderSide(color: AppTheme.surfaceContainerHigh),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: Fundamentos
  // ---------------------------------------------------------------------------
  Widget _buildFundamentosTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildHeroBanner(
          tag: 'INTRODUCCIÓN Y PSICOLOGÍA',
          title: 'El Atajo de la Recompensa Instantánea',
          description:
              'Comprender la raíz biológica del impulso es el primer paso hacia la libertad sin culpa destructiva.',
        ),
        const SizedBox(height: 20),
        _buildContentCard(
          icon: Icons.flash_on_rounded,
          title: '¿Por qué consumimos pornografía?',
          body:
              'Ofrece estimulación sexual instantánea en segundos, sin riesgo de rechazo, sin esfuerzo y sin la vulnerabilidad de una relación real.\n\nEl cerebro aprende rápidamente que este atajo artificial requiere menos fricción que conectar con personas o tolerar la incomodidad cotidiana, repitiéndose automáticamente ante el aburrimiento, la soledad o el estrés.',
        ),
        const SizedBox(height: 14),
        _buildContentCard(
          icon: Icons.repeat_rounded,
          title: '¿Por qué no basta la simple intención?',
          body:
              'No es solo "falta de carácter". Se combinan 3 factores letales:\n\n'
              '• Hábito automatizado: Disparado por anclas horarias o emocionales.\n'
              '• Alivio momentáneo: Calma una tensión emocional instantáneamente.\n'
              '• Fácil acceso y fricción cero: El smartphone está siempre a mano.\n\n'
              'FocusHabitual no busca juzgarte, sino darte visibilidad y fricción táctica para interrumpir el ciclo.',
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: Qué No Funciona
  // ---------------------------------------------------------------------------
  Widget _buildQueNoFuncionaTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildHeroBanner(
          tag: 'DESARMANDO ERRORES COMUNES',
          title: 'Lo que NO Sirve para Dejarlo',
          description:
              'Evita las trampas habituales que condenan los intentos tradicionales al fracaso cíclico.',
        ),
        const SizedBox(height: 20),
        _buildWarningCard(
          title: '1. Las razones correctas solas en el momento pico',
          body:
              'Saber por qué quieres dejarlo (salud, autocontrol, pareja, fe) es indispensable pero insuficiente. La mente racional se apaga en el pico dopaminérgico. Por eso necesitas anclajes activos y el protocolo de respiración de 5 pasos en el instante crítico.',
        ),
        const SizedBox(height: 14),
        _buildWarningCard(
          title: '2. Distracciones aisladas como única estrategia',
          body:
              'Jugar videojuegos o mirar series solo pospone el impulso sin desmantelar el disparador emocional. Funciona como torniquete de primer auxilio, no como cura de fondo.',
        ),
        const SizedBox(height: 14),
        _buildWarningCard(
          title: '3. El engaño del uso parcial o moderación',
          body:
              'Intentar "ver un poco" casi siempre degenera en recaída total. Los circuitos de recompensa no operan con "cuotas". La abstinencia clara y el reinicio honesto del contador son la vía probada.',
        ),
        const SizedBox(height: 14),
        _buildWarningCard(
          title: '4. Depender exclusivamente de la "fuerza de voluntad"',
          body:
              'La fuerza de voluntad es una batería biológica finita que se agota durante el día. La solución real es rediseñar tu entorno para eliminar la fricción de acceso.',
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 3: Mitos vs Realidad
  // ---------------------------------------------------------------------------
  Widget _buildMitosTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildHeroBanner(
          tag: 'EVIDENCIA Y CLARIDAD MENTAL',
          title: 'Mitos Desmentidos',
          description:
              'Diferenciando hechos psicológicos reales de exageraciones alarmistas de foros en internet.',
        ),
        const SizedBox(height: 20),
        _buildMythItem(
          myth: '«El porno destruye tu dopamina para siempre.»',
          reality:
              'No es daño permanente. El consumo repetido causa una desensibilización temporal de los receptores de recompensa. Con abstinencia sostenida, el sistema se recalibra y las actividades cotidianas vuelven a sentirse gratificantes.',
        ),
        const SizedBox(height: 14),
        _buildMythItem(
          myth: '«El porno es una herramienta eficaz contra el estrés.»',
          reality:
              'El alivio dura solo minutos, pero aumenta la ansiedad, la rumiación y la culpa después del episodio. El estrés no se resuelve, se acumula.',
        ),
        const SizedBox(height: 14),
        _buildMythItem(
          myth: '«Dejar el porno es reprimir mi sexualidad.»',
          reality:
              'Es todo lo contrario: es recuperar el control voluntario sobre tu energía vital en lugar de que la dicte un algoritmo o un hábito compulsivo.',
        ),
        const SizedBox(height: 14),
        _buildMythItem(
          myth: '«Una recaída te quita toda tu testosterona y energía vital.»',
          reality:
              'La evidencia de un cambio hormonal masivo es débil. Lo que realmente se recupera al dejarlo es claridad y energía mental al cortar el ciclo de culpa y frustración.',
        ),
        const SizedBox(height: 14),
        _buildMythItem(
          myth: '«Me ayuda a concentrarme mejor en mis proyectos.»',
          reality:
              'Fomenta el hábito de la recompensa fácil, deteriorando la capacidad de sostener atención prolongada en tareas complejas y profundas.',
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 4: Principios Bíblicos
  // ---------------------------------------------------------------------------
  Widget _buildBiblicalTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildHeroBanner(
          tag: 'SABIDURÍA TRASCENDENTE',
          title: 'Principios Bíblicos de Autodominio',
          description:
              'Enfoque de dignidad, higiene mental y dominio propio frente a la tentación visual.',
        ),
        const SizedBox(height: 20),
        _buildBiblicalCard(
          passage: 'MATEO 5:28',
          theme: 'Gobierno de la mirada interna',
          summary:
              'Jesús enseña que la batalla moral se gana o se pierde en el pensamiento, no solo en la conducta física externa.',
        ),
        const SizedBox(height: 12),
        _buildBiblicalCard(
          passage: '1 CORINTIOS 6:18-20',
          theme: 'Huir de la inmoralidad & Dignidad',
          summary:
              'Tu cuerpo es templo de valor sagrado. El llamado no es negociar con la tentación, sino huir con prontitud por dignidad propia.',
        ),
        const SizedBox(height: 12),
        _buildBiblicalCard(
          passage: 'GÁLATAS 5:16',
          theme: 'Enfoque positivo vs represión pasiva',
          summary:
              '«Caminen en el Espíritu»: la victoria no es solo reprimir lo malo, sino llenar activamente la vida de virtud y propósito elevado.',
        ),
        const SizedBox(height: 12),
        _buildBiblicalCard(
          passage: 'FILIPENSES 4:8',
          theme: 'Higiene mental proactiva',
          summary:
              '«En todo lo verdadero, todo lo honesto, todo lo puro... en esto pensad». Disciplina intencional para custodiar la atención.',
        ),
        const SizedBox(height: 12),
        _buildBiblicalCard(
          passage: '1 TESALONICENSES 4:3-5',
          theme: 'Santificación y gobierno corporal',
          summary:
              'Aprender a tener el propio cuerpo en dominio y honor, superando la pasión desordenada de la gratificación impulsiva.',
        ),
        const SizedBox(height: 12),
        _buildBiblicalCard(
          passage: 'SALMO 51:10',
          theme: 'Restauración tras una caída',
          summary:
              '«Crea en mí, oh Dios, un corazón limpio». Un modelo de oración honesta post-recaída: esperanza de recomienzo sin culpa paralizante.',
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 5: Estrategia de Éxito
  // ---------------------------------------------------------------------------
  Widget _buildEstrategiaTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildHeroBanner(
          tag: 'MÉTODO CONDUCTUAL',
          title: 'Cómo Dejarlo Definitivamente',
          description:
              'Técnicas comprobadas para sortear los momentos de máxima vulnerabilidad.',
        ),
        const SizedBox(height: 20),
        _buildContentCard(
          icon: Icons.surfing_rounded,
          title: 'Técnica: Surfing the Urge (Surfear la urgencia)',
          body:
              'El impulso sexual no crece infinitamente; opera como una ola en el mar: se forma, llega a una cresta de intensidad y desciende si no se retroalimenta.\n\n'
              'En lugar de luchar frontalmente o ceder en pánico:\n'
              '1. Nota la sensación corporal sin juzgarla.\n'
              '2. Respira con el protocolo 4-4-6 durante 60 segundos.\n'
              '3. Espera 10 minutos realizando una acción física de reemplazo. Verás cómo la marea desciende por sí sola.',
        ),
        const SizedBox(height: 14),
        _buildContentCard(
          icon: Icons.shield_rounded,
          title: 'Blindaje del Entorno Físico y Digital',
          body:
              '• Prohíbe el uso de pantallas en la cama o a oscuras.\n'
              '• Instala bloqueadores y desactiva búsquedas explícitas.\n'
              '• Identifica tus horarios críticos (ej. noche tarde o tras días de estrés laboral).\n'
              '• Ten siempre a mano tu lista de anclas y razones personales.',
        ),
        const SizedBox(height: 14),
        _buildContentCard(
          icon: Icons.analytics_outlined,
          title: 'El Reinicio como Dato de Aprendizaje',
          body:
              'Si ocurre una recaída, no te castigues con vergüenza autodestructiva. Utiliza el registro honesto de la app para preguntarte: ¿cuál fue el disparador real (aburrimiento, cansancio, soledad)? Ajusta esa grieta y retoma la cuenta con madurez.',
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Helper UI Widgets
  // ---------------------------------------------------------------------------
  Widget _buildHeroBanner({
    required String tag,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceContainerHigh),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tag,
            style: AppTheme.labelCaps(
              fontSize: 10,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppTheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentCard({
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceContainerHigh),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: AppTheme.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppTheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningCard({required String title, required String body}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceContainerHigh),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppTheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMythItem({required String myth, required String reality}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceContainerHigh),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.close_rounded, color: AppTheme.error, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  myth,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.check_circle_outline_rounded,
                  color: AppTheme.accentEmerald, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  reality,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppTheme.onSurface,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBiblicalCard({
    required String passage,
    required String theme,
    required String summary,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceContainerHigh),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                passage,
                style: AppTheme.numeric(
                  fontSize: 13,
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
                  theme,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            summary,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppTheme.onSurface,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
