import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:camera/camera.dart';
import '../../core/services/ai_integration_service.dart';
import '../../core/services/media_capture_service.dart';
import '../../core/state/child_state.dart';

/// Real-time OpenCV Camera Engagement HUD Overlay.
/// Mounts on the Q&A session and video screens to track:
///   - Face presence
///   - Eye gaze alignment (looking at screen)
///   - Lip & mouth movement (OpenCV Laplacian variance)
///   - Engagement score (0-100%)
class CameraEngagementOverlay extends StatefulWidget {
  final Widget child;
  final String activityId;

  const CameraEngagementOverlay({
    super.key,
    required this.child,
    this.activityId = 'netaji_qa_session',
  });

  @override
  State<CameraEngagementOverlay> createState() => _CameraEngagementOverlayState();
}

class _CameraEngagementOverlayState extends State<CameraEngagementOverlay> {
  Timer? _analysisTimer;
  bool _isAnalyzing = false;

  // Real-time OpenCV metrics returned by Python FastAPI (/analyze/engagement)
  bool _faceDetected = false;
  bool _lookingAtScreen = false;
  bool _mouthMovement = false;
  int _engagementScore = 0;

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
        if (mounted) {
          setState(() {
            _faceDetected = data['faceDetected'] == true;
            _lookingAtScreen = data['lookingAtScreen'] == true;
            _mouthMovement = data['mouthMovement'] == true;
            _engagementScore = (data['engagementScore'] as num?)?.toInt() ?? 0;
            _isAnalyzing = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isAnalyzing = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main Screen Content
        widget.child,

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

  Widget _buildHud() {
    if (_isMinimized) {
      return GestureDetector(
        onTap: () => setState(() => _isMinimized = false),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xDD1E100A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 6)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF3FB950),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.videocam, color: Color(0xFFFFD700), size: 14),
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
      width: 185,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xEE1E100A), // Sepia Dark Glass
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4AF37), width: 1.8),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4)),
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
                      color: _faceDetected ? const Color(0xFF3FB950) : const Color(0xFFFF9800),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'OPENCV CAM',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFD4AF37),
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
                color: _faceDetected
                    ? const Color(0xFF7EE787)
                    : (_isAnalyzing ? const Color(0xFFFFD700) : Colors.redAccent),
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
            icon: Icons.remove_red_eye_outlined,
            label: 'Screen Gaze',
            status: _faceDetected
                ? (_lookingAtScreen ? 'Centered ($_engagementScore%)' : 'Away ($_engagementScore%)')
                : 'No Face (0%)',
            isActive: _faceDetected && _lookingAtScreen,
          ),
          const SizedBox(height: 4),
          _buildMetricBadge(
            icon: Icons.record_voice_over,
            label: 'Lip Movement',
            status: _mouthMovement ? 'Detected' : 'Idle',
            isActive: _mouthMovement,
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
