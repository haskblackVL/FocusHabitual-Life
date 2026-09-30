import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme.dart';

class CustomWaterDialog extends StatefulWidget {
  final int currentGoal;
  final Function(int amountMl) onAddCustom;
  final Function(int newGoalMl) onUpdateGoal;

  const CustomWaterDialog({
    super.key,
    required this.currentGoal,
    required this.onAddCustom,
    required this.onUpdateGoal,
  });

  @override
  State<CustomWaterDialog> createState() => _CustomWaterDialogState();
}

class _CustomWaterDialogState extends State<CustomWaterDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _amountController = TextEditingController(text: '250');
  final _goalController = TextEditingController();
  final _weightController = TextEditingController(text: '70');
  int _suggestedGoal = 2450;

  final List<int> _quickPresets = [150, 250, 350, 500, 750, 1000];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _goalController.text = widget.currentGoal.toString();
    _calculateSuggestedGoal('70');
  }

  void _calculateSuggestedGoal(String weightText) {
    final weight = double.tryParse(weightText.replaceAll(',', '.')) ?? 0;
    if (weight > 0) {
      setState(() {
        _suggestedGoal = (weight * 35).round();
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _goalController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppTheme.surfaceContainerHigh),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF0284C7),
                labelColor: const Color(0xFF0284C7),
                unselectedLabelColor: AppTheme.onSurfaceVariant,
                labelStyle: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(text: 'Registrar Ingesta'),
                  Tab(text: 'Meta & Peso (kg)'),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 330,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Ingesta personalizada
                    _buildAddWaterTab(),

                    // Tab 2: Meta Diaria & Calculadora
                    _buildGoalAndWeightTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddWaterTab() {
    final currentAmount = int.tryParse(_amountController.text.trim()) ?? 0;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CANTIDAD A REGISTRAR (ML)',
            style: AppTheme.labelCaps(
              color: AppTheme.onSurfaceVariant,
              letterSpacing: 0.08,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            style: AppTheme.numeric(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: 'Ej. 350',
              prefixIcon: const Icon(
                Icons.water_drop_rounded,
                color: Color(0xFF0284C7),
                size: 20,
              ),
              suffixText: 'ml',
              suffixStyle: GoogleFonts.plusJakartaSans(
                color: AppTheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
              filled: true,
              fillColor: AppTheme.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'VOLÚMENES RÁPIDOS',
            style: AppTheme.labelCaps(
              fontSize: 9.5,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickPresets.map((amount) {
              final isSelected = currentAmount == amount;
              return InkWell(
                onTap: () {
                  setState(() {
                    _amountController.text = amount.toString();
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF0284C7).withValues(alpha: 0.15)
                        : AppTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF0284C7)
                          : AppTheme.surfaceContainerHigh,
                    ),
                  ),
                  child: Text(
                    '+$amount ml',
                    style: AppTheme.numeric(
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected
                          ? const Color(0xFF0284C7)
                          : AppTheme.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              minimumSize: const Size.fromHeight(46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.water_drop_rounded, color: Colors.white, size: 18),
            label: Text(
              'Añadir Ingesta (+5 XP)',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            onPressed: () {
              final val = int.tryParse(_amountController.text.trim()) ?? 0;
              if (val > 0) {
                widget.onAddCustom(val);
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGoalAndWeightTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF0284C7).withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.monitor_weight_outlined,
                      size: 16,
                      color: Color(0xFF0284C7),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'CALCULADORA POR PESO CORPORAL',
                      style: AppTheme.labelCaps(
                        fontSize: 9.5,
                        color: const Color(0xFF0284C7),
                        letterSpacing: 0.08,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Fórmula clínica recomendada: 35 ml por cada kg de peso corporal.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppTheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _weightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: _calculateSuggestedGoal,
                        style: AppTheme.numeric(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: '70',
                          suffixText: 'kg',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          filled: true,
                          fillColor: AppTheme.surfaceContainerLowest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _goalController.text = _suggestedGoal.toString();
                        });
                      },
                      child: Text(
                        'Usar $_suggestedGoal ml',
                        style: AppTheme.numeric(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'META DIARIA PERSONALIZADA (ML)',
            style: AppTheme.labelCaps(
              color: AppTheme.onSurfaceVariant,
              letterSpacing: 0.08,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _goalController,
            keyboardType: TextInputType.number,
            style: AppTheme.numeric(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: 'Ej. 2500',
              suffixText: 'ml',
              suffixStyle: GoogleFonts.plusJakartaSans(
                color: AppTheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
              filled: true,
              fillColor: AppTheme.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
            label: Text(
              'Guardar Meta Diaria',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            onPressed: () {
              final val = int.tryParse(_goalController.text.trim()) ?? 0;
              if (val >= 500) {
                widget.onUpdateGoal(val);
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }
}
