import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/services/ai_integration_service.dart';
import '../../core/services/media_capture_service.dart';
import '../../core/state/child_state.dart';
import '../models/speech_question.dart';

/// Renders a Speech Recognition question with 3D Vintage Speech Bubble styling,
/// active microphone recording button, real-time voice pulse animation,
/// real-time Google Speech Recognition & pronunciation scoring from Python FastAPI (/analyze/speech).
class SpeechQuestionWidget extends StatefulWidget {
  final SpeechQuestion question;
  final int questionNumber;
  final ValueChanged<bool> onAnswered;
  final void Function(bool isCorrect, int score, String transcript)? onAnsweredDetailed;

  const SpeechQuestionWidget({
    super.key,
    required this.question,
    required this.questionNumber,
    required this.onAnswered,
    this.onAnsweredDetailed,
    this.onPandaReaction,
  });

  final ValueChanged<bool>? onPandaReaction;

  @override
  State<SpeechQuestionWidget> createState() => _SpeechQuestionWidgetState();
}

class _SpeechQuestionWidgetState extends State<SpeechQuestionWidget>
    with SingleTickerProviderStateMixin {
  bool _isRecording = false;
  bool _isAnalyzing = false;
  bool _evaluated = false;

  int _pronunciationScore = 0;
  String _recognizedTranscript = '';
  bool _speechDetected = false;
  bool _passed = false;
  String _statusText = 'Tap the microphone button & read the sentence out loud!';

  late AnimationController _pulseController;
  Timer? _recordingTimer;
  int _secondsRecorded = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_isAnalyzing) return;

    if (_isRecording) {
      await _stopAndAnalyze();
      return;
    }

    setState(() {
      _statusText = '🎙️ Accessing microphone...';
    });

    final started = await MediaCaptureService.instance.startAudioRecording();
    if (!mounted) return;

    if (!started) {
      setState(() {
        _isRecording = false;
        _isAnalyzing = false;
        _statusText = 'Microphone access denied or unavailable.';
      });
      return;
    }

    setState(() {
      _isRecording = true;
      _evaluated = false;
      _secondsRecorded = 0;
      _statusText = '🎙️ Listening... Speak the highlighted phrase!';
    });
    _pulseController.repeat(reverse: true);

    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _secondsRecorded++;
      });
      // Auto-stop after 8 seconds
      if (_secondsRecorded >= 8) {
        _stopAndAnalyze();
      }
    });
  }

  Future<void> _stopAndAnalyze() async {
    _recordingTimer?.cancel();
    _pulseController.stop();

    if (mounted) {
      setState(() {
        _isRecording = false;
        _isAnalyzing = true;
        _statusText = 'Recognizing speech with Google AI Engine...';
      });
    }

    final childId = ChildState.instance.currentProfile.id;
    final sessionId = ChildState.instance.currentSessionId ?? 'SES_NETAJI_001';

    // Stop recording and retrieve audio bytes and browser transcript
    final audioRes = await MediaCaptureService.instance.stopAudioRecordingAndGetResult();
    final wavBytes = audioRes != null && audioRes['bytes'] != null ? (audioRes['bytes'] as List<int>) : <int>[];
    final clientTranscript = audioRes != null ? (audioRes['transcript'] as String? ?? '').trim() : '';

    if (wavBytes.isEmpty && clientTranscript.isEmpty) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _evaluated = true;
          _pronunciationScore = 0;
          _recognizedTranscript = '(No audio captured)';
          _speechDetected = false;
          _passed = false;
          _statusText = 'No audio captured. Tap mic to try again.';
        });
      }
      return;
    }

    try {
      Map<String, dynamic> res = {};
      if (wavBytes.isNotEmpty) {
        res = await AiIntegrationService.instance.analyzeSpeech(
          audioBytes: wavBytes,
          childId: childId,
          sessionId: sessionId,
          activityId: 'netaji_speech_${widget.question.id}',
          targetPhrase: widget.question.targetPhrase,
        );
      }

      int score = 0;
      String transcript = '';
      bool detected = false;

      if (res['success'] == true && res['aiEvent'] != null) {
        final data = res['aiEvent']['data'] as Map<String, dynamic>;
        score = (data['pronunciationScore'] as num?)?.toInt() ?? 0;
        final rawTranscript = data['transcript'] as String?;
        transcript = (rawTranscript != null && rawTranscript.trim().isNotEmpty)
            ? rawTranscript.trim()
            : '';
        detected = data['speechDetected'] == true;
      }

      // If backend returned 0/empty but browser Web Speech API heard speech, use client transcript
      if (transcript.isEmpty && clientTranscript.isNotEmpty) {
        transcript = clientTranscript;
        detected = true;
        score = _calculateLocalScore(clientTranscript, widget.question.targetPhrase);
      } else if (score == 0 && clientTranscript.isNotEmpty) {
        final localScore = _calculateLocalScore(clientTranscript, widget.question.targetPhrase);
        if (localScore > score) {
          score = localScore;
          if (transcript.isEmpty) transcript = clientTranscript;
        }
      }

      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _evaluated = true;
          _pronunciationScore = score;
          _recognizedTranscript = transcript.isNotEmpty ? transcript : '(No words recognized)';
          _speechDetected = detected;
          final passed = score >= widget.question.minScoreThreshold;
          _passed = passed;

          if (score >= 80) {
            _statusText = '🎉 Outstanding! Clear and accurate pronunciation!';
          } else if (score >= 50) {
            _statusText = '👍 Good effort! Spoke most words correctly.';
          } else if (detected) {
            _statusText = '👂 Speech heard, but words differed. Try speaking clearly.';
          } else {
            _statusText = '🔇 No clear speech heard. Speak a little louder and closer to mic.';
          }

          widget.onPandaReaction?.call(passed);
        });
      }
    } catch (e) {
      if (clientTranscript.isNotEmpty && mounted) {
        final score = _calculateLocalScore(clientTranscript, widget.question.targetPhrase);
        setState(() {
          _isAnalyzing = false;
          _evaluated = true;
          _pronunciationScore = score;
          _recognizedTranscript = clientTranscript;
          _speechDetected = true;
          _passed = score >= widget.question.minScoreThreshold;
          _statusText = score >= 60 ? '🎉 Clear pronunciation recognized!' : '👍 Good effort!';
        });
        return;
      }

      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _evaluated = true;
          _pronunciationScore = 0;
          _recognizedTranscript = '(Connection error)';
          _speechDetected = false;
          _passed = false;
          _statusText = 'Could not reach AI recognition service. Tap to retry.';
        });
      }
    }
  }

  int _calculateLocalScore(String heard, String target) {
    if (heard.trim().isEmpty || target.trim().isEmpty) return 0;
    final hWords = heard.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final tWords = target.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (tWords.isEmpty) return 0;
    int matched = 0;
    for (final tw in tWords) {
      if (hWords.any((hw) => hw == tw || hw.contains(tw) || tw.contains(hw))) {
        matched++;
      }
    }
    return ((matched / tWords.length) * 100).clamp(0, 100).toInt();
  }

  void _resetForRetry() {
    setState(() {
      _evaluated = false;
      _pronunciationScore = 0;
      _recognizedTranscript = '';
      _speechDetected = false;
      _passed = false;
      _statusText = 'Tap the microphone button & read the sentence out loud!';
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          // Speech Bubble Container
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xCC1E100A), // Vintage Sepia Glass
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: const Color(0xFFD4AF37), width: 2.5),
              boxShadow: const [
                BoxShadow(color: Colors.black54, blurRadius: 14, offset: Offset(0, 6)),
              ],
            ),
            child: Column(
              children: [
                // Header Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.record_voice_over, size: 18, color: Color(0xFF2E1C12)),
                      SizedBox(width: 6),
                      Text(
                        'VOICE PRONUNCIATION TEST',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF2E1C12),
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Question Prompt Text
                Text(
                  widget.question.questionText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),

                // Target Phrase Highlight Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xEE2E1C12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFD4AF37), width: 1.8),
                    boxShadow: const [
                      BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'READ & SPEAK OUT LOUD:',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: Color(0xFFD4AF37),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '"${widget.question.targetPhrase}"',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          color: Color(0xFFFFF8E1),
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Mic Recording Control Button
                _buildMicButton(),
                const SizedBox(height: 14),

                // Status message
                Text(
                  _statusText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _isRecording
                        ? const Color(0xFFFF6B6B)
                        : (_evaluated ? Colors.white : const Color(0xFFFFF8E1)),
                  ),
                ),
                const SizedBox(height: 20),

                // Evaluation Results Card (If evaluated)
                if (_evaluated) ...[
                  _buildResultsCard(),
                  const SizedBox(height: 20),
                ],

                // Action Buttons
                if (_evaluated)
                  Row(
                    children: [
                      // Practice / Try Again Button
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: _resetForRetry,
                            icon: const Icon(Icons.refresh_rounded, size: 20),
                            label: const Text(
                              'PRACTICE AGAIN',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFD4AF37),
                              side: const BorderSide(color: Color(0xFFD4AF37), width: 1.8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Continue / Submit Button
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              widget.onAnswered(_passed);
                              widget.onAnsweredDetailed?.call(_passed, _pronunciationScore, _recognizedTranscript);
                            },
                            icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                            label: const Text(
                              'SUBMIT',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD4AF37),
                              foregroundColor: const Color(0xFF2E1C12),
                              elevation: 6,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(color: Color(0xFFFFF8E1), width: 1.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMicButton() {
    if (_isAnalyzing) {
      return Column(
        children: [
          const SizedBox(
            width: 70,
            height: 70,
            child: CircularProgressIndicator(
              color: Color(0xFFD4AF37),
              strokeWidth: 4,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Analyzing Audio...',
            style: TextStyle(
              fontFamily: 'Outfit',
              color: Color(0xFFD4AF37),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = _isRecording ? 1.0 + (_pulseController.value * 0.15) : 1.0;
        return Transform.scale(
          scale: scale,
          child: GestureDetector(
            onTap: _toggleRecording,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isRecording
                    ? const Color(0xFFFF3333)
                    : (_evaluated
                        ? (_passed ? const Color(0xFF2E7D32) : const Color(0xFFE65100))
                        : const Color(0xFFD4AF37)),
                border: Border.all(
                  color: Colors.white,
                  width: 3.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _isRecording
                        ? Colors.redAccent.withValues(alpha: 0.6)
                        : Colors.black45,
                    blurRadius: _isRecording ? 20 : 10,
                    spreadRadius: _isRecording ? 4 : 1,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isRecording
                        ? Icons.mic
                        : (_evaluated ? Icons.mic_none_rounded : Icons.mic),
                    color: _isRecording || _evaluated ? Colors.white : const Color(0xFF2E1C12),
                    size: 38,
                  ),
                  if (_isRecording)
                    Text(
                      '${_secondsRecorded}s',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    )
                  else
                    Text(
                      _evaluated ? 'TAP MIC' : 'SPEAK',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: _evaluated ? Colors.white : const Color(0xFF2E1C12),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultsCard() {
    final isGoodScore = _pronunciationScore >= widget.question.minScoreThreshold;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isGoodScore ? const Color(0xDD1B5E20) : const Color(0xDD4A2810),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isGoodScore ? const Color(0xFFA5D6A7) : const Color(0xFFD4AF37),
          width: 1.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Score row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pronunciation Accuracy:',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isGoodScore ? const Color(0xFF2E7D32) : const Color(0xFFB71C1C),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$_pronunciationScore%',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    color: Color(0xFFFFD700),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Recognized Text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Google AI Heard:',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _speechDetected ? const Color(0x334CAF50) : const Color(0x33FF5722),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _speechDetected ? Icons.mic : Icons.mic_off,
                      size: 12,
                      color: _speechDetected ? const Color(0xFF81C784) : const Color(0xFFFF8A65),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _speechDetected ? 'Voice Detected' : 'Low/No Signal',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _speechDetected ? const Color(0xFF81C784) : const Color(0xFFFF8A65),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0x66000000),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '"$_recognizedTranscript"',
              style: const TextStyle(
                fontFamily: 'Outfit',
                color: Color(0xFFFFF8E1),
                fontSize: 14,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Word Breakdown Badges
          const Text(
            'Spoken Word Alignment:',
            style: TextStyle(
              fontFamily: 'Outfit',
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          _buildWordBreakdown(),
        ],
      ),
    );
  }

  Widget _buildWordBreakdown() {
    final targetWords = widget.question.targetPhrase.split(RegExp(r'\s+'));
    final spokenWords = _recognizedTranscript.toLowerCase().split(RegExp(r'\s+'));

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: targetWords.map((word) {
        final cleanTarget = word.toLowerCase().replaceAll(RegExp(r'[^\w]'), '');
        final isMatched = spokenWords.any((sw) {
          final cleanSw = sw.replaceAll(RegExp(r'[^\w]'), '');
          return cleanSw == cleanTarget ||
              (cleanTarget.length > 3 && cleanSw.contains(cleanTarget)) ||
              (cleanSw.length > 3 && cleanTarget.contains(cleanSw));
        });

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isMatched ? const Color(0x334CAF50) : const Color(0x33FF9800),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isMatched ? const Color(0xFF81C784) : const Color(0xFFFFB74D),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isMatched ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 13,
                color: isMatched ? const Color(0xFF81C784) : const Color(0xFFFFB74D),
              ),
              const SizedBox(width: 4),
              Text(
                word,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isMatched ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
