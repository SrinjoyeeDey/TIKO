import 'package:flutter/foundation.dart';
import 'web_audio_helper_stub.dart'
    if (dart.library.js_interop) 'web_audio_helper_web.dart';

abstract class WebAudioHelper {
  static Future<bool> startWebRecording() => startWebRecordingImpl();
  static Future<Map<String, dynamic>?> stopWebRecording() => stopWebRecordingImpl();
  static String? captureWebFrame() => captureWebFrameImpl();
  static Future<bool> ensureWebCameraReady() => ensureWebCameraReadyImpl();
  static void speakText(String text, VoidCallback onEnded) => speakWebTextImpl(text, onEnded);
  static void cancelSpeech() => cancelWebSpeechImpl();
  static void playAudioSource(String src, VoidCallback onEnded) => playWebAudioSourceImpl(src, onEnded);
}

