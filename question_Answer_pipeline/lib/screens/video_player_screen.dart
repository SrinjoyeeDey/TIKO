import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../models/learning_content.dart';
import '../models/transcript_segment.dart';
import '../screens/level_clear_screen.dart';
import '../screens/question_screen.dart';
import '../services/transcript_service.dart';
import '../widgets/caption_overlay.dart';

/// Plays the video for a given [LearningLevel] and overlays synchronized captions
/// when a transcript is available.
class VideoPlayerScreen extends StatefulWidget {
  final LearningLevel level;
  final String childId;

  const VideoPlayerScreen({super.key, required this.level, required this.childId});

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

  @override
  void initState() {
    super.initState();
    _player = Player();
    _videoController = VideoController(_player);
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      // Load transcript in parallel.
      final transcriptFuture =
          TranscriptService.loadTranscript(widget.level.transcriptPath);

      // Listen to position changes for caption sync.
      _player.stream.position.listen((position) {
        _position = position;
        _updateCaption(position);
        if (mounted) setState(() {});
      });

      _player.stream.duration.listen((duration) {
        _duration = duration;
        if (mounted) setState(() {});
      });

      _player.stream.playing.listen((playing) {
        _isPlaying = playing;
        if (mounted) setState(() {});
      });

      _player.stream.completed.listen((completed) {
        if (completed && !_isVideoCompleted) {
          _isVideoCompleted = true;
          if (mounted) setState(() {});
        }
      });

      // Open the video directly from assets.
      await _player.open(Media('asset:///${widget.level.videoPath}'));

      _segments = await transcriptFuture;

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
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
    final active =
        TranscriptService.getActiveSegment(_segments, positionSeconds);
    final newCaption = active?.text;

    if (newCaption != _activeCaption) {
      _activeCaption = newCaption;
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  // ─── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.level.levelName),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildBody(),
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
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 56),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 15),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
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
        child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
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
                // Video
                GestureDetector(
                  onTap: _togglePlayPause,
                  child: Video(
                    controller: _videoController,
                    controls: NoVideoControls,
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

        // Progress bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF6C63FF),
              inactiveTrackColor: Colors.white24,
              thumbColor: const Color(0xFF6C63FF),
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: _duration.inMilliseconds > 0
                  ? _position.inMilliseconds
                      .toDouble()
                      .clamp(0, _duration.inMilliseconds.toDouble())
                  : 0,
              max: _duration.inMilliseconds > 0
                  ? _duration.inMilliseconds.toDouble()
                  : 1,
              onChanged: (value) {
                _player.seek(Duration(milliseconds: value.toInt()));
              },
            ),
          ),
        ),

        // Controls row
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Replay button
              IconButton(
                icon: const Icon(Icons.replay_10, color: Colors.white70),
                iconSize: 32,
                onPressed: () {
                  final newPos =
                      _position - const Duration(seconds: 10);
                  _player.seek(
                      newPos < Duration.zero ? Duration.zero : newPos);
                },
              ),
              const SizedBox(width: 24),

              // Play / Pause
              IconButton(
                icon: Icon(
                  _isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  color: const Color(0xFF6C63FF),
                ),
                iconSize: 56,
                onPressed: _togglePlayPause,
              ),
              const SizedBox(width: 24),

              // Forward button
              IconButton(
                icon: const Icon(Icons.forward_10, color: Colors.white70),
                iconSize: 32,
                onPressed: () {
                  final newPos =
                      _position + const Duration(seconds: 10);
                  _player.seek(
                      newPos > _duration ? _duration : newPos);
                },
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
                  if (widget.level.questionsPath != null) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => QuestionScreen(
                            level: widget.level, childId: widget.childId),
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
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
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

  void _togglePlayPause() {
    _player.playOrPause();
  }
}
