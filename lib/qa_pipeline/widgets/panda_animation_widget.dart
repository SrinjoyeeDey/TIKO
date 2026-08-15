import 'dart:async';
import 'package:flutter/material.dart';

// ─── Animation States ────────────────────────────────────────────────────────

enum PandaState {
  idle,
  thinking,
  appear,
  correct,
  celebrate,
  wrongSad,
}

// ─── Frame Definitions ───────────────────────────────────────────────────────

/// Milliseconds per frame for each animation state.
const _kFrameDurations = {
  PandaState.idle: 135, // ~7.4 FPS (smooth subtle looping)
  PandaState.thinking: 110, // ~9.1 FPS (attentive looping)
  PandaState.appear: 80, // ~12.5 FPS (crisp entrance)
  PandaState.correct: 75, // ~13.3 FPS (snappy immediate reaction)
  PandaState.celebrate: 85, // ~11.8 FPS (expressive celebration)
  PandaState.wrongSad: 110, // ~9.1 FPS (sympathetic, clearly visible reaction)
};

/// Milliseconds to hold the final expressive frame before returning to idle.
const _kFinalFrameHoldDurations = {
  PandaState.wrongSad: 450, // Clearly visible sad hold for young learners
  PandaState.celebrate: 350, // Joyous victory pose hold
  PandaState.correct: 0, // Immediately chains to celebrate
  PandaState.appear: 0, // Transitions directly to idle
};

/// Folder names matching `assets/animations/panda/<folder>/`
const _kFolderNames = {
  PandaState.idle: 'idle',
  PandaState.thinking: 'thinking',
  PandaState.appear: 'appear',
  PandaState.correct: 'correct',
  PandaState.celebrate: 'celebrate',
  PandaState.wrongSad: 'wrong_sad',
};

/// Number of frames for each state (all 8 based on manifest).
const _kFrameCounts = {
  PandaState.idle: 8,
  PandaState.thinking: 8,
  PandaState.appear: 8,
  PandaState.correct: 8,
  PandaState.celebrate: 8,
  PandaState.wrongSad: 8,
};

/// States that loop indefinitely.
const _kLoopingStates = {PandaState.idle, PandaState.thinking};

/// One-shot states and what they transition to on completion.
const _kNextState = {
  PandaState.appear: PandaState.idle,
  PandaState.correct: PandaState.celebrate,
  PandaState.celebrate: PandaState.idle,
  PandaState.wrongSad: PandaState.idle,
};

// ─── Controller ──────────────────────────────────────────────────────────────

/// A controller to imperatively trigger and manage panda animation states.
class PandaController extends ChangeNotifier {
  PandaAnimationWidgetState? _stateRef;
  PandaState _initialState;

  PandaController({this._initialState = PandaState.idle});

  PandaState get currentState => _stateRef?.state ?? _initialState;

  void _attach(PandaAnimationWidgetState state) {
    _stateRef = state;
  }

  void _detach() {
    _stateRef = null;
  }

  /// Play the appear animation once, then switch to idle.
  void playAppear() {
    _initialState = PandaState.appear;
    _stateRef?.playAppear();
    notifyListeners();
  }

  /// Play correct -> celebrate -> idle chain immediately.
  void playCorrect() {
    _initialState = PandaState.correct;
    _stateRef?.playCorrect();
    notifyListeners();
  }

  /// Play celebrate -> idle.
  void playCelebrate() {
    _initialState = PandaState.celebrate;
    _stateRef?.playCelebrate();
    notifyListeners();
  }

  /// Play wrong_sad once, then return to idle.
  void playWrongSad() {
    _initialState = PandaState.wrongSad;
    _stateRef?.playWrongSad();
    notifyListeners();
  }

  /// Play thinking (loops until another state is set).
  void playThinking() {
    _initialState = PandaState.thinking;
    _stateRef?.playThinking();
    notifyListeners();
  }

  /// Play idle loop.
  void playIdle({bool force = false}) {
    _initialState = PandaState.idle;
    _stateRef?.playIdle(force: force);
    notifyListeners();
  }

  /// Return to idle immediately.
  void returnToIdle({bool force = false}) {
    playIdle(force: force);
  }
}

// ─── Widget ──────────────────────────────────────────────────────────────────

/// A panda companion character that plays frame-by-frame PNG animations
/// like a Duolingo-style educational companion.
///
/// Can be controlled via [controller] or `GlobalKey<PandaAnimationWidgetState>`.
class PandaAnimationWidget extends StatefulWidget {
  /// Desired display size of the panda character (width & height).
  final double size;

  /// Optional explicit width override.
  final double? width;

  /// Optional explicit height override.
  final double? height;

  /// Initial state to begin with on first mount.
  final PandaState initialState;

  /// Optional controller to manage the character externally.
  final PandaController? controller;

  /// Whether to render a soft grounding shadow beneath the panda.
  final bool showShadow;

  const PandaAnimationWidget({
    super.key,
    this.size = 140,
    this.width,
    this.height,
    this.initialState = PandaState.idle,
    this.controller,
    this.showShadow = true,
  });

