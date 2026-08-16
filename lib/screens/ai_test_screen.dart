import 'package:flutter/material.dart';
import '../core/services/ai_integration_service.dart';
import '../core/services/media_capture_service.dart';
import '../core/state/child_state.dart';

/// Standalone Development-Only AI Integration Test Screen.
/// Used to verify Python AI Service health, camera/mic status, and end-to-end event delivery.
class AiTestScreen extends StatefulWidget {
  const AiTestScreen({super.key});

  @override
  State<AiTestScreen> createState() => _AiTestScreenState();
}

class _AiTestScreenState extends State<AiTestScreen> {
  bool _speechModelConnected = false;
  bool _visionModelConnected = false;
  final bool _cameraAvailable = true;
  final bool _micAvailable = true;

  bool _isTestingSpeech = false;
  bool _isTestingVision = false;

  Map<String, dynamic>? _lastAiData;
  String _lastEventType = 'NONE';
  bool _eventSentToBackend = false;
  String _statusMessage = 'Ready to test AI services.';

  @override
  void initState() {
    super.initState();
    _refreshHealth();
  }

  Future<void> _refreshHealth() async {
    setState(() {
      _statusMessage = 'Checking Python AI Service on port 8001...';
    });

    final res = await AiIntegrationService.instance.checkHealth();

    setState(() {
      if (res['status'] == 'online') {
        _speechModelConnected = true;
        _visionModelConnected = true;
        _statusMessage = 'Python AI Service connected on port 8001!';
      } else {
        _speechModelConnected = false;
        _visionModelConnected = false;
        _statusMessage = 'AI Service Offline (Start with start_ai_service.bat)';
      }
    });
  }

  Future<void> _runSpeechTest() async {
    setState(() {
      _isTestingSpeech = true;
      _statusMessage = 'Running speech analysis test...';
    });

    final childId = ChildState.instance.currentProfile.id;
    final sessionId = ChildState.instance.currentSessionId ?? 'SES_001';

    // Capture 3 seconds of real audio
    final started = await MediaCaptureService.instance.startAudioRecording();
    if (!started) {
      setState(() {
        _isTestingSpeech = false;
        _statusMessage = 'Speech test error: Microphone access denied or failed.';
      });
      return;
    }

    setState(() {
      _statusMessage = 'Recording audio for 3 seconds...';
    });

    await Future.delayed(const Duration(seconds: 3));

    final wavBytes = await MediaCaptureService.instance.stopAudioRecordingAndGetBytes();
    
    if (wavBytes == null || wavBytes.isEmpty) {
      setState(() {
        _isTestingSpeech = false;
        _statusMessage = 'Speech test error: Failed to capture audio bytes.';
      });
      return;
    }

    setState(() {
      _statusMessage = 'Sending audio to backend...';
    });

    final res = await AiIntegrationService.instance.analyzeSpeech(
      audioBytes: wavBytes,
      childId: childId,
      sessionId: sessionId,
      activityId: 'netaji_q01',
      targetPhrase: 'Subhas Chandra Bose',
    );

    setState(() {
      _isTestingSpeech = false;
      if (res['success'] == true && res['aiEvent'] != null) {
        final aiEvent = res['aiEvent'] as Map<String, dynamic>;
        _lastEventType = (aiEvent['eventType'] ?? 'SPEECH_ANALYSIS').toString();
        _lastAiData = Map<String, dynamic>.from(aiEvent['data'] as Map);
        _eventSentToBackend = res['forwardedToBackend'] == true;
        _statusMessage = 'Speech analysis test completed successfully!';
      } else {
        _statusMessage = 'Speech test error: ${res['error']}';
      }
    });
  }

  Future<void> _runCameraTest() async {
    setState(() {
      _isTestingVision = true;
      _statusMessage = 'Running camera engagement test...';
    });

    final childId = ChildState.instance.currentProfile.id;
    final sessionId = ChildState.instance.currentSessionId ?? 'SES_001';

    // Capture real JPEG frame payload from camera
    final jpegBytes = await MediaCaptureService.instance.captureFrameBytes();
    if (jpegBytes == null || jpegBytes.isEmpty) {
      setState(() {
        _isTestingVision = false;
        _statusMessage = 'Vision test error: Camera access denied or failed.';
      });
      return;
    }

    final res = await AiIntegrationService.instance.analyzeEngagement(
      imageBytes: jpegBytes,
      childId: childId,
      sessionId: sessionId,
      activityId: 'netaji_q01',
    );

    setState(() {
      _isTestingVision = false;
      if (res['success'] == true && res['aiEvent'] != null) {
        final aiEvent = res['aiEvent'] as Map<String, dynamic>;
        _lastEventType = (aiEvent['eventType'] ?? 'ENGAGEMENT_ANALYSIS').toString();
        _lastAiData = Map<String, dynamic>.from(aiEvent['data'] as Map);
        _eventSentToBackend = res['forwardedToBackend'] == true;
        _statusMessage = 'Vision engagement test completed successfully!';
      } else {
        _statusMessage = 'Vision test error: ${res['error']}';
      }
    });
  }

