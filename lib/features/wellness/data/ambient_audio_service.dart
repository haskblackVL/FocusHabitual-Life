import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../domain/challenge_data.dart';

/// State of the ambient audio player.
class AmbientPlayerState {
  final AmbientSound? currentSound;
  final bool isPlaying;
  final bool isLoading;
  final double volume;
  final int? timerRemainingMinutes;
  final int? timerDurationMinutes;

  const AmbientPlayerState({
    this.currentSound,
    this.isPlaying = false,
    this.isLoading = false,
    this.volume = 0.8,
    this.timerRemainingMinutes,
    this.timerDurationMinutes,
  });

  AmbientPlayerState copyWith({
    AmbientSound? currentSound,
    bool? isPlaying,
    bool? isLoading,
    double? volume,
    int? timerRemainingMinutes,
    int? timerDurationMinutes,
    bool clearTimer = false,
    bool clearSound = false,
  }) {
    return AmbientPlayerState(
      currentSound: clearSound ? null : (currentSound ?? this.currentSound),
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      volume: volume ?? this.volume,
      timerRemainingMinutes: clearTimer ? null : (timerRemainingMinutes ?? this.timerRemainingMinutes),
      timerDurationMinutes: clearTimer ? null : (timerDurationMinutes ?? this.timerDurationMinutes),
    );
  }
}

/// Service managing natural soundscapes with looping and session timers.
class AmbientAudioService {
  static final AmbientAudioService _instance = AmbientAudioService._internal();
  factory AmbientAudioService() => _instance;

  AmbientAudioService._internal() {
    _init();
  }

  AudioPlayer? _player;
  Timer? _sessionTimer;
  final _stateController = StreamController<AmbientPlayerState>.broadcast();
  AmbientPlayerState _state = const AmbientPlayerState();

  Stream<AmbientPlayerState> get stateStream => _stateController.stream;
  AmbientPlayerState get currentState => _state;

  void _init() {
    try {
      _player = AudioPlayer();
      _player!.playerStateStream.listen((playerState) {
        final isPlaying = playerState.playing && playerState.processingState != ProcessingState.completed;
        final isLoading = playerState.processingState == ProcessingState.loading ||
            playerState.processingState == ProcessingState.buffering;
        _updateState(_state.copyWith(isPlaying: isPlaying, isLoading: isLoading));
      });
      _player!.setLoopMode(LoopMode.one);
      _player!.setVolume(_state.volume);
    } catch (e) {
      if (kDebugMode) print('[AmbientAudioService] Failed to init player: $e');
    }
  }

  void _updateState(AmbientPlayerState newState) {
    _state = newState;
    _stateController.add(_state);
  }

  /// Plays a specific ambient sound asset.
  Future<void> playSound(AmbientSound sound) async {
    try {
      if (_player == null) _init();
      if (_player == null) return;

      _updateState(_state.copyWith(currentSound: sound, isLoading: true));

      // Load asset
      await _player!.setAsset(sound.audioUrl);
      await _player!.setLoopMode(LoopMode.one);
      await _player!.setVolume(_state.volume);
      await _player!.play();

      _updateState(_state.copyWith(
        currentSound: sound,
        isPlaying: true,
        isLoading: false,
      ));
    } catch (e) {
      if (kDebugMode) print('[AmbientAudioService] Error playing sound: $e');
      _updateState(_state.copyWith(isLoading: false));
    }
  }

  /// Toggles between play and pause.
  Future<void> togglePlayPause() async {
    if (_player == null) return;
    try {
      if (_player!.playing) {
        await _player!.pause();
        _updateState(_state.copyWith(isPlaying: false));
      } else {
        if (_state.currentSound != null) {
          await _player!.play();
          _updateState(_state.copyWith(isPlaying: true));
        }
      }
    } catch (e) {
      if (kDebugMode) print('[AmbientAudioService] Error toggling play/pause: $e');
    }
  }

  /// Pauses playback.
  Future<void> pause() async {
    if (_player == null) return;
    try {
      await _player!.pause();
      _updateState(_state.copyWith(isPlaying: false));
    } catch (e) {
      if (kDebugMode) print('[AmbientAudioService] Error pausing: $e');
    }
  }

  /// Stops playback and clears session timer.
  Future<void> stop() async {
    _sessionTimer?.cancel();
    _sessionTimer = null;
    if (_player == null) return;
    try {
      await _player!.stop();
      _updateState(_state.copyWith(isPlaying: false, clearTimer: true));
    } catch (e) {
      if (kDebugMode) print('[AmbientAudioService] Error stopping: $e');
    }
  }

  /// Sets master volume between 0.0 and 1.0.
  Future<void> setVolume(double volume) async {
    final clamped = volume.clamp(0.0, 1.0);
    _updateState(_state.copyWith(volume: clamped));
    if (_player != null) {
      try {
        await _player!.setVolume(clamped);
      } catch (e) {
        if (kDebugMode) print('[AmbientAudioService] Error setting volume: $e');
      }
    }
  }

  /// Configures a countdown timer in minutes after which audio stops automatically.
  void setTimer(int? minutes) {
    _sessionTimer?.cancel();
    _sessionTimer = null;

    if (minutes == null || minutes <= 0) {
      _updateState(_state.copyWith(clearTimer: true));
      return;
    }

    _updateState(_state.copyWith(
      timerDurationMinutes: minutes,
      timerRemainingMinutes: minutes,
    ));

    _sessionTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      final remaining = (_state.timerRemainingMinutes ?? 0) - 1;
      if (remaining <= 0) {
        stop();
      } else {
        _updateState(_state.copyWith(timerRemainingMinutes: remaining));
      }
    });
  }

  void dispose() {
    _sessionTimer?.cancel();
    _player?.dispose();
    _stateController.close();
  }
}