  /// Precache all 48 panda animation PNG frames in parallel into memory for zero-jank playback.
  static Future<void> precacheAllFrames(BuildContext context) async {
    final List<Future<void>> futures = [];
    for (final entry in _kFolderNames.entries) {
      final folder = entry.value;
      final count = _kFrameCounts[entry.key]!;
      for (int i = 1; i <= count; i++) {
        final frameNum = i.toString().padLeft(2, '0');
        final path = 'assets/animations/panda/$folder/frame_$frameNum.png';
        try {
          futures.add(precacheImage(AssetImage(path), context).catchError((_) {}));
        } catch (_) {}
      }
    }
    await Future.wait(futures);
  }

  @override
  State<PandaAnimationWidget> createState() => PandaAnimationWidgetState();
}

class PandaAnimationWidgetState extends State<PandaAnimationWidget> {
  late PandaState _state;
  int _frameIndex = 0;
  Timer? _timer;
  Timer? _holdTimer;

  PandaState get state => _state;

  // ─── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _state = widget.initialState;
    widget.controller?._attach(this);

    // Precaching frames across all states in parallel
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        PandaAnimationWidget.precacheAllFrames(context);
      }
    });

    _startAnimation(_state);
  }

  @override
  void didUpdateWidget(covariant PandaAnimationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach();
      widget.controller?._attach(this);
    }
    // Note: Do NOT restart timer or reset frame index if state hasn't changed.
    // This guarantees full rebuild resilience when parent setState occurs!
  }

  @override
  void dispose() {
    widget.controller?._detach();
    _timer?.cancel();
    _holdTimer?.cancel();
    super.dispose();
  }

  // ─── Public API ────────────────────────────────────────────────────

  /// Play the appear animation once, then switch to idle.
  void playAppear() {
    if (!mounted) return;
    _startAnimation(PandaState.appear);
  }

  /// Play correct -> celebrate -> idle chain.
  void playCorrect() {
    if (!mounted) return;
    _startAnimation(PandaState.correct);
  }

  /// Play celebrate -> idle.
  void playCelebrate() {
    if (!mounted) return;
    _startAnimation(PandaState.celebrate);
  }

  /// Play wrong_sad once with clearly visible hold, then return to idle.
  void playWrongSad() {
    if (!mounted) return;
    _startAnimation(PandaState.wrongSad);
  }

  /// Play thinking (loops until another state is set).
  void playThinking() {
    if (!mounted) return;
    _startAnimation(PandaState.thinking);
  }

  /// Play idle loop.
  /// If [force] is false and an active reaction (wrongSad, correct, celebrate) is running,
  /// allows the reaction to complete its natural flow before settling in idle.
  void playIdle({bool force = false}) {
    if (!mounted) return;
    if (!force && (_state == PandaState.wrongSad || _state == PandaState.correct || _state == PandaState.celebrate)) {
      // Allow ongoing reaction to conclude naturally into idle
      return;
    }
    _startAnimation(PandaState.idle);
  }

  /// Return to idle immediately.
  void returnToIdle({bool force = false}) {
    playIdle(force: force);
  }

  // ─── Internal ──────────────────────────────────────────────────────

  void _startAnimation(PandaState newState) {
    _timer?.cancel();
    _holdTimer?.cancel();
    if (!mounted) return;

    setState(() {
      _state = newState;
      _frameIndex = 0;
    });

    final frameDuration = _kFrameDurations[newState]!;
    final frameCount = _kFrameCounts[newState]!;
    final loops = _kLoopingStates.contains(newState);

    _timer = Timer.periodic(
      Duration(milliseconds: frameDuration),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        final nextFrame = _frameIndex + 1;

        if (nextFrame >= frameCount) {
          if (loops) {
            setState(() => _frameIndex = 0);
          } else {
            timer.cancel();
            final next = _kNextState[newState];
            final holdMs = _kFinalFrameHoldDurations[newState] ?? 0;

            if (next != null && mounted) {
              if (holdMs > 0) {
                // Hold final expressive frame before transitioning
                _holdTimer = Timer(Duration(milliseconds: holdMs), () {
                  if (mounted) _startAnimation(next);
                });
              } else {
                _startAnimation(next);
              }
            }
          }
        } else {
          setState(() => _frameIndex = nextFrame);
        }
      },
    );
  }

  String get _currentFramePath {
    final folder = _kFolderNames[_state] ?? 'idle';
    final frameNum = (_frameIndex + 1).toString().padLeft(2, '0');
    return 'assets/animations/panda/$folder/frame_$frameNum.png';
  }

  // ─── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final double displayW = widget.width ?? widget.size;
    final double displayH = widget.height ?? widget.size;

    return RepaintBoundary(
      child: SizedBox(
        width: displayW,
        height: displayH,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Soft ground shadow for 3D presence
            if (widget.showShadow)
              Positioned(
                bottom: 2,
                child: Container(
                  width: displayW * 0.55,
                  height: 12,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(
                      Radius.elliptical(displayW * 0.55, 12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.28),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),

            // Animated PNG character frame with gapless playback and bicubic scaling
            Image.asset(
              _currentFramePath,
              key: ValueKey(_currentFramePath),
              width: displayW,
              height: displayH,
              fit: BoxFit.contain,
              gaplessPlayback: true,
              filterQuality: FilterQuality.high,
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Semantic alias for Panda companion across all app screens.
typedef PandaCharacter = PandaAnimationWidget;