  void _stopTest() {
    setState(() {
      _isTestingSpeech = false;
      _isTestingVision = false;
      _statusMessage = 'Test stopped.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF161B22),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        title: const Text(
          '🤖 NIMO AI Microservice Test Dashboard',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshHealth,
            tooltip: 'Check Health',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            _buildStatusCard(),
            const SizedBox(height: 20),

            // Controls Card
            _buildControlsCard(),
            const SizedBox(height: 20),

            // Live Metrics Card
            _buildLiveMetricsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF21262D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI SERVICE STATUS',
            style: TextStyle(
              color: Color(0xFF58A6FF),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatusBadge('Speech Model', _speechModelConnected)),
              Expanded(child: _buildStatusBadge('Vision Model', _visionModelConnected)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatusBadge('Camera', _cameraAvailable)),
              Expanded(child: _buildStatusBadge('Microphone', _micAvailable)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _statusMessage,
            style: TextStyle(
              fontSize: 13,
              color: _speechModelConnected ? const Color(0xFF7EE787) : const Color(0xFFFFA657),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String title, bool isConnected) {
    return Row(
      children: [
        Icon(
          Icons.circle,
          size: 10,
          color: isConnected ? const Color(0xFF3FB950) : const Color(0xFFF85149),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$title: ${isConnected ? "Connected" : "Offline"}',
            style: const TextStyle(fontSize: 13, color: Colors.white70),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildControlsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF21262D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TEST CONTROLS',
            style: TextStyle(
              color: Color(0xFF58A6FF),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF238636),
                  foregroundColor: Colors.white,
                ),
                onPressed: _isTestingSpeech ? null : _runSpeechTest,
                icon: const Icon(Icons.mic, size: 18),
                label: Text(_isTestingSpeech ? 'Testing Speech...' : 'Start Speech Test'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F6FEB),
                  foregroundColor: Colors.white,
                ),
                onPressed: _isTestingVision ? null : _runCameraTest,
                icon: const Icon(Icons.videocam, size: 18),
                label: Text(_isTestingVision ? 'Testing Vision...' : 'Start Camera Test'),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFF85149),
                  side: const BorderSide(color: Color(0xFFF85149)),
                ),
                onPressed: _stopTest,
                icon: const Icon(Icons.stop, size: 18),
                label: const Text('Stop Test'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiveMetricsCard() {
    final d = _lastAiData ?? {};
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF21262D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'LIVE AI OBSERVATION RESULTS',
            style: TextStyle(
              color: Color(0xFF58A6FF),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),

          _buildMetricRow('Transcript', d['transcript']?.toString() ?? 'N/A'),
          _buildMetricRow('Speech Detected', d['speechDetected'] == true ? 'YES' : 'NO'),
          _buildMetricRow('Speech Attempt', d['speechAttempt'] == true ? 'YES' : 'NO'),
          _buildMetricRow('Pronunciation Score', '${d['pronunciationScore'] ?? 0}%'),
          _buildMetricRow('Response Time', '${d['responseTime'] ?? 0.0} sec'),
          _buildMetricRow('Confidence', '${((d['confidence'] ?? 0.0) * 100).toStringAsFixed(0)}%'),
          const Divider(color: Color(0xFF30363D), height: 24),

          _buildMetricRow('Face Detected', d['faceDetected'] == true ? 'YES' : 'NO'),
          _buildMetricRow('Looking at Screen', d['lookingAtScreen'] == true ? 'YES' : 'NO'),
          _buildMetricRow('Mouth Movement', d['mouthMovement'] == true ? 'YES' : 'NO'),
          _buildMetricRow('Engagement Score', '${d['engagementScore'] ?? 0}%'),
          const Divider(color: Color(0xFF30363D), height: 24),

          _buildMetricRow('Last Event Type', _lastEventType),
          _buildMetricRow('Event Sent to NIMO Backend', _eventSentToBackend ? 'YES (201 Created)' : 'NO'),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFFFF8E1),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
