import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme.dart';
import '../../domain/finance_account.dart';
import '../controllers/finance_controller.dart';

/// Modal bottom sheet for creating a new financial account.
class AddAccountSheet extends ConsumerStatefulWidget {
  const AddAccountSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddAccountSheet(),
    );
  }

  @override
  ConsumerState<AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends ConsumerState<AddAccountSheet> {
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController(text: '0.00');

  AccountType _selectedType = AccountType.bank;
  String _selectedCurrency = 'MXN';
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor escribe el nombre de la cuenta.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final balanceText = _balanceController.text.replaceAll(',', '.').trim();
    final balance = double.tryParse(balanceText) ?? 0.0;

    setState(() => _isSaving = true);

    try {
      await ref.read(financeControllerProvider.notifier).createAccount(
            name: name,
            type: _selectedType,
            currency: _selectedCurrency,
            initialBalance: balance,
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
                  'Cuenta "$name" creada exitosamente',
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
            content: Text('Error al crear la cuenta: $e'),
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
              'Añadir Cuenta Financiera',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),

            // Account Name
            TextField(
              controller: _nameController,
              autofocus: true,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: isDark ? Colors.white : AppTheme.onSurface,
              ),
              decoration: InputDecoration(
                labelText: 'Nombre de la cuenta',
                labelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: isDark ? Colors.white60 : AppTheme.outline,
                ),
                hintText: 'Ej. BBVA Nómina, Cetes Directo, Efectivo',
                filled: true,
                fillColor: inputBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: borderColor),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Type Selector
            Text(
              'TIPO DE CUENTA',
              style: AppTheme.labelCaps(
                fontSize: 10,
                color: isDark ? Colors.white54 : AppTheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AccountType.values.map((type) {
                final isSelected = type == _selectedType;
                return ChoiceChip(
                  avatar: Icon(
                    type.icon,
                    size: 16,
                    color: isSelected ? Colors.white : type.color,
                  ),
                  label: Text(type.label),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedType = type);
                    }
                  },
                  selectedColor: type.color,
                  labelStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppTheme.onSurface),
                  ),
                  backgroundColor: inputBg,
                  side: BorderSide(
                    color: isSelected ? type.color : borderColor,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Initial Balance & Currency
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _balanceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: AppTheme.numeric(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppTheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      labelText: _selectedType == AccountType.creditCard ? 'Deuda Inicial' : 'Saldo Inicial',
                      labelStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : AppTheme.outline,
                      ),
                      prefixText: '\$ ',
                      prefixStyle: AppTheme.numeric(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _selectedType.color,
                      ),
                      filled: true,
                      fillColor: inputBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: borderColor),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedCurrency,
                    dropdownColor: sheetBg,
                    style: AppTheme.numeric(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppTheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Moneda',
                      labelStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : AppTheme.outline,
                      ),
                      filled: true,
                      fillColor: inputBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: borderColor),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'MXN', child: Text('MXN (\$')),
                      DropdownMenuItem(value: 'USD', child: Text('USD (\$')),
                      DropdownMenuItem(value: 'EUR', child: Text('EUR (€')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedCurrency = val);
                      }
                    },
                  ),
                ),
              ],
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
                      'Crear Cuenta',
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
}
