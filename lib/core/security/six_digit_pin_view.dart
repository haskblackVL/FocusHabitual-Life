import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme.dart';
import 'security_controller.dart';

/// Executive 6-digit PIN input view with numeric keypad and visual dot indicators.
class SixDigitPinPad extends StatefulWidget {
  final String title;
  final String subtitle;
  final String expectedPin;
  final VoidCallback onSuccess;
  final VoidCallback? onUseBiometrics;
  final VoidCallback? onCancel;
  final String? biometricButtonLabel;

  const SixDigitPinPad({
    super.key,
    this.title = 'Ingresa tu PIN de 6 dígitos',
    this.subtitle = 'Confirma tu identidad para continuar',
    required this.expectedPin,
    required this.onSuccess,
    this.onUseBiometrics,
    this.onCancel,
    this.biometricButtonLabel,
  });

  @override
  State<SixDigitPinPad> createState() => _SixDigitPinPadState();
}

class _SixDigitPinPadState extends State<SixDigitPinPad> {
  String _pin = '';
  String? _errorMessage;
  bool _isSuccess = false;

  void _onDigitPressed(String digit) {
    if (_pin.length >= 6 || _isSuccess) return;

    setState(() {
      _errorMessage = null;
      _pin += digit;
    });

    if (_pin.length == 6) {
      _validatePin();
    }
  }

