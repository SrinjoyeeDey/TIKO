import 'web_audio_helper_stub.dart'
    if (dart.library.js_interop) 'web_audio_helper_web.dart';

abstract class WebAudioHelper {
  static Future<bool> startWebRecording() => startWebRecordingImpl();
  static Future<Map<String, dynamic>?> stopWebRecording() => stopWebRecordingImpl();
  static String? captureWebFrame() => captureWebFrameImpl();
}
