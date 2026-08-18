import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../models/learning_content.dart';
import '../models/transcript_segment.dart';
import '../screens/level_clear_screen.dart';
import '../../widgets/wooden_back_button.dart';
import '../../widgets/game_textured_text.dart';
import '../screens/question_screen.dart';
import '../services/transcript_service.dart';
import '../widgets/caption_overlay.dart';
import '../widgets/camera_engagement_overlay.dart';
import '../../screens/sego_concept_screen.dart';

/// Plays the video for a given [LearningLevel] and overlays synchronized captions
/// when a transcript is available.
class VideoPlayerScreen extends StatefulWidget {
  final LearningLevel level;
  final String childId;

  const VideoPlayerScreen({
    super.key,
    required this.level,
    required this.childId,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final Player _player;
  late final VideoController _videoController;
  List<TranscriptSegment> _segments = [];
  String? _activeCaption;
  bool _isInitialized = false;
  String? _errorMessage;
  bool _isPlaying = false;
  bool _isVideoCompleted = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  bool _isDraggingSlider = false;
  double? _dragValue;

  final List<dynamic> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    _player = Player();
    _videoController = VideoController(_player);
    _initializePlayer();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _initializePlayer() async {
    try {
      // Load transcript in parallel.
      final transcriptFuture = TranscriptService.loadTranscript(
        widget.level.transcriptPath,
      );

      // Listen to position changes for caption sync.
      _subscriptions.add(_player.stream.position.listen((position) {
        if (!_isDraggingSlider) {
          _position = position;
          _updateCaption(position);
          if (mounted) setState(() {});
        }
      }));

      _subscriptions.add(_player.stream.duration.listen((duration) {
        _duration = duration;
        if (mounted) setState(() {});
      }));

      _subscriptions.add(_player.stream.playing.listen((playing) {
        _isPlaying = playing;
        if (mounted) setState(() {});
      }));

      _subscriptions.add(_player.stream.completed.listen((completed) {
        if (completed && !_isVideoCompleted) {
          _isVideoCompleted = true;
          if (mounted) setState(() {});
        }
      }));

      // Mount the Video widget immediately so the player starts buffering & rendering without UI delay.
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }

      // Open the video directly from assets.
      await _player.open(
        Media('asset:///${widget.level.videoPath}'),
        play: true,
      );

      _segments = await transcriptFuture;
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Could not load the video for ${widget.level.levelName}.\n\n$e';
        });
      }
    }
  }

  void _updateCaption(Duration position) {
    final positionSeconds = position.inMilliseconds / 1000.0;
    final active = TranscriptService.getActiveSegment(
      _segments,
      positionSeconds,
    );
    final newCaption = active?.text;

    if (newCaption != _activeCaption) {
      _activeCaption = newCaption;
    }
  }

  @override
  void dispose() {
    for (var sub in _subscriptions) {
      if (sub is StreamSubscription) {
        sub.cancel();
      }
    }
    _player.dispose();
    super.dispose();
  }

  void _handleBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SegoConceptScreen()),
      );
    }
  }

  // ─── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleBack();
        }
      },
      child: CameraEngagementOverlay(
        activityId: 'video_${widget.level.id}',
        child: Scaffold(
          backgroundColor: const Color(0xFFC5AE79), // Vintage Paper Canvas
          body: Stack(
            children: [
              // 1. GENERATED WEST BENGAL HISTORY MAP BACKGROUND (Replaces black bars!)
              Positioned.fill(
                child: Image.asset(
                  'assets/images/story_selection_wb_bg.png',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (ctx, err, stack) => Image.asset(
                    'assets/images/nimo_japanese_bg_clean.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // 2. Vintage Sepia Dark Vignette Overlay
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 0.95,
                        colors: [
                          Colors.transparent,
                          const Color(0xFF2E1C12).withValues(alpha: 0.35),
                          const Color(0xFF1E100A).withValues(alpha: 0.65),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              SafeArea(
                child: Column(
                  children: [
                    // Elevated Blurred Glassmorphic Top Bar
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      decoration: BoxDecoration(
                        color: const Color(0x882E1C12), // Vintage Sepia Glass
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xAA8B6914),
                          width: 1.8,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black54,
                            blurRadius: 14,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                WoodenBackButton(
                                  onTap: _handleBack,
                                ),
                                Expanded(
                                  child: Center(
                                    child: GameTexturedText(
                                      text: widget.level.levelName.toUpperCase(),
                                      fontSize: 24,
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 52,
                                ), // Balance for back button
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(child: _buildBody()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    // Error state
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 56,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 15),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _handleBack,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: const Color(0xFF2E1C12),
                ),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    // Loading state
    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
      );
    }

    // Player
    return Column(
      children: [
        // Video + captions
        Expanded(
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Video (Full Screen Viewport, Aspect Ratio Preserved)
                GestureDetector(
                  onTap: _togglePlayPause,
                  child: Center(
                    child: Video(
                      controller: _videoController,
                      fit: BoxFit.contain,
                      controls: NoVideoControls,
                    ),
                  ),
                ),

                // Caption overlay
                CaptionOverlay(text: _activeCaption),

                // Play/pause icon when paused
                if (!_isPlaying)
                  GestureDetector(
                    onTap: _togglePlayPause,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(12),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        size: 64,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Progress bar with timestamps
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
          child: Column(
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: const Color(0xFFD4AF37),
                  inactiveTrackColor: Colors.white24,
                  thumbColor: const Color(0xFFFFF8E1),
                  overlayColor: const Color(0x33D4AF37),
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                ),
                child: Slider(
                  value: (_dragValue ?? (_duration.inMilliseconds > 0
                      ? _position.inMilliseconds.toDouble().clamp(0.0, _duration.inMilliseconds.toDouble())
                      : 0.0)).clamp(0.0, _duration.inMilliseconds > 0 ? _duration.inMilliseconds.toDouble() : 1.0),
                  max: _duration.inMilliseconds > 0
                      ? _duration.inMilliseconds.toDouble()
                      : 1.0,
                  onChangeStart: (val) {
                    setState(() {
                      _isDraggingSlider = true;
                      _dragValue = val;
                    });
                  },
                  onChanged: (val) {
                    setState(() {
                      _dragValue = val;
                    });
                  },
                  onChangeEnd: (val) async {
                    final target = Duration(milliseconds: val.toInt());
                    await _player.seek(target);
                    if (mounted) {
                      setState(() {
                        _position = target;
                        _isDraggingSlider = false;
                        _dragValue = null;
                      });
                    }
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_dragValue != null
                          ? Duration(milliseconds: _dragValue!.toInt())
                          : _position),
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFD4AF37),
                      ),
                    ),
                    Text(
                      _formatDuration(_duration),
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Controls row
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Replay -10s button
              IconButton(
                icon: const Icon(Icons.replay_10, color: Colors.white70),
                iconSize: 32,
                tooltip: 'Rewind 10s',
                onPressed: () {
                  final newPos = _position - const Duration(seconds: 10);
                  _player.seek(newPos < Duration.zero ? Duration.zero : newPos);
                },
              ),
              const SizedBox(width: 16),

              // Play / Pause
              IconButton(
                icon: Icon(
                  _isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  color: const Color(0xFFD4AF37),
                ),
                iconSize: 56,
                onPressed: _togglePlayPause,
              ),
              const SizedBox(width: 16),

              // Forward +10s button
              IconButton(
                icon: const Icon(Icons.forward_10, color: Colors.white70),
                iconSize: 32,
                tooltip: 'Skip 10s',
                onPressed: () {
                  final newPos = _position + const Duration(seconds: 10);
                  _player.seek(newPos > _duration ? _duration : newPos);
                },
              ),
              const SizedBox(width: 16),

              // Quick Skip to Questions
              InkWell(
                onTap: () {
                  _player.pause();
                  _navigateToQuestionsOrComplete();
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0x662E1C12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD4AF37), width: 1.2),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'SKIP',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFD4AF37),
                          letterSpacing: 1.0,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.skip_next_rounded, color: Color(0xFFD4AF37), size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Action button (Continue to Questions or Complete Level)
        if (_isVideoCompleted)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  _player.pause();
                  _navigateToQuestionsOrComplete();
                },
                icon: Icon(
                  widget.level.questionsPath != null
                      ? Icons.quiz_outlined
                      : Icons.check_circle_outline,
                  size: 20,
                ),
                label: Text(
                  widget.level.questionsPath != null
                      ? 'Continue to Questions'
                      : 'Complete Level',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: const Color(0xFF2E1C12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _navigateToQuestionsOrComplete() {
    if (widget.level.questionsPath != null) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              QuestionScreen(
                childId: widget.childId,
                level: widget.level,
              ),
          transitionsBuilder:
              (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => LevelClearScreen(
            childId: widget.childId,
            level: widget.level,
            totalCorrect: 0,
            totalQuestions: 0,
          ),
        ),
      );
    }
  }

  void _togglePlayPause() {
    _player.playOrPause();
  }
}
