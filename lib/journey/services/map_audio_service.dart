import 'package:flutter/foundation.dart';

/// Audio controller service supporting parchment rustle, map reveal sounds, and mute toggle.
class MapAudioService {
  static final MapAudioService _instance = MapAudioService._internal();
  factory MapAudioService() => _instance;
  MapAudioService._internal();

  bool isMuted = false;

  void toggleMute() {
    isMuted = !isMuted;
    if (kDebugMode) {
      print('MapAudioService: Muted status set to $isMuted');
    }
  }

  void playPaperUnfold() {
    if (isMuted) return;
    // Audio hook for paper rustle sound
    if (kDebugMode) {
      print('Audio: Playing paper unfold sound...');
    }
  }

  void playDestinationReveal() {
    if (isMuted) return;
    // Audio hook for destination discovery chime
    if (kDebugMode) {
      print('Audio: Playing destination reveal chime...');
    }
  }

  void playProceedClick() {
    if (isMuted) return;
    // Audio hook for proceed button tap
    if (kDebugMode) {
      print('Audio: Playing proceed tap sound...');
    }
  }
}
