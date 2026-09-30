import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme.dart';
import '../controllers/cycle_controller.dart';

/// Modal bottom sheet to log granular day metrics across Ovulation, Basal Temp,
/// Pregnancy, Fertility Awareness (Prenupcial), and Daily Symptoms.
class CycleDayLoggerSheet extends ConsumerStatefulWidget {
  const CycleDayLoggerSheet({super.key, required this.date});

  final DateTime date;

  static Future<void> show(BuildContext context, DateTime date) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => CycleDayLoggerSheet(date: date),
    );
  }

  @override
  ConsumerState<CycleDayLoggerSheet> createState() => _CycleDayLoggerSheetState();
}

class _CycleDayLoggerSheetState extends ConsumerState<CycleDayLoggerSheet> {
  // Ovulation & Basal Temp
  late final TextEditingController _tempController;
  late final TextEditingController _ovulationNotesController;
  String? _cervicalMucus;
  String? _ovulationTestResult;

  // Daily Symptoms
  String _flowLevel = 'none';
  int _crampsLevel = 0;
  String _mood = 'calm';
  final List<String> _selectedSymptoms = [];
  late final TextEditingController _symptomsNotesController;

  // Fertility / Prenupcial
  String _fertilityMethod = 'symptothermal';
  String? _fertileWindowStatus;
  bool _partnerShared = false;
  late final TextEditingController _fertilityNotesController;

  // Pregnancy
  bool _enablePregnancy = false;
  int? _pregnancyWeek;
  DateTime? _dueDate;
  late final TextEditingController _pregnancyNotesController;

  bool _initializedWithExisting = false;

