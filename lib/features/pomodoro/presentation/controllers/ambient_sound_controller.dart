import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../wellness/data/ambient_audio_service.dart';
import '../../../wellness/domain/challenge_catalog.dart';
import '../../../wellness/domain/challenge_data.dart';

class PomodoroAmbientState {
  const PomodoroAmbientState({
    required this.selectedSound,
    required this.isPlaying,
    required this.autoPlayOnFocus,
    required this.volume,
  });

  final AmbientSound selectedSound;
  final bool isPlaying;
  final bool autoPlayOnFocus;
  final double volume;

  PomodoroAmbientState copyWith({
    AmbientSound? selectedSound,
    bool? isPlaying,
    bool? autoPlayOnFocus,
    double? volume,
  }) {
    return PomodoroAmbientState(
      selectedSound: selectedSound ?? this.selectedSound,
      isPlaying: isPlaying ?? this.isPlaying,
      autoPlayOnFocus: autoPlayOnFocus ?? this.autoPlayOnFocus,
      volume: volume ?? this.volume,
    );
  }
}

final pomodoroAmbientProvider =
    NotifierProvider<PomodoroAmbientNotifier, PomodoroAmbientState>(
  PomodoroAmbientNotifier.new,
);

class PomodoroAmbientNotifier extends Notifier<PomodoroAmbientState> {
  late final AmbientAudioService _audioService;
  StreamSubscription<AmbientPlayerState>? _sub;

  @override
  PomodoroAmbientState build() {
    _audioService = AmbientAudioService();
    final defaultSound = ChallengeCatalog.allSounds.firstWhere(
      (s) => s.id == 'sound-rain-thunder',
      orElse: () => ChallengeCatalog.allSounds.first,
    );

    ref.onDispose(() {
      _sub?.cancel();
    });

    _sub = _audioService.stateStream.listen((playerState) {
      if (state.isPlaying != playerState.isPlaying) {
        state = state.copyWith(isPlaying: playerState.isPlaying);
      }
    });

    return PomodoroAmbientState(
      selectedSound: defaultSound,
      isPlaying: _audioService.currentState.isPlaying,
      autoPlayOnFocus: true,
      volume: _audioService.currentState.volume,
    );
  }

  /// Sets the active nature soundscape track.
  Future<void> selectSound(AmbientSound sound) async {
    state = state.copyWith(selectedSound: sound);
    if (state.isPlaying) {
      await _audioService.playSound(sound);
    }
  }

  /// Toggles playback of the current sound.
  Future<void> togglePlayback() async {
    if (state.isPlaying) {
      await _audioService.pause();
      state = state.copyWith(isPlaying: false);
    } else {
      await _audioService.playSound(state.selectedSound);
      state = state.copyWith(isPlaying: true);
    }
  }

  /// Starts playback if auto-play is enabled.
  Future<void> playIfAutoEnabled() async {
    if (state.autoPlayOnFocus && !state.isPlaying) {
      await _audioService.playSound(state.selectedSound);
      state = state.copyWith(isPlaying: true);
    }
  }

  /// Pauses ambient playback.
  Future<void> pause() async {
    if (state.isPlaying) {
      await _audioService.pause();
      state = state.copyWith(isPlaying: false);
    }
  }

  /// Adjusts master volume.
  Future<void> setVolume(double volume) async {
    final clamped = volume.clamp(0.0, 1.0);
    state = state.copyWith(volume: clamped);
    await _audioService.setVolume(clamped);
  }

  /// Toggles auto-play on focus timer start.
  void toggleAutoPlay(bool value) {
    state = state.copyWith(autoPlayOnFocus: value);
  }
}
