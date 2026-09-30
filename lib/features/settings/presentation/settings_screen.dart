import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../../cycle/presentation/widgets/woman_cycle_settings_card.dart';
import 'widgets/notification_settings_card.dart';
import 'widgets/security_settings_card.dart';

/// Settings, Security, and Personalization Screen with live profile & auth control.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileControllerProvider);
    final user = ref.watch(authControllerProvider).value;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Ajustes & Privacidad'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        children: [
          // Profile Card
          _ProfileCard(
            profileAsync: profileAsync,
            userEmail: user?.email,
            onTap: () {
              if (user == null) {
                context.go('/login');
              }
            },
          ),
          const SizedBox(height: 20),

          // Primary Account & Session Section (First Option)
          _buildSectionHeader('SESIÓN & CUENTA'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _buildSettingTile(
                icon: user != null ? Icons.logout_rounded : Icons.login_rounded,
                title: user != null ? 'Cerrar Sesión' : 'Iniciar Sesión',
                subtitle: user != null
                    ? (user.email.isNotEmpty ? user.email : 'Sesión activa')
                    : 'Conecta tu cuenta para sincronizar tus hábitos y progreso',
                titleColor: user != null ? AppTheme.error : AppTheme.primaryContainer,
                trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.outline, size: 20),
                onTap: () async {
                  if (user != null) {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('¿Cerrar Sesión?'),
                        content: const Text('Podrás volver a entrar con tu correo en cualquier momento.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancelar'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Cerrar Sesión'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && context.mounted) {
                      await ref.read(authControllerProvider.notifier).signOut();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    }
                  } else {
                    context.go('/login');
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildSectionHeader('MÓDULOS CONDICIONALES'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _buildSettingTile(
                icon: profileAsync.value?.gender == 'female'
                    ? Icons.female_rounded
                    : Icons.male_rounded,
                title: 'Género Registrado',
                subtitle: profileAsync.value?.gender == 'female'
                    ? 'Mujer · Bloqueado desde registro'
                    : 'Hombre · Bloqueado desde registro',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.outlineVariant),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_outline_rounded, size: 13, color: AppTheme.outline),
                      const SizedBox(width: 5),
                      Text(
                        profileAsync.value?.gender == 'female' ? 'Mujer' : 'Hombre',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                onTap: () {
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
                          const Icon(Icons.lock_rounded, color: AppTheme.primaryContainer, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'El género biológico no puede modificarse tras el registro para preservar la integridad de tus registros y métricas.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                color: AppTheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      duration: const Duration(seconds: 4),
                    ),
                  );
                },
              ),
              _buildDivider(),
              _buildSettingTile(
                icon: Icons.church_outlined,
                title: 'Módulo Espiritual / Religioso',
                subtitle: 'Pasajes y reflexiones diarias',
                trailing: Switch(
                  value: profileAsync.value?.isReligious ?? false,
                  activeThumbColor: AppTheme.primaryContainer,
                  onChanged: (val) {
                    ref.read(userProfileControllerProvider.notifier).updateIsReligious(val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Woman Configuration & Cycle Section (Solo para usuarias de género mujer)
          if (profileAsync.value?.gender == 'female') ...[
            _buildSectionHeader('CONFIGURACIÓN DE LA MUJER (SALUD & CICLOS)'),
            const SizedBox(height: 8),
            const WomanCycleSettingsCard(
              isFemaleUser: true,
            ),
            const SizedBox(height: 20),
          ],

          _buildSectionHeader('SEGURIDAD & PRIVACIDAD'),
          const SizedBox(height: 8),
          const SecuritySettingsCard(),
          const SizedBox(height: 20),

          _buildSectionHeader('NOTIFICACIONES & RECORDATORIOS'),
          const SizedBox(height: 8),
          const NotificationSettingsCard(),
          const SizedBox(height: 20),

          _buildSectionHeader('SISTEMA'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _buildSettingTile(
                icon: Icons.info_outline_rounded,
                title: 'Versión',
                subtitle: 'Versión 1.0',
                trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.outline),
                onTap: () => _showAboutAppDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showAboutAppDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_rounded, color: AppTheme.primaryContainer, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'FocusHabitual Life',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: AppTheme.onSurface,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Versión 1.0',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Diseñado con los más altos estándares de privacidad, seguridad biométrica, rendimiento 100% offline y estética ejecutiva.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppTheme.outline,
                height: 1.45,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Entendido',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        color: AppTheme.outline,
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    Color? titleColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (titleColor ?? AppTheme.primaryContainer).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: titleColor ?? AppTheme.primaryContainer, size: 20),
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
                      fontWeight: FontWeight.w600,
                      color: titleColor ?? AppTheme.onSurface,
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
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, thickness: 1, color: AppTheme.outlineVariant.withValues(alpha: 0.5));
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profileAsync,
    this.userEmail,
    this.onTap,
  });

  final AsyncValue<dynamic> profileAsync;
  final String? userEmail;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final profile = profileAsync.value;
    final name = profile?.fullName ?? 'Usuario FocusHabitual';
    final email = userEmail ?? 'Modo Local / Invitado';
    final isLoggedIn = userEmail != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.primaryContainer.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(
                isLoggedIn ? Icons.person_rounded : Icons.login_rounded,
                color: AppTheme.primaryContainer,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurface,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppTheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isLoggedIn
                    ? AppTheme.surfaceContainerLow
                    : AppTheme.primaryContainer.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isLoggedIn ? AppTheme.outlineVariant : AppTheme.primaryContainer.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                isLoggedIn
                    ? (profile?.gender == 'female' ? 'Mujer' : 'Hombre')
                    : 'Iniciar Sesión',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}
