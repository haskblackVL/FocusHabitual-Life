import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme.dart';
import '../controllers/challenges_controller.dart';

/// Modal bottom sheet for controlling ambient natural soundscapes.
class AmbientSoundPlayerSheet extends ConsumerWidget {
  const AmbientSoundPlayerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AmbientSoundPlayerSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final soundsAsync = ref.watch(ambientSoundsProvider);
    final playerStateAsync = ref.watch(ambientPlayerStateProvider);
    final playerState = playerStateAsync.value ?? ref.read(ambientAudioServiceProvider).currentState;
    final controller = ref.read(challengesControllerProvider.notifier);

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppTheme.surfaceContainerHigh, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.nature_people_rounded, color: AppTheme.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sonidos Naturales de Inmersión',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.onSurface,
                          ),
                        ),
                        Text(
                          'MEDITACIÓN · ENFOQUE · DESCOMPRESIÓN',
                          style: AppTheme.labelCaps(
                            color: AppTheme.primary,
                            letterSpacing: 0.08,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (playerState.isPlaying)
                    IconButton(
                      icon: const Icon(Icons.stop_circle_outlined, color: AppTheme.error),
                      tooltip: 'Detener audio',
                      onPressed: () => controller.stopSound(),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Volume & Timer Row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.surfaceContainerHigh, width: 1),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.volume_down_rounded, size: 18, color: AppTheme.onSurfaceVariant),
                        Expanded(
                          child: Slider(
                            value: playerState.volume,
                            min: 0.0,
                            max: 1.0,
                            activeColor: AppTheme.primary,
                            inactiveColor: AppTheme.surfaceContainerHigh,
                            onChanged: (val) => controller.setVolume(val),
                          ),
                        ),
                        const Icon(Icons.volume_up_rounded, size: 18, color: AppTheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          '${(playerState.volume * 100).toInt()}%',
                          style: AppTheme.numeric(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 12, color: AppTheme.surfaceContainerHigh),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.timer_outlined, size: 16, color: AppTheme.onSurfaceVariant),
                            const SizedBox(width: 6),
                            Text(
                              playerState.timerRemainingMinutes != null
                                  ? 'Temporizador: ${playerState.timerRemainingMinutes} min restantes'
                                  : 'Temporizador de apagado:',
                              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                        PopupMenuButton<int?>(
                          initialValue: playerState.timerDurationMinutes,
                          tooltip: 'Seleccionar tiempo',
                          onSelected: (mins) => controller.setTimer(mins),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.surfaceContainerHigh),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  playerState.timerDurationMinutes != null
                                      ? '${playerState.timerDurationMinutes} min'
                                      : 'Continuo',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primary,
                                  ),
                                ),
                                const Icon(Icons.arrow_drop_down, size: 16, color: AppTheme.primary),
                              ],
                            ),
                          ),
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: null, child: Text('Continuo (Sin apagado)')),
                            const PopupMenuItem(value: 5, child: Text('5 minutos')),
                            const PopupMenuItem(value: 10, child: Text('10 minutos')),
                            const PopupMenuItem(value: 15, child: Text('15 minutos')),
                            const PopupMenuItem(value: 20, child: Text('20 minutos')),
                            const PopupMenuItem(value: 30, child: Text('30 minutos')),
                            const PopupMenuItem(value: 60, child: Text('60 minutos')),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'BIBLIOTECA DE PAISAJES SONOROS',
                style: AppTheme.labelCaps(
                  color: AppTheme.onSurfaceVariant,
                  letterSpacing: 0.08,
                ),
              ),
              const SizedBox(height: 10),

              // Sounds list
              soundsAsync.when(
                data: (sounds) {
                  if (sounds.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Cargando sonidos de naturaleza...', style: TextStyle(color: AppTheme.onSurfaceVariant)),
                    );
                  }

                  return ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: sounds.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final sound = sounds[index];
                        final isCurrentSound = playerState.currentSound?.id == sound.id;
                        final isPlayingThis = isCurrentSound && playerState.isPlaying;

                        return Material(
                          color: isCurrentSound
                              ? AppTheme.primary.withValues(alpha: 0.09)
                              : AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              if (isCurrentSound) {
                                controller.togglePlayPause();
                              } else {
                                controller.playSound(sound);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isCurrentSound ? AppTheme.primary : AppTheme.surfaceContainerHigh,
                                  width: isCurrentSound ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isPlayingThis
                                          ? AppTheme.primary
                                          : AppTheme.surfaceContainerHigh,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isPlayingThis
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      color: isPlayingThis ? Colors.black : AppTheme.onSurface,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          sound.name,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: isCurrentSound ? AppTheme.primary : AppTheme.onSurface,
                                          ),
                                        ),
                                        Text(
                                          isPlayingThis
                                              ? '● Reproduciendo en bucle continuo'
                                              : 'Ambiente natural relajante',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: isPlayingThis ? AppTheme.primary : AppTheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isPlayingThis)
                                    const Icon(Icons.graphic_eq_rounded, color: AppTheme.primary, size: 20),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Text('Error al cargar sonidos: $err', style: const TextStyle(color: AppTheme.error)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
