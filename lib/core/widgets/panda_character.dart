import 'dart:async';
import 'package:flutter/material.dart';

/// Supported panda animation states corresponding to transparent PNG sequences
/// in `assets/animations/panda/`.
enum PandaAnimation {
  appear('appear', 8, 11, false),
  idle('idle', 8, 7, true),
  thinking('thinking', 8, 9, true),
  correct('correct', 8, 11, false),
  celebrate('celebrate', 8, 11, false),
  wrongSad('wrong_sad', 8, 9, false);

  final String folderName;
  final int frameCount;
  final int fps;
  final bool isLooping;

  const PandaAnimation(this.folderName, this.frameCount, this.fps, this.isLooping);

  String getFramePath(int frameIndex) {
    // 1-indexed formatted as frame_01.png, frame_02.png, ...
    final numStr = (frameIndex + 1).toString().padLeft(2, '0');
    return 'assets/animations/panda/$folderName/frame_$numStr.png';
  }

  List<String> get allFramePaths {
    return List.generate(frameCount, (i) => getFramePath(i));
  }
}

/// Controller to drive Panda character animation sequences with Duolingo-style personality.
class PandaController extends ChangeNotifier {
  PandaAnimation _currentAnimation = PandaAnimation.idle;
  int _currentFrameIndex = 0;
  String? _speechText;
  Timer? _frameTimer;
  Timer? _holdTimer;
  bool _isDisposed = false;

  PandaAnimation get currentAnimation => _currentAnimation;
  int get currentFrameIndex => _currentFrameIndex;
  String? get speechText => _speechText;
  String get currentFramePath => _currentAnimation.getFramePath(_currentFrameIndex);

  PandaController({PandaAnimation initialAnimation = PandaAnimation.idle}) {
    _currentAnimation = initialAnimation;
    _startAnimationTimer();
  }

  /// All 48 frames across all animations for pre-caching
  static List<String> get allAssetPaths {
    final List<String> paths = [];
    for (final anim in PandaAnimation.values) {
      paths.addAll(anim.allFramePaths);
    }
    return paths;
  }

  /// Pre-cache all panda animation frames into Flutter's image cache
  static Future<void> precacheAll(BuildContext context) async {
    for (final path in allAssetPaths) {
      try {
        await precacheImage(AssetImage(path), context);
      } catch (_) {
        // Ignore missing frames gracefully
      }
    }
  }

  /// Immediately play idle loop
  void playIdle({String? speech}) {
    _play(PandaAnimation.idle, speech: speech);
  }

  /// Immediately play thinking loop
  void playThinking({String? speech = 'Thinking... 🤔'}) {
    _play(PandaAnimation.thinking, speech: speech);
  }

  /// Immediately play appear animation, then transition to idle
  void playAppear({String? speech = 'Hello! Let\'s learn! 🐼'}) {
    _play(
      PandaAnimation.appear,
      speech: speech,
      onCompleted: () => playIdle(speech: null),
    );
  }

  /// Immediately play correct animation → chains into celebrate → transitions to idle
  void playCorrect({String? speech = 'Great job! ⭐'}) {
    _play(
      PandaAnimation.correct,
      speech: speech,
      onCompleted: () {
        playCelebrate(
          speech: speech ?? 'Awesome! 🎉',
          onCompleted: () => playIdle(speech: null),
        );
      },
    );
  }

  /// Immediately play celebration animation → transitions to idle
  void playCelebrate({String? speech = 'Hooray! 🥳', VoidCallback? onCompleted}) {
    _play(
      PandaAnimation.celebrate,
      speech: speech,
      onCompleted: onCompleted ?? () => playIdle(speech: null),
    );
  }

  /// Immediately play wrong / sad animation → holds final sad frame for [holdDuration] → transitions to idle
  void playWrongSad({
    String? speech = 'Oops! Try again! 🤗',
    Duration holdDuration = const Duration(milliseconds: 550),
  }) {
    _play(
      PandaAnimation.wrongSad,
      speech: speech,
      holdDuration: holdDuration,
      onCompleted: () => playIdle(speech: null),
    );
  }

  /// Set speech bubble text dynamically
  void setSpeech(String? text) {
    _speechText = text;
    _notifySafe();
  }