  static const _availableSymptomsList = [
    {'key': 'cramps', 'label': 'Cólicos', 'icon': Icons.bolt_rounded},
    {'key': 'headache', 'label': 'Dolor de cabeza', 'icon': Icons.psychology_outlined},
    {'key': 'low_energy', 'label': 'Fatiga / Cansancio', 'icon': Icons.battery_2_bar_rounded},
    {'key': 'mood_sensitive', 'label': 'Sensibilidad emocional', 'icon': Icons.favorite_border_rounded},
    {'key': 'bloating', 'label': 'Inflamación abdominal', 'icon': Icons.water_drop_outlined},
    {'key': 'breast_tenderness', 'label': 'Sensibilidad mamaria', 'icon': Icons.health_and_safety_outlined},
    {'key': 'backache', 'label': 'Dolor lumbar', 'icon': Icons.accessibility_new_rounded},
    {'key': 'insomnia', 'label': 'Insomnio', 'icon': Icons.bedtime_outlined},
    {'key': 'acne', 'label': 'Brotes en piel', 'icon': Icons.face_retouching_natural_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _tempController = TextEditingController();
    _ovulationNotesController = TextEditingController();
    _symptomsNotesController = TextEditingController();
    _fertilityNotesController = TextEditingController();
    _pregnancyNotesController = TextEditingController();
  }

  @override
  void dispose() {
    _tempController.dispose();
    _ovulationNotesController.dispose();
    _symptomsNotesController.dispose();
    _fertilityNotesController.dispose();
    _pregnancyNotesController.dispose();
    super.dispose();
  }

  void _populateFromExisting(dynamic record) {
    if (_initializedWithExisting || record == null) return;
    _initializedWithExisting = true;

    // Ovulation
    if (record.ovulationLog != null) {
      if (record.ovulationLog.basalBodyTemp != null) {
        _tempController.text = record.ovulationLog.basalBodyTemp.toString();
      }
      _cervicalMucus = record.ovulationLog.cervicalMucus;
      _ovulationTestResult = record.ovulationLog.ovulationTestResult;
      _ovulationNotesController.text = record.ovulationLog.notes ?? '';
    }

    // Symptoms
    if (record.symptomsLog != null) {
      _flowLevel = record.symptomsLog.flowLevel;
      _crampsLevel = record.symptomsLog.crampsLevel;
      _mood = record.symptomsLog.mood;
      _selectedSymptoms.addAll(List<String>.from(record.symptomsLog.symptoms));
      _symptomsNotesController.text = record.symptomsLog.notes ?? '';
    }

    // Fertility
    if (record.fertilityLog != null) {
      _fertilityMethod = record.fertilityLog.method;
      _fertileWindowStatus = record.fertilityLog.fertileWindowStatus;
      _partnerShared = record.fertilityLog.partnerShared;
      _fertilityNotesController.text = record.fertilityLog.notes ?? '';
    }

    // Pregnancy
    if (record.pregnancyLog != null && record.pregnancyLog.isActive) {
      _enablePregnancy = true;
      _pregnancyWeek = record.pregnancyLog.currentWeek;
      _dueDate = record.pregnancyLog.dueDate;
      _pregnancyNotesController.text = record.pregnancyLog.notes ?? '';
    }
  }

  Future<void> _handleSave() async {
    final tempVal = double.tryParse(_tempController.text.trim().replaceAll(',', '.'));

    await ref.read(cycleLoggerProvider).saveDayRecord(
      date: widget.date,
      // Ovulation & Basal Temp
      basalBodyTemp: tempVal,
      cervicalMucus: _cervicalMucus,
      ovulationTestResult: _ovulationTestResult,
      ovulationNotes: _ovulationNotesController.text.trim(),
      // Daily Symptoms
      symptoms: _selectedSymptoms,
      flowLevel: _flowLevel,
      crampsLevel: _crampsLevel,
      mood: _mood,
      symptomsNotes: _symptomsNotesController.text.trim(),
      // Fertility / Prenupcial
      fertilityMethod: _fertilityMethod,
      fertileWindowStatus: _fertileWindowStatus,
      partnerShared: _partnerShared,
      fertilityNotes: _fertilityNotesController.text.trim(),
      // Pregnancy
      updatePregnancy: _enablePregnancy,
      pregnancyWeek: _pregnancyWeek,
      dueDate: _dueDate,
      isPregnancyActive: _enablePregnancy,
      pregnancyNotes: _pregnancyNotesController.text.trim(),
    );

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Registro guardado para el ${DateFormat('dd/MM/yyyy').format(widget.date)}',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppTheme.accentRose,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final existingAsync = ref.watch(cycleSelectedDayDataProvider);
    existingAsync.whenData(_populateFromExisting);

    const days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    const months = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
    final weekdayName = days[widget.date.weekday - 1];
    final monthName = months[widget.date.month - 1];
    final capitalizedHeader = '$weekdayName ${widget.date.day} de $monthName ${widget.date.year}';

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              // Top Notch Handle
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Registro del Día',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      Text(
                        capitalizedHeader,
                        style: AppTheme.labelCaps(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Scrollable sections
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    // SECTION 1: Temperatura Basal & Ovulación
                    _buildSectionCard(
                      title: 'Temperatura Basal & Ovulación',
                      badge: 'MÉTODO SINTOTÉRMICO',
                      badgeColor: AppTheme.accentAmber,
                      icon: Icons.thermostat_rounded,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextField(
                                controller: _tempController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  labelText: 'Temperatura (°C)',
                                  hintText: 'ej. 36.5',
                                  suffixText: '°C',
                                  prefixIcon: const Icon(Icons.device_thermostat_rounded, size: 20),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 4,
                              child: Text(
                                'Tomar inmediatamente al despertar, antes de levantarse.',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: AppTheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Moco cervical
                        Text(
                          'Moco Cervical',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _buildChoiceChip('Seco', 'dry', _cervicalMucus, (v) => setState(() => _cervicalMucus = v)),
                            _buildChoiceChip('Pegajoso', 'sticky', _cervicalMucus, (v) => setState(() => _cervicalMucus = v)),
                            _buildChoiceChip('Cremoso', 'creamy', _cervicalMucus, (v) => setState(() => _cervicalMucus = v)),
                            _buildChoiceChip('Clara de Huevo (Fértil)', 'egg_white', _cervicalMucus, (v) => setState(() => _cervicalMucus = v)),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Test de Ovulación LH
                        Text(
                          'Test de Ovulación LH',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _buildChoiceChip('Negativo', 'negative', _ovulationTestResult, (v) => setState(() => _ovulationTestResult = v)),
                            _buildChoiceChip('Positivo', 'positive', _ovulationTestResult, (v) => setState(() => _ovulationTestResult = v)),
                            _buildChoiceChip('Pico Máximo', 'peak', _ovulationTestResult, (v) => setState(() => _ovulationTestResult = v)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // SECTION 2: Síntomas Diarios & Estado de Ánimo
                    _buildSectionCard(
                      title: 'Síntomas & Estado de Ánimo',
                      badge: 'BIENESTAR DIARIO',
                      badgeColor: AppTheme.accentSky,
                      icon: Icons.healing_rounded,
                      children: [
                        // Nivel de Flujo
                        Text('Nivel de Flujo Menstrual', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _buildChoiceChip('Ninguno', 'none', _flowLevel, (v) => setState(() => _flowLevel = v ?? 'none')),
                            _buildChoiceChip('Manchado', 'spotting', _flowLevel, (v) => setState(() => _flowLevel = v ?? 'spotting')),
                            _buildChoiceChip('Ligero', 'light', _flowLevel, (v) => setState(() => _flowLevel = v ?? 'light')),
                            _buildChoiceChip('Medio', 'medium', _flowLevel, (v) => setState(() => _flowLevel = v ?? 'medium')),
                            _buildChoiceChip('Abundante', 'heavy', _flowLevel, (v) => setState(() => _flowLevel = v ?? 'heavy')),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Cólicos Slider
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Intensidad de Cólicos', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold)),
                            Text('$_crampsLevel / 5', style: GoogleFonts.jetBrainsMono(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.accentRose)),
                          ],
                        ),
                        Slider(
                          value: _crampsLevel.toDouble(),
                          min: 0,
                          max: 5,
                          divisions: 5,
                          activeColor: AppTheme.accentRose,
                          onChanged: (val) => setState(() => _crampsLevel = val.round()),
                        ),
                        const SizedBox(height: 10),

                        // Estado de Ánimo
                        Text('Estado de Ánimo', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _buildChoiceChip('Calma & Foco', 'calm', _mood, (v) => setState(() => _mood = v ?? 'calm')),
                            _buildChoiceChip('Alta Energía', 'energetic', _mood, (v) => setState(() => _mood = v ?? 'energetic')),
                            _buildChoiceChip('Sensible', 'sensitive', _mood, (v) => setState(() => _mood = v ?? 'sensitive')),
                            _buildChoiceChip('Irritable', 'irritable', _mood, (v) => setState(() => _mood = v ?? 'irritable')),
                            _buildChoiceChip('Ansiosa', 'anxious', _mood, (v) => setState(() => _mood = v ?? 'anxious')),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Síntomas específicos
                        Text('Síntomas Adicionales', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _availableSymptomsList.map((item) {
                            final key = item['key'] as String;
                            final label = item['label'] as String;
                            final icon = item['icon'] as IconData;
                            final isSel = _selectedSymptoms.contains(key);

                            return FilterChip(
                              avatar: Icon(icon, size: 14, color: isSel ? Colors.white : AppTheme.onSurfaceVariant),
                              label: Text(label),
                              selected: isSel,
                              selectedColor: AppTheme.accentSky,
                              labelStyle: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                color: isSel ? Colors.white : AppTheme.onSurface,
                              ),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedSymptoms.add(key);
                                  } else {
                                    _selectedSymptoms.remove(key);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // SECTION 3: Fertilidad & Planificación Familiar (Prenupcial)
                    _buildSectionCard(
                      title: 'Fertilidad / Modo Prenupcial',
                      badge: 'PLANIFICACIÓN NATURAL',
                      badgeColor: AppTheme.accentEmerald,
                      icon: Icons.volunteer_activism_rounded,
                      children: [
                        Text('Método de Observación', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _buildChoiceChip('Sintotérmico', 'symptothermal', _fertilityMethod, (v) => setState(() => _fertilityMethod = v ?? 'symptothermal')),
                            _buildChoiceChip('Billings', 'billings', _fertilityMethod, (v) => setState(() => _fertilityMethod = v ?? 'billings')),
                            _buildChoiceChip('Ritmo / Calendario', 'rhythm', _fertilityMethod, (v) => setState(() => _fertilityMethod = v ?? 'rhythm')),
                          ],
                        ),
                        const SizedBox(height: 14),

                        Text('Estado de la Ventana Fértil', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _buildChoiceChip('Fértil (Alta probabilidad)', 'fertile', _fertileWindowStatus, (v) => setState(() => _fertileWindowStatus = v)),
                            _buildChoiceChip('Infértil (Baja probabilidad)', 'infertile', _fertileWindowStatus, (v) => setState(() => _fertileWindowStatus = v)),
                            _buildChoiceChip('Incierta / En Evaluación', 'uncertain', _fertileWindowStatus, (v) => setState(() => _fertileWindowStatus = v)),
                          ],
                        ),
                        const SizedBox(height: 14),

                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Compartir con Pareja',
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            'Permite sincronización de ventana fértil en vista compartida prenupcial.',
                            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.onSurfaceVariant),
                          ),
                          value: _partnerShared,
                          activeThumbColor: AppTheme.accentEmerald,
                          onChanged: (val) => setState(() => _partnerShared = val),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // SECTION 4: Modo Embarazo
                    _buildSectionCard(
                      title: 'Seguimiento de Embarazo',
                      badge: 'GESTACIONAL',
                      badgeColor: const Color(0xFFAB47BC),
                      icon: Icons.pregnant_woman_rounded,
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Embarazo Activo',
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            'Pausa la predicción del ciclo y activa el contador de semanas de gestación.',
                            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.onSurfaceVariant),
                          ),
                          value: _enablePregnancy,
                          activeThumbColor: const Color(0xFFAB47BC),
                          onChanged: (val) => setState(() => _enablePregnancy = val),
                        ),
                        if (_enablePregnancy) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  initialValue: _pregnancyWeek ?? 4,
                                  decoration: InputDecoration(
                                    labelText: 'Semana Actual',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                  items: List.generate(42, (i) => i + 1).map((w) {
                                    return DropdownMenuItem(value: w, child: Text('Semana $w'));
                                  }).toList(),
                                  onChanged: (val) => setState(() => _pregnancyWeek = val),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 240)),
                                      firstDate: DateTime.now().subtract(const Duration(days: 60)),
                                      lastDate: DateTime.now().add(const Duration(days: 300)),
                                    );
                                    if (picked != null) {
                                      setState(() => _dueDate = picked);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: AppTheme.outlineVariant),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.cake_outlined, size: 18),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            _dueDate != null ? DateFormat('dd/MM/yyyy').format(_dueDate!) : 'Fecha Parto',
                                            style: GoogleFonts.plusJakartaSans(fontSize: 12),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),

              // Bottom Save Button
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.accentRose,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _handleSave,
                  icon: const Icon(Icons.save_rounded, size: 18),
                  label: Text(
                    'Guardar Registro del Día',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String badge,
    required Color badgeColor,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: badgeColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.onSurface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: badgeColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildChoiceChip(
    String label,
    String value,
    String? currentGroupValue,
    ValueChanged<String?> onSelected,
  ) {
    final isSelected = currentGroupValue == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        onSelected(selected ? value : null);
      },
      selectedColor: AppTheme.primary.withValues(alpha: 0.15),
      labelStyle: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? AppTheme.primary : AppTheme.onSurface,
      ),
    );
  }
}
