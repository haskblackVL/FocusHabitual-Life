import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme.dart';
import '../../domain/finance_account.dart';
import '../../domain/finance_transaction.dart';
import '../controllers/finance_controller.dart';

/// Modal bottom sheet for swiftly recording financial movements.
class AddTransactionSheet extends ConsumerStatefulWidget {
  const AddTransactionSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddTransactionSheet(),
    );
  }

  @override
  ConsumerState<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  TransactionType _selectedType = TransactionType.expense;
  String? _selectedAccountId;
  String? _selectedToAccountId;
  FinanceCategory _selectedCategory = FinanceCategory.needsGroceries;
  final DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  List<FinanceCategory> get _availableCategories {
    if (_selectedType == TransactionType.income) {
      return [
        FinanceCategory.incomeSalary,
        FinanceCategory.incomeFreelance,
        FinanceCategory.incomeBusiness,
        FinanceCategory.incomeDividends,
        FinanceCategory.incomeGeneral,
      ];
    } else if (_selectedType == TransactionType.expense) {
      return [
        // 50%
        FinanceCategory.needsHousing,
        FinanceCategory.needsGroceries,
        FinanceCategory.needsUtilities,
        FinanceCategory.needsTransport,
        FinanceCategory.needsHealth,
        FinanceCategory.needsGeneral,
        // 30%
        FinanceCategory.wantsDining,
        FinanceCategory.wantsEntertainment,
        FinanceCategory.wantsShopping,
        FinanceCategory.wantsTravel,
        FinanceCategory.wantsGeneral,
        // 20%
        FinanceCategory.savingsEmergency,
        FinanceCategory.investmentAssets,
        FinanceCategory.polymathEducation,
        FinanceCategory.savingsGeneral,
      ];
    } else {
      return [FinanceCategory.transfer];
    }
  }

  void _onTypeChanged(TransactionType type) {
    setState(() {
      _selectedType = type;
      if (type == TransactionType.income) {
        _selectedCategory = FinanceCategory.incomeSalary;
      } else if (type == TransactionType.expense) {
        _selectedCategory = FinanceCategory.needsGroceries;
      } else {
        _selectedCategory = FinanceCategory.transfer;
      }
    });
  }

  Future<void> _handleSave() async {
    final amountText = _amountController.text.replaceAll(',', '.').trim();
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa un monto válido mayor a 0.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una cuenta para este movimiento.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    if (_selectedType == TransactionType.transfer && _selectedToAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona la cuenta de destino para la transferencia.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ref.read(financeControllerProvider.notifier).recordTransaction(
            accountId: _selectedAccountId!,
            amount: amount,
            type: _selectedType,
            category: _selectedCategory,
            toAccountId: _selectedType == TransactionType.transfer ? _selectedToAccountId : null,
            occurredAt: _selectedDate,
            note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
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
                  'Movimiento registrado • +10 XP',
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
            content: Text('Error al guardar: $e'),
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
    final AsyncValue<List<FinanceAccount>> accountsAsync = ref.watch(financeAccountsProvider);
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

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nuevo Movimiento',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppTheme.onSurface,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '+10 XP',
                    style: AppTheme.numeric(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Type Selector (Gasto / Ingreso / Transferencia)
            Row(
              children: [
                _buildTypeButton(
                  type: TransactionType.expense,
                  title: 'Gasto',
                  icon: Icons.arrow_downward_rounded,
                  activeColor: const Color(0xFFEF4444),
                ),
                const SizedBox(width: 8),
                _buildTypeButton(
                  type: TransactionType.income,
                  title: 'Ingreso',
                  icon: Icons.arrow_upward_rounded,
                  activeColor: const Color(0xFF10B981),
                ),
                const SizedBox(width: 8),
                _buildTypeButton(
                  type: TransactionType.transfer,
                  title: 'Transferir',
                  icon: Icons.swap_horiz_rounded,
                  activeColor: const Color(0xFF3B82F6),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Amount Input Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: inputBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MONTO',
                    style: AppTheme.labelCaps(
                      fontSize: 10,
                      color: isDark ? Colors.white54 : AppTheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '\$',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: _selectedType.color,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          autofocus: true,
                          style: AppTheme.numeric(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppTheme.onSurface,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: '0.00',
                            hintStyle: AppTheme.numeric(
                              fontSize: 32,
                              fontWeight: FontWeight.w400,
                              color: isDark ? Colors.white24 : Colors.black26,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        'MXN',
                        style: AppTheme.numeric(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white54 : AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Account Selector
            accountsAsync.when(
              data: (accounts) {
                if (accounts.isEmpty) {
                  return const SizedBox.shrink();
                }
                _selectedAccountId ??= accounts.first.id;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedType == TransactionType.transfer ? 'CUENTA ORIGEN' : 'CUENTA',
                      style: AppTheme.labelCaps(
                        fontSize: 10,
                        color: isDark ? Colors.white54 : AppTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: accounts.map((acc) {
                          final isSelected = acc.id == _selectedAccountId;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(acc.type.icon, size: 14, color: isSelected ? Colors.white : acc.type.color),
                                  const SizedBox(width: 6),
                                  Text(acc.name),
                                ],
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _selectedAccountId = acc.id);
                                }
                              },
                              selectedColor: AppTheme.primary,
                              labelStyle: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppTheme.onSurface),
                              ),
                              backgroundColor: inputBg,
                              side: BorderSide(
                                color: isSelected ? AppTheme.primary : borderColor,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    // Destination account if transfer
                    if (_selectedType == TransactionType.transfer) ...[
                      const SizedBox(height: 12),
                      Text(
                        'CUENTA DESTINO',
                        style: AppTheme.labelCaps(
                          fontSize: 10,
                          color: isDark ? Colors.white54 : AppTheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: accounts
                              .where((a) => a.id != _selectedAccountId)
                              .map((acc) {
                            final isSelected = acc.id == _selectedToAccountId;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(acc.type.icon, size: 14, color: isSelected ? Colors.white : acc.type.color),
                                    const SizedBox(width: 6),
                                    Text(acc.name),
                                  ],
                                ),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() => _selectedToAccountId = acc.id);
                                  }
                                },
                                selectedColor: const Color(0xFF3B82F6),
                                labelStyle: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppTheme.onSurface),
                                ),
                                backgroundColor: inputBg,
                                side: BorderSide(
                                  color: isSelected ? const Color(0xFF3B82F6) : borderColor,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),

            // Category Selector (if not transfer)
            if (_selectedType != TransactionType.transfer) ...[
              Text(
                'CATEGORÍA',
                style: AppTheme.labelCaps(
                  fontSize: 10,
                  color: isDark ? Colors.white54 : AppTheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableCategories.map((cat) {
                  final isSelected = cat == _selectedCategory;
                  final group = cat.budgetGroup;
                  return ChoiceChip(
                    avatar: Icon(
                      cat.icon,
                      size: 14,
                      color: isSelected ? Colors.white : group.color,
                    ),
                    label: Text(cat.label),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedCategory = cat);
                      }
                    },
                    selectedColor: group.color,
                    labelStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppTheme.onSurface),
                    ),
                    backgroundColor: inputBg,
                    side: BorderSide(
                      color: isSelected ? group.color : borderColor,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Note Input
            TextField(
              controller: _noteController,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: isDark ? Colors.white : AppTheme.onSurface,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: inputBg,
                hintText: 'Nota o descripción opcional...',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: isDark ? Colors.white38 : AppTheme.outline,
                ),
                prefixIcon: Icon(
                  Icons.edit_note_rounded,
                  size: 20,
                  color: isDark ? Colors.white54 : AppTheme.outline,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: borderColor),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 20),

            // Submit Button
            ElevatedButton(
              onPressed: _isSaving ? null : _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedType.color,
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
                      'Guardar Movimiento • +10 XP',
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

  Widget _buildTypeButton({
    required TransactionType type,
    required String title,
    required IconData icon,
    required Color activeColor,
  }) {
    final isSelected = _selectedType == type;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveBg = isDark ? const Color(0xFF1E2533) : const Color(0xFFF1F5F9);
    final borderColor = isDark ? const Color(0xFF262D3D) : const Color(0xFFE2E8F0);

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTypeChanged(type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withValues(alpha: 0.15) : inactiveBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? activeColor : borderColor,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? activeColor : (isDark ? Colors.white60 : AppTheme.onSurfaceVariant),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? activeColor : (isDark ? Colors.white70 : AppTheme.onSurface),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