  void _play(
    PandaAnimation animation, {
    String? speech,
    Duration? holdDuration,
    VoidCallback? onCompleted,
  }) {
    if (_isDisposed) return;

    _frameTimer?.cancel();
    _holdTimer?.cancel();

    _currentAnimation = animation;
    _currentFrameIndex = 0;
    _speechText = speech;
    _notifySafe();

    final frameInterval = Duration(milliseconds: (1000 / animation.fps).round());

    _frameTimer = Timer.periodic(frameInterval, (timer) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }

      if (_currentFrameIndex < animation.frameCount - 1) {
        _currentFrameIndex++;
        _notifySafe();
      } else {
        // Animation sequence ended
        if (animation.isLooping) {
          _currentFrameIndex = 0;
          _notifySafe();
        } else {
          timer.cancel();
          if (holdDuration != null && holdDuration > Duration.zero) {
            _holdTimer = Timer(holdDuration, () {
              if (!_isDisposed && onCompleted != null) {
                onCompleted();
              }
            });
          } else if (onCompleted != null) {
            onCompleted();
          }
        }
      }
    });
  }

  void _startAnimationTimer() {
    switch (_currentAnimation) {
      case PandaAnimation.appear:
        playAppear(speech: _speechText);
        break;
      case PandaAnimation.correct:
        playCorrect(speech: _speechText);
        break;
      case PandaAnimation.celebrate:
        playCelebrate(speech: _speechText);
        break;
      case PandaAnimation.wrongSad:
        playWrongSad(speech: _speechText);
        break;
      case PandaAnimation.thinking:
        playThinking(speech: _speechText);
        break;
      case PandaAnimation.idle:
        playIdle(speech: _speechText);
        break;
    }
  }

  void _notifySafe() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _frameTimer?.cancel();
    _holdTimer?.cancel();
    super.dispose();
  }
}

/// Duolingo-style animated Panda Character Widget with speech bubble and frame-by-frame rendering.
class PandaCharacterWidget extends StatefulWidget {
  final PandaController? controller;
  final PandaAnimation initialAnimation;
  final double size;
  final bool showSpeechBubble;
  final String? speechText;
  final VoidCallback? onTap;
  final Alignment speechAlignment;

  const PandaCharacterWidget({
    super.key,
    this.controller,
    this.initialAnimation = PandaAnimation.idle,
    this.size = 120.0,
    this.showSpeechBubble = true,
    this.speechText,
    this.onTap,
    this.speechAlignment = Alignment.topCenter,
  });

  @override
  State<PandaCharacterWidget> createState() => _PandaCharacterWidgetState();
}

class _PandaCharacterWidgetState extends State<PandaCharacterWidget>
    with SingleTickerProviderStateMixin {
  late PandaController _controller;
  bool _ownsController = false;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  static bool _globalPrecached = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
      _ownsController = false;
    } else {
      _controller = PandaController(initialAnimation: widget.initialAnimation);
      _ownsController = true;
    }

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0.0, end: 4.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_globalPrecached) {
      _globalPrecached = true;
      PandaController.precacheAll(context);
    }
  }

  @override
  void didUpdateWidget(covariant PandaCharacterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != null && widget.controller != _controller) {
      if (_ownsController) {
        _controller.dispose();
      }
      _controller = widget.controller!;
      _ownsController = false;
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _handleTap() {
    if (widget.onTap != null) {
      widget.onTap!();
    } else {
      // Interactive poke reaction
      if (_controller.currentAnimation == PandaAnimation.idle) {
        _controller.playCelebrate(speech: 'Ready to learn! 🎋');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final speech = widget.speechText ?? _controller.speechText;
        final hasSpeech = widget.showSpeechBubble && speech != null && speech.isNotEmpty;

        return GestureDetector(
          onTap: _handleTap,
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Duolingo-style Pop Speech Bubble
              if (hasSpeech) ...[
                _buildSpeechBubble(speech!),
                const SizedBox(height: 6),
              ],

              // 2. Animated Character Frame with Smooth Float Bounce
              AnimatedBuilder(
                animation: _bounceAnimation,
                builder: (context, child) {
                  final isIdleOrThinking = _controller.currentAnimation == PandaAnimation.idle ||
                      _controller.currentAnimation == PandaAnimation.thinking;
                  final floatOffset = isIdleOrThinking ? _bounceAnimation.value : 0.0;

                  return Transform.translate(
                    offset: Offset(0, -floatOffset),
                    child: child,
                  );
                },
                child: SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Image.asset(
                      _controller.currentFramePath,
                      gaplessPlayback: true,
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: widget.size,
                          height: widget.size,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.pets_rounded,
                            color: Color(0xFFD4AF37),
                            size: 48,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSpeechBubble(String text) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutBack,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF4EE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4AF37), width: 1.8),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2E1C12),
                letterSpacing: 0.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
