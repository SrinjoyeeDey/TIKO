import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth_mode_selection_screen.dart';
import 'game_map_1913_screen.dart';
import 'leaderboard_screen.dart';
import '../widgets/smoke_bomb_transition.dart';
import '../qa_pipeline/models/learning_content.dart';
import '../qa_pipeline/services/content_discovery_service.dart';
import '../core/state/child_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AGE THEME DATA CLASS
// ─────────────────────────────────────────────────────────────────────────────
class _AgeTheme {
  final Color cardTop;
  final Color cardBottom;
  final Color bgEnd; // right-side page background color
  final Color bgBlend; // transition blend zone color
  final Color mouthTop; // mouth cavity top color
  final Color mouthBottom;
  final Color accentDark; // eyebrows, nostrils, border-like accents
  final Color toothGlow; // selected-tooth outer glow
  final Color toothText; // non-selected tooth number color
  final Color shadowColor;

  const _AgeTheme({
    required this.cardTop,
    required this.cardBottom,
    required this.bgEnd,
    required this.bgBlend,
    required this.mouthTop,
    required this.mouthBottom,
    required this.accentDark,
    required this.toothGlow,
    required this.toothText,
    required this.shadowColor,
  });

  // Smoothly lerp between two themes
  static _AgeTheme lerp(_AgeTheme a, _AgeTheme b, double t) {
    return _AgeTheme(
      cardTop: Color.lerp(a.cardTop, b.cardTop, t)!,
      cardBottom: Color.lerp(a.cardBottom, b.cardBottom, t)!,
      bgEnd: Color.lerp(a.bgEnd, b.bgEnd, t)!,
      bgBlend: Color.lerp(a.bgBlend, b.bgBlend, t)!,
      mouthTop: Color.lerp(a.mouthTop, b.mouthTop, t)!,
      mouthBottom: Color.lerp(a.mouthBottom, b.mouthBottom, t)!,
      accentDark: Color.lerp(a.accentDark, b.accentDark, t)!,
      toothGlow: Color.lerp(a.toothGlow, b.toothGlow, t)!,
      toothText: Color.lerp(a.toothText, b.toothText, t)!,
      shadowColor: Color.lerp(a.shadowColor, b.shadowColor, t)!,
    );
  }
}

// Age Range Themes
// 🌿 Ages 3–5: Zesty Fresh Leaf Green (matching reference screenshot)
const _themeGreen = _AgeTheme(
  cardTop: Color(0xFF85D64B),
  cardBottom: Color(0xFF71C538),
  bgEnd: Color(0xFF74C83F),
  bgBlend: Color(0xFFD6F0BE),
  mouthTop: Color(0xFF132D0E),
  mouthBottom: Color(0xFF0F220A),
  accentDark: Color(0xFF14300D),
  toothGlow: Color(0xFF80D246),
  toothText: Color(0xFF5C8049),
  shadowColor: Color(0x350F220A),
);

// ☀️ Ages 6–8: Sunny Yellow-Orange (playful, energetic)
const _themeYellow = _AgeTheme(
  cardTop: Color(0xFFFFBF27),
  cardBottom: Color(0xFFE89B00),
  bgEnd: Color(0xFFF5A800),
  bgBlend: Color(0xFFFFF0B0),
  mouthTop: Color(0xFF5C3A00),
  mouthBottom: Color(0xFF3A2200),
  accentDark: Color(0xFF5C3A00),
  toothGlow: Color(0xFFFFBF27),
  toothText: Color(0xFFB87800),
  shadowColor: Color(0x453A2200),
);

// 💗 Ages 9–11: Hot Pink (vibrant, cool)
const _themePink = _AgeTheme(
  cardTop: Color(0xFFFF3B63),
  cardBottom: Color(0xFFCC1A40),
  bgEnd: Color(0xFFE8274F),
  bgBlend: Color(0xFFFFBECB),
  mouthTop: Color(0xFF5C001A),
  mouthBottom: Color(0xFF3A0010),
  accentDark: Color(0xFF5C001A),
  toothGlow: Color(0xFFFF3B63),
  toothText: Color(0xFFCC3355),
  shadowColor: Color(0x453A0010),
);

// 🍇 Ages 12–15: Deep Purple (mature, mysterious)
const _themePurple = _AgeTheme(
  cardTop: Color(0xFFA855F7),
  cardBottom: Color(0xFF7C23D4),
  bgEnd: Color(0xFF9333EA),
  bgBlend: Color(0xFFE8C8FF),
  mouthTop: Color(0xFF2D0A4E),
  mouthBottom: Color(0xFF1A0030),
  accentDark: Color(0xFF2D0A4E),
  toothGlow: Color(0xFFA855F7),
  toothText: Color(0xFF9B4DCC),
  shadowColor: Color(0x451A0030),
);

_AgeTheme _lerpedTheme(double age) {
  // Smooth cross-fade in 1-unit transition zones at each boundary
  if (age < 5.0) return _themeGreen;
  if (age < 6.0) {
    final t = (age - 5.0).clamp(0.0, 1.0);
    return _AgeTheme.lerp(
      _themeGreen,
      _themeYellow,
      Curves.easeInOut.transform(t),
    );
  }
  if (age < 8.0) return _themeYellow;
  if (age < 9.0) {
    final t = (age - 8.0).clamp(0.0, 1.0);
    return _AgeTheme.lerp(
      _themeYellow,
      _themePink,
      Curves.easeInOut.transform(t),
    );
  }
  if (age < 11.0) return _themePink;
  if (age < 12.0) {
    final t = (age - 11.0).clamp(0.0, 1.0);
    return _AgeTheme.lerp(
      _themePink,
      _themePurple,
      Curves.easeInOut.transform(t),
    );
  }
  return _themePurple;
}

// ─────────────────────────────────────────────────────────────────────────────
// SEGO CONCEPT SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class SegoConceptScreen extends StatefulWidget {
  const SegoConceptScreen({super.key});

  @override
  State<SegoConceptScreen> createState() => _SegoConceptScreenState();
}

