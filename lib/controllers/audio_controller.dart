import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

final audioControllerProvider =
    StateNotifierProvider<AudioControllerNotifier, AudioControllerState>(
  (ref) => AudioControllerNotifier(),
);

class AudioControllerState {
  final bool isReady;
  final bool isPlaying;
  final String? error;

  AudioControllerState({
    this.isReady = false,
    this.isPlaying = false,
    this.error,
  });

  AudioControllerState copyWith({
    bool? isReady,
    bool? isPlaying,
    String? error,
  }) {
    return AudioControllerState(
      isReady: isReady ?? this.isReady,
      isPlaying: isPlaying ?? this.isPlaying,
      error: error ?? this.error,
    );
  }
}

class AudioControllerNotifier extends StateNotifier<AudioControllerState> {
  late AudioPlayer _audioPlayer;

  AudioControllerNotifier() : super(AudioControllerState()) {
    _audioPlayer = AudioPlayer();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Try to load from Media folder
      await _audioPlayer.setAsset('Media/mouth_sound.mp3');
      state = state.copyWith(isReady: true, error: null);
    } catch (e1) {
      try {
        // Fallback to assets folder
        await _audioPlayer.setAsset('assets/mouth_sound.mp3');
        state = state.copyWith(isReady: true, error: null);
      } catch (e2) {
        state = state.copyWith(
          isReady: false,
          error: 'Failed to load audio: $e2',
        );
      }
    }
  }

  Future<void> playAudio() async {
    if (!state.isReady) return;
    try {
      // Reset to beginning and play
      await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.play();
      state = state.copyWith(isPlaying: true, error: null);
    } catch (e) {
      state = state.copyWith(error: 'Failed to play audio: $e');
    }
  }

  Future<void> stopAudio() async {
    try {
      await _audioPlayer.stop();
      state = state.copyWith(isPlaying: false);
    } catch (e) {
      state = state.copyWith(error: 'Failed to stop audio: $e');
    }
  }

  @override
  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}