  void _onBackspacePressed() {
    if (_pin.isEmpty || _isSuccess) return;
    setState(() {
      _errorMessage = null;
      _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  void _validatePin() {
    if (_pin == widget.expectedPin) {
      setState(() {
        _isSuccess = true;
        _errorMessage = null;
      });
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          widget.onSuccess();
        }
      });
    } else {
      setState(() {
        _errorMessage = 'PIN incorrecto. Inténtalo de nuevo.';
      });
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() {
            _pin = '';
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Security Emblem
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: AppTheme.primaryContainer.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.primaryContainer.withValues(alpha: 0.3),
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.lock_outline_rounded,
              color: AppTheme.primaryContainer,
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Title & Subtitle
        Text(
          widget.title,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppTheme.onSurface,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.subtitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppTheme.outline,
          ),
        ),
        const SizedBox(height: 24),

        // 6 PIN Visual Dots
        _buildPinDotsRow(),
        const SizedBox(height: 12),

        // Error message row
        SizedBox(
          height: 24,
          child: _errorMessage != null
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 14, color: AppTheme.error),
                    const SizedBox(width: 6),
                    Text(
                      _errorMessage!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.error,
                      ),
                    ),
                  ],
                )
              : null,
        ),
        const SizedBox(height: 14),

        // Numeric Keypad
        _buildNumericKeypad(),

        // Cancel / Biometric option below keypad
        if (widget.onCancel != null) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: widget.onCancel,
            child: Text(
              'Cancelar',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppTheme.outline,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPinDotsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        final isFilled = index < _pin.length;
        final hasError = _errorMessage != null;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 16,
          height: 16,
          margin: const EdgeInsets.symmetric(horizontal: 7),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled
                ? (hasError
                    ? AppTheme.error
                    : (_isSuccess ? AppTheme.accentEmerald : AppTheme.primaryContainer))
                : Colors.transparent,
            border: Border.all(
              color: hasError
                  ? AppTheme.error
                  : (isFilled
                      ? (_isSuccess ? AppTheme.accentEmerald : AppTheme.primaryContainer)
                      : AppTheme.outlineVariant),
              width: 2,
            ),
            boxShadow: isFilled
                ? [
                    BoxShadow(
                      color: (hasError
                              ? AppTheme.error
                              : (_isSuccess ? AppTheme.accentEmerald : AppTheme.primaryContainer))
                          .withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
        );
      }),
    );
  }

  Widget _buildNumericKeypad() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Column(
        children: [
          _buildKeypadRow(['1', '2', '3']),
          const SizedBox(height: 12),
          _buildKeypadRow(['4', '5', '6']),
          const SizedBox(height: 12),
          _buildKeypadRow(['7', '8', '9']),
          const SizedBox(height: 12),
          _buildBottomKeypadRow(),
        ],
      ),
    );
  }

  Widget _buildKeypadRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((d) => _buildKeyButton(d)).toList(),
    );
  }

  Widget _buildBottomKeypadRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Biometrics button if available
        if (widget.onUseBiometrics != null)
          _buildActionKey(
            icon: Icons.fingerprint_rounded,
            tooltip: widget.biometricButtonLabel ?? 'Usar Huella',
            onTap: widget.onUseBiometrics!,
          )
        else
          const SizedBox(width: 66, height: 66),

        _buildKeyButton('0'),

        // Backspace
        _buildActionKey(
          icon: Icons.backspace_outlined,
          tooltip: 'Borrar',
          onTap: _onBackspacePressed,
        ),
      ],
    );
  }

  Widget _buildKeyButton(String digit) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onDigitPressed(digit),
        borderRadius: BorderRadius.circular(33),
        splashColor: AppTheme.primaryContainer.withValues(alpha: 0.2),
        highlightColor: AppTheme.primaryContainer.withValues(alpha: 0.1),
        child: Container(
          width: 66,
          height: 66,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.surfaceContainerLow,
            border: Border.all(color: AppTheme.surfaceContainerHigh),
          ),
          child: Center(
            child: Text(
              digit,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionKey({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(33),
        child: Container(
          width: 66,
          height: 66,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 26,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// Modal dialog providing 6-digit PIN verification.
class SixDigitPinDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final String expectedPin;
  final VoidCallback? onUseBiometrics;

  const SixDigitPinDialog({
    super.key,
    this.title = 'PIN de Seguridad',
    this.subtitle = 'Ingresa el código de 6 dígitos',
    required this.expectedPin,
    this.onUseBiometrics,
  });

  static Future<bool> show({
    required BuildContext context,
    required String expectedPin,
    String title = 'PIN de Seguridad',
    String subtitle = 'Ingresa tu PIN de 6 dígitos',
    VoidCallback? onUseBiometrics,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SixDigitPinDialog(
        title: title,
        subtitle: subtitle,
        expectedPin: expectedPin,
        onUseBiometrics: onUseBiometrics,
      ),
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppTheme.outlineVariant),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: SixDigitPinPad(
          title: title,
          subtitle: subtitle,
          expectedPin: expectedPin,
          onSuccess: () => Navigator.of(context).pop(true),
          onCancel: () => Navigator.of(context).pop(false),
          onUseBiometrics: onUseBiometrics != null
              ? () {
                  Navigator.of(context).pop(false);
                  onUseBiometrics!();
                }
              : null,
        ),
      ),
    );
  }
}

/// Dialog guiding the user through creating or updating their 6-digit security PIN.
class ChangePinDialog extends ConsumerStatefulWidget {
  const ChangePinDialog({super.key});

  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const ChangePinDialog(),
    );
    return result == true;
  }

  @override
  ConsumerState<ChangePinDialog> createState() => _ChangePinDialogState();
}

enum _PinSetupStep { verifyCurrent, enterNew, confirmNew }

