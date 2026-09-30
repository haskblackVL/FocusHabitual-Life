import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme.dart';
import '../../domain/finance_account.dart';
import '../../domain/finance_transaction.dart';
import '../controllers/finance_controller.dart';

/// Recurrence period for received amounts.
enum ReceivePeriod {
  weekly('Semanal', 'Por semana (x52/año)'),
  monthly('Mensual', 'Por mes (x12/año)'),
  annual('Anual', 'Por año (/12 mes)');

  const ReceivePeriod(this.label, this.description);
  final String label;
  final String description;
}

/// Executive modal sheet to record recurring or one-off received amounts (semanal, mensual, anual)
/// directly credited into a specific financial account.
class QuickReceiveSheet extends ConsumerStatefulWidget {
  final FinanceAccount account;

  const QuickReceiveSheet({super.key, required this.account});

  static Future<void> show(BuildContext context, FinanceAccount account) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => QuickReceiveSheet(account: account),
    );
  }

  @override
  ConsumerState<QuickReceiveSheet> createState() => _QuickReceiveSheetState();
}

class _QuickReceiveSheetState extends ConsumerState<QuickReceiveSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _conceptController = TextEditingController();

  ReceivePeriod _selectedPeriod = ReceivePeriod.monthly;
  final FinanceCategory _category = FinanceCategory.incomeGeneral;
  final DateTime _transactionDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _conceptController.text = 'Ingreso ${_selectedPeriod.label} - ${widget.account.name}';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _conceptController.dispose();
    super.dispose();
  }

  double get _enteredAmount {
    final cleaned = _amountController.text.replaceAll(',', '').trim();
    return double.tryParse(cleaned) ?? 0.0;
  }

  double get _calculatedWeekly {
    switch (_selectedPeriod) {
      case ReceivePeriod.weekly:
        return _enteredAmount;
      case ReceivePeriod.monthly:
        return _enteredAmount / 4.333;
      case ReceivePeriod.annual:
        return _enteredAmount / 52.0;
    }
  }

  double get _calculatedMonthly {
    switch (_selectedPeriod) {
      case ReceivePeriod.weekly:
        return _enteredAmount * 4.333;
      case ReceivePeriod.monthly:
        return _enteredAmount;
      case ReceivePeriod.annual:
        return _enteredAmount / 12.0;
    }
  }

  double get _calculatedAnnual {
    switch (_selectedPeriod) {
      case ReceivePeriod.weekly:
        return _enteredAmount * 52.0;
      case ReceivePeriod.monthly:
        return _enteredAmount * 12.0;
      case ReceivePeriod.annual:
        return _enteredAmount;
    }
  }

  String _formatCurrency(double amount) {
    final f = NumberFormat('#,##0.00', 'en_US');
    return f.format(amount);
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = _enteredAmount;
    if (amount <= 0) return;

    setState(() => _isLoading = true);

    try {
      final title = _conceptController.text.trim().isNotEmpty
          ? _conceptController.text.trim()
          : 'Ingreso ${_selectedPeriod.label}';

      final note = 'Recibido ${_selectedPeriod.label}: \$${_formatCurrency(amount)} '
          '(Eq. Mensual: \$${_formatCurrency(_calculatedMonthly)})';

      await ref.read(financeControllerProvider.notifier).recordTransaction(
            accountId: widget.account.id,
            amount: amount,
            type: TransactionType.income,
            category: _category,
            note: '$title - $note',
            occurredAt: _transactionDate,
          );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '+\$${_formatCurrency(amount)} ${widget.account.currency} acreditados en ${widget.account.name} (+10 XP)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.error,
            content: Text('Error al registrar ingreso: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.darkSurface : Colors.white;
    final borderColor = isDark ? const Color(0xFF262D3D) : const Color(0xFFE2E8F0);

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: borderColor, width: 1)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title and Account badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AÑADIR INGRESO RECIBIDO',
                        style: AppTheme.labelCaps(
                          fontSize: 11,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Acreditar a ${widget.account.name}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppTheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: widget.account.type.color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: widget.account.type.color.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(widget.account.type.icon, size: 14, color: widget.account.type.color),
                        const SizedBox(width: 4),
                        Text(
                          widget.account.currency,
                          style: AppTheme.numeric(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: widget.account.type.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Period Toggle (Semanal, Mensual, Anual)
              Text(
                'PERIODICIDAD RECIBIDA',
                style: AppTheme.labelCaps(
                  fontSize: 10,
                  color: isDark ? Colors.white60 : AppTheme.outline,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2533) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: ReceivePeriod.values.map((p) {
                    final isSel = _selectedPeriod == p;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedPeriod = p;
                            _conceptController.text = 'Ingreso ${p.label} - ${widget.account.name}';
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSel ? const Color(0xFF10B981) : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            p.label,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                              color: isSel ? Colors.white : (isDark ? Colors.white70 : AppTheme.onSurfaceVariant),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Amount Input
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                style: AppTheme.numeric(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF10B981),
                ),
                decoration: InputDecoration(
                  labelText: 'Monto Recibido (${_selectedPeriod.label})',
                  prefixText: '\$ ',
                  prefixStyle: AppTheme.numeric(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF10B981),
                  ),
                  hintText: '0.00',
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1A202C) : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                ),
                onChanged: (_) => setState(() {}),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Ingresa el monto recibido';
                  }
                  final parsed = double.tryParse(val.replaceAll(',', '').trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Ingresa un monto válido mayor a 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Automatic Conversion Projection Card
              if (_enteredAmount > 0)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'PROYECCIÓN CALCULADA',
                            style: AppTheme.labelCaps(
                              fontSize: 9.5,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                          Icon(Icons.auto_graph_rounded, size: 14, color: const Color(0xFF10B981)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Semanal', style: GoogleFonts.inter(fontSize: 10, color: isDark ? Colors.white60 : AppTheme.outline)),
                                Text('\$${_formatCurrency(_calculatedWeekly)}', style: AppTheme.numeric(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppTheme.onSurface)),
                              ],
                            ),
                          ),
                          Container(width: 1, height: 26, color: borderColor),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Mensual', style: GoogleFonts.inter(fontSize: 10, color: isDark ? Colors.white60 : AppTheme.outline)),
                                Text('\$${_formatCurrency(_calculatedMonthly)}', style: AppTheme.numeric(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF10B981))),
                              ],
                            ),
                          ),
                          Container(width: 1, height: 26, color: borderColor),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Anual', style: GoogleFonts.inter(fontSize: 10, color: isDark ? Colors.white60 : AppTheme.outline)),
                                Text('\$${_formatCurrency(_calculatedAnnual)}', style: AppTheme.numeric(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppTheme.onSurface)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 14),

              // Concept / Description Input
              TextFormField(
                controller: _conceptController,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppTheme.onSurface,
                ),
                decoration: InputDecoration(
                  labelText: 'Concepto / Descripción',
                  hintText: 'Ej. Sueldo quincenal, Venta, Inversión',
                  prefixIcon: const Icon(Icons.receipt_long_rounded, size: 20),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1A202C) : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Submit Button
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.account_balance_wallet_rounded, size: 20),
                label: Text(
                  _isLoading
                      ? 'Acreditando...'
                      : 'Acreditar \$${_enteredAmount > 0 ? _formatCurrency(_enteredAmount) : "0.00"} a Cuenta',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
