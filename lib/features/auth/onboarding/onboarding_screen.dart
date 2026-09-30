import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme.dart';
import '../../../app/widgets/brand_logo.dart';
import '../presentation/controllers/auth_controller.dart';

/// Onboarding screen presented after account creation.
/// Captures profile essentials: Name/Alias, Gender, and Spiritual Module.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nameController = TextEditingController();
  String _selectedGender = 'male';
  bool _isReligious = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Prefill name if available from registered user or cached profile
    final profile = ref.read(userProfileControllerProvider).value;
    final currentUser = ref.read(authControllerProvider).value;

    final initialName = profile?.fullName ??
        (currentUser?.userMetadata?['full_name'] as String? ?? '');
    if (initialName.isNotEmpty) {
      _nameController.text = initialName;
    }
    if (profile?.gender != null) {
      _selectedGender = profile!.gender;
    }
    if (profile?.isReligious != null) {
      _isReligious = profile!.isReligious;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleComplete() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(userProfileControllerProvider.notifier).completeOnboarding(
            fullName: _nameController.text.trim(),
            gender: _selectedGender,
            isReligious: _isReligious,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Perfil configurado con éxito!'),
          backgroundColor: AppTheme.accentEmerald,
        ),
      );
      context.go('/launcher');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar configuración: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const FocusHabitualLogo(size: 26),
            const SizedBox(width: 8),
            Text(
              'FocusHabitual',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: AppTheme.onSurface,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            // Welcome Header
            Text(
              'Personaliza tu Perfil',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Configura tus preferencias iniciales para adaptar tus hábitos y experiencia diaria.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 28),

            // 1. Full Name or Alias Input
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

            // 2. Gender selector (clean buttons without 'Activa NoFap' / 'Activa Ciclo')
            Text(
              'GÉNERO',
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
                  child: _buildGenderTile(
                    title: 'Hombre',
                    icon: Icons.male_rounded,
                    isSelected: _selectedGender == 'male',
                    onTap: () => setState(() => _selectedGender = 'male'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildGenderTile(
                    title: 'Mujer',
                    icon: Icons.female_rounded,
                    isSelected: _selectedGender == 'female',
                    onTap: () => setState(() => _selectedGender = 'female'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 3. Spiritual Module toggle
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

            // 4. Submit & Continue Button
            ElevatedButton(
              onPressed: _isLoading ? null : _handleComplete,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Comenzar Experiencia'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderTile({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryContainer : AppTheme.outline,
              size: 24,
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isSelected ? AppTheme.primaryContainer : AppTheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