class _ChangePinDialogState extends ConsumerState<ChangePinDialog> {
  _PinSetupStep _step = _PinSetupStep.enterNew;
  String _currentInput = '';
  String _firstNewPin = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(securityControllerProvider);
    if (settings.hasCustomPin) {
      _step = _PinSetupStep.verifyCurrent;
    } else {
      _step = _PinSetupStep.enterNew;
    }
  }

  void _onDigit(String d) {
    if (_currentInput.length >= 6) return;
    setState(() {
      _errorMessage = null;
      _currentInput += d;
    });

    if (_currentInput.length == 6) {
      _handleCompletedInput();
    }
  }

  void _onBackspace() {
    if (_currentInput.isEmpty) return;
    setState(() {
      _errorMessage = null;
      _currentInput = _currentInput.substring(0, _currentInput.length - 1);
    });
  }

  void _handleCompletedInput() {
    final settings = ref.read(securityControllerProvider);

    switch (_step) {
      case _PinSetupStep.verifyCurrent:
        if (_currentInput == settings.securityPin) {
          setState(() {
            _currentInput = '';
            _errorMessage = null;
            _step = _PinSetupStep.enterNew;
          });
        } else {
          setState(() {
            _errorMessage = 'PIN actual incorrecto';
          });
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) setState(() => _currentInput = '');
          });
        }
        break;

      case _PinSetupStep.enterNew:
        setState(() {
          _firstNewPin = _currentInput;
          _currentInput = '';
          _errorMessage = null;
          _step = _PinSetupStep.confirmNew;
        });
        break;

      case _PinSetupStep.confirmNew:
        if (_currentInput == _firstNewPin) {
          ref.read(securityControllerProvider.notifier).setSecurityPin(_currentInput);
          Navigator.of(context).pop(true);
        } else {
          setState(() {
            _errorMessage = 'Los PINs no coinciden. Inténtalo de nuevo.';
          });
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) {
              setState(() {
                _currentInput = '';
                _firstNewPin = '';
                _step = _PinSetupStep.enterNew;
              });
            }
          });
        }
        break;
    }
  }

  String get _stepTitle {
    switch (_step) {
      case _PinSetupStep.verifyCurrent:
        return 'Ingresa tu PIN actual';
      case _PinSetupStep.enterNew:
        return 'Nuevo PIN de 6 dígitos';
      case _PinSetupStep.confirmNew:
        return 'Confirma tu nuevo PIN';
    }
  }

  String get _stepSubtitle {
    switch (_step) {
      case _PinSetupStep.verifyCurrent:
        return 'Verificación de seguridad requerida';
      case _PinSetupStep.enterNew:
        return 'Elige un código seguro de 6 dígitos numéricos';
      case _PinSetupStep.confirmNew:
        return 'Vuelve a introducir el mismo PIN para confirmar';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppTheme.outlineVariant),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.primaryContainer.withValues(alpha: 0.3),
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.dialpad_rounded,
                  color: AppTheme.primaryContainer,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _stepTitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _stepSubtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: AppTheme.outline,
              ),
            ),
            const SizedBox(height: 22),

            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (i) {
                final isFilled = i < _currentInput.length;
                final hasError = _errorMessage != null;

                return Container(
                  width: 15,
                  height: 15,
                  margin: const EdgeInsets.symmetric(horizontal: 7),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled
                        ? (hasError ? AppTheme.error : AppTheme.primaryContainer)
                        : Colors.transparent,
                    border: Border.all(
                      color: hasError ? AppTheme.error : (isFilled ? AppTheme.primaryContainer : AppTheme.outlineVariant),
                      width: 2,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),

            SizedBox(
              height: 22,
              child: _errorMessage != null
                  ? Text(
                      _errorMessage!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.error,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 14),

            // Keypad
            Container(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Column(
                children: [
                  _buildRow(['1', '2', '3']),
                  const SizedBox(height: 12),
                  _buildRow(['4', '5', '6']),
                  const SizedBox(height: 12),
                  _buildRow(['7', '8', '9']),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const SizedBox(width: 66, height: 66),
                      _buildKey('0'),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _onBackspace,
                          borderRadius: BorderRadius.circular(33),
                          child: const SizedBox(
                            width: 66,
                            height: 66,
                            child: Icon(Icons.backspace_outlined, size: 24, color: AppTheme.onSurfaceVariant),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancelar',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppTheme.outline,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(List<String> items) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: items.map((i) => _buildKey(i)).toList(),
    );
  }

  Widget _buildKey(String d) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onDigit(d),
        borderRadius: BorderRadius.circular(33),
        splashColor: AppTheme.primaryContainer.withValues(alpha: 0.2),
        child: Container(
          width: 66,
          height: 66,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.surfaceContainerLow,
            border: Border.all(color: AppTheme.surfaceContainerHigh),
          ),
          child: Center(
            child: Text(
              d,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
