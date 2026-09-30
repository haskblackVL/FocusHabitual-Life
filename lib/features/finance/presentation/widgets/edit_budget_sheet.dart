import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme.dart';
import '../../data/finance_repository.dart';
import '../../domain/finance_budget.dart';
import '../../domain/finance_transaction.dart';
import '../controllers/finance_controller.dart';

/// Modal bottom sheet for customizing 50/30/20 budget limits.
class EditBudgetSheet extends ConsumerStatefulWidget {
  const EditBudgetSheet({
    super.key,
    required this.ruleSummary,
  });

  final Rule503020Summary ruleSummary;

  static Future<void> show(BuildContext context, Rule503020Summary summary) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditBudgetSheet(ruleSummary: summary),
    );
  }

  @override
  ConsumerState<EditBudgetSheet> createState() => _EditBudgetSheetState();
}

class _EditBudgetSheetState extends ConsumerState<EditBudgetSheet> {
  late final TextEditingController _needsController;
  late final TextEditingController _wantsController;
  late final TextEditingController _savingsController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _needsController = TextEditingController(
      text: widget.ruleSummary.needs.limit.toStringAsFixed(0),
    );
    _wantsController = TextEditingController(
      text: widget.ruleSummary.wants.limit.toStringAsFixed(0),
    );
    _savingsController = TextEditingController(
      text: widget.ruleSummary.savings.limit.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _needsController.dispose();
    _wantsController.dispose();
    _savingsController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final needsLimit = double.tryParse(_needsController.text.trim()) ?? 0.0;
    final wantsLimit = double.tryParse(_wantsController.text.trim()) ?? 0.0;
    final savingsLimit = double.tryParse(_savingsController.text.trim()) ?? 0.0;

    setState(() => _isSaving = true);

    try {
      final month = ref.read(selectedFinanceMonthProvider);
      final monthStr = FinanceRepository.formatMonthYear(month);
      final controller = ref.read(financeControllerProvider.notifier);

      await controller.setBudgetCap(
        monthYear: monthStr,
        group: BudgetGroup.needs50,
        limit: needsLimit,
      );
      await controller.setBudgetCap(
        monthYear: monthStr,
        group: BudgetGroup.wants30,
        limit: wantsLimit,
      );
      await controller.setBudgetCap(
        monthYear: monthStr,
        group: BudgetGroup.savings20,
        limit: savingsLimit,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Límites presupuestarios actualizados',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar presupuesto: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF131722) : Colors.white;
    final borderColor = isDark ? const Color(0xFF262D3D) : const Color(0xFFE2E8F0);
    final inputBg = isDark ? const Color(0xFF1A202C) : const Color(0xFFF8FAFC);

    final totalIncome = widget.ruleSummary.totalIncome;

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: borderColor),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Ajustar Presupuesto 50/30/20',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Ingresos del mes: \$${totalIncome.toStringAsFixed(2)} MXN',
              style: AppTheme.numeric(
                fontSize: 12,
                color: const Color(0xFF10B981),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),

            // 50% Needs Input
            _buildPillarInput(
              group: BudgetGroup.needs50,
              controller: _needsController,
              suggestedPct: 50,
              suggestedAmount: totalIncome * 0.50,
              inputBg: inputBg,
              borderColor: borderColor,
              isDark: isDark,
            ),
            const SizedBox(height: 14),

            // 30% Wants Input
            _buildPillarInput(
              group: BudgetGroup.wants30,
              controller: _wantsController,
              suggestedPct: 30,
              suggestedAmount: totalIncome * 0.30,
              inputBg: inputBg,
              borderColor: borderColor,
              isDark: isDark,
            ),
            const SizedBox(height: 14),

            // 20% Savings Input
            _buildPillarInput(
              group: BudgetGroup.savings20,
              controller: _savingsController,
              suggestedPct: 20,
              suggestedAmount: totalIncome * 0.20,
              inputBg: inputBg,
              borderColor: borderColor,
              isDark: isDark,
            ),
            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton(
              onPressed: _isSaving ? null : _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      'Guardar Límites Presupuestarios',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillarInput({
    required BudgetGroup group,
    required TextEditingController controller,
    required int suggestedPct,
    required double suggestedAmount,
    required Color inputBg,
    required Color borderColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: group.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    group.label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppTheme.onSurface,
                    ),
                  ),
                ],
              ),
              Text(
                'Sugerido: \$${suggestedAmount.toStringAsFixed(0)}',
                style: AppTheme.numeric(
                  fontSize: 11,
                  color: isDark ? Colors.white54 : AppTheme.outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTheme.numeric(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppTheme.onSurface,
            ),
            decoration: InputDecoration(
              prefixText: '\$ ',
              prefixStyle: AppTheme.numeric(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: group.color,
              ),
              suffixText: 'MXN',
              suffixStyle: AppTheme.numeric(
                fontSize: 11,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              isDense: true,
              border: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }
}
