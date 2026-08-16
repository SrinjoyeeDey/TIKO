import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'web_audio_helper.dart';

class MediaCaptureService {
  MediaCaptureService._privateConstructor();
  static final MediaCaptureService instance = MediaCaptureService._privateConstructor();

  CameraController? _cameraController;
  final AudioRecorder _audioRecorder = AudioRecorder();

  bool _isCameraInitialized = false;
  bool _isAudioInitialized = false;

  final List<int> _recordedAudioChunks = [];
  StreamSubscription<List<int>>? _audioStreamSub;

  bool get isCameraInitialized => _isCameraInitialized;
  bool get isRecordingAudio => _isAudioInitialized;
  CameraController? get cameraController => _cameraController;

  /// Request required permissions
  Future<bool> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    final cameraGranted = statuses[Permission.camera]?.isGranted ?? true;
    final micGranted = statuses[Permission.microphone]?.isGranted ?? true;
    return cameraGranted && micGranted;
  }

  Future<bool>? _initCameraFuture;

  /// Ensure camera is ready and properly attached for the current screen
  Future<bool> ensureCameraReady({bool forceReinit = false}) async {
    if (kIsWeb) {
      try {
        await WebAudioHelper.ensureWebCameraReady();
      } catch (e) {
        debugPrint('MediaCaptureService: WebAudioHelper ensureWebCameraReady note: $e');
      }
    }

    if (!forceReinit && _cameraController != null) {
      try {
        if (_cameraController!.value.isInitialized) {
          _isCameraInitialized = true;
          return true;
        }
      } catch (e) {
        debugPrint('MediaCaptureService: Cached controller check error: $e');
      }
    }

    if (_initCameraFuture != null) {
      return await _initCameraFuture!;
    }

    _initCameraFuture = initCamera();
    try {
      final res = await _initCameraFuture!;
      return res;
    } finally {
      _initCameraFuture = null;
    }
  }

  /// Initialize front camera safely across Web and Native
  Future<bool> initCamera() async {
    try {
      if (kIsWeb) {
        await WebAudioHelper.ensureWebCameraReady();
      }

      final hasPermissions = await requestPermissions();
      if (!hasPermissions && !kIsWeb) {
        debugPrint('MediaCaptureService: Camera permissions denied');
        return false;
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        debugPrint('MediaCaptureService: No available cameras found on system');
        // On web, direct getUserMedia in WebAudioHelper may still work even if camera_web fails to enumerate
        if (kIsWeb) {
          _isCameraInitialized = true;
          return true;
        }
        return false;
      }

      CameraDescription selectedCam = cameras.first;
      for (final cam in cameras) {
        if (cam.lensDirection == CameraLensDirection.front) {
          selectedCam = cam;
          break;
        }
      }

      try {
        await _cameraController?.dispose();
      } catch (_) {}
      _cameraController = null;
      _isCameraInitialized = false;

      final controller = CameraController(
        selectedCam,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      _cameraController = controller;
      await controller.initialize();
      _isCameraInitialized = true;
      debugPrint('MediaCaptureService: Camera successfully initialized (${selectedCam.name})');
      return true;
    } catch (e) {
      debugPrint('MediaCaptureService: Failed to init camera: $e');
      if (kIsWeb) {
        _isCameraInitialized = true;
        return true;
      }
      _isCameraInitialized = false;
      return false;
    }
  }

  bool _isCapturing = false;

  /// Capture JPEG frame bytes from camera with concurrency protection
  Future<List<int>?> captureFrameBytes() async {
    if (_isCapturing) return null;
    _isCapturing = true;

    try {
      if (kIsWeb) {
        // Fast offscreen canvas snapshot from live HTML5 webcam stream without freezing video
        var base64Frame = WebAudioHelper.captureWebFrame();
        if (base64Frame == null || base64Frame.isEmpty) {
          await WebAudioHelper.ensureWebCameraReady();
          base64Frame = WebAudioHelper.captureWebFrame();
        }
        if (base64Frame != null && base64Frame.isNotEmpty) {
          return base64.decode(base64Frame);
        }
      }

      if (!_isCameraInitialized || _cameraController == null) {
        final ready = await ensureCameraReady();
        if (!ready || _cameraController == null) return null;
      }

      if (_cameraController!.value.isTakingPicture) {
        return null;
      }

      final XFile picture = await _cameraController!.takePicture();
      final bytes = await picture.readAsBytes();
      return bytes;
    } catch (e) {
      debugPrint('MediaCaptureService: Frame capture note: $e');
      return null;
    } finally {
      _isCapturing = false;
    }
  }

  /// Dispose camera resources safely
  Future<void> disposeCamera() async {
    try {
      if (_cameraController != null) {
        await _cameraController!.dispose();
        _cameraController = null;
      }
      _isCameraInitialized = false;
    } catch (e) {
      debugPrint('MediaCaptureService: Error disposing camera: $e');
    }
  }

  /// Start audio recording to memory stream or temporary file/blob
  Future<bool> startAudioRecording() async {
    try {
      if (kIsWeb) {
        // Direct browser MediaRecorder & Web Speech API bridge
        final started = await WebAudioHelper.startWebRecording();
        if (started) {
          _isAudioInitialized = true;
          debugPrint('MediaCaptureService: WebAudioHelper recording started');
          return true;
        }
      }

      final bool hasMic = await _audioRecorder.hasPermission();
      if (!hasMic && !kIsWeb) {
        debugPrint('MediaCaptureService: Mic permission not granted');
        return false;
      }

      _recordedAudioChunks.clear();
      await _audioStreamSub?.cancel();
      _audioStreamSub = null;

      // Native platforms (Windows/Android/iOS):
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/speech_${DateTime.now().millisecondsSinceEpoch}.wav';
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: path,
      );
      _isAudioInitialized = true;
      debugPrint('MediaCaptureService: Native audio recording started at $path');
      return true;
    } catch (e) {
      debugPrint('MediaCaptureService: Failed to start audio recording: $e');
      return false;
    }
  }

  /// Stop recording and return audio bytes + transcript
  Future<Map<String, dynamic>?> stopAudioRecordingAndGetResult() async {
    if (!_isAudioInitialized) return null;

    try {
      if (kIsWeb) {
        final res = await WebAudioHelper.stopWebRecording();
        _isAudioInitialized = false;
        if (res != null) {
          return res;
        }
      }

      final String? pathOrUrl = await _audioRecorder.stop();
      await _audioStreamSub?.cancel();
      _audioStreamSub = null;
      _isAudioInitialized = false;

      List<int> bytes = [];
      if (pathOrUrl != null && pathOrUrl.isNotEmpty) {
        if (kIsWeb || pathOrUrl.startsWith('blob:') || pathOrUrl.startsWith('http')) {
          final res = await http.get(Uri.parse(pathOrUrl));
          bytes = res.bodyBytes;
        } else {
          final file = File(pathOrUrl);
          if (await file.exists()) {
            bytes = await file.readAsBytes();
            try {
              await file.delete();
            } catch (_) {}
          }
        }
      } else if (_recordedAudioChunks.isNotEmpty) {
        final pcm = List<int>.from(_recordedAudioChunks);
        _recordedAudioChunks.clear();
        bytes = _addWavHeader(pcm, 16000, 1);
      }

      return {
        'bytes': bytes,
        'transcript': '',
      };
    } catch (e) {
      debugPrint('MediaCaptureService: Failed to stop audio recording: $e');
      _isAudioInitialized = false;
      return null;
    }
  }

  /// Stop recording and return valid audio bytes (WAV/WebM/Opus)
  Future<List<int>?> stopAudioRecordingAndGetBytes() async {
    final res = await stopAudioRecordingAndGetResult();
    if (res != null && res['bytes'] != null) {
      return res['bytes'] as List<int>;
    }
    return null;
  }

  /// Wraps raw 16-bit PCM samples in a standard 44-byte RIFF/WAVE header
  List<int> _addWavHeader(List<int> pcmBytes, int sampleRate, int numChannels) {
    if (pcmBytes.length >= 4) {
      final headerStr = String.fromCharCodes(pcmBytes.sublist(0, 4));
      if (headerStr == 'RIFF' || pcmBytes[0] == 0x1A) {
        return pcmBytes;
      }
    }

    final byteRate = sampleRate * numChannels * 2;
    final blockAlign = numChannels * 2;
    final totalDataLen = pcmBytes.length;
    final totalAudioLen = totalDataLen + 36;

    final header = Uint8List(44);
    final view = ByteData.sublistView(header);

    // "RIFF"
    header.setRange(0, 4, [0x52, 0x49, 0x46, 0x46]);
    view.setUint32(4, totalAudioLen, Endian.little);
    // "WAVE"
    header.setRange(8, 12, [0x57, 0x41, 0x56, 0x45]);
    // "fmt "
    header.setRange(12, 16, [0x66, 0x6D, 0x74, 0x20]);
    view.setUint32(16, 16, Endian.little); // Subchunk1Size (16 for PCM)
    view.setUint16(20, 1, Endian.little);  // AudioFormat (1 for PCM)
    view.setUint16(22, numChannels, Endian.little);
    view.setUint32(24, sampleRate, Endian.little);
    view.setUint32(28, byteRate, Endian.little);
    view.setUint16(32, blockAlign, Endian.little);
    view.setUint16(34, 16, Endian.little); // BitsPerSample (16-bit)
    // "data"
    header.setRange(36, 40, [0x64, 0x61, 0x74, 0x61]);
    view.setUint32(40, totalDataLen, Endian.little);

    return [...header, ...pcmBytes];
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _cameraController?.dispose();
    await _audioRecorder.dispose();
    _isCameraInitialized = false;
    _isAudioInitialized = false;
  }
}
