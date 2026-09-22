import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme.dart';

/// Onboarding screen for new polymath users.
/// Captures name, gender (conditional NoFap/Cycle), and religious preference.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nameController = TextEditingController();
  String _selectedGender = 'male';
  bool _isReligious = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración Inicial'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            Text(
              'Bienvenido a FocusHabitual',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Personaliza tu ecosistema de enfoque y hábitos según tu perfil de vida.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 28),

            // Full Name input
            Text(
              'NOMBRE O ALIAS',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: AppTheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'Ej. Alejandro Santos',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 24),

            // Gender selector
            Text(
              'GÉNERO (DEFINE MÓDULOS DE SALUD Y DISCIPLINA)',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: AppTheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildOptionTile(
                    title: 'Hombre',
                    subtitle: 'Activa NoFap',
                    isSelected: _selectedGender == 'male',
                    onTap: () => setState(() => _selectedGender = 'male'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildOptionTile(
                    title: 'Mujer',
                    subtitle: 'Activa Ciclo',
                    isSelected: _selectedGender == 'female',
                    onTap: () => setState(() => _selectedGender = 'female'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Religious preference toggle
            Text(
              'MÓDULO ESPIRITUAL',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: AppTheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: SwitchListTile(
                title: Text(
                  'Habilitar pasaje bíblico diario',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Reflexión y lectura espiritual diaria integrada.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppTheme.outline,
                  ),
                ),
                value: _isReligious,
                onChanged: (val) => setState(() => _isReligious = val),
              ),
            ),
            const SizedBox(height: 36),

            // Complete button
            ElevatedButton(
              onPressed: () {
                // Navigate to main launcher dashboard
                context.go('/launcher');
              },
              child: const Text('Comenzar Experiencia'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryContainer.withValues(alpha: 0.08)
              : AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.primaryContainer : AppTheme.outlineVariant,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected ? AppTheme.primaryContainer : AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: AppTheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
