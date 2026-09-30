import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme.dart';
import '../../../../core/security/security_controller.dart';
import '../../../../core/security/six_digit_pin_view.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

/// Executive card managing biometrics, granular module locks, and discreet mode.
class SecuritySettingsCard extends ConsumerWidget {
  const SecuritySettingsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final security = ref.watch(securityControllerProvider);
    final profile = ref.watch(userProfileControllerProvider).value;
    final isMale = profile?.gender != 'female';
    final isFemale = profile?.gender == 'female';

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Biometric Lock Master Tile
          _buildMasterTile(
            context: context,
            icon: Icons.fingerprint_rounded,
            title: 'Bloqueo Biométrico',
            subtitle: security.biometricLockEnabled
                ? 'Activo · Face ID / Huella / Credenciales'
                : 'Desactivado · Acceso sin restricción',
            value: security.biometricLockEnabled,
            onChanged: (val) async {
              final ok = await ref.read(securityControllerProvider.notifier).setBiometricLock(val);
              if (!ok && context.mounted && val) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppTheme.surfaceContainerLowest,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppTheme.outlineVariant),
                    ),
                    content: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: AppTheme.error, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'No se pudo activar. Autenticación cancelada o no configurada en el dispositivo.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              color: AppTheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
          ),

          // Sub-options when Biometric Lock is Active
          if (security.biometricLockEnabled) ...[
            _buildDivider(),
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 4),
              child: Text(
                'PROTECCIÓN GRANULAR',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: AppTheme.outline,
                ),
              ),
            ),
            _buildSubSwitchTile(
              title: 'Bloquear al iniciar / reanudar app',
              subtitle: 'Exige verificación al abrir la aplicación',
              value: security.lockOnAppLaunch,
              onChanged: (v) {
                ref.read(securityControllerProvider.notifier).setLockOnAppLaunch(v);
              },
            ),
            if (isMale)
              _buildSubSwitchTile(
                title: 'Proteger módulo NoFap',
                subtitle: 'Exige biometría al acceder al contador y bitácora',
                value: security.lockNofap,
                onChanged: (v) {
                  ref.read(securityControllerProvider.notifier).setLockNofap(v);
                },
              ),
            if (isFemale)
              _buildSubSwitchTile(
                title: 'Proteger Salud & Ciclos',
                subtitle: 'Exige biometría al acceder a datos de fertilidad y ciclo',
                value: security.lockCycle,
                onChanged: (v) {
                  ref.read(securityControllerProvider.notifier).setLockCycle(v);
                },
              ),
            _buildSubSwitchTile(
              title: 'Proteger módulo de Finanzas',
              subtitle: 'Exige biometría al consultar libros contables',
              value: security.lockFinance,
              onChanged: (v) {
                ref.read(securityControllerProvider.notifier).setLockFinance(v);
              },
            ),

            // Auto-lock timeout selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tiempo de auto-bloqueo',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onSurface,
                          ),
                        ),
                        Text(
                          'Rebloquea si la app queda en segundo plano',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            color: AppTheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  DropdownButton<int>(
                    value: security.autoLockTimeoutSeconds,
                    dropdownColor: AppTheme.surfaceContainerLowest,
                    underline: const SizedBox.shrink(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryContainer,
                    ),
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('Inmediato')),
                      DropdownMenuItem(value: 60, child: Text('1 minuto')),
                      DropdownMenuItem(value: 300, child: Text('5 minutos')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(securityControllerProvider.notifier).setAutoLockTimeoutSeconds(val);
                      }
                    },
                  ),
                ],
              ),
            ),

            // 6-Digit PIN Configuration Tile
            _buildDivider(),
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 4),
              child: Text(
                'PIN DE RESPALDO (6 DÍGITOS)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: AppTheme.outline,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryContainer.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.dialpad_rounded, color: AppTheme.primaryContainer, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PIN de Seguridad',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onSurface,
                          ),
                        ),
                        Text(
                          security.hasCustomPin
                              ? 'PIN personalizado activo (••••••)'
                              : 'Predeterminado: 123456 (Toca para cambiar)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            color: AppTheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final updated = await ChangePinDialog.show(context);
                      if (updated && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppTheme.surfaceContainerLowest,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: AppTheme.primaryContainer),
                            ),
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: AppTheme.primaryContainer, size: 20),
                                const SizedBox(width: 12),
                                Text(
                                  'PIN de 6 dígitos actualizado correctamente',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5,
                                    color: AppTheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryContainer,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    child: Text(
                      security.hasCustomPin ? 'Cambiar PIN' : 'Personalizar',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Live Test Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () async {
                  final ok = await ref.read(securityControllerProvider.notifier).testAuthentication();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppTheme.surfaceContainerLowest,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: ok ? AppTheme.primaryContainer : AppTheme.error,
                          ),
                        ),
                        content: Row(
                          children: [
                            Icon(
                              ok ? Icons.check_circle_rounded : Icons.cancel_rounded,
                              color: ok ? AppTheme.primaryContainer : AppTheme.error,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              ok
                                  ? 'Sensor biométrico verificado con éxito'
                                  : 'Autenticación cancelada o no reconocida',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: AppTheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.outlineVariant),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.fingerprint_rounded, size: 16, color: AppTheme.primaryContainer),
                      const SizedBox(width: 8),
                      Text(
                        'Probar sensor biométrico ahora',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
          ],

          _buildDivider(),

          // 2. Discreet Mode Master Tile
          _buildMasterTile(
            context: context,
            icon: Icons.visibility_off_outlined,
            title: 'Modo Discreto',
            subtitle: security.discreetModeEnabled
                ? 'Activo · Enmascara métricas privadas en pantalla'
                : 'Desactivado · Visualización completa estándar',
            value: security.discreetModeEnabled,
            onChanged: (val) {
              ref.read(securityControllerProvider.notifier).setDiscreetMode(val);
            },
          ),

          // Sub-options when Discreet Mode is Active
          if (security.discreetModeEnabled) ...[
            _buildDivider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Alias discreto de la aplicación',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Nombre visible en cabecera y notificaciones',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                color: AppTheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => _showEditAliasDialog(context, ref, security.discreetAppAlias),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.outlineVariant),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                security.discreetAppAlias,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryContainer,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.edit_rounded, size: 14, color: AppTheme.outline),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.privacy_tip_outlined, size: 16, color: AppTheme.primaryContainer),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'En la pantalla principal, los contadores de NoFap, Ciclo y Finanzas se protegerán con un escudo táctil. Las notificaciones ocultarán detalles explícitos.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              color: AppTheme.outline,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static void _showEditAliasDialog(BuildContext context, WidgetRef ref, String currentAlias) {
    final textController = TextEditingController(text: currentAlias);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Alias Discreto',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppTheme.onSurface,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selecciona o escribe el nombre ficticio con el que se mostrará la app:',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.outline),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: textController,
              autofocus: true,
              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppTheme.onSurface),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppTheme.surfaceContainerHigh,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _aliasChip('Gestor Personal', textController),
                _aliasChip('Calculadora & Notas', textController),
                _aliasChip('Productividad Ejecutiva', textController),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryContainer,
              foregroundColor: AppTheme.onPrimaryContainer,
            ),
            onPressed: () {
              final newAlias = textController.text.trim();
              if (newAlias.isNotEmpty) {
                ref.read(securityControllerProvider.notifier).setDiscreetAppAlias(newAlias);
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  static Widget _aliasChip(String label, TextEditingController controller) {
    return InkWell(
      onTap: () {
        controller.text = label;
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.outlineVariant),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: AppTheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildMasterTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primaryContainer, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppTheme.outline,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: AppTheme.primaryContainer,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSubSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          const SizedBox(width: 6),
          const Icon(Icons.subdirectory_arrow_right_rounded, size: 16, color: AppTheme.outline),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: AppTheme.outline,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: AppTheme.primaryContainer,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppTheme.outlineVariant.withValues(alpha: 0.4),
    );
  }
}
