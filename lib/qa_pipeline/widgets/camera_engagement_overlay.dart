import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:camera/camera.dart';
import '../../core/services/ai_integration_service.dart';
import '../../core/services/ai_voice_service.dart';
import '../../core/services/media_capture_service.dart';
import '../../core/services/web_audio_helper.dart';
import '../../core/state/child_state.dart';

/// Real-time OpenCV Camera Engagement HUD Overlay & Child Monitoring Alerts.
/// Mounts on Q&A sessions, videos, and games to track:
///   - Person presence & face detection
///   - Eye gaze alignment (looking at screen)
///   - Lip & mouth movement + continuous mouth-open duration
///   - Head pose orientation (Yaw/Pitch/Roll)
///   - Facial expressions (Happy, Attentive, Looking Away, Open Mouth)
///   - Non-blocking child-friendly on-screen attention alerts
class CameraEngagementOverlay extends StatefulWidget {
  final Widget child;
  final String activityId;
  final bool isPronunciationScreen;

  const CameraEngagementOverlay({
    super.key,
    required this.child,
    this.activityId = 'netaji_qa_session',
    this.isPronunciationScreen = false,
  });

  @override
  State<CameraEngagementOverlay> createState() => _CameraEngagementOverlayState();
}

class _CameraEngagementOverlayState extends State<CameraEngagementOverlay> {
  Timer? _analysisTimer;
  bool _isAnalyzing = false;

  // Real-time OpenCV metrics returned by Python FastAPI (/analyze/engagement)
  bool _faceDetected = false;
  bool _personDetected = false;
  bool _lookingAtScreen = false;
  bool _mouthMovement = false;
  bool _mouthOpen = false;
  int _engagementScore = 0;
  String _facialExpression = 'NEUTRAL';
  String _headOrientation = 'FRONTAL';

  // Temporal Alert Timers (Debounced)
  double _lookingAwaySeconds = 0.0;
  double _mouthOpenSeconds = 0.0;
  bool _showLookingAwayAlert = false;
  bool _showMouthOpenAlert = false;

  // Track if voice prompts have been spoken for current alert state
  bool _hasSpokenLookingAwayPrompt = false;
  bool _hasSpokenMouthOpenPrompt = false;

  bool _isMinimized = false;

  @override
  void initState() {
    super.initState();
    _initializeCameraAndTracking();
  }

  Future<void> _initializeCameraAndTracking() async {
    // Re-initialize on web route transitions so a fresh, live HtmlElementView is bound
    await MediaCaptureService.instance.ensureCameraReady(forceReinit: kIsWeb);
    if (!mounted) return;
    setState(() {});
    _startPeriodicFrameAnalysis();
  }

  @override
  void dispose() {
    _analysisTimer?.cancel();
    super.dispose();
  }

