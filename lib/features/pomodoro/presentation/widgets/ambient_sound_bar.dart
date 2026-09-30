import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme.dart';
import '../../../wellness/domain/challenge_catalog.dart';
import '../controllers/ambient_sound_controller.dart';

/// Ambient Sound Controller Deck with natural soundscapes.
class AmbientSoundBar extends ConsumerWidget {
  const AmbientSoundBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final soundState = ref.watch(pomodoroAmbientProvider);
    final notifier = ref.read(pomodoroAmbientProvider.notifier);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: soundState.isPlaying
              ? AppTheme.primary.withValues(alpha: 0.4)
              : AppTheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Sound icon with animated pulse indicator if playing
          GestureDetector(
            onTap: () => _openSoundSelector(context, ref),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: soundState.isPlaying
                    ? AppTheme.primary.withValues(alpha: 0.15)
                    : AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: soundState.isPlaying
                      ? AppTheme.primary
                      : AppTheme.outlineVariant,
                ),
              ),
              child: Icon(
                _getSoundIcon(soundState.selectedSound.id),
                color: soundState.isPlaying ? AppTheme.primary : AppTheme.onSurfaceVariant,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Track name and tap to change
          Expanded(
            child: GestureDetector(
              onTap: () => _openSoundSelector(context, ref),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          soundState.selectedSound.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (soundState.isPlaying)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'EN BUCLE',
                            style: AppTheme.labelCaps(
                              fontSize: 9,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Sonido natural para enfoque • Tocar para cambiar',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppTheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),

          // Volume Button / Slider Popup
          IconButton(
            onPressed: () => _showVolumeSheet(context, ref),
            icon: Icon(
              soundState.volume == 0
                  ? Icons.volume_off_rounded
                  : (soundState.volume < 0.5 ? Icons.volume_down_rounded : Icons.volume_up_rounded),
              size: 20,
              color: AppTheme.onSurfaceVariant,
            ),
            tooltip: 'Volumen',
          ),

          // Play / Pause Toggle Button
          IconButton.filled(
            onPressed: notifier.togglePlayback,
            icon: Icon(
              soundState.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 20,
            ),
            style: IconButton.styleFrom(
              backgroundColor: soundState.isPlaying ? AppTheme.primary : AppTheme.surfaceContainerLowest,
              foregroundColor: soundState.isPlaying ? Colors.white : AppTheme.primary,
              side: BorderSide(
                color: soundState.isPlaying ? Colors.transparent : AppTheme.outlineVariant,
              ),
            ),
            tooltip: soundState.isPlaying ? 'Pausar sonido' : 'Reproducir sonido',
          ),
        ],
      ),
    );
  }

  void _openSoundSelector(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final currentSound = ref.watch(pomodoroAmbientProvider).selectedSound;
            final notifier = ref.read(pomodoroAmbientProvider.notifier);

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sonidos Naturales de Enfoque',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.onSurface,
                          ),
                        ),
                        Text(
                          '7 PAISAJES',
                          style: AppTheme.labelCaps(
                            fontSize: 10,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: ChallengeCatalog.allSounds.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final sound = ChallengeCatalog.allSounds[index];
                          final isSelected = currentSound.id == sound.id;

                          return ListTile(
                            dense: true,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isSelected ? AppTheme.primary : AppTheme.outlineVariant.withValues(alpha: 0.3),
                              ),
                            ),
                            tileColor: isSelected
                                ? AppTheme.primary.withValues(alpha: 0.08)
                                : AppTheme.surfaceContainerLow,
                            leading: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isSelected ? AppTheme.primary : AppTheme.surfaceContainerLowest,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getSoundIcon(sound.id),
                                color: isSelected ? Colors.white : AppTheme.onSurfaceVariant,
                                size: 18,
                              ),
                            ),
                            title: Text(
                              sound.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? AppTheme.primary : AppTheme.onSurface,
                              ),
                            ),
                            subtitle: Text(
                              _getSoundDescription(sound.id),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: AppTheme.onSurfaceVariant,
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 20)
                                : null,
                            onTap: () {
                              notifier.selectSound(sound);
                              Navigator.pop(ctx);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showVolumeSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final soundState = ref.watch(pomodoroAmbientProvider);
            final notifier = ref.read(pomodoroAmbientProvider.notifier);

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Volumen del Paisaje Sonoro',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.volume_down_rounded, color: AppTheme.onSurfaceVariant),
                        Expanded(
                          child: Slider(
                            value: soundState.volume,
                            min: 0.0,
                            max: 1.0,
                            activeColor: AppTheme.primary,
                            inactiveColor: AppTheme.surfaceContainerHigh,
                            onChanged: (val) => notifier.setVolume(val),
                          ),
                        ),
                        const Icon(Icons.volume_up_rounded, color: AppTheme.onSurfaceVariant),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      dense: true,
                      title: Text(
                        'Autoiniciar sonido al iniciar el cronómetro',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      value: soundState.autoPlayOnFocus,
                      activeThumbColor: AppTheme.primary,
                      onChanged: (val) => notifier.toggleAutoPlay(val),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static IconData _getSoundIcon(String id) {
    if (id.contains('rain')) return Icons.thunderstorm_rounded;
    if (id.contains('ocean')) return Icons.waves_rounded;
    if (id.contains('birds')) return Icons.flutter_dash_rounded;
    if (id.contains('wind')) return Icons.air_rounded;
    if (id.contains('river')) return Icons.water_rounded;
    if (id.contains('nature')) return Icons.eco_rounded;
    return Icons.forest_rounded;
  }

  static String _getSoundDescription(String id) {
    if (id.contains('rain')) return 'Gotas rítmicas con truenos lejanos';
    if (id.contains('ocean')) return 'Marea oceánica continua y relajante';
    if (id.contains('birds')) return 'Canto matutino y brisa de montaña';
    if (id.contains('wind')) return 'Viento suave entre el follaje espeso';
    if (id.contains('river')) return 'Corriente constante de agua pura';
    if (id.contains('nature')) return 'Inmersión acústica orgánica total';
    return 'Atmósfera tranquila de bosque templado';
  }
}
