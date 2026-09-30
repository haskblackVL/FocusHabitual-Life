import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/ambient_audio_service.dart';
import '../../data/wellness_repository.dart';
import '../../domain/challenge_data.dart';
import 'wellness_controller.dart';

/// Provider for the single AmbientAudioService instance.
final ambientAudioServiceProvider = Provider<AmbientAudioService>((ref) {
  return AmbientAudioService();
});

/// Stream provider for ambient audio player state.
final ambientPlayerStateProvider = StreamProvider<AmbientPlayerState>((ref) {
  final service = ref.watch(ambientAudioServiceProvider);
  return service.stateStream;
});

/// Currently active challenge tab (meditation, yoga, yoga_facial).
class ActiveChallengeTypeNotifier extends Notifier<ChallengeType> {
  @override
  ChallengeType build() => ChallengeType.meditation;

  void setType(ChallengeType type) {
    state = type;
  }
}

final activeChallengeTypeProvider = NotifierProvider<ActiveChallengeTypeNotifier, ChallengeType>(() {
  return ActiveChallengeTypeNotifier();
});

/// All available ambient sounds from the database.
final ambientSoundsProvider = FutureProvider<List<AmbientSound>>((ref) async {
  final repo = ref.watch(wellnessRepositoryProvider);
  return repo.getAmbientSounds();
});

/// Summary for a specific challenge type.
final challengeSummaryProvider = FutureProvider.family<ChallengeSummary, ChallengeType>((ref, type) async {
  final repo = ref.watch(wellnessRepositoryProvider);
  return repo.getChallengeSummary(type);
});

/// Controller handling user actions on challenges and audio playback.
class ChallengesController extends Notifier<void> {
  @override
  void build() {}

  WellnessRepository get _repo => ref.read(wellnessRepositoryProvider);
  AmbientAudioService get _audio => ref.read(ambientAudioServiceProvider);

  Future<void> completeDay({
    required ChallengeType type,
    required String challengeId,
    required int dayNumber,
  }) async {
    await _repo.completeChallengeDay(
      challengeId: challengeId,
      type: type,
      dayNumber: dayNumber,
    );
    // Invalidate summary for this type
    ref.invalidate(challengeSummaryProvider(type));
  }

  Future<void> resetChallenge(ChallengeType type) async {
    await _repo.resetChallenge(type);
    ref.invalidate(challengeSummaryProvider(type));
  }

  Future<void> playSound(AmbientSound sound) async {
    await _audio.playSound(sound);
  }

  Future<void> togglePlayPause() async {
    await _audio.togglePlayPause();
  }

  Future<void> pauseSound() async {
    await _audio.pause();
  }

  Future<void> stopSound() async {
    await _audio.stop();
  }

  Future<void> setVolume(double volume) async {
    await _audio.setVolume(volume);
  }

  void setTimer(int? minutes) {
    _audio.setTimer(minutes);
  }
}

final challengesControllerProvider = NotifierProvider<ChallengesController, void>(() {
  return ChallengesController();
});