  void _startPeriodicFrameAnalysis() {
    _analysisTimer?.cancel();
    // Run camera frame analysis every 1500ms for stable non-blocking performance
    _analysisTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      if (mounted) {
        _captureAndAnalyzeFrame();
      }
    });
    // Run first frame capture after 1 second
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _captureAndAnalyzeFrame();
      }
    });
  }

  Future<void> _captureAndAnalyzeFrame() async {
    if (_isAnalyzing) return;
    if (mounted) setState(() => _isAnalyzing = true);

    final childId = ChildState.instance.currentProfile.id;
    final sessionId = ChildState.instance.currentSessionId ?? 'SES_NETAJI_001';

    // Capture real JPEG frame payload from camera
    final jpegBytes = await MediaCaptureService.instance.captureFrameBytes();
    if (jpegBytes == null || jpegBytes.isEmpty) {
      if (kIsWeb) {
        _applyLocalWebDetectionFallback();
      }
      if (mounted) setState(() => _isAnalyzing = false);
      return;
    }

    try {
      final res = await AiIntegrationService.instance.analyzeEngagement(
        imageBytes: jpegBytes,
        childId: childId,
        sessionId: sessionId,
        activityId: widget.activityId,
      );

      if (res['success'] == true && res['aiEvent'] != null) {
        final data = res['aiEvent']['data'] as Map<String, dynamic>;
        final faceDetected = data['faceDetected'] == true;
        final lookingAtScreen = data['lookingAtScreen'] == true;
        final mouthMovement = data['mouthMovement'] == true;
        final engagementScore = (data['engagementScore'] as num?)?.toInt() ?? 0;
        final personDetected = data['personDetected'] == true || faceDetected;
        final mouthOpen = data['mouthOpen'] == true;
        final facialExpression = (data['facialExpression'] as String?) ?? (lookingAtScreen ? 'ATTENTIVE' : 'LOOKING_AWAY');
        final headOrientation = (data['headOrientation'] as String?) ?? 'FRONTAL';

        // 1. Temporal Looking-Away Accumulator (Debounced over 5-10 seconds)
        if (!faceDetected || !lookingAtScreen) {
          _lookingAwaySeconds += 1.5;
        } else {
          _lookingAwaySeconds = 0.0; // Auto-reset as soon as child looks back
          _hasSpokenLookingAwayPrompt = false;
        }

        // 2. Temporal Mouth-Open Accumulator (STRICTLY ON PRONUNCIATION SCREEN ONLY)
        if (widget.isPronunciationScreen && mouthOpen) {
          _mouthOpenSeconds += 1.5;
        } else {
          _mouthOpenSeconds = 0.0; // Auto-reset or keep 0 when not on pronunciation page
          _hasSpokenMouthOpenPrompt = false;
        }

        final showLookingAwayAlert = _lookingAwaySeconds >= 6.0;
        final showMouthOpenAlert = widget.isPronunciationScreen && _mouthOpenSeconds >= 4.5 && !showLookingAwayAlert;

        // Trigger ElevenLabs AI Voice Prompts on newly active alerts
        if (showLookingAwayAlert && !_hasSpokenLookingAwayPrompt) {
          _hasSpokenLookingAwayPrompt = true;
          AiVoiceService.instance.playLookingAwayAlert();
        } else if (showMouthOpenAlert && !_hasSpokenMouthOpenPrompt) {
          _hasSpokenMouthOpenPrompt = true;
          AiVoiceService.instance.playMouthOpenListeningPrompt();
        }

        if (mounted) {
          setState(() {
            _faceDetected = faceDetected;
            _personDetected = personDetected;
            _lookingAtScreen = lookingAtScreen;
            _mouthMovement = mouthMovement;
            _mouthOpen = mouthOpen;
            _engagementScore = engagementScore;
            _facialExpression = facialExpression;
            _headOrientation = headOrientation;
            _showLookingAwayAlert = showLookingAwayAlert;
            _showMouthOpenAlert = showMouthOpenAlert;
            _isAnalyzing = false;
          });
        }
      } else if (kIsWeb) {
        _applyLocalWebDetectionFallback();
        if (mounted) setState(() => _isAnalyzing = false);
      } else {
        if (mounted) {
          setState(() => _isAnalyzing = false);
        }
      }
    } catch (e) {
      if (kIsWeb) {
        _applyLocalWebDetectionFallback();
      }
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  void _applyLocalWebDetectionFallback() {
    try {
      final jsonStr = WebAudioHelper.detectFaceLocal();
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final map = json.decode(jsonStr) as Map<String, dynamic>;
        final faceDetected = map['faceDetected'] == true;
        if (mounted) {
          setState(() {
            _faceDetected = faceDetected;
            _personDetected = faceDetected;
            _lookingAtScreen = faceDetected;
            _engagementScore = faceDetected ? 85 : 0;
            _facialExpression = faceDetected ? 'ATTENTIVE' : 'NO_FACE';
            _headOrientation = faceDetected ? 'FRONTAL' : 'UNKNOWN';
          });
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main Screen Content
        widget.child,

        // Top Floating Child-Friendly On-Screen Attention Alert Banner
        if (_showLookingAwayAlert || _showMouthOpenAlert)
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: SafeArea(
              child: Material(
                color: Colors.transparent,
                child: Center(
                  child: _buildChildAlertBanner(),
                ),
              ),
            ),
          ),

        // Floating OpenCV Camera Engagement HUD Overlay (Top-Right)
        Positioned(
          top: 14,
          right: 14,
          child: SafeArea(
            child: Material(
              color: Colors.transparent,
              child: _buildHud(),
            ),
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // CHILD-FRIENDLY ON-SCREEN ALERT BANNER
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildChildAlertBanner() {
    final isLookingAway = _showLookingAwayAlert;
    final message = isLookingAway
        ? "Hey! Look back at the screen 👀"
        : "Yes! I'm listening, speak out loud! 🎙️";
    final bgGradient = isLookingAway
        ? const LinearGradient(colors: [Color(0xFFFEF2F2), Color(0xFFFEE2E2)])
        : const LinearGradient(colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)]);
    final borderColor = isLookingAway ? const Color(0xFFEF4444) : const Color(0xFF16A34A);
    final textColor = isLookingAway ? const Color(0xFF991B1B) : const Color(0xFF166534);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        gradient: bgGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 2.0),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: Icon(
              isLookingAway ? Icons.visibility_rounded : Icons.mic_rounded,
              size: 20,
              color: borderColor,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            message,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // HUD OVERLAY WIDGET
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildHud() {
    final hudBorderColor = _showLookingAwayAlert
        ? const Color(0xFFEF4444)
        : (_showMouthOpenAlert ? const Color(0xFFF59E0B) : const Color(0xFFD4AF37));

    if (_isMinimized) {
      return GestureDetector(
        onTap: () => setState(() => _isMinimized = false),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xDD1E100A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: hudBorderColor, width: 1.8),
            boxShadow: [
              BoxShadow(
                color: hudBorderColor.withValues(alpha: _showLookingAwayAlert ? 0.6 : 0.2),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _showLookingAwayAlert
                      ? const Color(0xFFEF4444)
                      : (_faceDetected ? const Color(0xFF3FB950) : const Color(0xFFFF9800)),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.videocam, color: hudBorderColor, size: 14),
              const SizedBox(width: 4),
              Text(
                'AI CAM $_engagementScore%',
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final camController = MediaCaptureService.instance.cameraController;
    final isCamReady = camController != null && camController.value.isInitialized;

    return Container(
      width: 190,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xEE1E100A), // Sepia Dark Glass
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: hudBorderColor, width: _showLookingAwayAlert ? 2.5 : 1.8),
        boxShadow: [
          BoxShadow(
            color: hudBorderColor.withValues(alpha: _showLookingAwayAlert ? 0.60 : 0.25),
            blurRadius: _showLookingAwayAlert ? 16 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _showLookingAwayAlert
                          ? const Color(0xFFEF4444)
                          : (_faceDetected ? const Color(0xFF3FB950) : const Color(0xFFFF9800)),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'OPENCV CAM',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: hudBorderColor,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => setState(() => _isMinimized = true),
                child: const Icon(Icons.close_rounded, color: Colors.white70, size: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Live Camera Preview / Viewfinder Box
          Container(
            height: 85,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _showLookingAwayAlert
                    ? const Color(0xFFEF4444)
                    : (_faceDetected
                        ? const Color(0xFF7EE787)
                        : (_isAnalyzing ? const Color(0xFFFFD700) : Colors.redAccent)),
                width: 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Stack(
                fit: StackFit.expand,
                alignment: Alignment.center,
                children: [
                  // Live Camera Stream Feed
                  if (isCamReady)
                    Center(
                      child: AspectRatio(
                        aspectRatio: camController.value.aspectRatio > 0
                            ? camController.value.aspectRatio
                            : (4.0 / 3.0),
                        child: CameraPreview(camController),
                      ),
                    )
                  else
                    const Center(
                      child: Text(
                        'AI CAM READYING...',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 9,
                          color: Color(0xFFD4AF37),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                  // Viewfinder Grid Overlay
                  CustomPaint(
                    size: const Size(double.infinity, 85),
                    painter: _CameraGridPainter(),
                  ),

                  // Bottom Gaze / Face Status Indicator Overlay
                  Positioned(
                    bottom: 4,
                    left: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _faceDetected ? Icons.face_retouching_natural : Icons.face,
                            color: _faceDetected
                                ? (_lookingAtScreen ? const Color(0xFF7EE787) : Colors.orangeAccent)
                                : Colors.white38,
                            size: 11,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              _faceDetected
                                  ? (_lookingAtScreen ? 'Gaze Locked' : 'Looking Away')
                                  : 'Searching Face...',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 8.5,
                                color: _faceDetected
                                    ? (_lookingAtScreen ? const Color(0xFF7EE787) : Colors.orangeAccent)
                                    : Colors.white70,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Top Right Live Scanning Indicator
                  if (_isAnalyzing)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: const Color(0xFFFFD700),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Live Metrics List
          _buildMetricBadge(
            icon: Icons.person_outline_rounded,
            label: 'Person / Face',
            status: _faceDetected ? 'Detected' : (_personDetected ? 'Person Only' : 'None'),
            isActive: _faceDetected,
          ),
          const SizedBox(height: 4),
          _buildMetricBadge(
            icon: Icons.remove_red_eye_outlined,
            label: 'Screen Gaze',
            status: _faceDetected
                ? (_lookingAtScreen ? 'Centered ($_engagementScore%)' : 'Away (${_lookingAwaySeconds.toStringAsFixed(0)}s)')
                : 'No Face',
            isActive: _faceDetected && _lookingAtScreen,
          ),
          const SizedBox(height: 4),
          _buildMetricBadge(
            icon: Icons.record_voice_over,
            label: 'Mouth / Lip',
            status: _faceDetected
                ? (_mouthOpen ? 'Open (${_mouthOpenSeconds.toStringAsFixed(0)}s)' : (_mouthMovement ? 'Moving' : 'Closed'))
                : 'No Face',
            isActive: _faceDetected && (_mouthMovement || _mouthOpen),
          ),
          const SizedBox(height: 4),
          _buildMetricBadge(
            icon: Icons.screen_rotation_rounded,
            label: 'Head Pose',
            status: _faceDetected ? _headOrientation : 'No Face',
            isActive: _faceDetected && _headOrientation == 'FRONTAL',
          ),
          const SizedBox(height: 4),
          _buildMetricBadge(
            icon: Icons.mood_rounded,
            label: 'Expression',
            status: _faceDetected ? _facialExpression : 'No Face',
            isActive: _faceDetected && (_facialExpression == 'HAPPY' || _facialExpression == 'ATTENTIVE'),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBadge({
    required IconData icon,
    required String label,
    required String status,
    required bool isActive,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: isActive ? const Color(0xFFFFD700) : Colors.white38),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 10,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        Text(
          status,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isActive ? const Color(0xFF7EE787) : Colors.white38,
          ),
        ),
      ],
    );
  }
}

class _CameraGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x337EE787)
      ..strokeWidth = 1.0;

    // Center Crosshair
    final cx = size.width / 2;
    final cy = size.height / 2;
    canvas.drawLine(Offset(cx - 10, cy), Offset(cx + 10, cy), paint);
    canvas.drawLine(Offset(cx, cy - 10), Offset(cx, cy + 10), paint);

    // Corner brackets
    final bracketPaint = Paint()
      ..color = const Color(0xAA7EE787)
      ..strokeWidth = 1.5;

    canvas.drawLine(const Offset(4, 4), const Offset(12, 4), bracketPaint);
    canvas.drawLine(const Offset(4, 4), const Offset(4, 12), bracketPaint);

    canvas.drawLine(Offset(size.width - 4, 4), Offset(size.width - 12, 4), bracketPaint);
    canvas.drawLine(Offset(size.width - 4, 4), Offset(size.width - 4, 12), bracketPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
