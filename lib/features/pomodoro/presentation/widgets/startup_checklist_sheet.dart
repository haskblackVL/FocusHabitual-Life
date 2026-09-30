import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme.dart';
import '../controllers/pomodoro_controller.dart';

/// Modal dialog / Bottom sheet for the mandatory Deep Work startup checklist.
class StartupChecklistSheet extends ConsumerStatefulWidget {
  const StartupChecklistSheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const StartupChecklistSheet(),
    );
  }

  @override
  ConsumerState<StartupChecklistSheet> createState() => _StartupChecklistSheetState();
}

class _StartupChecklistSheetState extends ConsumerState<StartupChecklistSheet> {
  final _objectiveController = TextEditingController();
  bool _tabsClosed = false;
  bool _dndEnabled = true;
  bool _notepadReady = false;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    final currentObjective = ref.read(pomodoroProvider).taskObjective;
    if (currentObjective != null && currentObjective.isNotEmpty) {
      _objectiveController.text = currentObjective;
    }
  }

  @override
  void dispose() {
    _objectiveController.dispose();
    super.dispose();
  }

  bool _validateObjective(String text) {
    final clean = text.trim();
    if (clean.length < 8) {
      _validationError = 'El objetivo debe tener al menos 8 caracteres descriptivos.';
      return false;
    }

    final words = clean.split(RegExp(r'\s+'));
    if (words.length < 2) {
      _validationError = 'Define un resultado medible (ej: "Implementar autenticación local", no solo "Trabajar").';
      return false;
    }

    final genericSingles = {'trabajar', 'avanzar', 'estudiar', 'hacer', 'programar', 'leer', 'proyecto'};
    if (words.length == 2 && genericSingles.contains(words.first.toLowerCase())) {
      _validationError = 'Especifica el resultado tangible esperado en esta sesión.';
      return false;
    }

    _validationError = null;
    return true;
  }

  bool get _isAllConfirmed {
    final validObjective = _objectiveController.text.trim().length >= 8 && _validationError == null;
    return validObjective && _tabsClosed && _dndEnabled && _notepadReady;
  }

  void _confirmAndStart() {
    if (!_validateObjective(_objectiveController.text)) return;
    if (!_isAllConfirmed) return;

    final notifier = ref.read(pomodoroProvider.notifier);
    notifier.setTaskObjective(_objectiveController.text.trim());
    notifier.toggleDnd(_dndEnabled);
    notifier.start();

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Title and badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Checklist de Arranque',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'DEEP WORK',
                      style: AppTheme.labelCaps(
                        fontSize: 10,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'El estado de flujo requiere fricción cero y blindaje atencional previo.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),

              // Step 1: Objective input
              Text(
                '1. OBJETIVO ÚNICO Y VERIFICABLE',
                style: AppTheme.labelCaps(fontSize: 11, color: AppTheme.onSurfaceVariant),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _objectiveController,
                onChanged: (val) {
                  setState(() => _validateObjective(val));
                },
                decoration: InputDecoration(
                  hintText: 'Ej: Implementar y testear persistencia SQLite de notas',
                  hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.outline),
                  filled: true,
                  fillColor: AppTheme.surfaceContainerLow,
                  errorText: _validationError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildSuggestionChip('Implementar y probar endpoints API'),
                    const SizedBox(width: 6),
                    _buildSuggestionChip('Diseño de arquitectura y datos'),
                    const SizedBox(width: 6),
                    _buildSuggestionChip('Refactorización y testing unitario'),
                    const SizedBox(width: 6),
                    _buildSuggestionChip('Depurar y optimizar rendimiento UI'),
                    const SizedBox(width: 6),
                    _buildSuggestionChip('Lectura e investigación técnica profunda'),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Step 2: Tabs closed check
              _buildCheckTile(
                title: 'Navegadores y pestañas redundantes cerrados',
                subtitle: 'Conserva únicamente las referencias técnicas indispensables.',
                value: _tabsClosed,
                onChanged: (val) => setState(() => _tabsClosed = val ?? false),
              ),
              const SizedBox(height: 10),

              // Step 3: DND check
              _buildCheckTile(
                title: 'Notificaciones y terminales silenciadas',
                subtitle: 'Modo No Molestar activo para proteger la memoria de trabajo.',
                value: _dndEnabled,
                onChanged: (val) => setState(() => _dndEnabled = val ?? false),
              ),
              const SizedBox(height: 10),

              // Step 4: Interruption notepad ready
              _buildCheckTile(
                title: 'Bloc de Descarga listo',
                subtitle: 'Cualquier pensamiento disperso se anotará en el bloc sin salir de foco.',
                value: _notepadReady,
                onChanged: (val) => setState(() => _notepadReady = val ?? false),
              ),
              const SizedBox(height: 24),

              // Start Action Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isAllConfirmed ? _confirmAndStart : null,
                  icon: const Icon(Icons.bolt_rounded, size: 22),
                  label: Text(
                    'Entrar a la Zona de Flujo',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppTheme.surfaceContainerHigh,
                    disabledForegroundColor: AppTheme.outline,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? AppTheme.primary.withValues(alpha: 0.4) : Colors.transparent,
        ),
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primary,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    final isSelected = _objectiveController.text == text;
    return InkWell(
      onTap: () {
        setState(() {
          _objectiveController.text = text;
          _validateObjective(text);
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.15)
              : AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.surfaceContainerHigh,
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppTheme.primary : AppTheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