class _SegoConceptScreenState extends State<SegoConceptScreen>
    with TickerProviderStateMixin {
  double _currentAge = 7.0;
  double _emotionValue = 0.5; // 0.0: Not good (Sky Blue), 0.5: Great (Lavender), 1.0: Awesome (Yellow)
  int _screenIndex =
      0; // 0: Age Selection, 1: Monster Takeover, 2: Role Selection
  String? _selectedRole;

  late AnimationController _ballController;
  bool _isBouncingBallActive = false;

  late AnimationController _typewriterController;
  bool _isTypewriterActive = false;
  String _typedText = "";
  int _lastSoundCharCount = 0;
  static const String _typewriterSentence =
      "Everyone's journey is unique, but yours is special.";

  late PageController _takeoverPageController;

  AnimationController? _unlockAnimationController;
  AnimationController get unlockAnimController {
    _unlockAnimationController ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
    return _unlockAnimationController!;
  }

  late final ScrollController _mapScrollController;
  late final AnimationController _waterWaveController;

  int _unlockedLevelIndex = 0; // Level 0 (Stone 1 at top) starts UNLOCKED!
  int? _animatingUnlockingIndex;
  int? _hoveredLevelIndex;
  int _activeNavIndex = 4; // Video Call tab default selected
  Offset _cursorPos = const Offset(-200, -200);
  bool _isCursorInside = false;

  List<LearningChapter> _chapters = [];
  Map<String, String?> _stageCoverImages = {};
  int _unlockedStageIndex = 0;

  @override
  void dispose() {
    _waterWaveController.dispose();
    _mapScrollController.dispose();
    _ballController.dispose();
    _typewriterController.dispose();
    _takeoverPageController.dispose();
    _unlockAnimationController?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _mapScrollController = ScrollController();
    _waterWaveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _ballController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2900),
    );
    _typewriterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7800),
    );
    _takeoverPageController = PageController(initialPage: 0);
    _unlockAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );

    _loadDynamicChapters();
  }

  Future<void> _loadDynamicChapters() async {
    final childId = ChildState.instance.currentProfile.id;
    final chapters = await ContentDiscoveryService.discoverContent();
    final covers = <String, String?>{};
    for (final c in chapters) {
      covers[c.id] = await ContentDiscoveryService.findCoverImage(c.id);
    }
    final highestUnlocked = await ContentDiscoveryService.getHighestUnlockedChapterIndex(childId);

    if (mounted) {
      setState(() {
        _chapters = chapters;
        _stageCoverImages = covers;
        _unlockedStageIndex = highestUnlocked;
        _unlockedLevelIndex = highestUnlocked;
      });
    }
  }

  void _onAgeChanged(double age) {
    setState(() => _currentAge = age);
  }

  void _goToTakeover() {
    if (_isBouncingBallActive) return;
    setState(() {
      _isBouncingBallActive = true;
      _typedText = "";
      _lastSoundCharCount = 0;
    });

    if (_takeoverPageController.hasClients) {
      _takeoverPageController.jumpToPage(0);
    }

    _ballController.forward(from: 0.0).then((_) {
      if (mounted) {
        if (_takeoverPageController.hasClients) {
          _takeoverPageController.jumpToPage(1);
        }
        setState(() {
          _screenIndex = 1;
          _isBouncingBallActive = false;
          _isTypewriterActive = true;
        });
        _typewriterController.forward(from: 0.0).then((_) {
          if (mounted) {
            setState(() {
              _isTypewriterActive = false;
              _typedText = _typewriterSentence;
            });
          }
        });
      }
    });
  }

  void _goToAgeSelection() {
    if (_takeoverPageController.hasClients) {
      _takeoverPageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutQuart,
      );
    }
  }

  void _goToTakeoverScreen() {
    if (_takeoverPageController.hasClients) {
      _takeoverPageController.animateToPage(
        1,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutQuart,
      );
    }
  }

  void _goToRoleSelection() {
    if (_takeoverPageController.hasClients) {
      _takeoverPageController.animateToPage(
        2,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutQuart,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = _lerpedTheme(_currentAge);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Listener(
        onPointerDown: (event) {
          setState(() {
            _cursorPos = event.position;
            _isCursorInside = true;
          });
        },
        onPointerMove: (event) {
          setState(() {
            _cursorPos = event.position;
            _isCursorInside = true;
          });
        },
        onPointerUp: (_) => setState(() => _isCursorInside = false),
        onPointerCancel: (_) => setState(() => _isCursorInside = false),
        onPointerHover: (event) {
          try {
            final pos = event.position;
            if ((pos - _cursorPos).distance > 0.5) {
              setState(() {
                _cursorPos = pos;
                _isCursorInside = true;
              });
            }
          } catch (_) {}
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: const Alignment(-0.9, -1.0),
              end: const Alignment(1.0, 0.9),
              colors: [
                const Color(0xFFF7FAEE),
                const Color(0xFFEDF6E2),
                theme.bgBlend,
                theme.bgEnd,
              ],
              stops: const [0.0, 0.28, 0.55, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Topo Lines
              Positioned.fill(child: CustomPaint(painter: TopoLinesPainter())),

              // 3-Page Vertical Navigation (Permanently Mounted)
              Positioned.fill(
                child: PageView(
                  controller: _takeoverPageController,
                  scrollDirection: Axis.vertical,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // Page 0: Age Selection Screen
                    _buildAgeScreen(context, theme),

                    // Page 1: Monster Takeover Screen (Monster Face)
                    _buildTakeoverScreen(context, theme),

                    // Page 2: Level Map Screen (Stepping Stones)
                    _buildRoleScreen(context, theme),
                  ],
                ),
              ),

              // Bouncing Ball Transition Overlay (3 Floor Bounces then Single-Layer Circular Iris Reveal of Page 2)
              if (_isBouncingBallActive) _buildBouncingBallOverlay(size, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBouncingBallOverlay(Size size, _AgeTheme theme) {
    return AnimatedBuilder(
      animation: _ballController,
      builder: (context, child) {
        final t = _ballController.value;

        const double phase1End =
            0.58; // 3 floor bounces occur in t: 0.0 -> 0.58 (~1.68s)
        final floorY = size.height * 0.70; // Baseline floor level
        final targetCenterY =
            size.height * 0.45; // Center target for zoom reveal

        if (t <= phase1End) {
          // PHASE 1: 3 REALISTIC HIGH FLOOR BOUNCES WITH SQUASH & STRETCH
          final tb = (t / phase1End).clamp(0.0, 1.0);
          double currentY = floorY;
          double squashX = 1.0;
          double squashY = 1.0;

          if (tb <= 0.36) {
            // Drop 1: Falling from top (-140) down to hit floorY
            final p = tb / 0.36;
            final fallCurve = Curves.easeInQuad.transform(p);
            const startY = -140.0;
            currentY = startY + (floorY - startY) * fallCurve;

            squashX = 0.85 + 0.15 * (1 - p);
            squashY = 1.18 - 0.18 * (1 - p);

            if (p > 0.90) {
              // Impact squash on floor
              squashX = 1.35;
              squashY = 0.65;
            }
          } else if (tb <= 0.68) {
            // Bounce 2: Bounces WAY HIGHER up to (floorY - 420) near top of screen
            final p = (tb - 0.36) / 0.32;
            final arc = math.sin(p * math.pi);
            currentY = floorY - 420.0 * arc;

            squashX = 1.0 - 0.22 * (1 - arc);
            squashY = 1.0 + 0.22 * (1 - arc);

            if (p > 0.90) {
              // Impact squash on floor
              squashX = 1.28;
              squashY = 0.72;
            }
          } else if (tb <= 0.90) {
            // Bounce 3: Bounces high up to (floorY - 240)
            final p = (tb - 0.68) / 0.22;
            final arc = math.sin(p * math.pi);
            currentY = floorY - 240.0 * arc;

            squashX = 1.0 - 0.14 * (1 - arc);
            squashY = 1.0 + 0.14 * (1 - arc);

            if (p > 0.90) {
              // Impact squash on floor
              squashX = 1.22;
              squashY = 0.78;
            }
          } else {
            // Final Launch UP towards targetCenterY
            final p = (tb - 0.90) / 0.10;
            currentY =
                floorY -
                (floorY - targetCenterY) * Curves.easeOutQuad.transform(p);
            squashX = 1.0;
            squashY = 1.0;
          }

          return Positioned(
            left: (size.width / 2) - 45.0,
            top: currentY - 45.0,
            width: 90.0,
            height: 90.0,
            child: IgnorePointer(
              child: Transform.scale(
              scaleX: squashX,
              scaleY: squashY,
              alignment: Alignment.bottomCenter,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    center: Alignment(-0.35, -0.35),
                    radius: 0.85,
                    colors: [
                      Color(0xFFB5F280),
                      Color(0xFF94D561),
                      Color(0xFF6AAE38),
                      Color(0xFF3F771A),
                    ],
                    stops: [0.0, 0.35, 0.75, 1.0],
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x551C4108),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Cute Eyes on Bouncing Ball
                    Positioned(
                      top: 22,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 14,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.black,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 14,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.black,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Cute smile curve on ball
                    Positioned(
                      bottom: 22,
                      child: Container(
                        width: 22,
                        height: 10,
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Color(0xFF111111),
                              width: 2.5,
                            ),
                          ),
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        } else {
          // PHASE 2: THE BALL EXPANDS AS A GROWING CIRCLE FROM THE BALL'S CENTER
          final te = ((t - phase1End) / (1.0 - phase1End)).clamp(0.0, 1.0);
          final expandCurve = Curves.easeInOutCubic.transform(te);

          final maxRadius = math.max(size.width, size.height) * 1.5;
          final currentRadius = 45.0 + (maxRadius - 45.0) * expandCurve;

          return Positioned.fill(
            child: IgnorePointer(
              child: ClipPath(
                clipper: _CircleClipper(
                  center: Offset(size.width / 2, targetCenterY),
                  radius: currentRadius,
                ),
                child: _buildTakeoverScreen(context, theme),
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildTypewriterBallOverlay(Size size) {
    final textStyle = GoogleFonts.fredoka(
      fontSize: 23,
      fontWeight: FontWeight.w700,
      color: Colors.white,
      letterSpacing: 0.6,
      shadows: const [
        Shadow(color: Color(0x601C4108), blurRadius: 14, offset: Offset(0, 3)),
        Shadow(color: Color(0x30000000), blurRadius: 6, offset: Offset(0, 2)),
      ],
    );

    // Measure exact sub-pixel X positions of every character in the text line
    final textPainter = TextPainter(
      text: TextSpan(text: _typewriterSentence, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - 40);

    final totalTextWidth = textPainter.width;
    final textLeft = (size.width - totalTextWidth) / 2;
    const textTopY = 100.0;
    const fontHeight = 30.0;
    final floorBaselineY = textTopY + fontHeight; // Text baseline floor

    final charXCenters = <double>[];
    for (int i = 0; i < _typewriterSentence.length; i++) {
      final boxes = textPainter.getBoxesForSelection(
        TextSelection(baseOffset: i, extentOffset: i + 1),
      );
      if (boxes.isNotEmpty) {
        charXCenters.add(textLeft + (boxes.first.left + boxes.first.right) / 2);
      } else {
        charXCenters.add(textLeft + i * 13.0);
      }
    }

    return AnimatedBuilder(
      animation: _typewriterController,
      builder: (context, child) {
        final t = _typewriterController.value;
        const double rollPhaseEnd =
            0.84; // 0.0 -> 0.84: Rolls slowly and smoothly
        final numChars = _typewriterSentence.length;

        double ballX;
        final ballY =
            floorBaselineY -
            24.0; // Larger 48px ball sits level on floor baseline
        double rotationAngle;
        int currentLength;

        final startX = charXCenters[0] - 22.0;
        final endX = charXCenters[numChars - 1] + 22.0;

        if (t <= rollPhaseEnd) {
          // PHASE A: Rolls slowly and smoothly along text baseline from left to right
          final rollProgress = (t / rollPhaseEnd).clamp(0.0, 1.0);
          final rollCurve = Curves.easeInOutCubic.transform(rollProgress);

          ballX = startX + (endX - startX) * rollCurve;
          rotationAngle = (ballX - startX) * 0.10;

          currentLength = 0;
          for (int i = 0; i < numChars; i++) {
            if (ballX >= charXCenters[i] - 14.0) {
              currentLength = i + 1;
            }
          }
        } else {
          // PHASE B: Sentence typed -> Rolls smoothly off the right edge of the screen!
          currentLength = numChars;
          final exitProgress = ((t - rollPhaseEnd) / (1.0 - rollPhaseEnd))
              .clamp(0.0, 1.0);
          final exitCurve = Curves.easeInQuad.transform(exitProgress);

          ballX = endX + (size.width + 70.0 - endX) * exitCurve;
          rotationAngle = (ballX - startX) * 0.10;
        }

        // Sound trigger for each character revealed
        if (currentLength > _lastSoundCharCount) {
          _lastSoundCharCount = currentLength;
          SystemSound.play(SystemSoundType.click);
        }

        // Calculate dynamic stage lighting dip & spotlight beam opacity (Deep Backstage Dimming)
        double dimOpacity = 0.0;
        if (t <= 0.12) {
          dimOpacity = (t / 0.12) * 0.82;
        } else if (t <= 0.82) {
          dimOpacity = 0.82;
        } else {
          dimOpacity = (1.0 - ((t - 0.82) / 0.18)) * 0.82;
        }
        dimOpacity = dimOpacity.clamp(0.0, 0.82);

        final liveText = _typewriterSentence.substring(0, currentLength);

        return Stack(
          children: [
            // Dramatic Stage Backstage Dimming + Moving Spotlight Following the Rolling Ball
            if (dimOpacity > 0.0)
              Positioned.fill(
                child: CustomPaint(
                  painter: StageSpotlightPainter(
                    spotlightCenter: Offset(ballX, ballY),
                    dimOpacity: dimOpacity,
                  ),
                ),
              ),

            // Live Typed Text Line sitting on floor baseline
            if (liveText.isNotEmpty)
              Positioned(
                top: textTopY,
                left: textLeft,
                width: totalTextWidth + 20,
                child: Text(
                  liveText,
                  textAlign: TextAlign.left,
                  style: textStyle,
                ),
              ),

            // Cute Larger Yellow Rolling Monster Ball (48px diameter)
            Positioned(
              left: ballX - 24.0,
              top: ballY - 24.0,
              child: Transform.rotate(
                angle: rotationAngle,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: Alignment(-0.35, -0.35),
                      radius: 0.85,
                      colors: [
                        Color(0xFFFFFDE8),
                        Color(0xFFFFEEA0),
                        Color(0xFFFCD440),
                      ],
                      stops: [0.0, 0.55, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x351C4108),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Glossy Top-Left Sheen Circle
                      Positioned(
                        top: 6,
                        left: 8,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.65),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),

                      // Cute Monster Face (Two dots + white smile)
                      Positioned(
                        bottom: 12,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Two cute eyes
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 5,
                                  height: 5.5,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF182E09),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5.5),
                                Container(
                                  width: 5,
                                  height: 5.5,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF182E09),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2.0),
                            // Cute happy white smile
                            Container(
                              width: 9,
                              height: 4.5,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.vertical(
                                  bottom: Radius.circular(5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // SCREEN 0: AGE SELECTION SCREEN
  Widget _buildAgeScreen(BuildContext context, _AgeTheme theme) {
    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null &&
            details.primaryVelocity! < -150) {
          _goToTakeoverScreen();
        }
      },
      behavior: HitTestBehavior.translucent,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),

              // Main Content
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 36.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Main Headline
                        CustomPaint(
                          painter: SunAndWavesPainter(),
                          child: const Padding(
                            padding: EdgeInsets.only(top: 14.0, bottom: 12.0),
                            child: Text(
                              '你好8月',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 108,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 0.95,
                                letterSpacing: 2.0,
                                shadows: [
                                  Shadow(
                                    color: Color(0x35143205),
                                    blurRadius: 24,
                                    offset: Offset(0, 8),
                                  ),
                                  Shadow(color: Colors.white70, blurRadius: 10),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Monster Teeth Age Selector Widget
                        MonsterAgeSelectorWidget(
                          onAgeChanged: _onAgeChanged,
                          onNext: _goToTakeover,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _lerp4Colors(Color c1, Color c2, Color c3, Color c4, double t) {
    if (t <= 0.33) {
      return Color.lerp(c1, c2, t / 0.33)!;
    } else if (t <= 0.66) {
      return Color.lerp(c2, c3, (t - 0.33) / 0.33)!;
    } else {
      return Color.lerp(c3, c4, (t - 0.66) / 0.34)!;
    }
  }

  // SCREEN 1: FULLSCREEN MONSTER TAKEOVER SCREEN (4 Emotion States + Typewriter Reveal)
  Widget _buildTakeoverScreen(BuildContext context, _AgeTheme theme) {
    final size = MediaQuery.of(context).size;

    // 4 Dynamic Emotion Background Colors: sad (Red), grumpy (Orange), silly (Green), happy (Gold)
    // Synchronized 100% with inner card theme colors!
    final bgTop = _lerp4Colors(
      const Color(0xFFFF6B55), // sad (Red)
      const Color(0xFFFF6D00), // grumpy (Orange)
      const Color(0xFF94D561), // silly (Apple Lime Green from Age Selection!)
      const Color(0xFFFFE082), // happy (Gold)
      _emotionValue,
    );

    final bgBottom = _lerp4Colors(
      const Color(0xFFE53935), // sad
      const Color(0xFFE65100), // grumpy
      const Color(0xFF3F771A), // silly (Deep Forest Green from Age Selection!)
      const Color(0xFFFFB300), // happy
      _emotionValue,
    );

    final pimpleColor = _lerp4Colors(
      const Color(0xFFFF8A65),
      const Color(0xFFFFAB91),
      const Color(0xFFB5F280), // Glowing lime accent
      const Color(0xFFFFE082),
      _emotionValue,
    );

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [bgTop, bgBottom],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Sparkles/Bubble Dots Accent
          Positioned.fill(
            child: CustomPaint(
              painter: BiboPimplesPainter(
                pimpleColor: pimpleColor.withValues(alpha: 0.35),
              ),
            ),
          ),

          // 1. Header Title & Typewriter Text Reveal (100% Visible!)
          Positioned(
            top: 75,
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'How was your day?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.fredoka(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.8,
                    shadows: const [
                      Shadow(
                        color: Color(0x40000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                if (_typedText.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    _typedText,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.fredoka(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.95),
                      letterSpacing: 0.5,
                      shadows: const [
                        Shadow(
                          color: Color(0x50000000),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Compact Floating 3D Emotion Card
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 60),
              child: _CompactEmotionCard(
                emotionValue: _emotionValue,
                onChanged: (val) {
                  setState(() => _emotionValue = val);
                },
              ),
            ),
          ),

          // White Bouncing Ball Typewriter Overlay (if active)
          if (_isTypewriterActive) _buildTypewriterBallOverlay(size),

          // Top-Right Sign Up Button
          Positioned(
            top: 24,
            right: 20,
            child: SafeArea(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder:
                            (context, animation, secondaryAnimation) =>
                                AuthModeSelectionScreen(
                                  onBeginJourney: () {
                                    Navigator.of(context).pushReplacement(
                                      PageRouteBuilder(
                                        pageBuilder: (context, animation, secondaryAnimation) =>
                                            const GameMap1913Screen(),
                                        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                                            FadeTransition(opacity: animation, child: child),
                                        transitionDuration: const Duration(milliseconds: 600),
                                      ),
                                    );
                                  },
                                ),
                        transitionsBuilder: (
                          context,
                          animation,
                          secondaryAnimation,
                          child,
                        ) {
                          return FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(
                              scale:
                                  Tween<double>(
                                    begin: 0.95,
                                    end: 1.0,
                                  ).animate(
                                    CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeOutCubic,
                                    ),
                                  ),
                              child: child,
                            ),
                          );
                        },
                        transitionDuration: const Duration(
                          milliseconds: 400,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.75),
                        width: 1.6,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_add_alt_1_rounded,
                            size: 15,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'SIGN UP',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Top Back Navigation Button
          Positioned(
            top: 24,
            left: 20,
            child: SafeArea(
              child: GestureDetector(
                onTap: _goToAgeSelection,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),

          // Bottom Swipe Up Prompt
          Positioned(
            bottom: 22,
            child: Opacity(
              opacity: 0.9,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.keyboard_arrow_up_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  Text(
                    'Swipe Up for Level Map',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // SCREEN 2: DUOLINGO-STYLE VIDEO CALL LEVEL MAP SCREEN (Custom Color Palette)
  Widget _buildRoleScreen(BuildContext context, _AgeTheme theme) {
    final size = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: _waterWaveController,
      builder: (context, child) {
        return Stack(
          children: [
            // Moving Realistic Water Background (No lines, smooth organic waves & caustics)
            Positioned.fill(
              child: CustomPaint(
                painter: RealisticMovingWaterPainter(
                  animationValue: _waterWaveController.value,
                ),
              ),
            ),

            // Main Screen Content
            SafeArea(
              top: false,
              bottom: false,
              child: Column(
                children: [
                  // 1. Top Header Stats Bar (Flag, Streak 🔥, Gems 💎, Power ⚡)
                  _buildDuolingoHeaderStats(),

                  // 2. Main Scrollable Stepping Stone Path Map
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _mapScrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          // Unit Header Card (SECTION 1, UNIT 1)
                          _buildDuolingoUnitBanner(size),

                          const SizedBox(height: 16),

                          // 3D Stepping Stone Path
                          _buildSteppingStonePath(size),
                        ],
                      ),
                    ),
                  ),

                  // 3. Bottom Navigation Bar
                  _buildDuolingoBottomNavBar(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _completeLevelAndUnlockNext(int levelIndex, [Offset? tapOffset, Color? buttonColor]) {
    debugPrint("_completeLevelAndUnlockNext called for stageIndex=$levelIndex");
    SystemSound.play(SystemSoundType.click);

    final effectiveChapters = _chapters.isNotEmpty
        ? _chapters
        : [
            LearningChapter(id: 'Netaji', name: 'Netaji', levels: []),
            LearningChapter(id: 'Success', name: 'Success', levels: []),
          ];

    if (levelIndex >= effectiveChapters.length) return;
    final chapter = effectiveChapters[levelIndex];
    final bool isLocked = levelIndex > _unlockedStageIndex;

    if (isLocked) {
      HapticFeedback.heavyImpact();
      final prevName = levelIndex > 0 ? effectiveChapters[levelIndex - 1].name : 'previous stage';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🔒 Complete $prevName first to unlock ${chapter.name}!'),
          backgroundColor: const Color(0xFF2E1C12),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final origin = tapOffset ??
        Offset(
          MediaQuery.of(context).size.width / 2,
          MediaQuery.of(context).size.height / 2,
        );
    final initialColor = buttonColor ?? const Color(0xFF94D561);

    // Clicking an unlocked stage node triggers the Smoke Bomb Time-Travel Transition to 1913 Game Map
    Navigator.of(context).push(
      SmokeBombPageRoute(
        page: GameMap1913Screen(chapterId: chapter.id),
        originOffset: origin,
        buttonColor: initialColor,
        vintageMapColor: const Color(0xFFF4E8C1),
      ),
    ).then((_) {
      _loadDynamicChapters();
    });
  }

  Widget _buildEmergingLevelStone({
    required int levelIndex,
    required double top,
    required double left,
    required double animVal,
  }) {
    return Positioned(
      top: top,
      left: left,
      child: AnimatedBuilder(
        animation: _mapScrollController,
        builder: (context, child) {
          double scrollOffset = 0.0;
          if (_mapScrollController.hasClients) {
            scrollOffset = _mapScrollController.offset;
          }

          final double viewportHeight = MediaQuery.of(context).size.height;
          final double stoneScreenY = top - scrollOffset;
          final double distFromBottom = viewportHeight - stoneScreenY;

          // Smooth emergence ratio as stone enters viewport from bottom wave pool
          final double emergenceRatio = (distFromBottom / 180.0).clamp(0.0, 1.0);
          final double scale = 0.50 + (0.50 * emergenceRatio);
          final double translateY = (1.0 - emergenceRatio) * 40.0;
          final double opacity = (0.20 + (0.80 * emergenceRatio)).clamp(0.0, 1.0);

          return Opacity(
            opacity: opacity,
            child: Transform.translate(
              offset: Offset(0, translateY),
              child: Transform.scale(
                scale: scale,
                child: _build3DSteppingStone(
                  levelIndex: levelIndex,
                  unlockAnimValue: _animatingUnlockingIndex == levelIndex
                      ? animVal
                      : 0.0,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSteppingStonePath(Size size) {
    final w = size.width;

    return AnimatedBuilder(
      animation: unlockAnimController,
      builder: (context, child) {
        final animVal = CurvedAnimation(
          parent: unlockAnimController,
          curve: Curves.easeInOutCubic,
        ).value;

        final effectiveChapters = _chapters.isNotEmpty
            ? _chapters
            : [
                LearningChapter(id: 'Netaji', name: 'Netaji', levels: []),
                LearningChapter(id: 'Success', name: 'Success', levels: []),
              ];

        final stageCount = effectiveChapters.length;
        const double verticalSpacing = 140.0;
        final double totalPathHeight = math.max(750.0, (stageCount * verticalSpacing) + 260.0);

        final xMultipliers = [0.48, 0.72, 0.54, 0.36, 0.18, 0.36, 0.54, 0.72];

        return SizedBox(
          height: totalPathHeight,
          width: w,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Top Hanging Creamy Drip Banner Accent
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 110,
                child: CustomPaint(
                  painter: CreamyDripsPainter(
                    creamColor: const Color(0xFFFFF8E7),
                    isHangingDown: true,
                  ),
                ),
              ),

              // Dynamic Stages from Discovered Chapters
              for (int i = 0; i < stageCount; i++)
                _buildEmergingLevelStone(
                  levelIndex: i,
                  top: 22.0 + (i * verticalSpacing),
                  left: (w * xMultipliers[i % xMultipliers.length]) - 36.0,
                  animVal: animVal,
                ),

              // Side Road Bumps
              Positioned(
                top: 180,
                right: 35,
                child: SideRoadBumpWidget(
                  bumpColor: const Color(0xFFFF8A65),
                  bumpType: SideRoadBumpType.buffAltar,
                  label: '2x XP',
                  sublabel: 'BUFF',
                  icon: Icons.flash_on_rounded,
                ),
              ),

              Positioned(
                top: 360,
                left: 35,
                child: SideRoadBumpWidget(
                  bumpColor: const Color(0xFF78C850),
                  bumpType: SideRoadBumpType.achievement,
                  label: '7 DAYS',
                  sublabel: 'STREAK',
                  icon: Icons.local_fire_department_rounded,
                ),
              ),

              // Bottom Creamy Drip Pool (Rendered IN FRONT of lower stones)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 125,
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: CreamyDripsPainter(
                      creamColor: const Color(0xFFFFF8E7),
                      isHangingDown: false,
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

  Widget _buildStageHoverCard(
    LearningChapter chapter,
    int stageIndex,
    bool isLocked,
    bool isCompleted,
    String? coverImage,
  ) {
    return Container(
      width: 170,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF13300C), // Deep Forest Green Panel
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isLocked ? const Color(0xFF757575) : const Color(0xFFFFD166),
          width: 1.8,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: double.infinity,
              height: 95,
              child: coverImage != null
                  ? Image.asset(
                      coverImage,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Container(
                        color: const Color(0xFF0D180B),
                        child: const Icon(Icons.movie_filter_rounded, color: Color(0xFFFFD166), size: 36),
                      ),
                    )
                  : Container(
                      color: const Color(0xFF0D180B),
                      child: const Icon(Icons.movie_filter_rounded, color: Color(0xFFFFD166), size: 36),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            chapter.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Color(0xFFFFD166),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            isLocked
                ? '🔒 LOCKED'
                : isCompleted
                    ? '✓ ${chapter.levels.length} Episodes Completed'
                    : '▶ ${chapter.levels.length} Episodes',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: isLocked
                  ? const Color(0xFFAAAAAA)
                  : isCompleted
                      ? const Color(0xFF78C850)
                      : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _build3DSteppingStone({
    required int levelIndex,
    required double unlockAnimValue,
  }) {
    final bool isCompleted = levelIndex < _unlockedLevelIndex;
    final bool isActive =
        levelIndex == _unlockedLevelIndex && _animatingUnlockingIndex == null;
    final bool isUnlocking = _animatingUnlockingIndex == levelIndex;
    final bool isLocked = levelIndex > _unlockedLevelIndex && !isUnlocking;
    final bool isBossNode = (levelIndex + 1) % 5 == 0;
    final bool isHovered = _hoveredLevelIndex == levelIndex;

    final effectiveChapters = _chapters.isNotEmpty
        ? _chapters
        : [
            LearningChapter(id: 'Netaji', name: 'Netaji', levels: []),
            LearningChapter(id: 'Success', name: 'Success', levels: []),
          ];
    final chapter = levelIndex < effectiveChapters.length ? effectiveChapters[levelIndex] : null;
    final coverImage = chapter != null ? _stageCoverImages[chapter.id] : null;

    Color topColor;
    Color bevelColor;
    Color borderColor;

    if (isBossNode) {
      if (isHovered || isCompleted || isActive) {
        topColor = const Color(0xFFFFAB00); // Ultra-Vibrant Electric Amber Gold
        bevelColor = const Color(0xFFC67100);
        borderColor = const Color(0xFFFFFFFF);
      } else if (isUnlocking) {
        topColor = Color.lerp(
          const Color(0xFF2C3539),
          const Color(0xFFFFAB00),
          unlockAnimValue,
        )!;
        bevelColor = Color.lerp(
          const Color(0xFF1A2124),
          const Color(0xFFC67100),
          unlockAnimValue,
        )!;
        borderColor = const Color(0xFFFFD54F);
      } else {
        topColor = const Color(0xFF2C3539); // Dark Cyber Obsidian
        bevelColor = const Color(0xFF1A2124);
        borderColor = const Color(0xFFFFAB00); // Gold Bezel Trim
      }
    } else {
      if (isHovered) {
        // Smoothly morph to corresponding bump color on hover!
        if (levelIndex < 5) {
          topColor = const Color(0xFFFF8A65); // Bump 3 Coral Orange
          bevelColor = const Color(0xFFD84315);
        } else if (levelIndex < 10) {
          topColor = const Color(0xFF78C850); // Bump 2 Fresh Green
          bevelColor = const Color(0xFF46B300);
        } else {
          topColor = const Color(0xFFF4C95D); // Bump 1 Warm Gold
          bevelColor = const Color(0xFFC79500);
        }
        borderColor = Colors.white;
      } else if (isCompleted || isActive) {
        topColor = const Color(0xFF58CC02); // Vibrant Neon Emerald
        bevelColor = const Color(0xFF46B300);
        borderColor = Colors.white;
      } else if (isUnlocking) {
        topColor = Color.lerp(
          const Color(0xFF2C3539),
          const Color(0xFF58CC02),
          unlockAnimValue,
        )!;
        bevelColor = Color.lerp(
          const Color(0xFF1A2124),
          const Color(0xFF46B300),
          unlockAnimValue,
        )!;
        borderColor = Colors.white;
      } else {
        // Locked Cyber-Glass Obsidian Block
        topColor = const Color(0xFF2C3539);
        bevelColor = const Color(0xFF1A2124);
        borderColor = Colors.white.withValues(alpha: 0.60);
      }
    }

    final double stoneWidth = isBossNode ? 90.0 : 76.0;
    final double stoneHeight = isBossNode ? 90.0 : 76.0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoveredLevelIndex = levelIndex),
      onExit: (_) => setState(() => _hoveredLevelIndex = null),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (details) => _completeLevelAndUnlockNext(
          levelIndex,
          details.globalPosition,
          topColor,
        ),
        child: AnimatedScale(
          scale: isHovered ? (isBossNode ? 1.28 : 1.16) : 1.0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dynamic COVER_IMG Preview on Hover OR XP Badge
              if (isHovered && chapter != null)
                _buildStageHoverCard(chapter, levelIndex, isLocked, isCompleted, coverImage)
              else if (isActive || isBossNode)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: isBossNode
                        ? const Color(0xFFFFAB00)
                        : const Color(0xFF183018),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: isBossNode ? const Color(0x60FFAB00) : const Color(0x30000000),
                        blurRadius: isBossNode ? 10 : 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    isBossNode ? '+200 XP' : '+50 XP',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: isBossNode ? const Color(0xFF2E1A00) : Colors.white,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),

              // 3D Stone Block with Smooth Animated Container Color Morphing
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                width: stoneWidth,
                height: stoneHeight,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: const Color(0xFF183018).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(isBossNode ? 28 : 22),
                  border: Border.all(
                    color: borderColor,
                    width: isBossNode ? 3.0 : 2.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isHovered
                          ? topColor.withValues(alpha: isBossNode ? 0.75 : 0.55)
                          : const Color(0xFF102010).withValues(alpha: 0.35),
                      blurRadius: isHovered ? (isBossNode ? 34 : 24) : 14,
                      spreadRadius: isHovered && isBossNode ? 6 : 0,
                      offset: isHovered ? const Offset(0, 10) : const Offset(0, 7),
                    ),
                    if (isActive || isHovered || isBossNode)
                      BoxShadow(
                        color: topColor.withValues(alpha: isBossNode ? 0.75 : 0.65),
                        blurRadius: isBossNode ? 24 : 20,
                        spreadRadius: isBossNode ? 4 : 3,
                      ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      width: stoneWidth - 4,
                      height: stoneHeight - 4,
                      decoration: BoxDecoration(
                        color: bevelColor,
                        borderRadius: BorderRadius.circular(isBossNode ? 26 : 20),
                      ),
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutCubic,
                            width: stoneWidth - 4,
                            height: stoneHeight - 14,
                            decoration: BoxDecoration(
                              color: topColor,
                              borderRadius: BorderRadius.circular(isBossNode ? 25 : 19),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.45),
                                width: 1.5,
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color.lerp(topColor, Colors.white, 0.45)!,
                                  topColor,
                                ],
                              ),
                            ),
                            child: Center(
                              child: isCompleted
                                  ? const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 36,
                                    )
                                  : isActive
                                  ? const Icon(
                                      Icons.videocam_rounded,
                                      color: Colors.white,
                                      size: 32,
                                    )
                                  : isUnlocking
                                  ? Opacity(
                                      opacity: unlockAnimValue,
                                      child: const Icon(
                                        Icons.videocam_rounded,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.lock_outline_rounded,
                                      color: Colors.white70,
                                      size: 26,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 3-Star Mastery Ratings Sitting Below Completed Nodes
              if (isCompleted)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.star_rounded, color: Color(0xFFFFD166), size: 14),
                      Icon(Icons.star_rounded, color: Color(0xFFFFD166), size: 14),
                      Icon(Icons.star_rounded, color: Color(0xFFFFD166), size: 14),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDuolingoHeaderStats() {
    final topInset = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.only(
        top: math.max(topInset, 8.0),
        bottom: 8,
        left: 8,
        right: 8,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFFFF8E7), // Popup #FFF8E7
        border: Border(
          bottom: BorderSide(color: Color(0xFFD5E2BC), width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x101F3B16),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 🔙 Back to Monster Character Button
          Tooltip(
            message: 'Back to Character',
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                _goToTakeoverScreen();
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF78C850).withValues(alpha: 0.20),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF78C850).withValues(alpha: 0.50),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.arrow_upward_rounded,
                  color: Color(0xFF1F3B16),
                  size: 16,
                ),
              ),
            ),
          ),

          // 🧠 12 Skills
          Flexible(
            child: _buildStatHeaderColumn(
              icon: '🧠',
              value: '12',
              label: 'Skills',
              valueColor: const Color(0xFF8E44AD),
            ),
          ),

          // 🔥 7 Streak
          Flexible(
            child: _buildStatHeaderColumn(
              icon: '🔥',
              value: '7',
              label: 'Streak',
              valueColor: const Color(0xFFFF8A65),
            ),
          ),

          // ⭐ 1,240 XP
          Flexible(
            child: _buildStatHeaderColumn(
              icon: '⭐',
              value: '1,240',
              label: 'XP',
              valueColor: const Color(0xFFF4C95D),
            ),
          ),

          // ❤️ 5 Attempts
          Flexible(
            child: _buildStatHeaderColumn(
              icon: '❤️',
              value: '5',
              label: 'Attempts',
              valueColor: const Color(0xFFFF5252),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatHeaderColumn({
    required String icon,
    required String value,
    required String label,
    required Color valueColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 3),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F3B16),
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDuolingoUnitBanner(Size size) {
    final effectiveChapters = _chapters.isNotEmpty
        ? _chapters
        : [
            LearningChapter(id: 'Netaji', name: 'Netaji', levels: []),
            LearningChapter(id: 'Success', name: 'Success', levels: []),
          ];

    final activeChapter = _unlockedStageIndex < effectiveChapters.length
        ? effectiveChapters[_unlockedStageIndex]
        : effectiveChapters.first;

    final stageNumber = _unlockedStageIndex + 1;
    final stageTitle = activeChapter.name;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF78C850), // Fresh Primary Leaf Green Outer Block
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF5BA33A), width: 2.0),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF46B300),
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Inner Complementary Deep Forest Green Section #13300C
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF13300C), // Deep Forest Green Inner Panel
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SECTION 1, STAGE $stageNumber',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFFFD166), // Warm Yellow Accent
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$stageTitle: Where there is courage, there is a way.',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Guidebook Notebook button in Warm Yellow #FFD166
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD166),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.import_contacts_rounded,
                      color: Color(0xFF13300C),
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDuolingoNode({required IconData icon, bool isActive = false}) {
    return Container(
      width: 66,
      height: 66,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF58CC02),
        boxShadow: const [
          BoxShadow(color: Color(0xFF46B300), offset: Offset(0, 7)),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glossy Top Sheen
          Positioned(
            top: 4,
            left: 10,
            right: 10,
            child: Container(
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.32),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
            ),
          ),

          // Center Icon
          Icon(icon, color: Colors.white, size: 32),
        ],
      ),
    );
  }

  Widget _buildDuolingoBottomNavBar() {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final double safeBottomPadding = math.max(bottomInset, 12.0);

    final navItems = [
      {'icon': Icons.home_rounded, 'color': const Color(0xFF78C850), 'label': 'Home'},
      {'icon': Icons.shield_rounded, 'color': const Color(0xFFF4C95D), 'label': 'Quests'},
      {'icon': Icons.leaderboard_rounded, 'color': const Color(0xFFF08A5D), 'label': 'Leaderboard'},
      {'icon': Icons.favorite_rounded, 'color': const Color(0xFFFF4B4B), 'label': 'Hearts'},
      {'icon': Icons.videocam_rounded, 'color': const Color(0xFF78C850), 'label': 'Call'},
      {'icon': Icons.more_horiz_rounded, 'color': const Color(0xFF1F3B16), 'label': 'More'},
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: 10,
        bottom: safeBottomPadding,
        left: 12,
        right: 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9EE), // Rich creamy vanilla background
        border: const Border(
          top: BorderSide(color: Color(0xFFD5E2BC), width: 1.5),
        ),
        boxShadow: [
          // Soft subtle top shadow
          BoxShadow(
            color: const Color(0xFF1F3B16).withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(navItems.length, (index) {
          final item = navItems[index];
          final bool isSelected = _activeNavIndex == index;
          final Color itemColor = item['color'] as Color;

          return Flexible(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                if (index == 2) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const LeaderboardScreen(),
                    ),
                  );
                  return;
                }
                setState(() => _activeNavIndex = index);
              },
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.symmetric(
                  horizontal: isSelected ? 14 : 8,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? itemColor.withValues(alpha: 0.18)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? itemColor.withValues(alpha: 0.40)
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item['icon'] as IconData,
                      color: isSelected
                          ? (index == 2 || index == 5
                              ? itemColor
                              : (itemColor == const Color(0xFF78C850)
                                  ? const Color(0xFF46991D)
                                  : itemColor))
                          : const Color(0xFF637856),
                      size: isSelected ? 27 : 25,
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 5),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: index == 2 || index == 5
                              ? itemColor
                              : (itemColor == const Color(0xFF78C850)
                                  ? const Color(0xFF2C6010)
                                  : itemColor),
                          letterSpacing: 0.4,
                        ),
                        child: Text(item['label'] as String),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildRoleCard({
    required String title,
    required String subtitle,
    required String emoji,
    required String roleKey,
  }) {
    final bool isSelected = _selectedRole == roleKey;

    return InkWell(
      onTap: () => setState(() => _selectedRole = roleKey),
      borderRadius: BorderRadius.circular(32),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 170,
        height: 210,
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white
              : Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white54,
            width: isSelected ? 3.0 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? Colors.black38 : Colors.black12,
              blurRadius: isSelected ? 24 : 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              isSelected ? '✓ $title' : title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isSelected ? const Color(0xFF1C4108) : Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isSelected
                    ? const Color(0xFF1C4108).withValues(alpha: 0.7)
                    : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TopoLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.12);

    final xRatios = [0.42, 0.52, 0.63, 0.74, 0.85, 0.94];

    for (var xRatio in xRatios) {
      final startX = size.width * xRatio;
      final path = Path();
      path.moveTo(startX, 0);
      path.cubicTo(
        startX - size.width * 0.03,
        size.height * 0.14,
        startX + size.width * 0.03,
        size.height * 0.26,
        startX - size.width * 0.007,
        size.height * 0.4,
      );
      path.cubicTo(
        startX - size.width * 0.035,
        size.height * 0.66,
        startX + size.width * 0.02,
        size.height * 0.74,
        startX + size.width * 0.02,
        size.height,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SunAndWavesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final whitePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()..color = Colors.white;

    // 1. Sun Motif above '好' (Centered above title)
    final sunCenter = Offset(size.width * 0.44, -4);
    final sunPath = Path()
      ..addArc(Rect.fromCircle(center: sunCenter, radius: 18), -3.14, 3.14);
    canvas.drawPath(sunPath, whitePaint);

    // Sun Rays
    canvas.drawLine(
      Offset(sunCenter.dx, sunCenter.dy - 24),
      Offset(sunCenter.dx, sunCenter.dy - 32),
      whitePaint,
    );
    canvas.drawLine(
      Offset(sunCenter.dx - 18, sunCenter.dy - 16),
      Offset(sunCenter.dx - 26, sunCenter.dy - 24),
      whitePaint,
    );
    canvas.drawLine(
      Offset(sunCenter.dx + 18, sunCenter.dy - 16),
      Offset(sunCenter.dx + 26, sunCenter.dy - 24),
      whitePaint,
    );

    // 2. Water Wave Squiggles Underneath
    final wave1 = Path()
      ..moveTo(size.width * 0.05, size.height + 8)
      ..cubicTo(
        size.width * 0.12,
        size.height + 16,
        size.width * 0.18,
        size.height,
        size.width * 0.28,
        size.height + 8,
      );

    final wave2 = Path()
      ..moveTo(size.width * 0.65, size.height + 8)
      ..cubicTo(
        size.width * 0.75,
        size.height + 16,
        size.width * 0.85,
        size.height,
        size.width * 0.95,
        size.height + 8,
      );

    canvas.drawPath(wave1, whitePaint);
    canvas.drawPath(wave2, whitePaint);

    // 3. Floating Bubble Dots
    canvas.drawCircle(
      Offset(size.width * 0.32, size.height + 10),
      3.5,
      dotPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.38, size.height + 14),
      2.5,
      dotPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.60, size.height + 6),
      3.0,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// MONSTER AGE SELECTOR WIDGET
// ─────────────────────────────────────────────────────────────────────────────
class MonsterAgeSelectorWidget extends StatefulWidget {
  final void Function(double age) onAgeChanged;
  final VoidCallback? onNext;

  const MonsterAgeSelectorWidget({
    super.key,
    required this.onAgeChanged,
    this.onNext,
  });

  @override
  State<MonsterAgeSelectorWidget> createState() =>
      _MonsterAgeSelectorWidgetState();
}

class _MonsterAgeSelectorWidgetState extends State<MonsterAgeSelectorWidget>
    with SingleTickerProviderStateMixin {
  double _currentAgeDouble = 7.0;
  int get _selectedAge => _currentAgeDouble.round().clamp(_minAge, _maxAge);
  final int _minAge = 3;
  final int _maxAge = 15;

  late AnimationController _animController;
  double _animStartAge = 7.0;
  double _animEndAge = 7.0;

  @override
  void initState() {
    super.initState();
    _animController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 300),
        )..addListener(() {
          final t = Curves.easeOutCubic.transform(_animController.value);
          setState(() {
            _currentAgeDouble =
                _animStartAge + (_animEndAge - _animStartAge) * t;
            widget.onAgeChanged(_currentAgeDouble);
          });
        });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _animateToAge(int targetAge) {
    final clampedTarget = targetAge.clamp(_minAge, _maxAge).toDouble();
    _animStartAge = _currentAgeDouble;
    _animEndAge = clampedTarget;
    _animController.forward(from: 0);
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    final deltaAge = -details.delta.dx / 40.0;
    setState(() {
      _currentAgeDouble = (_currentAgeDouble + deltaAge).clamp(
        _minAge.toDouble(),
        _maxAge.toDouble(),
      );
      widget.onAgeChanged(_currentAgeDouble);
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    _animateToAge(_selectedAge);
  }

  @override
  Widget build(BuildContext context) {
    final theme = _lerpedTheme(_currentAgeDouble);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      width: 480,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.cardTop,
            // Mid-diagonal shimmer accent
            Color.lerp(theme.cardTop, Colors.white, 0.12)!,
            theme.cardBottom,
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
        borderRadius: BorderRadius.circular(38),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor,
            blurRadius: 44,
            offset: const Offset(0, 22),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: theme.accentDark.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Corner Organic White Accent Details
          Positioned(
            top: -15,
            right: -15,
            child: Container(
              width: 85,
              height: 85,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 45,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: -20,
            left: 20,
            child: Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Main Card Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Question Header
                const Text(
                  'Select Your Age',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Color(0x351C4108),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Big Expressive Cartoon Eyes & Eyebrows
                BlinkingEyesWidget(accentDark: theme.accentDark),
                const SizedBox(height: 12),

                // Smiling Mouth Cavity
                AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeInOut,
                  height: 180,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [theme.mouthTop, theme.mouthBottom],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(36),
                      topRight: Radius.circular(36),
                      bottomLeft: Radius.elliptical(260, 110),
                      bottomRight: Radius.elliptical(260, 110),
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.45),
                      width: 2.0,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final containerWidth = constraints.maxWidth;
                      final centerX = containerWidth / 2;
                      const double toothSpacing = 40.0;

                      return GestureDetector(
                        onHorizontalDragUpdate: _onHorizontalDragUpdate,
                        onHorizontalDragEnd: _onHorizontalDragEnd,
                        behavior: HitTestBehavior.opaque,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(36),
                            topRight: Radius.circular(36),
                            bottomLeft: Radius.elliptical(260, 110),
                            bottomRight: Radius.elliptical(260, 110),
                          ),
                          child: Stack(
                            alignment: Alignment.topCenter,
                            clipBehavior: Clip.none,
                            children: [
                              // Non-active teeth first
                              for (
                                int age = _minAge;
                                age <= _maxAge;
                                age++
                              ) ...[
                                if ((age - _currentAgeDouble).abs() > 0.5 &&
                                    (age - _currentAgeDouble).abs() <= 5.5)
                                  _buildToothItem(
                                    age,
                                    centerX,
                                    toothSpacing,
                                    theme,
                                  ),
                              ],
                              // Active center tooth on top
                              for (
                                int age = _minAge;
                                age <= _maxAge;
                                age++
                              ) ...[
                                if ((age - _currentAgeDouble).abs() <= 0.5)
                                  _buildToothItem(
                                    age,
                                    centerX,
                                    toothSpacing,
                                    theme,
                                  ),
                              ],
                              // Subtitle "YEARS OLD"
                              Positioned(
                                bottom: 12,
                                child: Text(
                                  'YEARS OLD',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),

                // Bottom Action Control Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => _animateToAge(_selectedAge - 1),
                      icon: const Icon(
                        Icons.arrow_back_ios_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                        padding: const EdgeInsets.all(10),
                      ),
                    ),
                    Text(
                      '$_selectedAge Years',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _animateToAge(_selectedAge + 1),
                      icon: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                        padding: const EdgeInsets.all(10),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Scroll Up Prompt Indicator (Clean text only, no capsule pill container or border)
                GestureDetector(
                  onTap: () => widget.onNext?.call(),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.keyboard_arrow_up_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Swipe Up to Continue',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white.withValues(alpha: 0.95),
                            letterSpacing: 0.4,
                            shadows: const [
                              Shadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _getToothWidth(double ageVal) {
    final double dist = (ageVal - _currentAgeDouble).abs();
    return (58.0 - dist * 5.0).clamp(34.0, 58.0);
  }

  double _calculateAttachedToothX(int age, double centerX) {
    final int baseInt = _currentAgeDouble.floor().clamp(_minAge, _maxAge);
    final double frac = _currentAgeDouble - baseInt;

    double centerOffsetFromMin = 0.0;
    for (int k = _minAge; k < baseInt; k++) {
      centerOffsetFromMin += _getToothWidth(k.toDouble());
    }
    centerOffsetFromMin += frac * _getToothWidth(baseInt.toDouble());
    centerOffsetFromMin += _getToothWidth(_currentAgeDouble) / 2.0;

    final double minAgeLeftX = centerX - centerOffsetFromMin;

    double targetLeftX = minAgeLeftX;
    for (int k = _minAge; k < age; k++) {
      targetLeftX += _getToothWidth(k.toDouble());
    }

    return targetLeftX;
  }

  Widget _buildToothItem(
    int age,
    double centerX,
    double toothSpacing,
    _AgeTheme theme,
  ) {
    final double signedOffset = age - _currentAgeDouble;
    final double distance = signedOffset.abs();
    final bool isSelected = distance < 0.5;

    final double toothWidth = _getToothWidth(age.toDouble());
    final double toothHeight = (105.0 - distance * 15.0).clamp(38.0, 105.0);
    final double fontSize = (28.0 - distance * 2.2).clamp(15.0, 28.0);

    final double posX = _calculateAttachedToothX(age, centerX);

    final double rotateY = (-signedOffset * 0.13).clamp(-0.45, 0.45);
    final double translateZ = (25.0 - distance * distance * 15.0).clamp(
      -90.0,
      25.0,
    );
    final double opacity = (1.0 - distance * 0.08).clamp(0.60, 1.0);

    final matrix = Matrix4.identity()
      ..setEntry(3, 2, 0.0022)
      ..translate(0.0, 0.0, translateZ)
      ..rotateY(rotateY);

    return Positioned(
      left: posX,
      top: -8.0,
      width: toothWidth,
      height: toothHeight,
      child: Opacity(
        opacity: opacity,
        child: Transform(
          transform: matrix,
          alignment: Alignment.topCenter,
          child: GestureDetector(
            onTap: () => _animateToAge(age),
            child: Container(
              width: toothWidth,
              height: toothHeight,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isSelected
                      ? [Colors.white, const Color(0xFFFAFDFA)]
                      : [const Color(0xFFE4EBDC), const Color(0xFFD5DFCC)],
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(toothWidth * 0.45),
                ),
                border: Border.all(
                  color: isSelected
                      ? Colors.white
                      : Colors.black.withValues(alpha: 0.08),
                  width: isSelected ? 2.0 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? Colors.black.withValues(alpha: 0.45)
                        : Colors.black.withValues(alpha: 0.20),
                    blurRadius: isSelected ? 18.0 : 4.0,
                    offset: Offset(0, isSelected ? 8.0 : 2.0),
                  ),
                  if (isSelected)
                    BoxShadow(
                      color: theme.toothGlow.withValues(alpha: 0.65),
                      blurRadius: 22.0,
                      spreadRadius: 2.0,
                    ),
                ],
              ),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: toothHeight * 0.12),
                  child: Text(
                    '$age',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w900,
                      color: isSelected ? theme.accentDark : theme.toothText,
                      shadows: isSelected
                          ? const [
                              Shadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BLINKING EYES WIDGET (theme-aware)
// ─────────────────────────────────────────────────────────────────────────────
class BlinkingEyesWidget extends StatefulWidget {
  final Color accentDark;
  const BlinkingEyesWidget({super.key, required this.accentDark});

  @override
  State<BlinkingEyesWidget> createState() => _BlinkingEyesWidgetState();
}

class _BlinkingEyesWidgetState extends State<BlinkingEyesWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;
  Timer? _blinkTimer;
  Offset _eyeOffset = Offset.zero;

  void _onMouseMove(PointerHoverEvent event) {
    try {
      final RenderBox? box = context.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return;
      final local = box.globalToLocal(event.position);
      final cx = box.size.width / 2;
      final cy = box.size.height / 2;
      final dx = local.dx - cx;
      final dy = local.dy - cy;
      final dist = (dx * dx + dy * dy);
      if (dist < 0.01) return;
      final len = math.sqrt(dist);
      final mag = len < 7.0 ? len : 7.0;
      final nx = dx / len * mag;
      final ny = dy / len * mag;
      final clamped = Offset(nx, ny);
      if ((clamped - _eyeOffset).distance > 0.3) {
        setState(() => _eyeOffset = clamped);
      }
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    );

    _blinkAnimation = Tween<double>(begin: 1.0, end: 0.08).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );

    _blinkTimer = Timer.periodic(const Duration(milliseconds: 3500), (
      timer,
    ) async {
      if (mounted) {
        await _blinkController.forward();
        await _blinkController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: _onMouseMove,
      child: AnimatedBuilder(
        animation: _blinkAnimation,
        builder: (context, child) {
          final double scaleY = _blinkAnimation.value;
          const specFrameColor = Color(0xFF2C1B54); // Deep Navy Purple Spectacle Frame

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Curved Eyebrows Row above Spectacles
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomPaint(
                    size: const Size(44, 14),
                    painter: _EyebrowPainter(color: widget.accentDark),
                  ),
                  const SizedBox(width: 42),
                  CustomPaint(
                    size: const Size(44, 14),
                    painter: _EyebrowPainter(color: widget.accentDark),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Spectacle Lenses + Connected Bridge Row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left Spectacle Eye
                  Transform.scale(
                    scaleY: scaleY,
                    alignment: Alignment.center,
                    child: _buildSpectacleEye(isLeft: true, eyeOffset: _eyeOffset, frameColor: specFrameColor),
                  ),

                  // Spectacle Bridge Bar + Nostril Holes
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Spectacle Bridge connecting the two round frames
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: CustomPaint(
                          size: const Size(26, 12),
                          painter: _SpectacleBridgePainter(color: specFrameColor),
                        ),
                      ),
                      // Nostrils below bridge
                      Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 6,
                              decoration: BoxDecoration(
                                color: widget.accentDark.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 8,
                              height: 6,
                              decoration: BoxDecoration(
                                color: widget.accentDark.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Right Spectacle Eye
                  Transform.scale(
                    scaleY: scaleY,
                    alignment: Alignment.center,
                    child: _buildSpectacleEye(isLeft: false, eyeOffset: _eyeOffset, frameColor: specFrameColor),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSpectacleEye({
    required bool isLeft,
    required Offset eyeOffset,
    required Color frameColor,
  }) {
    return Container(
      width: 66,
      height: 66,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: frameColor, width: 5.5),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Center(
        child: Transform.translate(
          offset: eyeOffset,
          child: Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Color(0xFF1565C0), // Rich Royal Blue Iris (matching reference spec image!)
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Color(0xFF0D0D0D), // Deep Black Pupil
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 3,
                      left: 3,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Draws the arched bridge linking the left and right spectacle frames
class _SpectacleBridgePainter extends CustomPainter {
  final Color color;
  const _SpectacleBridgePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(size.width / 2, -2, size.width, size.height * 0.7);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SpectacleBridgePainter oldDelegate) => oldDelegate.color != color;
}

// Draws a smooth upward-arched eyebrow with a theme-aware color
class _EyebrowPainter extends CustomPainter {
  final Color color;
  const _EyebrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 5.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height);
    path.quadraticBezierTo(size.width / 2, 0, size.width, size.height);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_EyebrowPainter oldDelegate) => oldDelegate.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// BIBO PURPLE MONSTER PAINTERS & DATA
// ─────────────────────────────────────────────────────────────────────────────
class _BiboPimpleDot {
  final double dx;
  final double dy;
  final double radius;
  final double opacity;
  const _BiboPimpleDot(this.dx, this.dy, this.radius, this.opacity);
}

const List<_BiboPimpleDot> _biboPimples = [
  // Top left cluster (above left eye)
  _BiboPimpleDot(-75, -110, 8.0, 0.45),
  _BiboPimpleDot(-110, -85, 15.0, 0.35),
  _BiboPimpleDot(-145, -60, 6.0, 0.50),
  _BiboPimpleDot(-90, -145, 10.0, 0.40),
  _BiboPimpleDot(-45, -150, 5.0, 0.45),
  _BiboPimpleDot(-125, -120, 7.0, 0.38),

  // Top right cluster (above right eye)
  _BiboPimpleDot(75, -105, 12.0, 0.40),
  _BiboPimpleDot(115, -70, 8.0, 0.50),
  _BiboPimpleDot(145, -115, 14.0, 0.30),
  _BiboPimpleDot(45, -145, 6.0, 0.45),
  _BiboPimpleDot(95, -150, 9.0, 0.40),
  _BiboPimpleDot(130, -140, 5.0, 0.42),

  // Top center between/above eyes
  _BiboPimpleDot(0, -135, 7.0, 0.45),
  _BiboPimpleDot(-20, -165, 4.0, 0.50),
  _BiboPimpleDot(25, -160, 5.0, 0.42),

  // Far left cheek cluster
  _BiboPimpleDot(-165, -10, 16.0, 0.35),
  _BiboPimpleDot(-130, 10, 9.0, 0.45),
  _BiboPimpleDot(-185, 30, 11.0, 0.40),
  _BiboPimpleDot(-145, 65, 18.0, 0.30),
  _BiboPimpleDot(-105, 45, 6.0, 0.50),
  _BiboPimpleDot(-175, 80, 8.0, 0.38),

  // Far right cheek cluster
  _BiboPimpleDot(165, -15, 10.0, 0.45),
  _BiboPimpleDot(130, 15, 15.0, 0.35),
  _BiboPimpleDot(185, 25, 8.0, 0.40),
  _BiboPimpleDot(145, 60, 13.0, 0.35),
  _BiboPimpleDot(105, 45, 6.0, 0.50),
  _BiboPimpleDot(175, 75, 7.0, 0.42),

  // Left mouth corner cluster
  _BiboPimpleDot(-125, 95, 12.0, 0.35),
  _BiboPimpleDot(-85, 115, 8.0, 0.45),
  _BiboPimpleDot(-140, 130, 6.0, 0.40),

  // Right mouth corner cluster
  _BiboPimpleDot(125, 95, 9.0, 0.45),
  _BiboPimpleDot(85, 115, 13.0, 0.30),
  _BiboPimpleDot(140, 130, 7.0, 0.40),

  // Chin & lower area cluster
  _BiboPimpleDot(-35, 140, 10.0, 0.35),
  _BiboPimpleDot(35, 140, 9.0, 0.40),
  _BiboPimpleDot(0, 155, 6.0, 0.50),
  _BiboPimpleDot(-85, 150, 6.0, 0.45),
  _BiboPimpleDot(85, 150, 7.0, 0.40),
  _BiboPimpleDot(-45, 175, 5.0, 0.48),
  _BiboPimpleDot(45, 175, 6.0, 0.42),
];

class BiboPimplesPainter extends CustomPainter {
  final Color pimpleColor;
  const BiboPimplesPainter({this.pimpleColor = const Color(0xFFD3F1BA)});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.45;

    for (final dot in _biboPimples) {
      final paint = Paint()
        ..color = pimpleColor.withValues(alpha: dot.opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(cx + dot.dx, cy + dot.dy), dot.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant BiboPimplesPainter oldDelegate) =>
      oldDelegate.pimpleColor != pimpleColor;
}

class BiboMonsterFaceWidget extends StatefulWidget {
  final Color chinColor;

  const BiboMonsterFaceWidget({
    super.key,
    this.chinColor = const Color(0xFF1C4108),
  });

  @override
  State<BiboMonsterFaceWidget> createState() => _BiboMonsterFaceWidgetState();
}

class _BiboMonsterFaceWidgetState extends State<BiboMonsterFaceWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;
  Timer? _blinkTimer;
  Offset _eyeOffset = Offset.zero; // Pupil direction driven by mouse

  void _onMouseMove(PointerHoverEvent event) {
    try {
      final RenderBox? box = context.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return;
      final local = box.globalToLocal(event.position);
      final cx = box.size.width / 2;
      final cy = box.size.height * 0.45 - 35.0;
      final dx = local.dx - cx;
      final dy = local.dy - cy;
      final dist = (dx * dx + dy * dy);
      if (dist < 0.01) return; // avoid divide-by-zero
      final len = math.sqrt(dist);
      final mag = len < 7.0 ? len : 7.0; // clamp to 7px max
      final nx = dx / len * mag;
      final ny = dy / len * mag;
      final clamped = Offset(nx, ny);
      if ((clamped - _eyeOffset).distance > 0.3) {
        setState(() => _eyeOffset = clamped);
      }
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    );

    _blinkAnimation = Tween<double>(begin: 1.0, end: 0.08).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );

    _blinkTimer = Timer.periodic(const Duration(milliseconds: 3500), (
      timer,
    ) async {
      if (mounted) {
        await _blinkController.forward();
        await _blinkController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: _onMouseMove,
      child: AnimatedBuilder(
        animation: _blinkAnimation,
        builder: (context, child) {
          return CustomPaint(
            painter: BiboMonsterFacePainter(
              chinColor: widget.chinColor,
              eyeScaleY: _blinkAnimation.value,
              eyeOffset: _eyeOffset,
            ),
          );
        },
      ),
    );
  }
}

class BiboMonsterFacePainter extends CustomPainter {
  final Color chinColor;
  final double eyeScaleY;
  final Offset eyeOffset; // Mouse-driven pupil direction

  const BiboMonsterFacePainter({
    this.chinColor = const Color(0xFF1C4108),
    this.eyeScaleY = 1.0,
    this.eyeOffset = Offset.zero,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.45;
    final eyeCenterY = cy - 35.0;

    const specFrameColor = Color(0xFF2C1B54); // Deep Navy Purple Spectacle Frame
    final specFramePaint = Paint()
      ..color = specFrameColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    final whiteFillPaint = Paint()
      ..color = const Color(0xFFFAFAFA)
      ..style = PaintingStyle.fill;

    final irisPaint = Paint()..color = const Color(0xFF1565C0); // Royal Blue Iris
    final pupilPaint = Paint()..color = const Color(0xFF0D0D0D); // Black Pupil
    final shinePaint = Paint()..color = Colors.white;

    final eyebrowPaint = Paint()
      ..color = chinColor.withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.5
      ..strokeCap = StrokeCap.round;

    // ─── 0. CURVED EYEBROWS ABOVE SPECTACLES ───
    final eyebrowLeftPath = Path()
      ..moveTo(cx - 74.0, eyeCenterY - 48.0)
      ..quadraticBezierTo(cx - 46.0, eyeCenterY - 64.0, cx - 18.0, eyeCenterY - 48.0);

    final eyebrowRightPath = Path()
      ..moveTo(cx + 18.0, eyeCenterY - 48.0)
      ..quadraticBezierTo(cx + 46.0, eyeCenterY - 64.0, cx + 74.0, eyeCenterY - 48.0);

    canvas.drawPath(eyebrowLeftPath, eyebrowPaint);
    canvas.drawPath(eyebrowRightPath, eyebrowPaint);

    // ─── 1. SPECTACLE BRIDGE ───
    final bridgePath = Path()
      ..moveTo(cx - 16.0, eyeCenterY - 4.0)
      ..quadraticBezierTo(cx, eyeCenterY - 18.0, cx + 16.0, eyeCenterY - 4.0);
    canvas.drawPath(bridgePath, specFramePaint);

    // ─── 2. EYES & PUPILS (Blinking Spectacle Lenses) ───
    canvas.save();
    canvas.translate(cx, eyeCenterY);
    canvas.scale(1.0, eyeScaleY);
    canvas.translate(-cx, -eyeCenterY);

    const specRadius = 42.0;

    // Left Spectacle Eye
    canvas.save();
    canvas.translate(cx - 44.0, eyeCenterY);
    final leftEyeRect = Rect.fromCircle(center: Offset.zero, radius: specRadius);
    canvas.drawOval(leftEyeRect, whiteFillPaint);
    canvas.drawOval(leftEyeRect, specFramePaint);

    // Left Royal Blue Iris & Black Pupil — moves with mouse
    final leftIrisCenter = Offset(eyeOffset.dx * 1.5, eyeOffset.dy * 1.5);
    canvas.drawCircle(leftIrisCenter, 24.0, irisPaint);
    canvas.drawCircle(leftIrisCenter, 14.0, pupilPaint);
    canvas.drawCircle(
      Offset(leftIrisCenter.dx - 4.5, leftIrisCenter.dy - 4.5),
      4.5,
      shinePaint,
    );
    canvas.restore();

    // Right Spectacle Eye
    canvas.save();
    canvas.translate(cx + 44.0, eyeCenterY);
    final rightEyeRect = Rect.fromCircle(center: Offset.zero, radius: specRadius);
    canvas.drawOval(rightEyeRect, whiteFillPaint);
    canvas.drawOval(rightEyeRect, specFramePaint);

    // Right Royal Blue Iris & Black Pupil — moves with mouse
    final rightIrisCenter = Offset(eyeOffset.dx * 1.5, eyeOffset.dy * 1.5);
    canvas.drawCircle(rightIrisCenter, 24.0, irisPaint);
    canvas.drawCircle(rightIrisCenter, 14.0, pupilPaint);
    canvas.drawCircle(
      Offset(rightIrisCenter.dx - 4.5, rightIrisCenter.dy - 4.5),
      4.5,
      shinePaint,
    );
    canvas.restore();

    canvas.restore(); // Restore blink scale transform

    // 3. CURVED LIP LINE & ROOTED SMOOTH SHINY FANGS (Positioned Lower on Face)
    final mouthCy = cy + 48.0;
    final mouthLeft = Offset(cx - 106, mouthCy);
    final mouthRight = Offset(cx + 106, mouthCy);
    final mouthBottomControl = Offset(cx, mouthCy + 36.0);

    final mouthPath = Path()
      ..moveTo(mouthLeft.dx, mouthLeft.dy)
      ..quadraticBezierTo(
        mouthBottomControl.dx,
        mouthBottomControl.dy,
        mouthRight.dx,
        mouthRight.dy,
      );

    // Left Fang (Rooted on mouth curve around x = cx - 44)
    final leftFangBaseLeft = Offset(cx - 54, mouthCy + 16.0);
    final leftFangBaseRight = Offset(cx - 34, mouthCy + 20.0);
    final leftFangTip = Offset(cx - 44, mouthCy - 4.0);

    final leftFangPath = _buildCurvedFangPath(
      baseLeft: leftFangBaseLeft,
      baseRight: leftFangBaseRight,
      tip: leftFangTip,
    );

    // Right Fang (Rooted on mouth curve around x = cx + 44)
    final rightFangBaseLeft = Offset(cx + 34, mouthCy + 20.0);
    final rightFangBaseRight = Offset(cx + 54, mouthCy + 16.0);
    final rightFangTip = Offset(cx + 44, mouthCy - 4.0);

    final rightFangPath = _buildCurvedFangPath(
      baseLeft: rightFangBaseLeft,
      baseRight: rightFangBaseRight,
      tip: rightFangTip,
    );

    // Glossy Tooth Fill Gradient (White to soft pearl cream)
    final toothBounds = Rect.fromLTRB(
      cx - 60,
      mouthCy - 5,
      cx + 60,
      mouthCy + 25,
    );
    final toothGradientPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white, Color(0xFFEFF7EA)],
      ).createShader(toothBounds)
      ..style = PaintingStyle.fill;

    final fangBorderPaint = Paint()
      ..color = const Color(0xFF111111)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final lipPaint = Paint()
      ..color = const Color(0xFF111111)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Draw 0: Chin / Lower Lip Shadow Patch (Drawn FIRST behind lip and teeth)
    final chinShadowFillPaint = Paint()
      ..color = const Color(0xFF193B05).withValues(alpha: 0.90)
      ..style = PaintingStyle.fill;

    final chinShadowPath = Path()
      ..moveTo(cx - 36, mouthCy + 24.0)
      ..quadraticBezierTo(cx, mouthCy + 46.0, cx + 36, mouthCy + 24.0)
      ..quadraticBezierTo(cx, mouthCy + 32.0, cx - 36, mouthCy + 24.0)
      ..close();

    canvas.drawPath(chinShadowPath, chinShadowFillPaint);

    final chinOutlinePaint = Paint()
      ..color = const Color(0xFF122E04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;

    final chinOutlinePath = Path()
      ..moveTo(cx - 36, mouthCy + 24.0)
      ..quadraticBezierTo(cx, mouthCy + 46.0, cx + 36, mouthCy + 24.0);

    canvas.drawPath(chinOutlinePath, chinOutlinePaint);

    // Draw 1: Soft Shadow under the Main Lip Line
    final lipShadowPaint = Paint()
      ..color = const Color(0x350A1A02)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);

    final lipShadowPath = Path()
      ..moveTo(mouthLeft.dx, mouthLeft.dy + 3.0)
      ..quadraticBezierTo(
        mouthBottomControl.dx,
        mouthBottomControl.dy + 3.5,
        mouthRight.dx,
        mouthRight.dy + 3.0,
      );

    canvas.drawPath(lipShadowPath, lipShadowPaint);

    // Draw 2: Tooth Fills with Glossy Gradient
    canvas.drawPath(leftFangPath, toothGradientPaint);
    canvas.drawPath(rightFangPath, toothGradientPaint);

    // Draw 3: Glossy Tooth Highlight Accents
    final shineLinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final leftShine = Path()
      ..moveTo(cx - 50, mouthCy + 12.0)
      ..quadraticBezierTo(cx - 47, mouthCy + 4.0, cx - 44, mouthCy);
    final rightShine = Path()
      ..moveTo(cx + 38, mouthCy + 12.0)
      ..quadraticBezierTo(cx + 41, mouthCy + 4.0, cx + 44, mouthCy);

    canvas.drawPath(leftShine, shineLinePaint);
    canvas.drawPath(rightShine, shineLinePaint);

    // Draw 4: Tooth Outlines
    canvas.drawPath(leftFangPath, fangBorderPaint);
    canvas.drawPath(rightFangPath, fangBorderPaint);

    // Draw 5: Main Curved Lip Line (Anchoring and Rooting the Teeth)
    canvas.drawPath(mouthPath, lipPaint);
  }

  Path _buildCurvedFangPath({
    required Offset baseLeft,
    required Offset baseRight,
    required Offset tip,
  }) {
    final path = Path();
    path.moveTo(baseLeft.dx, baseLeft.dy);

    // Smooth curve up to the tip
    final leftControl = Offset(
      baseLeft.dx + (tip.dx - baseLeft.dx) * 0.35 - 2.5,
      baseLeft.dy - (baseLeft.dy - tip.dy) * 0.65,
    );
    path.quadraticBezierTo(leftControl.dx, leftControl.dy, tip.dx, tip.dy);

    // Smooth curve back down to baseRight
    final rightControl = Offset(
      baseRight.dx + (tip.dx - baseRight.dx) * 0.35 + 2.5,
      baseRight.dy - (baseRight.dy - tip.dy) * 0.65,
    );
    path.quadraticBezierTo(
      rightControl.dx,
      rightControl.dy,
      baseRight.dx,
      baseRight.dy,
    );

    // Smooth base curve rooted into the lip
    final baseControl = Offset(
      (baseLeft.dx + baseRight.dx) / 2,
      (baseLeft.dy + baseRight.dy) / 2 + 3.0,
    );
    path.quadraticBezierTo(
      baseControl.dx,
      baseControl.dy,
      baseLeft.dx,
      baseLeft.dy,
    );
    path.close();

    return path;
  }

  @override
  bool shouldRepaint(covariant BiboMonsterFacePainter oldDelegate) =>
      oldDelegate.chinColor != chinColor ||
      oldDelegate.eyeScaleY != eyeScaleY ||
      oldDelegate.eyeOffset != eyeOffset;
}

class _CircleClipper extends CustomClipper<Path> {
  final Offset center;
  final double radius;

  _CircleClipper({required this.center, required this.radius});

  @override
  Path getClip(Size size) {
    return Path()..addOval(Rect.fromCircle(center: center, radius: radius));
  }

  @override
  bool shouldReclip(_CircleClipper oldClipper) =>
      oldClipper.center != center || oldClipper.radius != radius;
}

class StageSpotlightPainter extends CustomPainter {
  final Offset spotlightCenter;
  final double dimOpacity;

  StageSpotlightPainter({
    required this.spotlightCenter,
    required this.dimOpacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dimOpacity <= 0.0) return;

    final rect = Offset.zero & size;
    final normCenter = Alignment(
      (spotlightCenter.dx / size.width) * 2.0 - 1.0,
      (spotlightCenter.dy / size.height) * 2.0 - 1.0,
    );

    // 1. Heavy Backstage Dark Overlay with Radial Cutout for Spotlight Focus
    final darkPaint = Paint()
      ..shader = RadialGradient(
        center: normCenter,
        radius: 145.0 / (size.width / 2),
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: dimOpacity * 0.65),
          Colors.black.withValues(alpha: dimOpacity * 0.96),
        ],
        stops: const [0.0, 0.50, 1.0],
      ).createShader(rect);

    canvas.drawRect(rect, darkPaint);

    // 2. Warm Vibrant Spotlight Glow Beam Centered on the Rolling Ball
    final beamPaint = Paint()
      ..shader = RadialGradient(
        center: normCenter,
        radius: 140.0 / (size.width / 2),
        colors: [
          Colors.white.withValues(alpha: 0.35),
          const Color(0xFFFFF4B8).withValues(alpha: 0.18),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(rect);

    canvas.drawRect(rect, beamPaint);
  }

  @override
  bool shouldRepaint(covariant StageSpotlightPainter oldDelegate) {
    return oldDelegate.spotlightCenter != spotlightCenter ||
        oldDelegate.dimOpacity != dimOpacity;
  }
}

class DuolingoPathLinePainter extends CustomPainter {
  final Size size;

  DuolingoPathLinePainter({required this.size});

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final paint = Paint()
      ..color = const Color(0xFFE5E5E5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final w = size.width;

    path.moveTo(w * 0.58, 45);
    path.quadraticBezierTo(w * 0.45, 100, w * 0.45, 125);
    path.quadraticBezierTo(w * 0.35, 190, w * 0.33, 210);
    path.quadraticBezierTo(w * 0.25, 275, w * 0.32, 365);
    path.quadraticBezierTo(w * 0.45, 435, w * 0.46, 455);
    path.quadraticBezierTo(w * 0.55, 520, w * 0.56, 545);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant DuolingoPathLinePainter oldDelegate) => false;
}

enum SideRoadBumpType { buffAltar, achievement, crystalRelic }

// ─────────────────────────────────────────────────────────────────────────────
// SIDE-ROAD BUMP WIDGET (Interactive Teen-Grade Altars, Achievement & Crystal Relics)
// ─────────────────────────────────────────────────────────────────────────────
class SideRoadBumpWidget extends StatefulWidget {
  final Color bumpColor;
  final SideRoadBumpType bumpType;
  final String label;
  final String sublabel;
  final IconData icon;

  const SideRoadBumpWidget({
    super.key,
    required this.bumpColor,
    this.bumpType = SideRoadBumpType.buffAltar,
    this.label = '',
    this.sublabel = '',
    this.icon = Icons.flash_on_rounded,
  });

  @override
  State<SideRoadBumpWidget> createState() => _SideRoadBumpWidgetState();
}

class _SideRoadBumpWidgetState extends State<SideRoadBumpWidget>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color c = widget.bumpColor;
    final bool isCrystal = widget.bumpType == SideRoadBumpType.crystalRelic;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.08 : 1.0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final double pulse = _pulseController.value;
            return Stack(
              alignment: Alignment.topCenter,
              clipBehavior: Clip.none,
              children: [
                // Floating label chip above bump
                Positioned(
                  top: -38,
                  child: AnimatedOpacity(
                    opacity: _hovered ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: c,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: c.withValues(alpha: 0.55),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        widget.label,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),

                // Main mound body
                Container(
                  width: 160,
                  height: 95,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(90)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color.lerp(c, Colors.white, _hovered ? 0.50 : 0.32)!,
                        c,
                        Color.lerp(c, Colors.black, 0.18)!,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: c.withValues(alpha: _hovered ? 0.60 : 0.32),
                        blurRadius: _hovered ? 26 : 16,
                        offset: const Offset(0, 10),
                        spreadRadius: _hovered ? 3 : 1,
                      ),
                      BoxShadow(
                        color: c.withValues(alpha: 0.18 + 0.12 * pulse),
                        blurRadius: 32 + 8 * pulse,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.55),
                        blurRadius: 8,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      // Bottom 3D bevel
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 10,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Color.lerp(c, Colors.black, 0.28)!,
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(4),
                            ),
                          ),
                        ),
                      ),

                      // Inner shine highlight
                      Positioned(
                        top: 6,
                        child: Container(
                          width: 140,
                          height: 58,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: _hovered ? 0.38 : 0.22),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(75),
                            ),
                          ),
                        ),
                      ),

                      // Crystal prism facets (only for crystalRelic type)
                      if (isCrystal) ...
                        List.generate(3, (i) => Positioned(
                          top: 12 + i * 12.0,
                          child: Container(
                            width: 80 - i * 16.0,
                            height: 1.5,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.30 - i * 0.06),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        )),

                      // Icon with animated pulse scale
                      Positioned(
                        top: 14,
                        child: AnimatedScale(
                          scale: _hovered ? 1.18 : 1.0 + 0.06 * pulse,
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          child: Icon(
                            widget.icon,
                            color: Colors.white.withValues(alpha: 0.95),
                            size: 30,
                            shadows: [
                              Shadow(
                                color: c.withValues(alpha: 0.80),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Sublabel tiny text inside mound
                      Positioned(
                        bottom: 14,
                        child: AnimatedOpacity(
                          opacity: _hovered ? 0.0 : 0.85,
                          duration: const Duration(milliseconds: 150),
                          child: Text(
                            widget.sublabel,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1.2,
                              shadows: [
                                Shadow(
                                  color: c.withValues(alpha: 0.70),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class GrassFieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final grassPaint = Paint()
      ..color = const Color(0xFF5CA208)
      ..style = PaintingStyle.fill;

    final tuftPaint = Paint()
      ..color = const Color(0xFF7CCD12).withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final rect = Offset.zero & size;
    canvas.drawRect(rect, grassPaint);

    // Draw organic grass tufts scattered across terrain
    final random = math.Random(42);
    for (int i = 0; i < 40; i++) {
      final gx = random.nextDouble() * size.width;
      final gy = random.nextDouble() * size.height;

      final tuftPath = Path();
      tuftPath.moveTo(gx - 4, gy + 6);
      tuftPath.quadraticBezierTo(gx - 6, gy, gx - 8, gy - 6);

      tuftPath.moveTo(gx, gy + 6);
      tuftPath.quadraticBezierTo(gx, gy - 2, gx, gy - 8);

      tuftPath.moveTo(gx + 4, gy + 6);
      tuftPath.quadraticBezierTo(gx + 6, gy, gx + 8, gy - 6);

      canvas.drawPath(tuftPath, tuftPaint);
    }
  }

  @override
  bool shouldRepaint(covariant GrassFieldPainter oldDelegate) => false;
}

class WoodenBridgePathPainter extends CustomPainter {
  final Size size;

  WoodenBridgePathPainter({required this.size});

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final w = size.width;

    // 1. Define Bridge Center Path
    final path = Path();
    path.moveTo(w * 0.58, 45);
    path.quadraticBezierTo(w * 0.45, 100, w * 0.45, 125);
    path.quadraticBezierTo(w * 0.35, 190, w * 0.33, 210);
    path.quadraticBezierTo(w * 0.25, 275, w * 0.32, 365);
    path.quadraticBezierTo(w * 0.45, 435, w * 0.46, 455);
    path.quadraticBezierTo(w * 0.55, 520, w * 0.56, 565);

    // 2. Draw 3D Wooden Under-Log Shadow Layer (Width: 84px)
    final logPaint = Paint()
      ..color = const Color(0xFF7A4A14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 84.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, logPaint);

    // 3. Draw Main Honey-Gold Wooden Plank Deck (Width: 70px)
    final woodPaint = Paint()
      ..color = const Color(0xFFDCAE66)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 70.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, woodPaint);

    // 4. Draw Plank Seams, Wooden Posts, Rope Rails & Directional Chevrons
    final metrics = path.computeMetrics();
    final seamPaint = Paint()
      ..color = const Color(0xFF8C5C1D).withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final ropePaint = Paint()
      ..color = const Color(0xFFFFF8E7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;

    final postPaint = Paint()
      ..color = const Color(0xFFB57F3A)
      ..style = PaintingStyle.fill;

    final postBorderPaint = Paint()
      ..color = const Color(0xFF5C380C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final chevronPaint = Paint()
      ..color = const Color(0xFFFFFDF5).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    for (final metric in metrics) {
      final length = metric.length;

      for (double d = 0; d < length; d += 16.0) {
        final tangent = metric.getTangentForOffset(d);
        if (tangent == null) continue;

        final pos = tangent.position;
        final normal = Offset(-tangent.vector.dy, tangent.vector.dx);

        // Draw Plank Seam Line across bridge width
        final p1 = pos + normal * 34.0;
        final p2 = pos - normal * 34.0;
        canvas.drawLine(p1, p2, seamPaint);

        // Every 48px, draw Left & Right Wooden Posts holding the Rope
        if ((d.toInt() % 48) < 16) {
          canvas.drawCircle(p1, 5.0, postPaint);
          canvas.drawCircle(p1, 5.0, postBorderPaint);

          canvas.drawCircle(p2, 5.0, postPaint);
          canvas.drawCircle(p2, 5.0, postBorderPaint);
        }

        // Every 64px, draw Directional Chevron Arrows <<<<
        if ((d.toInt() % 64) < 16) {
          final cCenter = pos + normal * 6.0;
          final forward = tangent.vector;
          final perp = normal;

          final arrowPath = Path();
          arrowPath.moveTo(
            cCenter.dx - forward.dx * 5 + perp.dx * 4,
            cCenter.dy - forward.dy * 5 + perp.dy * 4,
          );
          arrowPath.lineTo(
            cCenter.dx + forward.dx * 3,
            cCenter.dy + forward.dy * 3,
          );
          arrowPath.lineTo(
            cCenter.dx - forward.dx * 5 - perp.dx * 4,
            cCenter.dy - forward.dy * 5 - perp.dy * 4,
          );

          canvas.drawPath(arrowPath, chevronPaint);
        }
      }

      // Draw Top & Bottom Cream Rope Rails along bridge edges
      final leftRopePath = Path();
      final rightRopePath = Path();
      bool first = true;

      for (double d = 0; d < length; d += 6.0) {
        final tangent = metric.getTangentForOffset(d);
        if (tangent == null) continue;
        final pos = tangent.position;
        final normal = Offset(-tangent.vector.dy, tangent.vector.dx);

        final rp1 = pos + normal * 33.0;
        final rp2 = pos - normal * 33.0;

        if (first) {
          leftRopePath.moveTo(rp1.dx, rp1.dy);
          rightRopePath.moveTo(rp2.dx, rp2.dy);
          first = false;
        } else {
          leftRopePath.lineTo(rp1.dx, rp1.dy);
          rightRopePath.lineTo(rp2.dx, rp2.dy);
        }
      }

      canvas.drawPath(leftRopePath, ropePaint);
      canvas.drawPath(rightRopePath, ropePaint);
    }
  }

  @override
  bool shouldRepaint(covariant WoodenBridgePathPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// CREAMY LIQUID DRIPS PAINTER (White Creamy Texture & Organic Drips)
// ─────────────────────────────────────────────────────────────────────────────
class CreamyDripsPainter extends CustomPainter {
  final Color creamColor;
  final Color shadowColor;
  final bool isHangingDown;

  CreamyDripsPainter({
    this.creamColor = const Color(0xFFFFF8E7), // Warm Creamy Vanilla Texture
    this.shadowColor = const Color(0x281F3B16),
    this.isHangingDown = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paint = Paint()
      ..color = creamColor
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = shadowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final path = Path();

    if (isHangingDown) {
      // Drips hanging down from top edge
      path.moveTo(0, 0);
      path.lineTo(w, 0);
      path.lineTo(w, h * 0.28);

      path.cubicTo(w * 0.96, h * 0.28, w * 0.94, h * 0.68, w * 0.91, h * 0.68);
      path.cubicTo(w * 0.88, h * 0.68, w * 0.86, h * 0.24, w * 0.82, h * 0.24);

      path.cubicTo(w * 0.79, h * 0.24, w * 0.76, h * 0.92, w * 0.72, h * 0.92);
      path.cubicTo(w * 0.68, h * 0.92, w * 0.65, h * 0.32, w * 0.61, h * 0.32);

      path.cubicTo(w * 0.58, h * 0.32, w * 0.55, h * 0.58, w * 0.52, h * 0.58);
      path.cubicTo(w * 0.49, h * 0.58, w * 0.47, h * 0.20, w * 0.43, h * 0.20);

      path.cubicTo(w * 0.39, h * 0.20, w * 0.36, h * 0.98, w * 0.31, h * 0.98);
      path.cubicTo(w * 0.26, h * 0.98, w * 0.24, h * 0.28, w * 0.19, h * 0.28);

      path.cubicTo(w * 0.16, h * 0.28, w * 0.13, h * 0.75, w * 0.09, h * 0.75);
      path.cubicTo(w * 0.05, h * 0.75, w * 0.03, h * 0.20, 0, h * 0.20);

      path.close();
    } else {
      // Drips rising up from bottom edge
      path.moveTo(0, h);
      path.lineTo(w, h);
      path.lineTo(w, h * 0.72);

      path.cubicTo(w * 0.96, h * 0.72, w * 0.94, h * 0.32, w * 0.91, h * 0.32);
      path.cubicTo(w * 0.88, h * 0.32, w * 0.86, h * 0.76, w * 0.82, h * 0.76);

      path.cubicTo(w * 0.79, h * 0.76, w * 0.76, h * 0.08, w * 0.72, h * 0.08);
      path.cubicTo(w * 0.68, h * 0.08, w * 0.65, h * 0.68, w * 0.61, h * 0.68);

      path.cubicTo(w * 0.58, h * 0.68, w * 0.55, h * 0.42, w * 0.52, h * 0.42);
      path.cubicTo(w * 0.49, h * 0.42, w * 0.47, h * 0.80, w * 0.43, h * 0.80);

      path.cubicTo(w * 0.39, h * 0.80, w * 0.36, h * 0.02, w * 0.31, h * 0.02);
      path.cubicTo(w * 0.26, h * 0.02, w * 0.24, h * 0.72, w * 0.19, h * 0.72);

      path.cubicTo(w * 0.16, h * 0.72, w * 0.13, h * 0.25, w * 0.09, h * 0.25);
      path.cubicTo(w * 0.05, h * 0.25, w * 0.03, h * 0.80, 0, h * 0.80);

      path.close();
    }

    canvas.drawPath(path.shift(const Offset(0, 5)), shadowPaint);
    canvas.drawPath(path, paint);

    final dropsX = [w * 0.91, w * 0.72, w * 0.52, w * 0.31, w * 0.09];
    final dropsY = isHangingDown
        ? [h * 0.64, h * 0.88, h * 0.54, h * 0.94, h * 0.71]
        : [h * 0.36, h * 0.12, h * 0.46, h * 0.06, h * 0.29];

    for (int i = 0; i < dropsX.length; i++) {
      final highlightPath = Path();
      highlightPath.addArc(
        Rect.fromCircle(
          center: Offset(dropsX[i] - 2, dropsY[i]),
          radius: 5.5,
        ),
        0.8,
        1.8,
      );
      canvas.drawPath(highlightPath, highlightPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CreamyDripsPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// CREAMY WAVE PEDESTAL PAINTER (Wave peak cupping the base of level stones)
// ─────────────────────────────────────────────────────────────────────────────
class CreamyWavePedestalPainter extends CustomPainter {
  final Color waveColor;
  final Color shadowColor;

  CreamyWavePedestalPainter({
    this.waveColor = const Color(0xFFFFF8E7),
    this.shadowColor = const Color(0x221F3B16),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paint = Paint()
      ..color = waveColor
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = shadowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    final path = Path();
    path.moveTo(-10, h);
    path.lineTo(w + 10, h);
    path.lineTo(w + 10, h * 0.65);

    path.cubicTo(w * 0.80, h * 0.65, w * 0.68, h * 0.08, w * 0.50, h * 0.08);
    path.cubicTo(w * 0.32, h * 0.08, w * 0.20, h * 0.65, -10, h * 0.65);

    path.close();

    canvas.drawPath(path.shift(const Offset(0, 3)), shadowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CreamyWavePedestalPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// REALISTIC MOVING WATER PAINTER (No lines, smooth animated liquid waves)
// ─────────────────────────────────────────────────────────────────────────────
class RealisticMovingWaterPainter extends CustomPainter {
  final double animationValue; // 0.0 to 1.0 continuous phase cycle

  RealisticMovingWaterPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final phase = animationValue * 2 * math.pi;

    // 1. Base Soft Water Pool Background Gradient (Fresh Leaf Green Water)
    final bgRect = Offset.zero & size;
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFF7FAF2), // Soft cream surface water
          Color(0xFFE6F4DB), // Translucent seafoam green
          Color(0xFFD2ECC0), // Rich aquatic green
          Color(0xFFBFDFA8), // Deep water base
        ],
        stops: [0.0, 0.35, 0.70, 1.0],
      ).createShader(bgRect);

    canvas.drawRect(bgRect, bgPaint);

    // 2. Layer 1: Deep Slow Ocean Wave (Filled Liquid Shape - NO LINES)
    _drawSmoothLiquidWave(
      canvas: canvas,
      size: size,
      baseY: h * 0.25,
      amplitude: 38.0,
      wavelength: w * 1.1,
      phase: phase * 0.6,
      waveColor: const Color(0xFFCBEAB7).withValues(alpha: 0.55),
    );

    // 3. Layer 2: Mid Dynamic Aqua Wave
    _drawSmoothLiquidWave(
      canvas: canvas,
      size: size,
      baseY: h * 0.50,
      amplitude: 45.0,
      wavelength: w * 0.85,
      phase: -phase * 0.85 + 1.5,
      waveColor: const Color(0xFFBBE4A3).withValues(alpha: 0.50),
    );

    // 4. Layer 3: Surface Flow Liquid Wave
    _drawSmoothLiquidWave(
      canvas: canvas,
      size: size,
      baseY: h * 0.75,
      amplitude: 42.0,
      wavelength: w * 0.95,
      phase: phase * 1.1 + 3.0,
      waveColor: const Color(0xFFAFE094).withValues(alpha: 0.45),
    );

    // 5. Sunlit Caustic Liquid Shimmer Highlights (Soft drifting oval refractions)
    final causticPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    final causticX1 = (w * 0.30 + math.sin(phase) * 60).clamp(0.0, w);
    final causticY1 = (h * 0.20 + math.cos(phase * 0.7) * 40).clamp(0.0, h);
    canvas.drawCircle(Offset(causticX1, causticY1), 90, causticPaint);

    final causticX2 = (w * 0.70 - math.cos(phase * 0.8) * 70).clamp(0.0, w);
    final causticY2 = (h * 0.65 + math.sin(phase * 0.9) * 50).clamp(0.0, h);
    canvas.drawCircle(Offset(causticX2, causticY2), 110, causticPaint);
  }

  void _drawSmoothLiquidWave({
    required Canvas canvas,
    required Size size,
    required double baseY,
    required double amplitude,
    required double wavelength,
    required double phase,
    required Color waveColor,
  }) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = waveColor
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, h);
    path.lineTo(0, baseY);

    const int steps = 40;
    final double stepWidth = w / steps;

    for (int i = 0; i <= steps; i++) {
      final x = i * stepWidth;
      final y = baseY +
          amplitude * math.sin((x / wavelength) * 2 * math.pi + phase) +
          (amplitude * 0.35) * math.cos((x / (wavelength * 0.5)) * 2 * math.pi - phase * 0.5);
      path.lineTo(x, y);
    }

    path.lineTo(w, h);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant RealisticMovingWaterPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DYNAMIC ORGANIC MULTI-DIRECTIONAL MORPHING SOAP BUBBLE CURSOR
// ─────────────────────────────────────────────────────────────────────────────
class GlassBubbleCursorWidget extends StatefulWidget {
  final _AgeTheme theme;
  final Offset targetPos;

  const GlassBubbleCursorWidget({
    super.key,
    required this.theme,
    required this.targetPos,
  });

  @override
  State<GlassBubbleCursorWidget> createState() =>
      _GlassBubbleCursorWidgetState();
}

class _GlassBubbleCursorWidgetState extends State<GlassBubbleCursorWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tickerController;
  Offset _currentPos = const Offset(-200, -200);
  Offset _velocity = Offset.zero;
  double _wobblePhase = 0.0;

  @override
  void initState() {
    super.initState();
    _currentPos = widget.targetPos;
    _tickerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _tickerController.addListener(_updatePhysics);
  }

  void _updatePhysics() {
    if (!mounted) return;

    final target = widget.targetPos;
    if (_currentPos == const Offset(-200, -200)) {
      _currentPos = target;
    }

    // Direct Tight Follow to Cursor / Finger (0.80 follow factor)
    final diff = target - _currentPos;
    _velocity = diff * 0.80;
    _currentPos = _currentPos + _velocity;

    // Wobble Phase advances ONLY when user's mouse or finger actually moves!
    final speed = _velocity.distance;
    if (speed > 0.15) {
      _wobblePhase += speed * 0.035;
    }

    setState(() {});
  }

  @override
  void dispose() {
    _tickerController.removeListener(_updatePhysics);
    _tickerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double bubbleSize = 140.0;
    const double bubbleRadius = bubbleSize / 2;

    return Positioned(
      left: _currentPos.dx - bubbleRadius,
      top: _currentPos.dy - bubbleRadius,
      child: IgnorePointer(
        child: SizedBox(
          width: bubbleSize,
          height: bubbleSize,
          child: CustomPaint(
            painter: OrganicBlobBubblePainter(
              phase: _wobblePhase,
              velocity: _velocity,
              theme: widget.theme,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AMORPHOUS ORGANIC BUBBLE PAINTER (User Pointer-Driven Perimeter Morphing)
// ─────────────────────────────────────────────────────────────────────────────
class OrganicBlobBubblePainter extends CustomPainter {
  final double phase;
  final Offset velocity;
  final _AgeTheme theme;

  OrganicBlobBubblePainter({
    required this.phase,
    required this.velocity,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width / 2 - 14.0;

    const int numPoints = 8;
    final speed = velocity.distance;
    final moveAngle = speed > 0.15 ? math.atan2(velocity.dy, velocity.dx) : 0.0;

    // Motion Factor: 0.0 when mouse/finger is still, ramps up dynamically with movement speed!
    final motionFactor = (speed / 10.0).clamp(0.0, 1.0);

    final points = <Offset>[];

    for (int i = 0; i < numPoints; i++) {
      final a = i * (2 * math.pi / numPoints);

      // Organic sine wave distortions occur ONLY when user moves mouse/finger!
      final wave1 = math.sin(phase * 1.8 + i * 1.5) * 8.0 * motionFactor;
      final wave2 = math.cos(phase * 2.6 - i * 2.1) * 5.0 * motionFactor;

      // Directional motion distortion: bulges outward towards motion direction, compresses behind
      final angleDiff = math.cos(a - moveAngle);
      final directionalDistortion = angleDiff * motionFactor * 20.0;

      final r = baseRadius + wave1 + wave2 + directionalDistortion;
      points.add(Offset(
        center.dx + r * math.cos(a),
        center.dy + r * math.sin(a),
      ));
    }

    // Build smooth closed cubic Bezier path around vertices
    final path = Path();
    path.moveTo(
      (points[0].dx + points[numPoints - 1].dx) / 2,
      (points[0].dy + points[numPoints - 1].dy) / 2,
    );

    for (int i = 0; i < numPoints; i++) {
      final p1 = points[i];
      final p2 = points[(i + 1) % numPoints];
      final midX = (p1.dx + p2.dx) / 2;
      final midY = (p1.dy + p2.dy) / 2;
      path.quadraticBezierTo(p1.dx, p1.dy, midX, midY);
    }
    path.close();

    // 1. Soft Sheer Outer Glass Glow
    final shadowPaint = Paint()
      ..color = theme.toothGlow.withValues(alpha: 0.10)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawPath(path, shadowPaint);

    final whiteGlowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.20)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(path, whiteGlowPaint);

    // 2. Crystal Clear Transparent Soap Film Radial Shader Fill (Center is 100% See-Through!)
    final rect = Offset.zero & size;
    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.35),
        radius: 0.85,
        colors: [
          Colors.white.withValues(alpha: 0.25), // Top specular sheen
          theme.toothGlow.withValues(alpha: 0.05), // Subtle iridescent tint
          Colors.transparent, // Completely see-through center body!
          Colors.cyanAccent.withValues(alpha: 0.06), // Very light glass edge tint
          Colors.white.withValues(alpha: 0.12), // Subtle rim definition
        ],
        stops: const [0.0, 0.20, 0.50, 0.80, 1.0],
      ).createShader(rect);

    canvas.drawPath(path, fillPaint);

    // 3. Sheer Iridescent Soap Film Rim Border
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..shader = SweepGradient(
        transform: GradientRotation(phase * 0.5),
        colors: const [
          Color(0x60FF9A9E),
          Color(0x60FECFEF),
          Color(0x60A1C4FD),
          Color(0x60C2E9FB),
          Color(0x60E2EBF0),
          Color(0x60FF9A9E),
        ],
      ).createShader(rect);

    canvas.drawPath(path, rimPaint);

    // 4. White Glass Specular Highlight Glint (Top-left organic arc)
    final highlightPath = Path();
    highlightPath.moveTo(center.dx - baseRadius * 0.50, center.dy - baseRadius * 0.45);
    highlightPath.quadraticBezierTo(
      center.dx - baseRadius * 0.20,
      center.dy - baseRadius * 0.70,
      center.dx + baseRadius * 0.15,
      center.dy - baseRadius * 0.55,
    );

    final highlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.70)
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 1);

    canvas.drawPath(highlightPath, highlightPaint);

    // 5. Small Secondary Gloss Dot
    final dotCenter = Offset(center.dx + baseRadius * 0.45, center.dy + baseRadius * 0.45);
    canvas.drawCircle(
      dotCenter,
      3.5,
      Paint()..color = Colors.white.withValues(alpha: 0.60),
    );
  }

  @override
  bool shouldRepaint(covariant OrganicBlobBubblePainter oldDelegate) =>
      oldDelegate.phase != phase || oldDelegate.velocity != velocity;
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPACT 3D FLOATING EMOTION CARD INTERFACE
// ─────────────────────────────────────────────────────────────────────────────
class _CompactEmotionCard extends StatelessWidget {
  final double emotionValue;
  final ValueChanged<double> onChanged;

  const _CompactEmotionCard({
    required this.emotionValue,
    required this.onChanged,
  });

  Color _lerp4Colors(Color c1, Color c2, Color c3, Color c4, double t) {
    if (t <= 0.33) {
      return Color.lerp(c1, c2, t / 0.33)!;
    } else if (t <= 0.66) {
      return Color.lerp(c2, c3, (t - 0.33) / 0.33)!;
    } else {
      return Color.lerp(c3, c4, (t - 0.66) / 0.34)!;
    }
  }

  Color _getThemeTopColor(double t) {
    return _lerp4Colors(
      const Color(0xFFFF6B55), // sad (Red)
      const Color(0xFFFF6D00), // grumpy (Burnt Orange)
      const Color(0xFF94D561), // silly (Apple Lime Green from Age Selection!)
      const Color(0xFFFFE082), // awesome (Gold)
      t,
    );
  }

  Color _getThemeBottomColor(double t) {
    return _lerp4Colors(
      const Color(0xFFE53935), // sad
      const Color(0xFFE65100), // grumpy
      const Color(0xFF3F771A), // silly (Deep Forest Green from Age Selection!)
      const Color(0xFFFFB300), // awesome
      t,
    );
  }

  String _getEmotionTitle(double t) {
    if (t < 0.25) {
      return 'sad';
    } else if (t < 0.50) {
      return 'grumpy';
    } else if (t < 0.75) {
      return 'silly';
    } else {
      return 'happy';
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cardW = math.min(size.width * 0.88, 340.0);
    final cardH = math.min(size.height * 0.70, 500.0);

    final topColor = _getThemeTopColor(emotionValue);
    final bottomColor = _getThemeBottomColor(emotionValue);
    final title = _getEmotionTitle(emotionValue);

    return Container(
      width: cardW,
      height: cardH,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [topColor, bottomColor],
        ),
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.38),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: topColor.withValues(alpha: 0.40),
            blurRadius: 44,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // Top Emotion Title Text ("sad", "great", "awesome")
            Positioned(
              top: 24,
              child: Text(
                title,
                style: GoogleFonts.fredoka(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.95),
                  letterSpacing: 1.0,
                  shadows: const [
                    Shadow(
                      color: Color(0x30000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),

            // Monster Face (Centered in top portion of card)
            Positioned.fill(
              top: 48,
              bottom: 110,
              child: InteractiveEmotionMonsterFaceWidget(
                emotionValue: emotionValue,
                chinColor: bottomColor,
              ),
            ),

            // White 3D Dock Container at Bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 120,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Center(
                    child: _CompactEmotionSlider(
                      value: emotionValue,
                      onChanged: onChanged,
                      themeColor: topColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPACT 3D SLIDER WITH TICK MARKERS (| . | . |) & FLOATING 3D SPHERE
// ─────────────────────────────────────────────────────────────────────────────
class _CompactEmotionSlider extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final Color themeColor;

  const _CompactEmotionSlider({
    required this.value,
    required this.onChanged,
    required this.themeColor,
  });

  @override
  State<_CompactEmotionSlider> createState() => _CompactEmotionSliderState();
}

class _CompactEmotionSliderState extends State<_CompactEmotionSlider> {
  void _updateValueFromOffset(Offset localPos, double trackWidth) {
    final double clampedX = localPos.dx.clamp(0.0, trackWidth);
    final double newValue = (clampedX / trackWidth).clamp(0.0, 1.0);
    widget.onChanged(newValue);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth;
        const thumbRadius = 18.0;
        final thumbX = (widget.value * trackWidth).clamp(0.0, trackWidth);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (details) =>
              _updateValueFromOffset(details.localPosition, trackWidth),
          onPanUpdate: (details) =>
              _updateValueFromOffset(details.localPosition, trackWidth),
          onTapDown: (details) =>
              _updateValueFromOffset(details.localPosition, trackWidth),
          child: SizedBox(
            height: 60,
            width: trackWidth,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // Track Container with 4 Notch Markers (| . | . | . |)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: const Color(0xFF222222),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: const Color(0xFFB0B0B0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: const Color(0xFFB0B0B0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: const Color(0xFFB0B0B0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),

                // Floating 3D Red/Theme Sphere Knob Handle
                Positioned(
                  left: (thumbX - thumbRadius).clamp(
                    0.0,
                    trackWidth - thumbRadius * 2,
                  ),
                  top: 12,
                  child: Container(
                    width: thumbRadius * 2,
                    height: thumbRadius * 2,
                    decoration: BoxDecoration(
                      color: widget.themeColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.themeColor.withValues(alpha: 0.50),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.20),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INTERACTIVE EMOTION MONSTER FACE WIDGET & PAINTER
// ─────────────────────────────────────────────────────────────────────────────
class InteractiveEmotionMonsterFaceWidget extends StatefulWidget {
  final double emotionValue; // 0.0 to 1.0
  final Color chinColor;

  const InteractiveEmotionMonsterFaceWidget({
    super.key,
    required this.emotionValue,
    required this.chinColor,
  });

  @override
  State<InteractiveEmotionMonsterFaceWidget> createState() =>
      _InteractiveEmotionMonsterFaceWidgetState();
}

class _InteractiveEmotionMonsterFaceWidgetState
    extends State<InteractiveEmotionMonsterFaceWidget>
    with TickerProviderStateMixin {
  late AnimationController _blinkController;
  late AnimationController _tearController;
  Offset _pointerOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _tearController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _scheduleNextBlink();
  }

  void _scheduleNextBlink() {
    Future.delayed(
      Duration(milliseconds: 2500 + math.Random().nextInt(3000)),
      () {
        if (mounted) {
          _blinkController.forward().then((_) {
            if (mounted) {
              _blinkController.reverse().then((_) {
                if (mounted) _scheduleNextBlink();
              });
            }
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _blinkController.dispose();
    _tearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) {
        final RenderBox? box = context.findRenderObject() as RenderBox?;
        if (box != null) {
          final localPos = box.globalToLocal(event.position);
          final size = box.size;
          if (size.width > 0 && size.height > 0) {
            setState(() {
              _pointerOffset = Offset(
                ((localPos.dx / size.width) - 0.5) * 2.0,
                ((localPos.dy / size.height) - 0.5) * 2.0,
              );
            });
          }
        }
      },
      onExit: (_) {
        setState(() {
          _pointerOffset = Offset.zero;
        });
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_blinkController, _tearController]),
        builder: (context, child) {
          final blinkVal = _blinkController.value;
          final eyeScaleY = 1.0 - (blinkVal * 0.92);

          return CustomPaint(
            size: Size.infinite,
            painter: _InteractiveEmotionMonsterFacePainter(
              emotionValue: widget.emotionValue,
              chinColor: widget.chinColor,
              eyeScaleY: eyeScaleY,
              tearProgress: _tearController.value,
              pointerOffset: _pointerOffset,
            ),
          );
        },
      ),
    );
  }
}

class _InteractiveEmotionMonsterFacePainter extends CustomPainter {
  final double emotionValue; // 0.0 to 1.0
  final Color chinColor;
  final double eyeScaleY;
  final double tearProgress;
  final Offset pointerOffset;

  _InteractiveEmotionMonsterFacePainter({
    required this.emotionValue,
    required this.chinColor,
    required this.eyeScaleY,
    required this.tearProgress,
    required this.pointerOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 - 10.0;

    // 1. EYEBROWS MORPHING (Distinct Expressive Curved Eyebrow Arches)
    final browPaint = Paint()
      ..color = const Color(0xFF111111)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9.0
      ..strokeCap = StrokeCap.round;

    final browShadowPaint = Paint()
      ..color = const Color(0x30000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final leftBrowPath = Path();
    final rightBrowPath = Path();

    if (emotionValue < 0.25) {
      // 0.0 ("sad"): Worried high-arched sad eyebrows (🥺)
      final t = (emotionValue / 0.25).clamp(0.0, 1.0);
      final outerY = cy - 64.0 - 4.0 * t;
      final innerY = cy - 88.0 + 4.0 * t;
      final archY = cy - 106.0 + 4.0 * t;

      leftBrowPath.moveTo(cx - 72, outerY);
      leftBrowPath.quadraticBezierTo(cx - 44, archY, cx - 18, innerY);

      rightBrowPath.moveTo(cx + 18, innerY);
      rightBrowPath.quadraticBezierTo(cx + 44, archY, cx + 72, outerY);
    } else if (emotionValue < 0.50) {
      // 0.33 ("grumpy"): Fierce angry curved V-eyebrows (😠)
      leftBrowPath.moveTo(cx - 72, cy - 102.0);
      leftBrowPath.quadraticBezierTo(cx - 44, cy - 72.0, cx - 18, cy - 62.0);

      rightBrowPath.moveTo(cx + 18, cy - 62.0);
      rightBrowPath.quadraticBezierTo(cx + 44, cy - 72.0, cx + 72, cy - 102.0);
    } else if (emotionValue < 0.75) {
      // 0.66 ("silly"): Playful bouncy curved raised eyebrows (😜)
      leftBrowPath.moveTo(cx - 70, cy - 82.0);
      leftBrowPath.quadraticBezierTo(cx - 44, cy - 108.0, cx - 18, cy - 90.0);

      rightBrowPath.moveTo(cx + 18, cy - 90.0);
      rightBrowPath.quadraticBezierTo(cx + 44, cy - 108.0, cx + 70, cy - 82.0);
    } else {
      // 1.0 ("awesome"): Joyful high curved happy eyebrows (😊)
      leftBrowPath.moveTo(cx - 70, cy - 84.0);
      leftBrowPath.quadraticBezierTo(cx - 44, cy - 114.0, cx - 18, cy - 88.0);

      rightBrowPath.moveTo(cx + 18, cy - 88.0);
      rightBrowPath.quadraticBezierTo(cx + 44, cy - 114.0, cx + 70, cy - 84.0);
    }

    canvas.drawPath(leftBrowPath.shift(const Offset(0, 3)), browShadowPaint);
    canvas.drawPath(rightBrowPath.shift(const Offset(0, 3)), browShadowPaint);
    canvas.drawPath(leftBrowPath, browPaint);
    canvas.drawPath(rightBrowPath, browPaint);

    // 2. EYES & EYELIDS MORPHING (Interactive Mouse-Following Pupils)
    final eyeCenterY = cy - 30.0;
    const eyeW = 52.0;
    const eyeH = 58.0;

    final whiteFillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final blackBorderPaint = Paint()
      ..color = const Color(0xFF111111)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5;

    final pupilPaint = Paint()
      ..color = const Color(0xFF111111)
      ..style = PaintingStyle.fill;

    final shinePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Pupil shift based on interactive mouse pointer direction
    final pupilFollowX = (pointerOffset.dx * 13.0).clamp(-14.0, 14.0);
    final pupilFollowY = (pointerOffset.dy * 13.0).clamp(-14.0, 14.0);
    final basePupilY = emotionValue < 0.25 ? 2.0 : 0.0;

    canvas.save();
    canvas.translate(cx, eyeCenterY);
    canvas.scale(1.0, eyeScaleY);
    canvas.translate(-cx, -eyeCenterY);

    final isSilly = emotionValue >= 0.50 && emotionValue < 0.75;
    final isGrumpy = emotionValue >= 0.25 && emotionValue < 0.50;

    // Left Eye
    canvas.save();
    canvas.translate(cx - 38.0, eyeCenterY);
    final leftEyeRect = Rect.fromCenter(
      center: Offset.zero,
      width: eyeW,
      height: eyeH,
    );

    if (isSilly) {
      // Winking Eye
      canvas.drawOval(leftEyeRect, Paint()..color = chinColor..style = PaintingStyle.fill);
      canvas.drawOval(leftEyeRect, blackBorderPaint);

      final winkArcPath = Path()
        ..moveTo(-eyeW / 2 + 4, 0)
        ..quadraticBezierTo(0, 14, eyeW / 2 - 4, 0);
      canvas.drawPath(winkArcPath, blackBorderPaint);
    } else {
      canvas.drawOval(leftEyeRect, whiteFillPaint);
      canvas.drawOval(leftEyeRect, blackBorderPaint);

      final pupilOffsetLeft = Offset(
        pupilFollowX,
        basePupilY + pupilFollowY,
      );
      canvas.drawCircle(pupilOffsetLeft, 12.0, pupilPaint);
      canvas.drawCircle(
        Offset(pupilOffsetLeft.dx - 3.5, pupilOffsetLeft.dy - 3.5),
        3.8,
        shinePaint,
      );
    }
    canvas.restore();

    // Right Eye
    canvas.save();
    canvas.translate(cx + 38.0, eyeCenterY);
    final rightEyeRect = Rect.fromCenter(
      center: Offset.zero,
      width: eyeW,
      height: eyeH,
    );

    canvas.drawOval(rightEyeRect, whiteFillPaint);
    canvas.drawOval(rightEyeRect, blackBorderPaint);

    if (isSilly) {
      // Big Anime Open Eye with Green Iris
      final greenIrisPaint = Paint()
        ..color = const Color(0xFF78C800)
        ..style = PaintingStyle.fill;
      final greenIrisCenter = Offset(
        -4.0 + pupilFollowX * 0.8,
        2.0 + pupilFollowY * 0.8,
      );
      canvas.drawCircle(greenIrisCenter, 16.0, greenIrisPaint);
      canvas.drawCircle(greenIrisCenter, 10.0, pupilPaint);
      canvas.drawCircle(
        Offset(greenIrisCenter.dx - 5.0, greenIrisCenter.dy - 5.0),
        5.0,
        shinePaint,
      );
    } else {
      final pupilOffsetRight = Offset(
        pupilFollowX,
        basePupilY + pupilFollowY,
      );
      canvas.drawCircle(pupilOffsetRight, 12.0, pupilPaint);
      canvas.drawCircle(
        Offset(pupilOffsetRight.dx - 3.5, pupilOffsetRight.dy - 3.5),
        3.8,
        shinePaint,
      );
    }
    canvas.restore();

    // Glaring Slanted Top Eyelids for Grumpy
    if (isGrumpy) {
      final lidFillPaint = Paint()
        ..color = chinColor
        ..style = PaintingStyle.fill;
      final lidLinePaint = Paint()
        ..color = const Color(0xFF111111)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0
        ..strokeCap = StrokeCap.round;

      final leftLidPath = Path()
        ..moveTo(cx - 38.0 - eyeW / 2 - 4, eyeCenterY - eyeH / 2 - 4)
        ..lineTo(cx - 38.0 + eyeW / 2 + 4, eyeCenterY - 4)
        ..lineTo(cx - 38.0 + eyeW / 2 + 4, eyeCenterY - eyeH / 2 - 4)
        ..close();
      canvas.drawPath(leftLidPath, lidFillPaint);
      canvas.drawLine(
        Offset(cx - 38.0 - eyeW / 2 - 4, eyeCenterY - eyeH / 2 - 4),
        Offset(cx - 38.0 + eyeW / 2 + 4, eyeCenterY - 4),
        lidLinePaint,
      );

      final rightLidPath = Path()
        ..moveTo(cx + 38.0 + eyeW / 2 + 4, eyeCenterY - eyeH / 2 - 4)
        ..lineTo(cx + 38.0 - eyeW / 2 - 4, eyeCenterY - 4)
        ..lineTo(cx + 38.0 - eyeW / 2 - 4, eyeCenterY - eyeH / 2 - 4)
        ..close();
      canvas.drawPath(rightLidPath, lidFillPaint);
      canvas.drawLine(
        Offset(cx + 38.0 + eyeW / 2 + 4, eyeCenterY - eyeH / 2 - 4),
        Offset(cx + 38.0 - eyeW / 2 - 4, eyeCenterY - 4),
        lidLinePaint,
      );
    }

    canvas.restore(); // Restore blink scale transform

    // 2.5 ANIMATED FALLING TEARDROPS FOR SAD EMOTION (Continuous Dripping Tears)
    if (emotionValue < 0.25) {
      void drawTearDrop(Offset topPoint, double dropProgress) {
        final opacity = (1.0 - dropProgress).clamp(0.0, 1.0);
        if (opacity <= 0.05) return;

        final dropY = topPoint.dy + dropProgress * 70.0;
        final dropX = topPoint.dx;
        final dropSize = 6.5 + dropProgress * 3.0;

        final tearPath = Path()
          ..moveTo(dropX, dropY - dropSize * 1.4)
          ..cubicTo(
            dropX + dropSize,
            dropY - dropSize * 0.2,
            dropX + dropSize,
            dropY + dropSize,
            dropX,
            dropY + dropSize,
          )
          ..cubicTo(
            dropX - dropSize,
            dropY + dropSize,
            dropX - dropSize,
            dropY - dropSize * 0.2,
            dropX,
            dropY - dropSize * 1.4,
          );

        final tearFillPaint = Paint()
          ..color = const Color(0xFF4FC3F7).withValues(alpha: opacity)
          ..style = PaintingStyle.fill;

        final tearBorderPaint = Paint()
          ..color = const Color(0xFF0288D1).withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

        final tearShinePaint = Paint()
          ..color = Colors.white.withValues(alpha: opacity * 0.9)
          ..style = PaintingStyle.fill;

        canvas.drawPath(tearPath, tearFillPaint);
        canvas.drawPath(tearPath, tearBorderPaint);
        canvas.drawCircle(
          Offset(dropX - dropSize * 0.3, dropY - dropSize * 0.2),
          dropSize * 0.3,
          tearShinePaint,
        );
      }

      // Left Eye Teardrops (Staggered continuous flow)
      final leftEyeOrigin = Offset(cx - 38.0 - 10.0, eyeCenterY + eyeH / 2 - 4.0);
      drawTearDrop(leftEyeOrigin, tearProgress);
      drawTearDrop(leftEyeOrigin, (tearProgress + 0.5) % 1.0);

      // Right Eye Teardrops (Staggered continuous flow)
      final rightEyeOrigin = Offset(cx + 38.0 + 10.0, eyeCenterY + eyeH / 2 - 4.0);
      drawTearDrop(rightEyeOrigin, (tearProgress + 0.25) % 1.0);
      drawTearDrop(rightEyeOrigin, (tearProgress + 0.75) % 1.0);
    }

    // 3. UNIFIED PLUSH 3D CLAY CURVED SMILE MOUTH (Expressive curved smile shape)
    final mouthCy = cy + 40.0;
    final mouthPath = Path();
    double mouthW, mouthH;
    bool showTeeth, showTongue;

    if (emotionValue >= 0.75) {
      // 1.0 ("happy" / "awesome"): Joyful open curved smile (U-crescent smile curve!)
      final t = ((emotionValue - 0.75) / 0.25).clamp(0.0, 1.0);
      mouthW = 128.0 + 14.0 * t;
      mouthH = 48.0 + 16.0 * t;

      final leftCorner = Offset(cx - mouthW / 2, mouthCy - 12.0);
      final rightCorner = Offset(cx + mouthW / 2, mouthCy - 12.0);
      final topControl = Offset(cx, mouthCy - 4.0);
      final bottomCenterY = mouthCy + mouthH * 0.75;

      mouthPath.moveTo(leftCorner.dx, leftCorner.dy);
      // Top lip: gentle curve connecting corners
      mouthPath.quadraticBezierTo(
        topControl.dx,
        topControl.dy,
        rightCorner.dx,
        rightCorner.dy,
      );
      // Right corner rounded arc into bottom smile curve
      mouthPath.cubicTo(
        rightCorner.dx + 4.0, rightCorner.dy + mouthH * 0.35,
        cx + mouthW * 0.32, bottomCenterY,
        cx, bottomCenterY,
      );
      // Bottom smile curve sweeping back up to left corner
      mouthPath.cubicTo(
        cx - mouthW * 0.32, bottomCenterY,
        leftCorner.dx - 4.0, leftCorner.dy + mouthH * 0.35,
        leftCorner.dx, leftCorner.dy,
      );
      mouthPath.close();

      showTeeth = true;
      showTongue = false;
    } else if (emotionValue >= 0.50) {
      // 0.66 ("silly"): Cheerful grinning curved smile with tongue
      final t = ((emotionValue - 0.50) / 0.25).clamp(0.0, 1.0);
      mouthW = 118.0 + 8.0 * t;
      mouthH = 40.0 + 8.0 * t;

      final leftCorner = Offset(cx - mouthW / 2, mouthCy - 10.0);
      final rightCorner = Offset(cx + mouthW / 2, mouthCy - 10.0);
      final topControl = Offset(cx, mouthCy - 3.0);
      final bottomCenterY = mouthCy + mouthH * 0.70;

      mouthPath.moveTo(leftCorner.dx, leftCorner.dy);
      mouthPath.quadraticBezierTo(
        topControl.dx,
        topControl.dy,
        rightCorner.dx,
        rightCorner.dy,
      );
      mouthPath.cubicTo(
        rightCorner.dx + 4.0, rightCorner.dy + mouthH * 0.35,
        cx + mouthW * 0.32, bottomCenterY,
        cx, bottomCenterY,
      );
      mouthPath.cubicTo(
        cx - mouthW * 0.32, bottomCenterY,
        leftCorner.dx - 4.0, leftCorner.dy + mouthH * 0.35,
        leftCorner.dx, leftCorner.dy,
      );
      mouthPath.close();

      showTeeth = true;
      showTongue = true;
    } else if (emotionValue >= 0.25) {
      // 0.33 ("grumpy"): Tight annoyed downturned curved mouth
      final t = ((emotionValue - 0.25) / 0.25).clamp(0.0, 1.0);
      mouthW = 114.0 - 4.0 * t;
      mouthH = 26.0 + 4.0 * t;

      final cornerY = mouthCy + 14.0;
      final topArchY = mouthCy - 6.0;
      final bottomArchY = mouthCy + 8.0;

      final leftCorner = Offset(cx - mouthW / 2, cornerY);
      final rightCorner = Offset(cx + mouthW / 2, cornerY);

      mouthPath.moveTo(leftCorner.dx, leftCorner.dy);
      mouthPath.quadraticBezierTo(
        cx,
        topArchY,
        rightCorner.dx,
        rightCorner.dy,
      );
      mouthPath.quadraticBezierTo(
        cx,
        bottomArchY,
        leftCorner.dx,
        leftCorner.dy,
      );
      mouthPath.close();

      showTeeth = true;
      showTongue = false;
    } else {
      // 0.0 ("sad"): Deep downturned sad frown curve (drooping corners ☹️)
      final t = (emotionValue / 0.25).clamp(0.0, 1.0);
      mouthW = 118.0 - 8.0 * t;
      mouthH = 34.0;

      final cornerY = mouthCy + 24.0 - 4.0 * t;
      final topArchY = mouthCy - 14.0 + 4.0 * t;
      final bottomArchY = mouthCy + 4.0 + 2.0 * t;

      final leftCorner = Offset(cx - mouthW / 2, cornerY);
      final rightCorner = Offset(cx + mouthW / 2, cornerY);

      mouthPath.moveTo(leftCorner.dx, leftCorner.dy);
      // Top lip: Arches UPWARDS high in the middle into a sad frown arc
      mouthPath.quadraticBezierTo(
        cx,
        topArchY,
        rightCorner.dx,
        rightCorner.dy,
      );
      // Bottom lip: Follows frown curve, arching UP in the middle
      mouthPath.quadraticBezierTo(
        cx,
        bottomArchY,
        leftCorner.dx,
        leftCorner.dy,
      );
      mouthPath.close();

      showTeeth = true;
      showTongue = false;
    }

    // 0. Soft 3D Drop Shadow Under Plush Lip Rim & Mouth Cavity
    final mouthShadowStrokePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);

    final mouthShadowFillPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.24)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);

    // Draw drop shadow behind mouth
    canvas.drawPath(mouthPath.shift(const Offset(0, 5.0)), mouthShadowFillPaint);
    canvas.drawPath(mouthPath.shift(const Offset(0, 5.0)), mouthShadowStrokePaint);

    // 1. Thick Plush 3D Clay Outer Lip Bevel Rim (16px)
    final plushLipRimPaint = Paint()
      ..color = const Color(0xFFFFB74D) // Signature warm plush 3D lip bevel highlight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // 2. Inner Dark Mouth Cavity Fill
    final mouthCavityPaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.fill;

    // 3. Inner Black Contour Border (4px)
    final mouthOutlinePaint = Paint()
      ..color = const Color(0xFF111111)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Draw outer plush lip rim
    canvas.drawPath(mouthPath, plushLipRimPaint);

    // Draw inner dark cavity
    canvas.drawPath(mouthPath, mouthCavityPaint);

    // Clip & Draw Teeth / Tongue inside Cavity
    canvas.save();
    canvas.clipPath(mouthPath);

    if (emotionValue >= 0.75) {
      // Smooth Solid White Top Tooth Band following the top smile curve
      final toothBarPath = Path()
        ..moveTo(cx - mouthW / 2 - 10, mouthCy - 30.0)
        ..lineTo(cx + mouthW / 2 + 10, mouthCy - 30.0)
        ..lineTo(cx + mouthW / 2 + 10, mouthCy + 4.0)
        ..quadraticBezierTo(cx, mouthCy + 14.0, cx - mouthW / 2 - 10, mouthCy + 4.0)
        ..close();

      final toothBarPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
      final toothBarBorderPaint = Paint()
        ..color = const Color(0xFF111111)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;

      canvas.drawPath(toothBarPath, toothBarPaint);
      canvas.drawPath(toothBarPath, toothBarBorderPaint);
    } else {
      if (showTeeth) {
        final toothPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        final toothBorderPaint = Paint()
          ..color = const Color(0xFF222222)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6;

        const numTeeth = 6;
        final toothW = (mouthW - 16) / numTeeth;
        final toothTop = mouthCy - 10.0;

        for (int i = 0; i < numTeeth; i++) {
          final tLeft = cx - (mouthW - 16) / 2 + i * toothW;
          final tRect = Rect.fromLTWH(tLeft, toothTop, toothW - 1, 12);
          canvas.drawRect(tRect, toothPaint);
          canvas.drawRect(tRect, toothBorderPaint);
        }
      }

      if (showTongue && emotionValue >= 0.50) {
        // "silly": Cheeky side tongue for winking face
        final tonguePaint = Paint()
          ..color = const Color(0xFFFF5252)
          ..style = PaintingStyle.fill;
        final tongueCenter = Offset(cx + 14.0, mouthCy + mouthH * 0.40);
        canvas.drawCircle(tongueCenter, mouthW * 0.32, tonguePaint);
      }
    }
    canvas.restore();

    // Draw inner black contour border on top
    canvas.drawPath(mouthPath, mouthOutlinePaint);
  }

  @override
  bool shouldRepaint(
    covariant _InteractiveEmotionMonsterFacePainter oldDelegate,
  ) {
    return oldDelegate.emotionValue != emotionValue ||
        oldDelegate.chinColor != chinColor ||
        oldDelegate.eyeScaleY != eyeScaleY ||
        oldDelegate.tearProgress != tearProgress ||
        oldDelegate.pointerOffset != pointerOffset;
  }
}


