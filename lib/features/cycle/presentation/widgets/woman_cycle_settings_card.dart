import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme.dart';
import '../../../../core/local_db/database.dart';
import 'woman_cycle_detail_sheet.dart';

/// Interactive Settings & Telemetry Card for the Female Biological Cycle & Wellness module.
class WomanCycleSettingsCard extends StatefulWidget {
  const WomanCycleSettingsCard({
    super.key,
    required this.isFemaleUser,
  });

  final bool isFemaleUser;

  @override
  State<WomanCycleSettingsCard> createState() => _WomanCycleSettingsCardState();
}

class _WomanCycleSettingsCardState extends State<WomanCycleSettingsCard> {
  late int _cycleLength;
  late int _periodLength;
  late bool _polymathSync;
  late bool _notifications;
  late bool _biometricLock;

  @override
  void initState() {
    super.initState();
    _cycleLength = int.tryParse(AppDatabase.getSetting('woman_cycle_length') ?? '28') ?? 28;
    _periodLength = int.tryParse(AppDatabase.getSetting('woman_period_length') ?? '5') ?? 5;
    _polymathSync = (AppDatabase.getSetting('woman_polymath_sync') ?? 'true') == 'true';
    _notifications = (AppDatabase.getSetting('woman_notifications') ?? 'true') == 'true';
    _biometricLock = (AppDatabase.getSetting('woman_biometric_lock') ?? 'true') == 'true';
  }

  void _updateCycleLength(int delta) {
    final next = (_cycleLength + delta).clamp(21, 35);
    if (next != _cycleLength) {
      setState(() => _cycleLength = next);
      AppDatabase.setSetting('woman_cycle_length', next.toString());
    }
  }

  void _updatePeriodLength(int delta) {
    final next = (_periodLength + delta).clamp(3, 10);
    if (next != _periodLength) {
      setState(() => _periodLength = next);
      AppDatabase.setSetting('woman_period_length', next.toString());
    }
  }

  void _togglePolymathSync(bool value) {
    setState(() => _polymathSync = value);
    AppDatabase.setSetting('woman_polymath_sync', value.toString());
  }

  void _toggleNotifications(bool value) {
    setState(() => _notifications = value);
    AppDatabase.setSetting('woman_notifications', value.toString());
  }

  void _toggleBiometricLock(bool value) {
    setState(() => _biometricLock = value);
    AppDatabase.setSetting('woman_biometric_lock', value.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineVariant),
      ),
      child: Column(
        children: [
          // Banner Status (Active Module)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.secondary.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.secondary.withValues(alpha: 0.15),
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.spa_rounded,
                  size: 18,
                  color: AppTheme.secondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'MÓDULO ACTIVO · RITMO BIOLÓGICO FEMENINO',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppTheme.secondary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'SINCRONIZADO',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 1. Cycle Length Stepper Tile
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.cached_rounded, color: AppTheme.secondary, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Duración del Ciclo',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Intervalo promedio (21 - 35 días)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppTheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStepper(
                  valueText: '$_cycleLength d',
                  onDecrement: () => _updateCycleLength(-1),
                  onIncrement: () => _updateCycleLength(1),
                ),
              ],
            ),
          ),
          _buildDivider(),

          // 2. Period Duration Stepper Tile
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.water_drop_outlined, color: AppTheme.secondary, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Duración de Menstruación',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Días de sangrado activo (3 - 10 días)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppTheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStepper(
                  valueText: '$_periodLength d',
                  onDecrement: () => _updatePeriodLength(-1),
                  onIncrement: () => _updatePeriodLength(1),
                ),
              ],
            ),
          ),
          _buildDivider(),

          // 3. Current Phase Status & Cognitive Peak Preview
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryContainer.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.psychology_outlined, color: AppTheme.primaryContainer, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fase Neuroquímica Actual',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.onSurface,
                              ),
                            ),
                            Text(
                              'Fase Folicular (Día 11 de $_cycleLength)',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: AppTheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.secondary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'PICO CREATIVO',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Mini 3-bar metric overview
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildMiniBar('Claridad Cognitiva', '92%', 0.92, AppTheme.primaryContainer),
                      const SizedBox(height: 6),
                      _buildMiniBar('Energía Física', '88%', 0.88, AppTheme.secondary),
                      const SizedBox(height: 6),
                      _buildMiniBar('Estabilidad & Calma', '85%', 0.85, AppTheme.secondaryContainer),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildDivider(),

          // 4. Polymath Task Synchronization Switch
          _buildSwitchTile(
            icon: Icons.sync_alt_rounded,
            title: 'Sincronización de Enfoque',
            subtitle: 'Calibrar tareas complejas con ventanas de máximo foco hormonal',
            value: _polymathSync,
            onChanged: _togglePolymathSync,
          ),
          _buildDivider(),

          // 5. Phase Notifications Switch
          _buildSwitchTile(
            icon: Icons.notifications_active_outlined,
            title: 'Predicciones & Alertas Discretas',
            subtitle: 'Notificar transiciones de fase y ventana fértil',
            value: _notifications,
            onChanged: _toggleNotifications,
          ),
          _buildDivider(),

          // 6. Biometric Encryption
          _buildSwitchTile(
            icon: Icons.lock_outline_rounded,
            title: 'Cifrado Biométrico de Ciclo',
            subtitle: 'Exigir autenticación para ver notas e historial del ciclo',
            value: _biometricLock,
            onChanged: _toggleBiometricLock,
          ),
          _buildDivider(),

          // 7. Visualizer Action Button
          InkWell(
            onTap: () => WomanCycleDetailSheet.show(
              context,
              cycleLength: _cycleLength,
              periodLength: _periodLength,
              currentDay: 11,
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.remove_red_eye_outlined, color: AppTheme.primaryContainer, size: 18),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Visualizar Dial Biológico y Bienestar Completo',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryContainer,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_rounded, color: AppTheme.primaryContainer, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepper({
    required String valueText,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onDecrement,
            icon: const Icon(Icons.remove, size: 16),
            color: AppTheme.onSurfaceVariant,
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              valueText,
              style: AppTheme.numeric(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurface,
              ),
            ),
          ),
          IconButton(
            onPressed: onIncrement,
            icon: const Icon(Icons.add, size: 16),
            color: AppTheme.onSurfaceVariant,
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBar(String label, String value, double progress, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.surfaceContainerHigh,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 32,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTheme.numeric(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer.withValues(alpha: 0.08),
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
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
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
    return Divider(height: 1, thickness: 1, color: AppTheme.outlineVariant.withValues(alpha: 0.5));
  }
}
