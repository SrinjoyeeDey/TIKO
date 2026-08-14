import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth_mode_selection_screen.dart';
import 'game_map_1913_screen.dart';

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

  // SCREEN 1: FULLSCREEN MONSTER TAKEOVER SCREEN (Green Theme)
  Widget _buildTakeoverScreen(BuildContext context, _AgeTheme theme) {
    final size = MediaQuery.of(context).size;
    const cardTopGreen = Color(0xFF94D561);
    const cardBottomGreen = Color(0xFF6AAE38);
    final midShimmerGreen = Color.lerp(cardTopGreen, Colors.white, 0.14)!;

    return GestureDetector(
      onTap: _goToRoleSelection,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [cardTopGreen, midShimmerGreen, cardBottomGreen],
            stops: const [0.0, 0.45, 1.0],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Soft Organic Corner Accent Circles (Matching the card in screenshot)
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              top: 50,
              right: 60,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              top: -35,
              left: 30,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // 1. Pimples / Sparkles / Bubble Dots Background (Light mint green)
            Positioned.fill(
              child: CustomPaint(
                painter: const BiboPimplesPainter(
                  pimpleColor: Color(0xFFD3F1BA),
                ),
              ),
            ),

            // 2. Exact Monster Face with Smooth Blinking Eyes (Smile, Shiny Fangs, Chin Accent)
            Positioned.fill(
              child: BiboMonsterFaceWidget(chinColor: const Color(0xFF1C4108)),
            ),

            // 3. Typed Sentence Reveal (Rendered smoothly above eyes)
            if (_typedText.isNotEmpty)
              Positioned(
                top: 100,
                left: 20,
                right: 20,
                child: Center(
                  child: Text(
                    _typedText,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.fredoka(
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.6,
                      shadows: const [
                        Shadow(
                          color: Color(0x601C4108),
                          blurRadius: 14,
                          offset: Offset(0, 3),
                        ),
                        Shadow(
                          color: Color(0x30000000),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // 4. White Bouncing Ball Typewriter Overlay
            if (_isTypewriterActive) _buildTypewriterBallOverlay(size),

            // 5. Top-Right 3D Organic Signup Pill Button
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
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF1C4108), // Dark Forest Green
                            Color(0xFF2D5E12),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.65),
                          width: 1.6,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF1C4108,
                            ).withValues(alpha: 0.40),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Cute Avatar Badge Icon
                          Container(
                            width: 26,
                            height: 26,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFFDE8),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person_add_alt_1_rounded,
                              size: 15,
                              color: Color(0xFF1C4108),
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
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: Color(0xFFFFEEA0),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 6. Top Swipe Down Indicator Prompt (Go to Age Selection)
            Positioned(
              top: 28,
              child: GestureDetector(
                onTap: _goToAgeSelection,
                behavior: HitTestBehavior.opaque,
                child: Opacity(
                  opacity: 0.9,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Swipe Down for Age Selection',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(
                              color: Color(0x60000000),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 2),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 6. Bottom Swipe Up Indicator Prompt (Go to Level Map)
            Positioned(
              bottom: 28,
              child: Opacity(
                opacity: 0.9,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.keyboard_arrow_up_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Swipe Up for Level Map',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.6,
                        shadows: [
                          Shadow(
                            color: Color(0x60000000),
                            blurRadius: 8,
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

  void _completeLevelAndUnlockNext(int levelIndex) {
    debugPrint("_completeLevelAndUnlockNext called for levelIndex=$levelIndex");
    SystemSound.play(SystemSoundType.click);

    // Clicking the first level (level 0) or any level opens the 1913 World Map
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const GameMap1913Screen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
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

        return SizedBox(
          height: 1100,
          width: w,
          child: Stack(
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

              // Stone 1 (Level 0 - Top Left Curve: STARTS UNLOCKED AT TOP!)
              _buildEmergingLevelStone(
                levelIndex: 0,
                top: 22,
                left: w * 0.48 - 36,
                animVal: animVal,
              ),

              // Stone 2 (Level 1 - Heavy Right Turn)
              _buildEmergingLevelStone(
                levelIndex: 1,
                top: 88,
                left: w * 0.72 - 36,
                animVal: animVal,
              ),

              // Stone 3 (Level 2 - Mid Right Curve)
              _buildEmergingLevelStone(
                levelIndex: 2,
                top: 154,
                left: w * 0.54 - 36,
                animVal: animVal,
              ),

              // Stone 4 (Level 3 - Swing Back Center)
              _buildEmergingLevelStone(
                levelIndex: 3,
                top: 220,
                left: w * 0.36 - 36,
                animVal: animVal,
              ),

              // BUMP 3 - Buff Altar: 2x XP (Top Region, Coral Orange)
              Positioned(
                top: 260,
                right: 35,
                child: SideRoadBumpWidget(
                  bumpColor: const Color(0xFFFF8A65),
                  bumpType: SideRoadBumpType.buffAltar,
                  label: '2x XP',
                  sublabel: 'BUFF',
                  icon: Icons.flash_on_rounded,
                ),
              ),

              // Stone 5 (Level 4 - Boss Crown Node 👑)
              _buildEmergingLevelStone(
                levelIndex: 4,
                top: 286,
                left: w * 0.18 - 36,
                animVal: animVal,
              ),

              // Stone 6 (Level 5 - Mid Left Curve)
              _buildEmergingLevelStone(
                levelIndex: 5,
                top: 352,
                left: w * 0.36 - 36,
                animVal: animVal,
              ),

              // Stone 7 (Level 6 - Mid Right Curve)
              _buildEmergingLevelStone(
                levelIndex: 6,
                top: 418,
                left: w * 0.54 - 36,
                animVal: animVal,
              ),

              // BUMP 2 - Achievement Mound: 7-Day Streak (Mid Region, Fresh Green)
              Positioned(
                top: 460,
                left: 35,
                child: SideRoadBumpWidget(
                  bumpColor: const Color(0xFF78C850),
                  bumpType: SideRoadBumpType.achievement,
                  label: '7 DAYS',
                  sublabel: 'STREAK',
                  icon: Icons.local_fire_department_rounded,
                ),
              ),

              // Stone 8 (Level 7 - Heavy Right Turn)
              _buildEmergingLevelStone(
                levelIndex: 7,
                top: 484,
                left: w * 0.72 - 36,
                animVal: animVal,
              ),

              // Stone 9 (Level 8 - Mid Right Curve)
              _buildEmergingLevelStone(
                levelIndex: 8,
                top: 550,
                left: w * 0.54 - 36,
                animVal: animVal,
              ),

              // Stone 10 (Level 9 - Swing Back Center)
              _buildEmergingLevelStone(
                levelIndex: 9,
                top: 616,
                left: w * 0.36 - 36,
                animVal: animVal,
              ),

              // BUMP 1 - Crystal Relic: XP (Lower Region, Warm Gold)
              Positioned(
                top: 660,
                right: 35,
                child: SideRoadBumpWidget(
                  bumpColor: const Color(0xFFF4C95D),
                  bumpType: SideRoadBumpType.crystalRelic,
                  label: '1,240 XP',
                  sublabel: 'TOTAL',
                  icon: Icons.star_rounded,
                ),
              ),

              // Stone 11 (Level 10 - Heavy Left Turn)
              _buildEmergingLevelStone(
                levelIndex: 10,
                top: 682,
                left: w * 0.18 - 36,
                animVal: animVal,
              ),

              // Stone 12 (Level 11 - Mid Left Curve)
              _buildEmergingLevelStone(
                levelIndex: 11,
                top: 748,
                left: w * 0.36 - 36,
                animVal: animVal,
              ),

              // Stone 13 (Level 12 - Mid Right Curve)
              _buildEmergingLevelStone(
                levelIndex: 12,
                top: 814,
                left: w * 0.54 - 36,
                animVal: animVal,
              ),

              // Stone 14 (Level 13 - Bottom Right Curve)
              _buildEmergingLevelStone(
                levelIndex: 13,
                top: 880,
                left: w * 0.72 - 36,
                animVal: animVal,
              ),

              // Stone 15 (Level 14 - Winding Loop Level)
              _buildEmergingLevelStone(
                levelIndex: 14,
                top: 946,
                left: w * 0.54 - 36,
                animVal: animVal,
              ),

              // Stone 16 (Level 15 - Winding Loop Level)
              _buildEmergingLevelStone(
                levelIndex: 15,
                top: 1012,
                left: w * 0.36 - 36,
                animVal: animVal,
              ),

              // Bottom Creamy Drip Pool (Rendered IN FRONT of lower stones so stones emerge from behind it as you scroll!)
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
        onTap: () => _completeLevelAndUnlockNext(levelIndex),
        child: AnimatedScale(
          scale: isHovered ? (isBossNode ? 1.28 : 1.16) : 1.0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // XP Badge Sitting Above Active / Boss Levels
              if (isActive || isBossNode || isHovered)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: isBossNode
                        ? const Color(0xFFFFAB00)
                        : isHovered
                        ? topColor
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
                      color: isBossNode ? const Color(0xFF2E1A00) : isHovered ? const Color(0xFF183018) : Colors.white,
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
                      children: const [
                        Text(
                          'SECTION 1, UNIT 1',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFFFD166), // Warm Yellow Accent
                            letterSpacing: 0.8,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Netaji: Where there is courage, there is a way.',
                          style: TextStyle(
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

  Widget _buildDuolingoChestNode() {
    return Container(
      width: 58,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFF3C79A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4A265), width: 3),
        boxShadow: const [
          BoxShadow(color: Color(0xFFC48145), offset: Offset(0, 5)),
        ],
      ),
      child: Center(
        child: Container(
          width: 14,
          height: 14,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildDuoOwlMascot() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Blue Crystal Gem 💎
        const Text('💎', style: TextStyle(fontSize: 22)),
        const SizedBox(width: 4),

        // Cute Green Mascot Body (Duo Owl)
        Container(
          width: 56,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFF78C800),
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x35000000),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Large White Eye Patches
              Positioned(
                top: 14,
                child: Row(
                  children: [
                    Container(
                      width: 18,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF111111),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Container(
                      width: 18,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF111111),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Orange Beak
              Positioned(
                top: 32,
                child: Container(
                  width: 10,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF9600),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(5),
                    ),
                  ),
                ),
              ),

              // Orange Feet
              Positioned(
                bottom: 2,
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9600),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 10,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9600),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDuolingoWorkoutNode() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Progress Ring Arc
        const SizedBox(
          width: 78,
          height: 78,
          child: CircularProgressIndicator(
            value: 0.72,
            strokeWidth: 5,
            color: Color(0xFF58CC02),
            backgroundColor: Color(0xFFE5E5E5),
          ),
        ),

        // Node Button
        _buildDuolingoNode(icon: Icons.fitness_center_rounded),
      ],
    );
  }

  Widget _buildDuolingoBottomNavBar() {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final double safeBottomPadding = math.max(bottomInset, 12.0);

    final navItems = [
      {'icon': Icons.home_rounded, 'color': const Color(0xFF78C850), 'label': 'Home'},
      {'icon': Icons.shield_rounded, 'color': const Color(0xFFF4C95D), 'label': 'Quests'},
      {'icon': Icons.park_rounded, 'color': const Color(0xFF1F3B16), 'label': 'Practice'},
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
    return AnimatedBuilder(
      animation: _blinkAnimation,
      builder: (context, child) {
        final double scaleY = _blinkAnimation.value;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Eyebrows Row — curved arches
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomPaint(
                  size: const Size(42, 14),
                  painter: _EyebrowPainter(color: widget.accentDark),
                ),
                const SizedBox(width: 44),
                CustomPaint(
                  size: const Size(42, 14),
                  painter: _EyebrowPainter(color: widget.accentDark),
                ),
              ],
            ),
            const SizedBox(height: 5),

            // Eyes + Nostrils Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left Eye
                Transform.scale(
                  scaleY: scaleY,
                  alignment: Alignment.center,
                  child: _buildEye(isLeft: true),
                ),

                // Two nostril holes in center
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    children: [
                      const SizedBox(width: 10),
                      Container(
                        width: 9,
                        height: 7,
                        decoration: BoxDecoration(
                          color: widget.accentDark.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 9,
                        height: 7,
                        decoration: BoxDecoration(
                          color: widget.accentDark.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                  ),
                ),

                // Right Eye
                Transform.scale(
                  scaleY: scaleY,
                  alignment: Alignment.center,
                  child: _buildEye(isLeft: false),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildEye({required bool isLeft}) {
    return Container(
      width: 58,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: widget.accentDark, width: 3.0),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: isLeft ? 12 : 8,
            top: 4,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFF111111),
                shape: BoxShape.circle,
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 5,
                    left: 6,
                    child: Container(
                      width: 10,
                      height: 10,
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
        ],
      ),
    );
  }
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

    final blackBorderPaint = Paint()
      ..color = const Color(0xFF111111)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final whiteFillPaint = Paint()
      ..color = const Color(0xFFFAFAFA)
      ..style = PaintingStyle.fill;

    // 1. EYES & PUPILS (Smoothly Blinking, Two distinct tilted ovals touching at inner border)
    const eyeW = 84.0;
    const eyeH = 102.0;
    final pupilPaint = Paint()..color = const Color(0xFF111111);
    final shinePaint = Paint()..color = Colors.white;

    final eyeCenterY = cy - 35.0;

    canvas.save();
    // Apply vertical blink scaling transformation around eyeCenterY
    canvas.translate(cx, eyeCenterY);
    canvas.scale(1.0, eyeScaleY);
    canvas.translate(-cx, -eyeCenterY);

    // Left Eye (Tilted slightly right towards center)
    canvas.save();
    canvas.translate(cx - 41.0, eyeCenterY);
    canvas.rotate(0.18);
    final leftEyeLocalRect = Rect.fromCenter(
      center: Offset.zero,
      width: eyeW,
      height: eyeH,
    );
    canvas.drawOval(leftEyeLocalRect, whiteFillPaint);
    canvas.drawOval(leftEyeLocalRect, blackBorderPaint);

    // Left Pupil & Glossy Shine — moves with mouse
    final leftPupilLocal = Offset(3.5 + eyeOffset.dx, 4.0 + eyeOffset.dy);
    canvas.drawCircle(leftPupilLocal, 18.5, pupilPaint);
    canvas.drawCircle(
      Offset(leftPupilLocal.dx - 5.0, leftPupilLocal.dy - 5.0),
      4.8,
      shinePaint,
    );
    canvas.restore();

    // Right Eye (Tilted slightly left towards center)
    canvas.save();
    canvas.translate(cx + 41.0, eyeCenterY);
    canvas.rotate(-0.18);
    final rightEyeLocalRect = Rect.fromCenter(
      center: Offset.zero,
      width: eyeW,
      height: eyeH,
    );
    canvas.drawOval(rightEyeLocalRect, whiteFillPaint);
    canvas.drawOval(rightEyeLocalRect, blackBorderPaint);

    // Right Pupil & Glossy Shine — moves with mouse
    final rightPupilLocal = Offset(-3.5 + eyeOffset.dx, 4.0 + eyeOffset.dy);
    canvas.drawCircle(rightPupilLocal, 18.5, pupilPaint);
    canvas.drawCircle(
      Offset(rightPupilLocal.dx - 5.0, rightPupilLocal.dy - 5.0),
      4.8,
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

