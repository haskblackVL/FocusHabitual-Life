import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme.dart';

/// Settings, Security, and Personalization Screen.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Ajustes & Privacidad'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        children: [
          // Profile Card
          _ProfileCard(),
          const SizedBox(height: 20),

          _buildSectionHeader('SEGURIDAD & PRIVACIDAD'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _buildSettingTile(
                icon: Icons.fingerprint_rounded,
                title: 'Bloqueo biométrico',
                subtitle: 'Exigir Face ID o huella dactilar',
                trailing: Switch(
                  value: false,
                  onChanged: (val) {},
                  activeThumbColor: AppTheme.primaryContainer,
                ),
              ),
              _buildDivider(),
              _buildSettingTile(
                icon: Icons.visibility_off_outlined,
                title: 'Modo discreto',
                subtitle: 'Ocultar detalles en notificaciones',
                trailing: Switch(
                  value: false,
                  onChanged: (val) {},
                  activeThumbColor: AppTheme.primaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildSectionHeader('MÓDULOS CONDICIONALES'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _buildSettingTile(
                icon: Icons.church_outlined,
                title: 'Módulo Espiritual / Religioso',
                subtitle: 'Pasajes y reflexiones diarias',
                trailing: Icon(Icons.chevron_right_rounded, color: AppTheme.outline, size: 20),
              ),
              _buildDivider(),
              _buildSettingTile(
                icon: Icons.shield_outlined,
                title: 'Módulo de Disciplina (NoFap)',
                subtitle: 'Configuración y razones de enfoque',
                trailing: Icon(Icons.chevron_right_rounded, color: AppTheme.outline, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildSectionHeader('SISTEMA'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _buildSettingTile(
                icon: Icons.file_download_outlined,
                title: 'Exportar mis datos',
                subtitle: 'Generar descarga en formato JSON',
                trailing: Icon(Icons.chevron_right_rounded, color: AppTheme.outline, size: 20),
              ),
              _buildDivider(),
              _buildSettingTile(
                icon: Icons.info_outline_rounded,
                title: 'Versión',
                subtitle: 'FocusHabitual Life 1.0.0 (Fase 0)',
                trailing: const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTheme.labelCaps(color: AppTheme.outline),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 52,
      color: AppTheme.outlineVariant,
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.outlineVariant),
        ),
        child: Icon(icon, color: AppTheme.onSurfaceVariant, size: 18),
      ),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          color: AppTheme.outline,
        ),
      ),
      trailing: trailing,
    );
  }
}

class _ProfileCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
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
            child: const Icon(
              Icons.person_outline_rounded,
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
                  'Usuario Polímata',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurface,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Perfil Corporativo • Plan Gratuito',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppTheme.outline,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.outlineVariant),
            ),
            child: Text(
              'Editar',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

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
