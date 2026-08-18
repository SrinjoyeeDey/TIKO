import 'dart:async';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth_mode_selection_screen.dart';
import 'parent_auth_screen.dart';
import 'game_map_1913_screen.dart';
import 'leaderboard_screen.dart';
import '../core/services/parent_repository.dart';
import '../qa_pipeline/screens/parent_dashboard.dart';
import '../features/activities/catch_nimo/screens/catch_nimo_screen.dart';
import '../features/activities/remember_nimo/screens/remember_nimo_screen.dart';
import '../features/activities/echo_nimo/screens/echo_nimo_screen.dart';
import '../features/activities/find_nimo/screens/find_nimo_screen.dart';
import '../features/activities/category_sort/screens/category_sort_screen.dart';
import '../features/activities/turn_nimo/screens/turn_nimo_screen.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
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
  final int initialPage;
  const SegoConceptScreen({super.key, this.initialPage = 0});

  @override
  State<SegoConceptScreen> createState() => _SegoConceptScreenState();
}

class _SegoConceptScreenState extends State<SegoConceptScreen>
    with TickerProviderStateMixin {
  double _currentAge = 7.0;
  double _emotionValue =
      0.5; // 0.0: Not good (Sky Blue), 0.5: Great (Lavender), 1.0: Awesome (Yellow)
  int _screenIndex =
      0; // 0: Age Selection, 1: Monster Takeover, 2: Role Selection
  String? _selectedRole;
  int _selectedSpeechLevelIndex = 1;
  int _assessmentStep = 0;
  final String _childName = 'Alex';

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

  late final Player _bgVideoPlayer;
  late final VideoController _bgVideoController;
  bool _isBgVideoInitialized = false;
  Duration _bgVideoDuration = Duration.zero;
  bool _isLoopingTransitioning = false;

  int _unlockedLevelIndex =
      2; // Node 2 ("Your Vehicle") is the active yellow play button matching reference image!
  int? _animatingUnlockingIndex;
  int? _hoveredLevelIndex;
  int _activeNavIndex = 4; // Video Call tab default selected
  Offset _cursorPos = const Offset(-200, -200);
  bool _isCursorInside = false;
  String _selectedOnboardingRole = 'child';
  String? _hoveredOnboardingRole;
  bool _roleCardLocked = false;
  bool _showParentPin = false;
  String _parentPinInput = '';

  String _getEmotionTitleString(double t) {
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

  List<LearningChapter> _chapters = [];
  Map<String, String?> _stageCoverImages = {};
  int _unlockedStageIndex = 0;

  @override
  void dispose() {
    _bgVideoPlayer.dispose();
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
    _bgVideoPlayer = Player();
    _bgVideoController = VideoController(_bgVideoPlayer);
    _initBgVideoPlayer();
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
    _takeoverPageController = PageController(initialPage: widget.initialPage);
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

  Future<void> _initBgVideoPlayer() async {
    try {
      await _bgVideoPlayer.setVolume(0.0); // Mute ambient background video

      _bgVideoPlayer.stream.duration.listen((duration) {
        _bgVideoDuration = duration;
      });

      // Ultra-smooth pre-emptive loop transition rewind before EOF freeze!
      _bgVideoPlayer.stream.position.listen((position) {
        if (_bgVideoDuration > Duration.zero &&
            position >= _bgVideoDuration - const Duration(milliseconds: 300) &&
            !_isLoopingTransitioning) {
          _isLoopingTransitioning = true;
          _bgVideoPlayer.seek(Duration.zero);
          Future.delayed(const Duration(milliseconds: 500), () {
            _isLoopingTransitioning = false;
          });
        }
      });

      final playlist = Playlist([
        Media('asset:///assets/Netaji/COVER_IMG/video2.mp4'),
        Media('asset:///assets/images/video2.mp4'),
      ]);

      // Auto-restart listener guarantees video2 loops infinitely without ever stopping!
      _bgVideoPlayer.stream.completed.listen((completed) async {
        if (completed) {
          try {
            await _bgVideoPlayer.seek(Duration.zero);
            await _bgVideoPlayer.play();
          } catch (_) {
            await _bgVideoPlayer.open(playlist, play: true);
          }
        }
      });

      await _bgVideoPlayer.open(playlist, play: true);
      await _bgVideoPlayer.setPlaylistMode(PlaylistMode.loop);

      if (mounted) {
        setState(() {
          _isBgVideoInitialized = true;
        });
      }
    } catch (e) {
      debugPrint("Background video playlist init error: $e");
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

  void _goToOnboardingSplash() {
    if (_takeoverPageController.hasClients) {
      _takeoverPageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutQuart,
      );
    }
  }

  void _goToAgeSelection() {
    if (_takeoverPageController.hasClients) {
      _takeoverPageController.jumpToPage(1);
    }
  }

  void _showRegistrationSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Dialog(
            backgroundColor: const Color(0xEE18181B),
            elevation: 16,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
              side: BorderSide(color: const Color(0xFF10B981).withValues(alpha: 0.6), width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0x2210B981),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF10B981), width: 2),
                      boxShadow: const [
                        BoxShadow(color: Color(0x4410B981), blurRadius: 18, spreadRadius: 2),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 36),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Registration Successful ✓',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Learner age (${_currentAge.round()} Years) saved. Proceed to complete child developmental assessment.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13,
                      color: Color(0xFF9CA3AF),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(dialogCtx).pop();
                        if (_takeoverPageController.hasClients) {
                          _takeoverPageController.jumpToPage(2);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Continue to Questionnaire', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                        ],
                      ),
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

  void _goToSpeechLevelScreen() {
    _showRegistrationSuccessDialog();
  }

  void _goToTakeoverScreen() {
    if (_takeoverPageController.hasClients) {
      _takeoverPageController.jumpToPage(0);
    }
  }

  void _goToQuestCategoryScreen() {
    if (_takeoverPageController.hasClients) {
      _takeoverPageController.jumpToPage(3);
    }
  }

  void _goToRoleSelection() {
    if (_takeoverPageController.hasClients) {
      _takeoverPageController.animateToPage(
        4,
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

              // 5-Page Navigation (Programmatic Flow Controlled - NeverScrollable)
              Positioned.fill(
                child: PageView(
                  controller: _takeoverPageController,
                  scrollDirection: Axis.vertical,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    // Page 0: Expression Entry Screen ("How was your day?")
                    _buildOnboardingSplashScreen(context),

                    // Page 1: Age Selection Screen
                    _buildAgeScreen(context, theme),

                    // Page 2 (Placement 3): Question & Answers Screen (Speech Level)
                    _buildSpeechLevelScreen(context, theme),

                    // Page 3 (Placement 4): Quest Page (Category / 6 Quests)
                    _buildQuestCategoryScreen(context, theme),

                    // Page 4: Level Map Screen (Stepping Stones)
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

  // MAIN ENTRY SCREEN (Replaces "Who's joining Tiko?" with "How was your day?" Expression Entry Screen)
  Widget _buildOnboardingSplashScreen(BuildContext context) {
    return _buildTakeoverScreen(context, _themeGreen);
  }

  Widget _buildOnboardingRoleCard({
    required String roleKey,
    required String title,
    required String subtitle,
    required IconData iconData,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final bool isHovered = _hoveredOnboardingRole == roleKey;
    final bool isLocked = _roleCardLocked && _selectedOnboardingRole == roleKey;
    final bool isHighlighted = isHovered || isLocked;

    final themeColor = roleKey == 'child'
        ? const Color(0xFFFFB300)
        : const Color(0xFFFF2A6D);

    final Gradient heroGradient = roleKey == 'child'
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFD54F), Color(0xFFFFB300), Color(0xFFFF8F00)],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF5252), Color(0xFFFF2A6D), Color(0xFFE91E63)],
          );

    final String overlayHeadline = roleKey == 'child'
        ? "Let's Explore! 🚀"
        : 'Ready to Guide ✨';
    final String overlaySubtext = roleKey == 'child'
        ? 'Start your adventure\nthrough NIMO\'s world'
        : 'Support & track your\nchild\'s journey';

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredOnboardingRole = roleKey),
      onExit: (_) => setState(() => _hoveredOnboardingRole = null),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (_roleCardLocked && _selectedOnboardingRole == roleKey) {
              _roleCardLocked = false;
            } else {
              _selectedOnboardingRole = roleKey;
              _roleCardLocked = true;
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          width: double.infinity,
          height: 220,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0x35FFF3C4), // Luminous warm yellow tint!
            borderRadius: BorderRadius.circular(36),
            border: Border.all(
              color: const Color(0x60FFB300),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0x1A000000),
                blurRadius: isHighlighted ? 24 : 14,
                offset: Offset(0, isHighlighted ? 10 : 5),
                spreadRadius: 0,
              ),
              if (isHighlighted)
                BoxShadow(
                  color: themeColor.withValues(alpha: 0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.antiAlias,
            children: [
              // --- Translucent Warm Yellowish Card Background ---
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x55FFF8E1),
                        Color(0x35FFD54F),
                      ],
                    ),
                  ),
                ),
              ),

              // --- Top Hero Color Slice Background Accent ---
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 80,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        themeColor.withValues(alpha: 0.22),
                        themeColor.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),

              // --- Floating Translucent Background Accents (Eliminates Empty Look!) ---
              Positioned(
                top: 10,
                right: -10,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: themeColor.withValues(alpha: 0.12),
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                left: -15,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.30),
                  ),
                ),
              ),

              // --- Unhovered Content (At bottom of card, covered smoothly by white panel) ---
              Positioned(
                bottom: 10,
                left: 8,
                right: 8,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: isHighlighted ? 0.0 : 1.0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title + Green Verified Badge Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF3E1F00),
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Icon(
                            Icons.verified_rounded,
                            color: Color(0xFF22C55E),
                            size: 17,
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        roleKey == 'child'
                            ? 'Games • Quizzes • Creative World'
                            : 'Progress • Controls • PIN Guard',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6B4300),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // 3 Feature Badges Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: (roleKey == 'child'
                                ? ['🎮 Play', '⭐ Learn', '🚀 Explore']
                                : ['📊 Track', '🛡️ Safety', '🎯 Insights'])
                            .map((tag) => Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 2.5),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.white.withValues(alpha: 0.88),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: themeColor.withValues(alpha: 0.35),
                                      width: 1.0,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x10000000),
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      )
                                    ],
                                  ),
                                  child: Text(
                                    tag,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: themeColor,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 6),
                      // Status / Hover Hint Line
                      Text(
                        roleKey == 'child'
                            ? '✨ Tap / Hover to start adventure'
                            : '🔒 Secure Parent Portal Entry',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF8C5800),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- WHITE PANEL: Slides UP smoothly from bottom on hover! ---
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                    bottomLeft: Radius.circular(36),
                    bottomRight: Radius.circular(36),
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 380),
                    curve: Curves.easeOutCubic,
                    height: isHighlighted ? 135 : 0,
                    color: Colors.white,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 240),
                      opacity: isHighlighted ? 1.0 : 0.0,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            overlayHeadline,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: themeColor,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            overlaySubtext,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B7280),
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () {
                              if (roleKey == 'child') {
                                _goToAgeSelection();
                              } else {
                                setState(() {
                                  _showParentPin = true;
                                  _parentPinInput = '';
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 22, vertical: 8),
                              decoration: BoxDecoration(
                                color: themeColor,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: themeColor.withValues(alpha: 0.40),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Text(
                                roleKey == 'child'
                                    ? "Let's Go  →"
                                    : 'Enter PIN  🔐',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // --- Persistent Avatar Circle (Always at top center) ---
              Positioned(
                top: 10,
                left: 0,
                right: 0,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutBack,
                    width: isHighlighted ? 72 : 66,
                    height: isHighlighted ? 72 : 66,
                    decoration: BoxDecoration(
                      gradient: heroGradient,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 3.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: themeColor.withValues(
                              alpha: isHighlighted ? 0.55 : 0.25),
                          blurRadius: isHighlighted ? 20 : 12,
                          offset: const Offset(0, 4),
                          spreadRadius: isHighlighted ? 2 : 0,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        iconData,
                        size: isHighlighted ? 40 : 36,
                        color: Colors.white,
                      ),
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

  // ====== PARENT PIN OVERLAY ======
  Widget _buildParentPinOverlay() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () {}, // block tap-through
        child: Container(
          color: const Color(0xEF000000),
          child: SafeArea(
            child: Column(
              children: [
                // Top Action Bar with Sign Up & Close button
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Sign Up Action Pill
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showParentPin = false;
                            _parentPinInput = '';
                          });
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ParentAuthScreen(
                                initialMode: ParentAuthMode.signup,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFC6B6B),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x33FC6B6B),
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 16),
                              SizedBox(width: 6),
                              Text(
                                'SIGN UP',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Close button
                      GestureDetector(
                        onTap: () => setState(() {
                          _showParentPin = false;
                          _parentPinInput = '';
                        }),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Color(0xFF27272A),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Lock icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF27272A),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFF2A6D).withValues(alpha: 0.60),
                      width: 2,
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.lock_rounded, color: Color(0xFFFF2A6D), size: 30),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Parent PIN',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Set a 4-digit PIN to secure\nParent mode',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9CA3AF),
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 40),

                // 4 dot PIN indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (i) {
                    final filled = i < _parentPinInput.length;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutBack,
                      margin: const EdgeInsets.symmetric(horizontal: 14),
                      width: filled ? 20 : 16,
                      height: filled ? 20 : 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: filled
                            ? const Color(0xFFFF2A6D)
                            : Colors.transparent,
                        border: Border.all(
                          color: filled
                              ? const Color(0xFFFF2A6D)
                              : const Color(0xFF52525B),
                          width: 2,
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 48),

                // Numeric Keypad
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  child: Column(
                    children: [
                      _buildPinRow(['1', '2', '3']),
                      const SizedBox(height: 14),
                      _buildPinRow(['4', '5', '6']),
                      const SizedBox(height: 14),
                      _buildPinRow(['7', '8', '9']),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          const SizedBox(width: 80, height: 80), // placeholder
                          _buildPinKey('0'),
                          _buildPinBackspace(),
                        ],
                      ),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showParentPin = false;
                            _parentPinInput = '';
                          });
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ParentAuthScreen(
                                initialMode: ParentAuthMode.signup,
                              ),
                            ),
                          );
                        },
                        child: RichText(
                          text: const TextSpan(
                            text: "Don't have an Account ? ",
                            style: TextStyle(fontFamily: 'Outfit', color: Colors.grey, fontSize: 13),
                            children: [
                              TextSpan(
                                text: 'Sign up',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  color: Color(0xFFFF2A6D),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPinRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map(_buildPinKey).toList(),
    );
  }

  Widget _buildPinKey(String digit) {
    return GestureDetector(
      onTap: () {
        if (_parentPinInput.length < 4) {
          setState(() => _parentPinInput += digit);
          if (_parentPinInput.length == 4) {
            Future.delayed(const Duration(milliseconds: 350), () {
              if (mounted) {
                setState(() {
                  _showParentPin = false;
                  _parentPinInput = '';
                  _roleCardLocked = false;
                });
                _goToAgeSelection();
              }
            });
          }
        }
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF27272A),
          boxShadow: const [
            BoxShadow(
              color: Color(0x50000000),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            digit,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPinBackspace() {
    return GestureDetector(
      onTap: () {
        if (_parentPinInput.isNotEmpty) {
          setState(() => _parentPinInput =
              _parentPinInput.substring(0, _parentPinInput.length - 1));
        }
      },
      child: const SizedBox(
        width: 80,
        height: 80,
        child: Center(
          child: Icon(Icons.backspace_outlined, color: Colors.white, size: 26),
        ),
      ),
    );
  }
  // ====== END PARENT PIN OVERLAY ======

  Widget _buildPopUpMascot({
    required String roleKey,
    required bool isHighlighted,
  }) {
    final bodyColor = isHighlighted
        ? const Color(0xFF1E1B4B)
        : const Color(0xFF2C2C2C).withValues(alpha: 0.45);

    if (roleKey == 'child') {
      // --- CHILD CARD MASCOT: Playful Little Alien/Monster with Glowing Antenna & Eyes ---
      return SizedBox(
        width: 54,
        height: 68,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Body dome
            Container(
              width: 44,
              height: 48,
              decoration: BoxDecoration(
                color: bodyColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
            ),

            // Top Center Antenna
            Positioned(
              top: 2,
              child: Column(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: isHighlighted
                          ? const Color(0xFFFFD54F)
                          : Colors.white.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                      boxShadow: isHighlighted
                          ? [
                              const BoxShadow(
                                color: Color(0xFFFFD54F),
                                blurRadius: 8,
                                spreadRadius: 1,
                              )
                            ]
                          : [],
                    ),
                  ),
                  Container(
                    width: 3,
                    height: 10,
                    color: bodyColor,
                  ),
                ],
              ),
            ),

            // Big Glowing Eyes with Pupils
            Positioned(
              top: 24,
              child: Row(
                children: [
                  Container(
                    width: isHighlighted ? 11 : 6,
                    height: isHighlighted ? 11 : 3,
                    decoration: BoxDecoration(
                      color: isHighlighted
                          ? const Color(0xFFFFEA00)
                          : Colors.white.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: isHighlighted
                        ? Center(
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: Color(0xFF0F172A),
                                shape: BoxShape.circle,
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: isHighlighted ? 11 : 6,
                    height: isHighlighted ? 11 : 3,
                    decoration: BoxDecoration(
                      color: isHighlighted
                          ? const Color(0xFFFFEA00)
                          : Colors.white.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: isHighlighted
                        ? Center(
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: Color(0xFF0F172A),
                                shape: BoxShape.circle,
                              ),
                            ),
                          )
                        : null,
                  ),
                ],
              ),
            ),

            // Cute Pink Cheeks
            if (isHighlighted)
              Positioned(
                top: 34,
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF80AB),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 22),
                    Container(
                      width: 6,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF80AB),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    } else {
      // --- PARENT CARD MASCOT: Wise Owl with Round Spectacles & Beak ---
      return SizedBox(
        width: 56,
        height: 68,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Owl Body
            Container(
              width: 46,
              height: 48,
              decoration: BoxDecoration(
                color: bodyColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(23),
                  topRight: Radius.circular(23),
                ),
              ),
            ),

            // Pointy Owl Ear Tufts
            Positioned(
              top: 6,
              left: 7,
              child: Container(
                width: 10,
                height: 14,
                decoration: BoxDecoration(
                  color: bodyColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 6,
              right: 7,
              child: Container(
                width: 10,
                height: 14,
                decoration: BoxDecoration(
                  color: bodyColor,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(8),
                  ),
                ),
              ),
            ),

            // Spectacles + Eyes
            Positioned(
              top: 20,
              child: Row(
                children: [
                  Container(
                    width: isHighlighted ? 15 : 8,
                    height: isHighlighted ? 15 : 4,
                    decoration: BoxDecoration(
                      color: isHighlighted
                          ? const Color(0xFFFFF8E7)
                          : Colors.white.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isHighlighted
                            ? const Color(0xFFFFD54F)
                            : Colors.transparent,
                        width: 1.8,
                      ),
                    ),
                    child: isHighlighted
                        ? Center(
                            child: Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                color: Color(0xFF0F172A),
                                shape: BoxShape.circle,
                              ),
                            ),
                          )
                        : null,
                  ),
                  Container(
                    width: 4,
                    height: 2,
                    color: isHighlighted ? const Color(0xFFFFD54F) : Colors.transparent,
                  ),
                  Container(
                    width: isHighlighted ? 15 : 8,
                    height: isHighlighted ? 15 : 4,
                    decoration: BoxDecoration(
                      color: isHighlighted
                          ? const Color(0xFFFFF8E7)
                          : Colors.white.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isHighlighted
                            ? const Color(0xFFFFD54F)
                            : Colors.transparent,
                        width: 1.8,
                      ),
                    ),
                    child: isHighlighted
                        ? Center(
                            child: Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                color: Color(0xFF0F172A),
                                shape: BoxShape.circle,
                              ),
                            ),
                          )
                        : null,
                  ),
                ],
              ),
            ),

            // Golden Beak
            if (isHighlighted)
              Positioned(
                top: 36,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF59E0B),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      );
    }
  }

  // SCREEN 1: AGE SELECTION SCREEN
  Widget _buildAgeScreen(BuildContext context, _AgeTheme theme) {
    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null &&
            details.primaryVelocity! < -150) {
          _goToSpeechLevelScreen();
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
                          onNext: _goToSpeechLevelScreen,
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

  // SCREEN 2: SPEECH LEVEL SELECTION SCREEN (PRELIMINARY Question & Assessment Flow)
  Widget _buildSpeechLevelScreen(BuildContext context, _AgeTheme theme) {
    const int totalQuestions = 29;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF3B82F6),
            Color(0xFF6366F1),
            Color(0xFFDBEAFE),
          ],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: _SpeechLevelSelectorWidget(
              theme: theme,
              step: _assessmentStep,
              childName: _childName,
              onNextStep: () async {
                if (_assessmentStep < totalQuestions - 1) {
                  setState(() => _assessmentStep++);
                } else {
                  final parent = await ParentRepository.getActiveParent();
                  final parentId = parent?.id ?? 'default_parent';
                  await ParentRepository.setOnboardingCompleted(parentId);
                  if (mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => ParentDashboard(
                          childId: ChildState.instance.currentProfile.id,
                        ),
                      ),
                    );
                  }
                }
              },
              onPrevStep: () {
                if (_assessmentStep > 0) {
                  setState(() => _assessmentStep--);
                } else {
                  _goToAgeSelection();
                }
              },
            ),
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

  // SCREEN 1: PREMIUM EXPRESSION-BASED ENTRY SCREEN (Dynamic Emotion Synced Theme)
  Widget _buildTakeoverScreen(BuildContext context, _AgeTheme theme) {
    final bgTopColor = _lerp4Colors(
      const Color(0xFFEF4444), // sad (Red)
      const Color(0xFFF97316), // grumpy (Burnt Orange)
      const Color(0xFF84CC16), // silly (Apple Lime Green)
      const Color(0xFFEAB308), // awesome (Gold)
      _emotionValue,
    );

    final bgBottomColor = _lerp4Colors(
      const Color(0xFF991B1B), // sad (Deep Crimson)
      const Color(0xFFC2410C), // grumpy (Deep Burnt Orange)
      const Color(0xFF4D7C0F), // silly (Deep Forest Green)
      const Color(0xFFA16207), // awesome (Deep Amber)
      _emotionValue,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            bgTopColor,
            bgBottomColor,
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Straight Grid Pattern Background Layer
          Positioned.fill(
            child: CustomPaint(
              painter: CategoryGridPainter(),
            ),
          ),

          // Main Screen Content Layout
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Navigation Header: Back Arrow & Sign Up
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                        },
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white,
                              width: 1.5,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x10000000),
                                blurRadius: 10,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),

                      // Sign Up Action Pill
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ParentAuthScreen(
                                initialMode: ParentAuthMode.signup,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white,
                              width: 1.5,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x1A000000),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.person_add_alt_1_rounded,
                                size: 16,
                                color: Color(0xFF10B981),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'SIGN UP',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E293B),
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Header Prompt: "How was your day?"
                  const Text(
                    'How was your day?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Express your mood & select your access path.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.90),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Hero Expression Card & Access Path Cards
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Enlarged Expression Hero Card (Upper Layer Floating)
                            _CompactEmotionCard(
                              emotionValue: _emotionValue,
                              onChanged: (val) {
                                setState(() => _emotionValue = val);
                              },
                            ),

                            const SizedBox(height: 14),

                            // Two Pastel Access Cards: CHILD and PARENT (Slightly Enlarged)
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 460),
                              child: Row(
                                children: [
                                  // CHILD ACCESS CARD (Soft Pastel Pink Card with Grid)
                                  Expanded(
                                    child: _buildWhiteAccessCard(
                                      title: 'CHILD',
                                      subtext: "Let's Play 🎮",
                                      iconData: Icons.face_rounded,
                                      bgGradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [Color(0xFFFCE7F3), Color(0xFFFBCFE8)], // Soft Pastel Pink
                                      ),
                                      titleColor: const Color(0xFF831843),
                                      gridColor: const Color(0x38F472B6),
                                      onTap: () {
                                        HapticFeedback.mediumImpact();
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => ParentAuthScreen(
                                              initialMode: ParentAuthMode.childLogin,
                                              onAuthSuccess: () {
                                                Navigator.of(context).pop(); // Pop Auth screen
                                                _goToQuestCategoryScreen(); // Show Ready to Play Category page
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  // PARENT ACCESS CARD (Soft Sky Blue Card with Grid)
                                  Expanded(
                                    child: _buildWhiteAccessCard(
                                      title: 'PARENT',
                                      subtext: 'Guide & Track 🔒',
                                      iconData: Icons.family_restroom_rounded,
                                      bgGradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [Color(0xFFE0F2FE), Color(0xFFBAE6FD)], // Soft Sky Blue
                                      ),
                                      titleColor: const Color(0xFF1E3A8A),
                                      gridColor: const Color(0x3838BDF8),
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => ParentAuthScreen(
                                              initialMode: ParentAuthMode.loginPin,
                                              onAuthSuccess: () {
                                                Navigator.of(context).pop(); // Pop Auth screen
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (_) => ParentDashboard(
                                                      childId: ChildState.instance.currentProfile.id,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        );
                                      },
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
              ),
            ),
          ),

          // Parent PIN Authentication Overlay
          if (_showParentPin) _buildParentPinOverlay(),
        ],
      ),
    );
  }

  // ACCESS CARD COMPONENT (Matching Reference Card with Thick White Border, Grid Pattern & Hover Shadow)
  Widget _buildWhiteAccessCard({
    required String title,
    required String subtext,
    required IconData iconData,
    required VoidCallback onTap,
    Gradient? bgGradient,
    Color? titleColor,
    Color? gridColor,
  }) {
    bool isPressed = false;
    bool isHovered = false;
    final Color textColor = titleColor ?? const Color(0xFF0F172A);
    final Color cardGridColor = gridColor ?? const Color(0x20000000);

    return StatefulBuilder(
      builder: (context, setCardState) {
        return MouseRegion(
          onEnter: (_) => setCardState(() => isHovered = true),
          onExit: (_) => setCardState(() => isHovered = false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTapDown: (_) => setCardState(() => isPressed = true),
            onTapUp: (_) => setCardState(() => isPressed = false),
            onTapCancel: () => setCardState(() => isPressed = false),
            onTap: onTap,
            child: AnimatedScale(
              scale: isPressed ? 0.96 : (isHovered ? 1.03 : 1.0),
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                transform: Matrix4.translationValues(0, isHovered ? -5 : 0, 0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white,
                    width: 6.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: textColor.withValues(alpha: isHovered ? 0.32 : 0.18),
                      blurRadius: isHovered ? 24 : 16,
                      spreadRadius: isHovered ? 2 : 0,
                      offset: Offset(0, isHovered ? 12 : 6),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isHovered ? 0.14 : 0.08),
                      blurRadius: isHovered ? 14 : 8,
                      offset: Offset(0, isHovered ? 6 : 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(21),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: bgGradient ??
                          const LinearGradient(
                            colors: [Colors.white, Colors.white],
                          ),
                    ),
                    child: Stack(
                      children: [
                        // In-Card Grid Background Layer
                        Positioned.fill(
                          child: CustomPaint(
                            painter: InCardGridPainter(gridColor: cardGridColor),
                          ),
                        ),

                        // Card Content
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Icon Container (White Circle)
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: textColor.withValues(alpha: 0.16),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  iconData,
                                  size: 28,
                                  color: textColor,
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Card Title
                              Text(
                                title,
                                style: GoogleFonts.poppins(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: textColor,
                                  letterSpacing: 0.6,
                                ),
                              ),

                              const SizedBox(height: 10),

                              // White Action Pill Button
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x14000000),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  subtext,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
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
            ),
          ),
        );
      },
    );
  }

  // SCREEN 3.5: QUEST CATEGORY SELECTION SCREEN (6 Quests - Single Page Fit)
  Widget _buildQuestCategoryScreen(BuildContext context, _AgeTheme theme) {
    final List<Map<String, dynamic>> quests = [
      {
        'title': 'Cognitive Quest',
        'image': 'ui_assets/Cognitive quest.png',
        'altImage': 'assets/images/Cognitive quest.png',
        'emoji': '🧠',
        'sub': '15 Courses',
        'topPadding': 38.0,
        'scale': 1.0,
        'gradient': const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFB0B0), Color(0xFFFF6B6B)],
        ),
        'accent': const Color(0xFFFF5252),
      },
      {
        'title': 'Communication Quest',
        'image': 'ui_assets/communication.png',
        'altImage': 'assets/images/communication.png',
        'emoji': '🗣️',
        'sub': '12 Courses',
        'topPadding': 46.0,
        'scale': 0.95,
        'gradient': const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5CD2B5), Color(0xFF20B2AA)],
        ),
        'accent': const Color(0xFF009688),
      },
      {
        'title': 'Motor Quest',
        'image': 'ui_assets/motor.png',
        'altImage': 'assets/images/motor.png',
        'emoji': '✋',
        'sub': '10 Courses',
        'topPadding': 38.0,
        'scale': 1.0,
        'gradient': const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF9FA8DA), Color(0xFF5C6BC0)],
        ),
        'accent': const Color(0xFF3F51B5),
      },
      {
        'title': 'Heritage Quest',
        'image': 'ui_assets/heritage.png',
        'altImage': 'assets/images/heritage.png',
        'emoji': '🇮🇳',
        'sub': '14 Courses',
        'topPadding': 42.0,
        'scale': 0.98,
        'gradient': const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFCC80), Color(0xFFFB8C00)],
        ),
        'accent': const Color(0xFFF57C00),
      },
      {
        'title': 'Social Quest',
        'image': 'ui_assets/social.png',
        'altImage': 'assets/images/social.png',
        'emoji': '🤝',
        'sub': '8 Courses',
        'topPadding': 38.0,
        'scale': 1.15,
        'gradient': const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
        ),
        'accent': const Color(0xFF0284C7),
      },
      {
        'title': 'Creative Quest',
        'image': 'ui_assets/creative.png',
        'altImage': 'assets/images/creative.png',
        'emoji': '🎨',
        'sub': '16 Courses',
        'topPadding': 38.0,
        'scale': 1.0,
        'gradient': const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFCE93D8), Color(0xFFAB47BC)],
        ),
        'accent': const Color(0xFF8E24AA),
      },
    ];

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFB497F8), // Soft Lavender Purple Header
            Color(0xFFA78BFA),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Grid Pattern Background Layer
          Positioned.fill(
            child: CustomPaint(
              painter: CategoryGridPainter(),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header (Compact)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              _goToTakeoverScreen();
                            },
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_back_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Category',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Ready to learn? Headline Title
                      const Text(
                        'Ready to learn?',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.1,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Choose your subject. Subtitle
                      Text(
                        'Choose your subject.',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // White Sheet Container for Filter Tabs + Quests Grid
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x1A000000),
                          blurRadius: 20,
                          offset: Offset(0, -6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),

                        // Filter Pill Tabs (All, Favourite, Recommended)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Row(
                            children: [
                              // "All" Active Tab
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8B5CF6),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x358B5CF6),
                                      blurRadius: 8,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  'All',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),

                              // "Favourite" Inactive Tab
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEF2FF),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Favourite',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF6366F1),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),

                              // "Recommended" Inactive Tab
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEF2FF),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Recommended',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF6366F1),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // 2-Column Grid of 6 Quest Cards
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18.0),
                            child: GridView.builder(
                              physics: const BouncingScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                                childAspectRatio: 1.05,
                              ),
                              itemCount: quests.length,
                              itemBuilder: (context, index) {
                                final item = quests[index];
                                return GestureDetector(
                                  onTap: () {
                                    HapticFeedback.mediumImpact();
                                    _goToRoleSelection();
                                  },
                                  child: Container(
                                    clipBehavior: Clip.antiAlias,
                                    decoration: BoxDecoration(
                                      gradient: item['gradient'] as Gradient,
                                      borderRadius: BorderRadius.circular(22),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2.0,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: (item['accent'] as Color).withValues(alpha: 0.35),
                                          blurRadius: 10,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      children: [
                                        // 1. Direct Card Image Illustration Fit (Clipped within Boundaries)
                                        Positioned.fill(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(20),
                                            child: Padding(
                                              padding: EdgeInsets.only(
                                                top: (item['topPadding'] as double? ?? 40.0),
                                                bottom: 6,
                                                left: 6,
                                                right: 6,
                                              ),
                                              child: Transform.scale(
                                                scale: item['scale'] as double? ?? 1.0,
                                                alignment: Alignment.bottomCenter,
                                                child: Image.asset(
                                                  item['image'] as String,
                                                  fit: BoxFit.contain,
                                                  alignment: Alignment.bottomCenter,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return Image.asset(
                                                      item['altImage'] as String? ?? '',
                                                      fit: BoxFit.contain,
                                                      alignment: Alignment.bottomCenter,
                                                      errorBuilder: (context, err, st) => Container(),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),

                                        // 2. Subtle Text Protection Shadow Gradient (Top)
                                        Positioned(
                                          top: 0,
                                          left: 0,
                                          right: 0,
                                          height: 48,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Colors.black.withValues(alpha: 0.35),
                                                  Colors.transparent,
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),

                                        // 3. Card Title & Courses Subtitle Text (Top Left)
                                        Positioned(
                                          top: 12,
                                          left: 12,
                                          right: 12,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                item['title'] as String,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontFamily: 'Outfit',
                                                  fontSize: 14.5,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.white,
                                                  shadows: [
                                                    Shadow(
                                                      color: Color(0x80000000),
                                                      blurRadius: 4,
                                                      offset: Offset(0, 1),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                item['sub'] as String,
                                                style: TextStyle(
                                                  fontFamily: 'Outfit',
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white.withValues(alpha: 0.92),
                                                  shadows: const [
                                                    Shadow(
                                                      color: Color(0x70000000),
                                                      blurRadius: 4,
                                                      offset: Offset(0, 1),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
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

  // SCREEN 2: DUOLINGO-STYLE VIDEO CALL LEVEL MAP SCREEN (Custom Color Palette)
  Widget _buildRoleScreen(BuildContext context, _AgeTheme theme) {
    final size = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: _waterWaveController,
      builder: (context, child) {
        return Stack(
          children: [
            // 1. Looping Background Video with Light Shade Tint Overlay!
            Positioned.fill(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Base Mint Landscape Gradient Background
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.0, 0.45, 1.0],
                        colors: [
                          Color(0xFFFFFFFF),
                          Color(0xFFEFF8F2),
                          Color(0xFFD6EFE0),
                        ],
                      ),
                    ),
                  ),

                  // Looping Video Layer
                  if (_isBgVideoInitialized)
                    Video(
                      controller: _bgVideoController,
                      fit: BoxFit.cover,
                      controls: NoVideoControls,
                    ),

                  // Light Shade Tint Overlay (Translucent soft white tint layer)
                  Container(color: Colors.white.withValues(alpha: 0.82)),
                ],
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

  void _completeLevelAndUnlockNext(
    int levelIndex, [
    Offset? tapOffset,
    Color? buttonColor,
  ]) {
    debugPrint("_completeLevelAndUnlockNext called for levelIndex=$levelIndex");
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
      final prevName = levelIndex > 0
          ? effectiveChapters[levelIndex - 1].name
          : 'previous stage';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('🔒 Complete $prevName first to unlock ${chapter.name}!'),
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

    // If this node corresponds to an active learning chapter (Level 1: Bharatnatyam, Level 2: Netaji, etc.)
    if (levelIndex < effectiveChapters.length) {
      Navigator.of(context)
          .push(
        SmokeBombPageRoute(
          page: GameMap1913Screen(chapterId: chapter.id),
          originOffset: origin,
          buttonColor: initialColor,
          vintageMapColor: const Color(0xFFF4E8C1),
        ),
      )
          .then((_) {
        _loadDynamicChapters();
      });
      return;
    }

    // Minigame & Special Activity Node Fallbacks for higher levels:
    if (levelIndex == 2) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const CatchNimoScreen()));
      return;
    }
    if (levelIndex == 3) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const RememberNimoScreen()));
      return;
    }
    if (levelIndex == 4) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const EchoNimoScreen()));
      return;
    }
    if (levelIndex == 5) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const FindNimoScreen()));
      return;
    }
    if (levelIndex == 6) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const CategorySortScreen()));
      return;
    }
    if (levelIndex == 7) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const TurnNimoScreen()));
      return;
    }

    // Default: Smoke Bomb Time-Travel Transition to 1913 Game Map
    Navigator.of(context)
        .push(
      SmokeBombPageRoute(
        page: GameMap1913Screen(chapterId: chapter.id),
        originOffset: origin,
        buttonColor: initialColor,
        vintageMapColor: const Color(0xFFF4E8C1),
      ),
    )
        .then((_) {
      _loadDynamicChapters();
    });
  }

  static const List<String> _levelTitles = [
    'Bharatnatyam',
    'Netaji Bose',
    'Swami Dayanandji',
    'Swami Vivekananda',
    'Bhagat Singh',
    'Rani Lakshmibai',
    'Subhashini',
    'Rabindranath',
    'Sarojini Naidu',
    'APJ Abdul Kalam',
    'Ashoka Great',
    'Chhatrapati Shivaji',
  ];

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

          final double emergenceRatio = (distFromBottom / 180.0).clamp(
            0.0,
            1.0,
          );
          final double scale = 0.60 + (0.40 * emergenceRatio);
          final double translateY = (1.0 - emergenceRatio) * 30.0;
          final double opacity = (0.30 + (0.70 * emergenceRatio)).clamp(
            0.0,
            1.0,
          );

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

    // Spacious Serpentine Node Grid (175px vertical step spacing between road tiers!)
    final List<Offset> nodeOffsets = [
      Offset(
        w * 0.28,
        80,
      ), // Node 0 (Row 1 Left: Road to Your License - Completed)
      Offset(w * 0.72, 80), // Node 1 (Row 1 Right: Right of Way I - Completed)
      Offset(
        w * 0.50,
        255,
      ), // Node 2 (Row 2 Center: Your Vehicle - ACTIVE PLAY BUTTON 🔥)
      Offset(
        w * 0.28,
        430,
      ), // Node 3 (Row 3 Lower Left: Road Markings I - Locked 🔒)
      Offset(
        w * 0.72,
        430,
      ), // Node 4 (Row 3 Lower Right: Right of Way II - Locked 🔒)
      Offset(w * 0.50, 605), // Node 5 (Row 4 Center: Echo NIMO - Locked 🔒)
      Offset(
        w * 0.28,
        780,
      ), // Node 6 (Row 5 Bottom Left: Find NIMO - Locked 🔒)
      Offset(
        w * 0.72,
        780,
      ), // Node 7 (Row 5 Bottom Right: Category Sort - Locked 🔒)
      Offset(w * 0.50, 955), // Node 8 (Row 6 Center: Turn NIMO - Locked 🔒)
      Offset(
        w * 0.28,
        1130,
      ), // Node 9 (Row 7 Bottom Left: Feel NIMO - Locked 🔒)
      Offset(
        w * 0.72,
        1130,
      ), // Node 10 (Row 7 Bottom Right: Speak NIMO - Locked 🔒)
    ];

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
          height: math.max(1300.0, totalPathHeight),
          width: w,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Environmental Accents (Grass & Environment Painter)
              Positioned.fill(
                child: CustomPaint(
                  painter: _SubtleEnvironmentMapPainter(points: nodeOffsets),
                ),
              ),

              // 1A. Red Fort Monument - Centered in Row 1->2 meadow
              Positioned(
                top: 270,
                left: w * 0.16,
                child: Opacity(
                  opacity: 0.88,
                  child: Image.asset(
                    'assets/images/curve_element_clean.png',
                    width: 155,
                    height: 155,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Image.asset(
                      'assets/Netaji/COVER_IMG/curve_element_clean.png',
                      width: 155,
                      height: 155,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                ),
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

              // 1B. India Gate & Doves - Centered in Row 4->5 meadow (top ~455-555)
              // Node 4 at top~460, Node 5 at top~635. Clear meadow center.
              Positioned(
                top: 450,
                left: w * 0.76,
                child: Opacity(
                  opacity: 0.86,
                  child: Image.asset(
                    'assets/images/tree_replacement_clean.png',
                    width: 155,
                    height: 155,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Image.asset(
                      'assets/Netaji/COVER_IMG/tree_replacement_clean.png',
                      width: 155,
                      height: 155,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),

              // 1C. Freedom Fighters Silhouette - Centered in Row 7->8 meadow (top ~820-900)
              // Node 7 at top~810, Node 8 at top~985. Clear meadow center.
              Positioned(
                top: 820,
                left: w * 0.08,
                child: Opacity(
                  opacity: 0.86,
                  child: Image.asset(
                    'assets/images/curve_element_clean_3.png',
                    width: 155,
                    height: 155,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Image.asset(
                      'assets/Netaji/COVER_IMG/curve_element_clean_3.png',
                      width: 155,
                      height: 155,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),

              // 2. Prominent Edge U-Turn Serpentine Loop Path matching reference image!
              Positioned.fill(
                child: CustomPaint(
                  painter: WindingRoadPathPainter(
                    points: nodeOffsets,
                    unlockedLevelIndex: _unlockedLevelIndex,
                  ),
                ),
              ),

              // Level Nodes (Sized matching reference image)
              _buildEmergingLevelStone(
                levelIndex: 0,
                top: 34,
                left: w * 0.28 - 43,
                animVal: animVal,
              ),

              _buildEmergingLevelStone(
                levelIndex: 1,
                top: 34,
                left: w * 0.72 - 43,
                animVal: animVal,
              ),

              _buildEmergingLevelStone(
                levelIndex: 2,
                top: 202,
                left: w * 0.50 - 47,
                animVal: animVal,
              ),

              _buildEmergingLevelStone(
                levelIndex: 3,
                top: 384,
                left: w * 0.28 - 40,
                animVal: animVal,
              ),

              _buildEmergingLevelStone(
                levelIndex: 4,
                top: 384,
                left: w * 0.72 - 40,
                animVal: animVal,
              ),

              _buildEmergingLevelStone(
                levelIndex: 5,
                top: 559,
                left: w * 0.50 - 40,
                animVal: animVal,
              ),

              _buildEmergingLevelStone(
                levelIndex: 6,
                top: 734,
                left: w * 0.28 - 40,
                animVal: animVal,
              ),

              _buildEmergingLevelStone(
                levelIndex: 7,
                top: 734,
                left: w * 0.72 - 40,
                animVal: animVal,
              ),

              _buildEmergingLevelStone(
                levelIndex: 8,
                top: 909,
                left: w * 0.50 - 47,
                animVal: animVal,
              ),

              _buildEmergingLevelStone(
                levelIndex: 9,
                top: 1084,
                left: w * 0.28 - 40,
                animVal: animVal,
              ),

              _buildEmergingLevelStone(
                levelIndex: 10,
                top: 1084,
                left: w * 0.72 - 40,
                animVal: animVal,
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
            child: Container(
              width: double.infinity,
              height: 95,
              color: const Color(0xFF0D180B),
              child: coverImage != null
                  ? Image.asset(
                      coverImage,
                      fit: (coverImage.toLowerCase().contains('bharat') || chapter.name.toLowerCase().contains('bharat'))
                          ? BoxFit.contain
                          : BoxFit.cover,
                      alignment: Alignment.center,
                      errorBuilder: (ctx, err, stack) => Container(
                        color: const Color(0xFF0D180B),
                        child: const Icon(Icons.movie_filter_rounded,
                            color: Color(0xFFFFD166), size: 36),
                      ),
                    )
                  : Container(
                      color: const Color(0xFF0D180B),
                      child: const Icon(Icons.movie_filter_rounded,
                          color: Color(0xFFFFD166), size: 36),
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
    final bool isHovered = _hoveredLevelIndex == levelIndex;

    final effectiveChapters = _chapters.isNotEmpty
        ? _chapters
        : [
            LearningChapter(id: 'Netaji', name: 'Netaji', levels: []),
            LearningChapter(id: 'Success', name: 'Success', levels: []),
          ];
    final chapter = levelIndex < effectiveChapters.length
        ? effectiveChapters[levelIndex]
        : null;
    final coverImage = chapter != null ? _stageCoverImages[chapter.id] : null;
    final bool isLocked = levelIndex > _unlockedStageIndex;

    final String title = levelIndex < _levelTitles.length
        ? _levelTitles[levelIndex].replaceAll('\n', ' ')
        : (chapter?.name ?? 'Level ${levelIndex + 1}');

    // 3D Closed Hardcover Book Dimensions
    final double bookWidth = isActive ? 96.0 : (isCompleted ? 88.0 : 82.0);
    final double bookHeight = isActive ? 116.0 : (isCompleted ? 106.0 : 98.0);

    // Exact Color Schemes matching user's reference:
    final Color frontCoverColor = isActive
        ? const Color(0xFFFFFDF5)
        : (isCompleted ? const Color(0xFFFDF6E2) : const Color(0xFFF1F5F9));

    final Color frontCoverDarkColor = isActive
        ? const Color(0xFFF5E6D3)
        : (isCompleted ? const Color(0xFFEFE3C3) : const Color(0xFFE2E8F0));

    final Color spineColor = isActive
        ? const Color(0xFF4A2E1B)
        : (isCompleted ? const Color(0xFF3E2723) : const Color(0xFF475569));

    final Color spineStrapColor = isActive
        ? const Color(0xFFD4AF37)
        : (isCompleted ? const Color(0xFFC5A059) : const Color(0xFF94A3B8));

    final Color outlineColor = isActive
        ? const Color(0xFF6D4C41)
        : (isCompleted ? const Color(0xFF5D4037) : const Color(0xFF334155));

    final Color titleTextColor = isActive
        ? const Color(0xFF5C3A21)
        : (isCompleted ? const Color(0xFF4A2E1B) : const Color(0xFF64748B));

    final Color bookmarkColor = isActive
        ? const Color(0xFF991B1B)
        : (isCompleted ? const Color(0xFF22C55E) : const Color(0xFF94A3B8));

    final Color borderColor = isHovered
        ? (isCompleted
            ? const Color(0xFFD4AF37)
            : (isActive ? const Color(0xFFF59E0B) : const Color(0xFF64748B)))
        : outlineColor;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoveredLevelIndex = levelIndex),
      onExit: (_) => setState(() => _hoveredLevelIndex = null),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (details) => _completeLevelAndUnlockNext(
          levelIndex,
          details.globalPosition,
          outlineColor,
        ),
        child: AnimatedScale(
          scale: isHovered ? 1.08 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // 2. Main 3D Closed Storybook Container
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutBack,
                width: isHovered ? (isActive ? 154.0 : 144.0) : bookWidth,
                height: bookHeight,
                decoration: BoxDecoration(
                  color: spineColor, // Solid 3D Back Cover & Spine Base
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: borderColor,
                    width: isActive ? 3.5 : 3.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isHovered
                          ? borderColor.withValues(alpha: 0.65)
                          : const Color(0x35000000),
                      blurRadius: isHovered ? 16 : 8,
                      offset: Offset(isActive ? 4 : 3, isActive ? 6 : 4),
                    ),
                  ],
                ),
                child: isHovered
                    ? Row(
                        children: [
                          // A) Opened Left Page (Chapter Info & Read Action)
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.fromLTRB(4, 4, 1, 10),
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFDF5),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(9),
                                  bottomLeft: Radius.circular(3),
                                ),
                                border: Border.all(
                                  color: outlineColor.withValues(alpha: 0.30),
                                  width: 1.0,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 1.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isCompleted
                                          ? const Color(0xFFDCFCE7)
                                          : (isActive
                                                ? const Color(0xFFFEF3C7)
                                                : const Color(0xFFE2E8F0)),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      isCompleted
                                          ? 'PASSED ✔'
                                          : (isActive
                                                ? 'START ▶'
                                                : 'LOCKED 🔒'),
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.outfit(
                                        fontSize: 7.5,
                                        fontWeight: FontWeight.w900,
                                        color: isCompleted
                                            ? const Color(0xFF15803D)
                                            : (isActive
                                                  ? const Color(0xFFB45309)
                                                  : const Color(0xFF475569)),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        (isCompleted || isActive)
                                            ? title.toUpperCase()
                                            : '???',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.outfit(
                                          fontSize: 7.5,
                                          fontWeight: FontWeight.w800,
                                          color: titleTextColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Book Spine Crease Line in Middle
                          Container(
                            width: 2,
                            margin: const EdgeInsets.only(bottom: 10),
                            color: outlineColor.withValues(alpha: 0.40),
                          ),

                          // B) Opened Right Page (Contains Story Visual e.g. Netaji Subhas Chandra Bose Picture!)
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.fromLTRB(1, 4, 4, 10),
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFDF5),
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(9),
                                  bottomRight: Radius.circular(3),
                                ),
                                border: Border.all(
                                  color: outlineColor.withValues(alpha: 0.30),
                                  width: 1.0,
                                ),
                              ),
                              child: _buildBookStoryVisual(
                                levelIndex,
                                isCompleted,
                                isActive,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Stack(
                        children: [
                          // A) Left 3D Vertical Spine Section with Horizontal Ribbon Straps & Crease Shadow
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 12, // Space for bottom 3D white paper pages
                            width: 15,
                            child: Container(
                              decoration: BoxDecoration(
                                color: spineColor,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(11),
                                ),
                                border: Border(
                                  right: BorderSide(
                                    color: outlineColor.withValues(alpha: 0.50),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Container(
                                    height: 4,
                                    width: double.infinity,
                                    color: spineStrapColor,
                                  ),
                                  Container(
                                    height: 4,
                                    width: double.infinity,
                                    color: spineStrapColor,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // B) Front Cover Parchment Card (Fills ENTIRE front cover with Netaji portrait image!)
                          Positioned(
                            left: 14,
                            right: 0,
                            top: 0,
                            bottom: 12, // Space for bottom 3D white paper pages
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(11),
                                bottomRight: Radius.circular(3),
                              ),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  // 1. Full-cover Level Image (Level 1: Bharatnatyam, Level 2: Netaji)
                                  if (levelIndex == 0)
                                    Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        // Warm parchment gradient background for dancer illustration
                                        Container(
                                          decoration: const BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Color(0xFFFFF7ED), // Warm Cream
                                                Color(0xFFFFEDD5), // Soft Amber Parchment
                                              ],
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(4, 18, 4, 4),
                                          child: Image.asset(
                                            coverImage ?? 'assets/Bharatnatayam/COVER_IMG/Bharatnatyam.png',
                                            fit: BoxFit.contain,
                                            alignment: Alignment.center,
                                            errorBuilder: (context, error, stackTrace) => Image.asset(
                                              'assets/Bharatnatayam/COVER_IMG/Bharatnatyam.png',
                                              fit: BoxFit.contain,
                                              alignment: Alignment.center,
                                              errorBuilder: (context, error, stackTrace) => Container(
                                                color: const Color(0xFFB45309).withValues(alpha: 0.35),
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Soft Vintage Antique Sepia & Leather Vignette Overlay
                                        Container(
                                          decoration: const BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Color(0x10B45309), // Warm Sepia Gold
                                                Color(0x204A2E1B), // Deep Vintage Leather Dark Vignette
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  else if (levelIndex == 1)
                                    Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.asset(
                                          coverImage ?? 'assets/Netaji/COVER_IMG/netaji-bose-portrait-in-his-birthday-celebration-6y6feyj10k9hshwc.jpg',
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Image.asset(
                                            'assets/Netaji/COVER_IMG/netaji-bose-portrait-in-his-birthday-celebration-6y6feyj10k9hshwc.jpg',
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Image.asset(
                                              'assets/Netaji/COVER_IMG/netaji_portrait.png',
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => Container(
                                                color: const Color(0xFFFF9933).withValues(alpha: 0.35),
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Soft Vintage Antique Sepia & Leather Vignette Overlay
                                        Container(
                                          decoration: const BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Color(0x18B45309),
                                                Color(0x354A2E1B),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            frontCoverColor,
                                            frontCoverDarkColor,
                                          ],
                                        ),
                                      ),
                                    ),

                                  // 2. Top Title Ribbon Overlaid on Full-Cover Image
                                  Positioned(
                                    top: 3,
                                    left: 3,
                                    right: 3,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 2,
                                        horizontal: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.90,
                                        ),
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(
                                          color: outlineColor.withValues(
                                            alpha: 0.35,
                                          ),
                                          width: 1.0,
                                        ),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0x30000000),
                                            blurRadius: 2,
                                            offset: Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        (isCompleted || isActive)
                                            ? title.toUpperCase()
                                            : '???',
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.outfit(
                                          fontSize: isActive ? 8.5 : 7.5,
                                          fontWeight: FontWeight.w900,
                                          color: titleTextColor,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // 3. Center Icon / Play Button for non-image or active levels
                                  if (levelIndex > 1)
                                    Center(
                                      child: isActive
                                          ? Container(
                                              padding: const EdgeInsets.all(7),
                                              decoration: const BoxDecoration(
                                                color: Color(0xFFF59E0B),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.play_arrow_rounded,
                                                color: Colors.white,
                                                size: 24,
                                              ),
                                            )
                                          : Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: const Color(
                                                  0xFF94A3B8,
                                                ).withValues(alpha: 0.35),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.lock_rounded,
                                                color: Color(0xFF64748B),
                                                size: 22,
                                              ),
                                            ),
                                    ),
                                ],
                              ),
                            ),
                          ),

                          // C) Bottom 3D Closed Paper Page Edge Block (White Paper Block matching reference image!)
                          Positioned(
                            left: 14,
                            right: 1,
                            bottom: 1,
                            height: 11,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(3),
                                  bottomRight: Radius.circular(5),
                                ),
                                border: Border.all(
                                  color: outlineColor.withValues(alpha: 0.35),
                                  width: 1.0,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x15000000),
                                    blurRadius: 2,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
              ),

              // 3. Right Bookmark Ribbon Clasp matching image reference!
              Positioned(
                right: isActive ? -22 : -10,
                top: bookHeight * 0.38,
                child: isActive
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B00),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x40000000),
                              blurRadius: 4,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                        child: const Text(
                          'CURRENT',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: bookmarkColor,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                            topLeft: Radius.circular(3),
                            bottomLeft: Radius.circular(3),
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x40000000),
                              blurRadius: 4,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                        child: isCompleted
                            ? const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 14,
                              )
                            : const Icon(
                                Icons.lock_rounded,
                                color: Colors.white,
                                size: 12,
                              ),
                      ),
              ),

              // 4. ⭐ Star Badge Attached to Completed / Active Storybooks
              Positioned(
                top: -8,
                left: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD166),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x35000000),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.star_rounded, color: Colors.white, size: 11),
                      SizedBox(width: 1),
                      Text(
                        '3',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF5C3A00),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookStoryVisual(
    int levelIndex,
    bool isCompleted,
    bool isActive,
  ) {
    if (levelIndex == 0) {
      // 🇮🇳 Full-Page Bharatnatyam Story Visual!
      return Container(
        key: const ValueKey('story_visual_bharatnatyam'),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
          ),
          border: Border.all(color: const Color(0xFFD97706), width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x25000000),
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 14),
              child: Image.asset(
                'assets/Bharatnatayam/COVER_IMG/Bharatnatyam.png',
                fit: BoxFit.contain,
                alignment: Alignment.center,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFFB45309).withValues(alpha: 0.35),
                ),
              ),
            ),
            // Vintage Warm Sepia Overlay
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x18B45309), // Warm Sepia Gold
                    Color(0x354A2E1B), // Deep Vintage Leather Dark Vignette
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 2,
              left: 2,
              right: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 1.5,
                  horizontal: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'BHARATNATYAM',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 7.0,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFFFD166),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else if (levelIndex == 1) {
      // 🇮🇳 Full-Page Netaji Subhas Chandra Bose Story Visual!
      return Container(
        key: const ValueKey('story_visual_netaji'),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF16A34A), width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x25000000),
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/Netaji/COVER_IMG/netaji-bose-portrait-in-his-birthday-celebration-6y6feyj10k9hshwc.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Image.asset(
                'assets/Netaji/COVER_IMG/netaji_portrait.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFFFF9933).withValues(alpha: 0.35),
                ),
              ),
            ),
            Positioned(
              bottom: 2,
              left: 2,
              right: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 1.5,
                  horizontal: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'NETAJI BOSE',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 7.5,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF86EFAC),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else if (levelIndex == 2) {
      // 🇮🇳 Swami Dayanandji Story Visual!
      return Container(
        key: const ValueKey('story_visual_dayanandji'),
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: const LinearGradient(
            colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
          ),
          border: Border.all(color: const Color(0xFF2563EB), width: 1.2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2563EB).withValues(alpha: 0.20),
                border: Border.all(color: const Color(0xFF2563EB), width: 1.0),
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                color: Color(0xFF1D4ED8),
                size: 20,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'DAYANANDJI',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 7.5,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1E40AF),
              ),
            ),
          ],
        ),
      );
    } else {
      // 🔒 Locked Archive Mystery Visual (Cannot unlock until previous ones are completed!)
      return Container(
        key: ValueKey('story_visual_locked_$levelIndex'),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: const Color(0xFFF1F5F9),
          border: Border.all(color: const Color(0xFF94A3B8), width: 1.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_clock_rounded,
              color: Color(0xFF64748B),
              size: 18,
            ),
            const SizedBox(height: 2),
            Text(
              'LOCKED',
              style: GoogleFonts.outfit(
                fontSize: 7.5,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF475569),
              ),
            ),
          ],
        ),
      );
    }
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
        color: Colors
            .white, // Crisp Pure White Top Header Bar matching reference image!
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0E000000),
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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF0B1220), // Deep Midnight Obsidian Navy Card
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF1E293B), width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x35000000),
              offset: Offset(0, 6),
              blurRadius: 14,
            ),
          ],
        ),
        child: Row(
          children: [
            // Inner Complementary Deep Forest Green Section #13300C
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF13300C),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SECTION 1, STAGE $stageNumber',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFFFD166),
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
            ),
            const SizedBox(width: 12),
            // Read Book Button matching reference image
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF070B14),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF22C55E), width: 2.0),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.menu_book_rounded,
                    color: Color(0xFF4ADE80),
                    size: 22,
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Read',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
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

  Widget _buildDuolingoBottomNavBar() {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final double safeBottomPadding = math.max(bottomInset, 12.0);

    final navItems = [
      {
        'icon': Icons.home_rounded,
        'color': const Color(0xFF78C850),
        'label': 'Home',
      },
      {
        'icon': Icons.shield_rounded,
        'color': const Color(0xFFF4C95D),
        'label': 'Quests',
      },
      {
        'icon': Icons.leaderboard_rounded,
        'color': const Color(0xFFF08A5D),
        'label': 'Leaderboard',
      },
      {
        'icon': Icons.favorite_rounded,
        'color': const Color(0xFFFF4B4B),
        'label': 'Hearts',
      },
      {
        'icon': Icons.videocam_rounded,
        'color': const Color(0xFF78C850),
        'label': 'Call',
      },
      {
        'icon': Icons.more_horiz_rounded,
        'color': const Color(0xFF1F3B16),
        'label': 'More',
      },
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
    final w = size.width;
    final h = size.height;

    final whiteLinePaint = Paint()
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.28);

    final goldLinePaint = Paint()
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFFFD54F).withValues(alpha: 0.22);

    // 1. Topo Contour Wire Line 1 (Upper Arc)
    final path1 = Path()
      ..moveTo(-w * 0.10, h * 0.08)
      ..cubicTo(w * 0.35, h * 0.02, w * 0.65, h * 0.18, w * 1.15, h * 0.05);
    canvas.drawPath(path1, whiteLinePaint);

    // 2. Topo Contour Wire Line 2 (Sweeping Upper Wire Flow)
    final path2 = Path()
      ..moveTo(-w * 0.15, h * 0.18)
      ..cubicTo(w * 0.25, h * 0.06, w * 0.75, h * 0.24, w * 1.12, h * 0.14);
    canvas.drawPath(path2, goldLinePaint);

    // 3. Topo Contour Wire Line 3 (Mid-Upper Organic Contour)
    final path3 = Path()
      ..moveTo(-w * 0.05, h * 0.30)
      ..cubicTo(w * 0.40, h * 0.14, w * 0.60, h * 0.38, w * 1.10, h * 0.25);
    canvas.drawPath(path3, whiteLinePaint);

    // 4. Topo Contour Wire Line 4 (Sweeping Across Yellow Tile Boundary)
    final path4 = Path()
      ..moveTo(-w * 0.10, h * 0.45)
      ..cubicTo(w * 0.30, h * 0.32, w * 0.70, h * 0.52, w * 1.15, h * 0.38);
    canvas.drawPath(path4, whiteLinePaint);

    // 5. Topo Contour Wire Line 5 (Lower Tile Surface Contour)
    final path5 = Path()
      ..moveTo(-w * 0.08, h * 0.60)
      ..cubicTo(w * 0.35, h * 0.46, w * 0.65, h * 0.68, w * 1.12, h * 0.54);
    canvas.drawPath(path5, goldLinePaint);

    // 6. Topo Contour Wire Line 6 (Bottom Outer Flow Wire)
    final path6 = Path()
      ..moveTo(-w * 0.12, h * 0.76)
      ..cubicTo(w * 0.28, h * 0.62, w * 0.72, h * 0.84, w * 1.10, h * 0.70);
    canvas.drawPath(path6, whiteLinePaint);

    // 7. Topo Contour Wire Line 7 (Deep Base Wire Flow)
    final path7 = Path()
      ..moveTo(-w * 0.05, h * 0.90)
      ..cubicTo(w * 0.42, h * 0.78, w * 0.68, h * 0.96, w * 1.15, h * 0.84);
    canvas.drawPath(path7, goldLinePaint);
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

                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => widget.onNext?.call(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.accentDark,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    elevation: 4,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('CONFIRM AGE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                      SizedBox(width: 6),
                      Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                    ],
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
  final double scale;
  const BlinkingEyesWidget({
    super.key,
    required this.accentDark,
    this.scale = 1.0,
  });

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
          const specFrameColor = Color(
            0xFF2C1B54,
          ); // Deep Navy Purple Spectacle Frame

          return Transform.scale(
            scale: widget.scale,
            child: Column(
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
                    child: _buildSpectacleEye(
                      isLeft: true,
                      eyeOffset: _eyeOffset,
                      frameColor: specFrameColor,
                    ),
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
                          painter: _SpectacleBridgePainter(
                            color: specFrameColor,
                          ),
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
                                color: widget.accentDark.withValues(
                                  alpha: 0.65,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 8,
                              height: 6,
                              decoration: BoxDecoration(
                                color: widget.accentDark.withValues(
                                  alpha: 0.65,
                                ),
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
                    child: _buildSpectacleEye(
                      isLeft: false,
                      eyeOffset: _eyeOffset,
                      frameColor: specFrameColor,
                    ),
                  ),
                ],
              ),
            ],
          ), // close Column
          ); // close Transform.scale
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
              color: Color(
                0xFF1565C0,
              ), // Rich Royal Blue Iris (matching reference spec image!)
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
  bool shouldRepaint(_SpectacleBridgePainter oldDelegate) =>
      oldDelegate.color != color;
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

    const specFrameColor = Color(
      0xFF2C1B54,
    ); // Deep Navy Purple Spectacle Frame
    final specFramePaint = Paint()
      ..color = specFrameColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    final whiteFillPaint = Paint()
      ..color = const Color(0xFFFAFAFA)
      ..style = PaintingStyle.fill;

    final irisPaint = Paint()
      ..color = const Color(0xFF1565C0); // Royal Blue Iris
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
      ..quadraticBezierTo(
        cx - 46.0,
        eyeCenterY - 64.0,
        cx - 18.0,
        eyeCenterY - 48.0,
      );

    final eyebrowRightPath = Path()
      ..moveTo(cx + 18.0, eyeCenterY - 48.0)
      ..quadraticBezierTo(
        cx + 46.0,
        eyeCenterY - 64.0,
        cx + 74.0,
        eyeCenterY - 48.0,
      );

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
    final leftEyeRect = Rect.fromCircle(
      center: Offset.zero,
      radius: specRadius,
    );
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
    final rightEyeRect = Rect.fromCircle(
      center: Offset.zero,
      radius: specRadius,
    );
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
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
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(90),
                    ),
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
                            color: Colors.white.withValues(
                              alpha: _hovered ? 0.38 : 0.22,
                            ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(75),
                            ),
                          ),
                        ),
                      ),

                      // Crystal prism facets (only for crystalRelic type)
                      if (isCrystal)
                        ...List.generate(
                          3,
                          (i) => Positioned(
                            top: 12 + i * 12.0,
                            child: Container(
                              width: 80 - i * 16.0,
                              height: 1.5,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(
                                  alpha: 0.30 - i * 0.06,
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),

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
        Rect.fromCircle(center: Offset(dropsX[i] - 2, dropsY[i]), radius: 5.5),
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
      final y =
          baseY +
          amplitude * math.sin((x / wavelength) * 2 * math.pi + phase) +
          (amplitude * 0.35) *
              math.cos((x / (wavelength * 0.5)) * 2 * math.pi - phase * 0.5);
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
      points.add(
        Offset(center.dx + r * math.cos(a), center.dy + r * math.sin(a)),
      );
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
          Colors.cyanAccent.withValues(
            alpha: 0.06,
          ), // Very light glass edge tint
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
    highlightPath.moveTo(
      center.dx - baseRadius * 0.50,
      center.dy - baseRadius * 0.45,
    );
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
    final dotCenter = Offset(
      center.dx + baseRadius * 0.45,
      center.dy + baseRadius * 0.45,
    );
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
    final cardW = math.min(size.width * 0.86, 320.0);
    final cardH = math.min(size.height * 0.44, 330.0);

    final topColor = _getThemeTopColor(emotionValue);
    final bottomColor = _getThemeBottomColor(emotionValue);

    return Container(
      width: cardW,
      height: cardH,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [topColor, bottomColor],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.32),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: topColor.withValues(alpha: 0.35),
            blurRadius: 36,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // Monster Face (Centered comfortably in colored section of card)
            Positioned.fill(
              top: 4,
              bottom: 78,
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
              height: 78,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(30),
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
                    horizontal: 20,
                    vertical: 10,
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
    final cy = size.height / 2 + 28.0;

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
      canvas.drawOval(
        leftEyeRect,
        Paint()
          ..color = chinColor
          ..style = PaintingStyle.fill,
      );
      canvas.drawOval(leftEyeRect, blackBorderPaint);

      final winkArcPath = Path()
        ..moveTo(-eyeW / 2 + 4, 0)
        ..quadraticBezierTo(0, 14, eyeW / 2 - 4, 0);
      canvas.drawPath(winkArcPath, blackBorderPaint);
    } else {
      canvas.drawOval(leftEyeRect, whiteFillPaint);
      canvas.drawOval(leftEyeRect, blackBorderPaint);

      final pupilOffsetLeft = Offset(pupilFollowX, basePupilY + pupilFollowY);
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
      final pupilOffsetRight = Offset(pupilFollowX, basePupilY + pupilFollowY);
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
      final leftEyeOrigin = Offset(
        cx - 38.0 - 10.0,
        eyeCenterY + eyeH / 2 - 4.0,
      );
      drawTearDrop(leftEyeOrigin, tearProgress);
      drawTearDrop(leftEyeOrigin, (tearProgress + 0.5) % 1.0);

      // Right Eye Teardrops (Staggered continuous flow)
      final rightEyeOrigin = Offset(
        cx + 38.0 + 10.0,
        eyeCenterY + eyeH / 2 - 4.0,
      );
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
        rightCorner.dx + 4.0,
        rightCorner.dy + mouthH * 0.35,
        cx + mouthW * 0.32,
        bottomCenterY,
        cx,
        bottomCenterY,
      );
      // Bottom smile curve sweeping back up to left corner
      mouthPath.cubicTo(
        cx - mouthW * 0.32,
        bottomCenterY,
        leftCorner.dx - 4.0,
        leftCorner.dy + mouthH * 0.35,
        leftCorner.dx,
        leftCorner.dy,
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
        rightCorner.dx + 4.0,
        rightCorner.dy + mouthH * 0.35,
        cx + mouthW * 0.32,
        bottomCenterY,
        cx,
        bottomCenterY,
      );
      mouthPath.cubicTo(
        cx - mouthW * 0.32,
        bottomCenterY,
        leftCorner.dx - 4.0,
        leftCorner.dy + mouthH * 0.35,
        leftCorner.dx,
        leftCorner.dy,
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
      mouthPath.quadraticBezierTo(cx, topArchY, rightCorner.dx, rightCorner.dy);
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
      mouthPath.quadraticBezierTo(cx, topArchY, rightCorner.dx, rightCorner.dy);
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
    canvas.drawPath(
      mouthPath.shift(const Offset(0, 5.0)),
      mouthShadowFillPaint,
    );
    canvas.drawPath(
      mouthPath.shift(const Offset(0, 5.0)),
      mouthShadowStrokePaint,
    );

    // 1. Thick Plush 3D Clay Outer Lip Bevel Rim (16px)
    final plushLipRimPaint = Paint()
      ..color =
          const Color(0xFFFFB74D) // Signature warm plush 3D lip bevel highlight
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
        ..quadraticBezierTo(
          cx,
          mouthCy + 14.0,
          cx - mouthW / 2 - 10,
          mouthCy + 4.0,
        )
        ..close();

      final toothBarPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
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

/// Custom Painter drawing the exact wide circular C-curve serpentine road ribbon matching reference image.
class WindingRoadPathPainter extends CustomPainter {
  final List<Offset> points;
  final int unlockedLevelIndex;

  WindingRoadPathPainter({required this.points, this.unlockedLevelIndex = 1});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final w = size.width;

    // Generate individual curve segments between adjacent nodes
    final List<Path> segmentPaths = [];

    for (int i = 0; i < points.length - 1; i++) {
      final pA = points[i];
      final pB = points[i + 1];
      final segPath = Path();
      segPath.moveTo(pA.dx, pA.dy);

      if (i % 3 == 0) {
        // Downward S-Curve
        segPath.cubicTo(
          pA.dx + (pB.dx - pA.dx) * 0.5,
          pA.dy + 45,
          pA.dx + (pB.dx - pA.dx) * 0.5,
          pB.dy - 35,
          pB.dx,
          pB.dy,
        );
      } else if (i % 3 == 1) {
        // Right U-Turn Loop
        segPath.cubicTo(
          w * 0.94,
          pA.dy + 25,
          w * 0.94,
          pB.dy - 25,
          pB.dx,
          pB.dy,
        );
      } else {
        // Left U-Turn Loop
        segPath.cubicTo(
          w * 0.06,
          pA.dy + 25,
          w * 0.06,
          pB.dy - 25,
          pB.dx,
          pB.dy,
        );
      }
      segmentPaths.add(segPath);
    }

    // End continuation ribbon past last node
    final lastP = points.last;
    final endExtensionPath = Path();
    endExtensionPath.moveTo(lastP.dx, lastP.dy);
    endExtensionPath.cubicTo(
      lastP.dx + 40,
      lastP.dy + 70,
      w * 0.50,
      size.height + 40,
      w * 0.50,
      size.height + 80,
    );
    segmentPaths.add(endExtensionPath);

    // Build completedPath dynamically based on unlockedLevelIndex!
    final Path completedPath = Path();
    final Path lockedPath = Path();

    final int completedSegmentCount = math.min(
      unlockedLevelIndex,
      segmentPaths.length,
    );

    for (int i = 0; i < segmentPaths.length; i++) {
      if (i < completedSegmentCount) {
        completedPath.addPath(segmentPaths[i], Offset.zero);
      } else {
        lockedPath.addPath(segmentPaths[i], Offset.zero);
      }
    }

    // 1. Ground Drop Shadow (Soft Ambient Shadow on Grass below the 3D Slab Wall)
    if (lockedPath.computeMetrics().isNotEmpty) {
      final shadowPath = lockedPath.shift(const Offset(0, 10.0));
      final lockedGroundShadowPaint = Paint()
        ..color = const Color(0x1F0F172A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 56.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);

      canvas.drawPath(shadowPath, lockedGroundShadowPaint);

      // 2. 3D Extruded Side Wall (Solid 3D Thickness Slab shifted down 4.0px)
      final wallPath = lockedPath.shift(const Offset(0, 4.0));
      final locked3DWallPaint = Paint()
        ..color =
            const Color(0xFFCBD5E1) // Solid Slate 3D Extruded Wall Base
        ..style = PaintingStyle.stroke
        ..strokeWidth = 48.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final locked3DWallFacePaint = Paint()
        ..color =
            const Color(0xFFE2E8F0) // Lighter Slate Extruded Wall Face
        ..style = PaintingStyle.stroke
        ..strokeWidth = 45.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPath(wallPath, locked3DWallPaint);
      canvas.drawPath(wallPath, locked3DWallFacePaint);

      // 3. Top Ribbon Surface (Wider Crisp Pure White Main Driving Surface)
      final lockedMainSurfacePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 40.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPath(lockedPath, lockedMainSurfacePaint);

      // 4. Draw Precision Curve-Following Center Dashed Lines along lockedPath
      final dashedCenterPaint = Paint()
        ..color = const Color(0xFF94A3B8).withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8
        ..strokeCap = StrokeCap.round;

      for (final metric in lockedPath.computeMetrics()) {
        double distance = 10.0;
        const double dashLength = 12.0;
        const double dashGap = 12.0;
        while (distance < metric.length - 10.0) {
          final Path extract = metric.extractPath(
            distance,
            distance + dashLength,
          );
          canvas.drawPath(extract, dashedCenterPaint);
          distance += dashLength + dashGap;
        }
      }
    }

    // 2. Draw Completed Road Segment with Rich Antique Light Vintage Sepia & Gold Palette!
    if (completedPath.computeMetrics().isNotEmpty) {
      final p0 = points[0];
      final targetP = points[math.min(unlockedLevelIndex, points.length - 1)];

      // White outer border stroke
      final completedWhiteOutlinePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 42.0
        ..strokeCap = StrokeCap.round;

      // Darker Vintage Antique Sepia Burnt-Sienna Gradient Track Paint!
      final completedGradientPaint = Paint()
        ..shader = LinearGradient(
          colors: const [
            Color(0xFF4A2508), // Deep Dark Burnt Sienna
            Color(0xFF7A4E1A), // Dark Antique Walnut Brown
            Color(0xFFA8722E), // Rich Warm Amber Brown
            Color(0xFFC49A45), // Darkened Antique Gold
          ],
          stops: const [0.0, 0.35, 0.70, 1.0],
        ).createShader(Rect.fromPoints(p0, targetP))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 38.0
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(completedPath, completedWhiteOutlinePaint);
      canvas.drawPath(completedPath, completedGradientPaint);

      // Draw Precision Curve-Following White Center Dashes along completedPath
      final completedDashedCenterPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.92)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round;

      for (final metric in completedPath.computeMetrics()) {
        double distance = 12.0;
        const double dashLength = 12.0;
        const double dashGap = 12.0;
        while (distance < metric.length - 12.0) {
          final Path extract = metric.extractPath(
            distance,
            distance + dashLength,
          );
          canvas.drawPath(extract, completedDashedCenterPaint);
          distance += dashLength + dashGap;
        }
      }

      // Draw Glowing Directional Arrow Sparks (» » ») along completedPath
      final sparkGlowPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3);

      final sparkCorePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round;

      for (final metric in completedPath.computeMetrics()) {
        final List<double> sparkFractions = [0.55, 0.65, 0.75];
        for (final frac in sparkFractions) {
          final ui.Tangent? tangent = metric.getTangentForOffset(
            metric.length * frac,
          );
          if (tangent != null) {
            final Offset pos = tangent.position;
            final double angle = tangent.angle;

            canvas.save();
            canvas.translate(pos.dx, pos.dy);
            canvas.rotate(angle);

            final sparkPath = Path()
              ..moveTo(-5, -6)
              ..lineTo(2, 0)
              ..lineTo(-5, 6);

            canvas.drawPath(sparkPath, sparkGlowPaint);
            canvas.drawPath(sparkPath, sparkCorePaint);
            canvas.restore();
          }
        }
      }

      // Draw Green Circle Checkmark Badge (✔) at exit of all completed nodes
      for (int c = 0; c < completedSegmentCount && c < points.length; c++) {
        final cp = points[c];
        final checkmarkCenter = Offset(cp.dx + 44, cp.dy);
        final checkmarkBgPaint = Paint()
          ..color = const Color(0xFF22C55E)
          ..style = PaintingStyle.fill;
        final checkmarkBorderPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

        canvas.drawCircle(checkmarkCenter, 13, checkmarkBgPaint);
        canvas.drawCircle(checkmarkCenter, 13, checkmarkBorderPaint);

        // Draw White Check Icon (✔) inside badge
        final checkPath = Path()
          ..moveTo(checkmarkCenter.dx - 4, checkmarkCenter.dy)
          ..lineTo(checkmarkCenter.dx - 1, checkmarkCenter.dy + 3.5)
          ..lineTo(checkmarkCenter.dx + 4.5, checkmarkCenter.dy - 3.5);

        final checkIconPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

        canvas.drawPath(checkPath, checkIconPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant WindingRoadPathPainter oldDelegate) => true;
}

/// Custom Painter drawing rolling pastel mint hills, grass tufts, dot matrix grid, concentric target circles, 3D pine trees, and gray boulders matching reference image.
class _SubtleEnvironmentMapPainter extends CustomPainter {
  final List<Offset> points;

  _SubtleEnvironmentMapPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Rolling Hills (Slightly Darker Rich Pasture Mint Background Mounds)
    final hillPaint1 = Paint()
      ..color = const Color(0xFFC4E8D1).withValues(alpha: 0.88)
      ..style = PaintingStyle.fill;

    final hillPaint2 = Paint()
      ..color = const Color(0xFFB5E2C5).withValues(alpha: 0.92)
      ..style = PaintingStyle.fill;

    // Left Rolling Hill Mound 1
    final hillPath1 = Path()
      ..moveTo(0, h * 0.15)
      ..cubicTo(w * 0.25, h * 0.12, w * 0.35, h * 0.24, 0, h * 0.32)
      ..close();
    canvas.drawPath(hillPath1, hillPaint1);

    // Right Rolling Hill Mound 2
    final hillPath2 = Path()
      ..moveTo(w, h * 0.22)
      ..cubicTo(w * 0.68, h * 0.18, w * 0.60, h * 0.36, w, h * 0.42)
      ..close();
    canvas.drawPath(hillPath2, hillPaint2);

    // Lower Left Rolling Hill Mound 3
    final hillPath3 = Path()
      ..moveTo(0, h * 0.52)
      ..cubicTo(w * 0.30, h * 0.48, w * 0.40, h * 0.62, 0, h * 0.70)
      ..close();
    canvas.drawPath(hillPath3, hillPaint1);

    // Lower Right Rolling Hill Mound 4
    final hillPath4 = Path()
      ..moveTo(w, h * 0.65)
      ..cubicTo(w * 0.65, h * 0.60, w * 0.58, h * 0.78, w, h * 0.85)
      ..close();
    canvas.drawPath(hillPath4, hillPaint2);

    // 2. Concentric Target Rings & 3x3 Dot Grid Matrix (Left Flank Accents matching reference image!)
    final ringPaint = Paint()
      ..color = const Color(0xFF86EFAC).withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final ringFillPaint = Paint()
      ..color = const Color(0xFF86EFAC).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    final dotPaint = Paint()
      ..color = const Color(0xFF86EFAC).withValues(alpha: 0.50)
      ..style = PaintingStyle.fill;

    // Concentric Circle Ring (Top Left)
    final ringCenter1 = Offset(w * 0.12, 140);
    canvas.drawCircle(ringCenter1, 14, ringPaint);
    canvas.drawCircle(ringCenter1, 4, ringFillPaint);

    // Concentric Circle Ring (Middle Left)
    final ringCenter2 = Offset(w * 0.09, 530);
    canvas.drawCircle(ringCenter2, 12, ringPaint);
    canvas.drawCircle(ringCenter2, 3, ringFillPaint);

    // 3x3 Dot Matrix Grid Clusters
    final List<Offset> gridCenters = [
      Offset(w * 0.08, 280),
      Offset(w * 0.06, 680),
      Offset(w * 0.88, 320),
    ];

    for (final gc in gridCenters) {
      for (int row = 0; row < 3; row++) {
        for (int col = 0; col < 3; col++) {
          canvas.drawCircle(
            Offset(gc.dx + (col * 8), gc.dy + (row * 8)),
            1.8,
            dotPaint,
          );
        }
      }
    }

    // 3. Grass Tufts (3-Blade Green Grass Tufts near road bends matching reference image!)
    final List<Offset> grassPositions = [
      Offset(w * 0.44, 310),
      Offset(w * 0.18, 480),
      Offset(w * 0.52, 680),
      Offset(w * 0.82, 850),
    ];

    final grassPaint = Paint()
      ..color = const Color(0xFF22C55E).withValues(alpha: 0.70)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    for (final gpos in grassPositions) {
      // Center blade
      canvas.drawLine(gpos, Offset(gpos.dx, gpos.dy - 8), grassPaint);
      // Left blade
      canvas.drawLine(gpos, Offset(gpos.dx - 5, gpos.dy - 6), grassPaint);
      // Right blade
      canvas.drawLine(gpos, Offset(gpos.dx + 5, gpos.dy - 6), grassPaint);
    }

    // 4. Gray Boulders / Rocks on hill slopes
    final rockPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..style = PaintingStyle.fill;
    final rockDarkPaint = Paint()
      ..color = const Color(0xFF64748B)
      ..style = PaintingStyle.fill;
    final groundShadowPaint = Paint()
      ..color = const Color(0x20000000)
      ..style = PaintingStyle.fill;

    // 4. Gray Boulders / Rocks on hill slopes
    final List<Offset> rockPositions = [
      Offset(w * 0.86, 445),
      Offset(w * 0.12, 885),
    ];

    for (final rpos in rockPositions) {
      // Ground shadow
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(rpos.dx, rpos.dy + 4),
          width: 14,
          height: 4,
        ),
        groundShadowPaint,
      );
      // Rock body
      canvas.drawCircle(rpos, 6, rockPaint);
      // Rock shadow face
      canvas.drawCircle(Offset(rpos.dx + 1.5, rpos.dy + 1.5), 4, rockDarkPaint);
    }

    // 5. 3D Indian Tricolor Flag Victory Monument (Placed in the Empty Space of the Last Curve at y=1240!)
    final flagMonumentPos = Offset(w * 0.88, 1240);

    // A) Radiant Golden Sunburst Light Rays behind monument
    final sunburstRayPaint = Paint()
      ..color = const Color(0xFFFEF08A).withValues(alpha: 0.40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5;

    for (int i = 0; i < 11; i++) {
      final double angle = (i * 0.20) - 1.0;
      final Offset rayEnd = Offset(
        flagMonumentPos.dx + math.cos(angle) * 85,
        flagMonumentPos.dy - 55 + math.sin(angle) * 85,
      );
      canvas.drawLine(
        Offset(flagMonumentPos.dx, flagMonumentPos.dy - 55),
        rayEnd,
        sunburstRayPaint,
      );
    }

    // B) 3D Mountain Peak Rocks & Boulders (Larger 96px Base Platform!)
    final mountainBaseShadow = Paint()
      ..color = const Color(0x35000000)
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(flagMonumentPos.dx, flagMonumentPos.dy + 24),
        width: 96,
        height: 26,
      ),
      mountainBaseShadow,
    );

    // Left Rock Peak
    final leftRockPath = Path()
      ..moveTo(flagMonumentPos.dx - 40, flagMonumentPos.dy + 22)
      ..lineTo(flagMonumentPos.dx - 26, flagMonumentPos.dy - 18)
      ..lineTo(flagMonumentPos.dx - 8, flagMonumentPos.dy + 22)
      ..close();
    canvas.drawPath(leftRockPath, rockDarkPaint);

    // Center Main Flat-Top Rock Peak
    final centerRockPath = Path()
      ..moveTo(flagMonumentPos.dx - 22, flagMonumentPos.dy + 24)
      ..lineTo(flagMonumentPos.dx - 14, flagMonumentPos.dy - 32)
      ..lineTo(flagMonumentPos.dx + 20, flagMonumentPos.dy - 32)
      ..lineTo(flagMonumentPos.dx + 32, flagMonumentPos.dy + 24)
      ..close();
    canvas.drawPath(centerRockPath, rockPaint);

    // Flat Top Rock Platform
    final topPlatformPath = Path()
      ..moveTo(flagMonumentPos.dx - 14, flagMonumentPos.dy - 32)
      ..lineTo(flagMonumentPos.dx + 20, flagMonumentPos.dy - 32)
      ..lineTo(flagMonumentPos.dx + 14, flagMonumentPos.dy - 26)
      ..lineTo(flagMonumentPos.dx - 9, flagMonumentPos.dy - 26)
      ..close();
    final topPlatformPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.fill;
    canvas.drawPath(topPlatformPath, topPlatformPaint);

    // C) Wooden Flagpole (Taller 96px Pole!)
    final poleBaseY = flagMonumentPos.dy - 28;
    final poleTopY = flagMonumentPos.dy - 124;
    final poleX = flagMonumentPos.dx + 3;

    final polePaint = Paint()
      ..color = const Color(0xFF5C2C06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(poleX, poleBaseY),
      Offset(poleX, poleTopY),
      polePaint,
    );

    // Golden Finial Sphere on Pole Top
    final finialPaint = Paint()
      ..color = const Color(0xFFFFD166)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(poleX, poleTopY - 3), 5.5, finialPaint);

    // D) Waving 3D Indian Tricolor Flag (54px wide, 36px high with Waving Bezier Ripples!)
    // Saffron Top Stripe (#FF9933)
    final saffronPath = Path()
      ..moveTo(poleX, poleTopY)
      ..cubicTo(
        poleX + 18,
        poleTopY - 6,
        poleX + 36,
        poleTopY + 6,
        poleX + 54,
        poleTopY - 4,
      )
      ..lineTo(poleX + 54, poleTopY + 8)
      ..cubicTo(
        poleX + 36,
        poleTopY + 18,
        poleX + 18,
        poleTopY + 6,
        poleX,
        poleTopY + 12,
      )
      ..close();
    final saffronPaint = Paint()
      ..color = const Color(0xFFFF9933)
      ..style = PaintingStyle.fill;
    canvas.drawPath(saffronPath, saffronPaint);

    // White Middle Stripe (#FFFFFF)
    final whitePath = Path()
      ..moveTo(poleX, poleTopY + 12)
      ..cubicTo(
        poleX + 18,
        poleTopY + 6,
        poleX + 36,
        poleTopY + 18,
        poleX + 54,
        poleTopY + 8,
      )
      ..lineTo(poleX + 54, poleTopY + 20)
      ..cubicTo(
        poleX + 36,
        poleTopY + 30,
        poleX + 18,
        poleTopY + 18,
        poleX,
        poleTopY + 24,
      )
      ..close();
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawPath(whitePath, whitePaint);

    // Navy Blue Ashoka Chakra Wheel (#000080) centered on white stripe
    final chakraCenter = Offset(poleX + 26, poleTopY + 16);
    final chakraOuterPaint = Paint()
      ..color = const Color(0xFF000080)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final chakraDotPaint = Paint()
      ..color = const Color(0xFF000080)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(chakraCenter, 5.0, chakraOuterPaint);
    canvas.drawCircle(chakraCenter, 1.6, chakraDotPaint);
    for (int i = 0; i < 12; i++) {
      final double spokeAngle = i * (math.pi / 6);
      canvas.drawLine(
        chakraCenter,
        Offset(
          chakraCenter.dx + math.cos(spokeAngle) * 4.8,
          chakraCenter.dy + math.sin(spokeAngle) * 4.8,
        ),
        chakraOuterPaint,
      );
    }

    // India Green Bottom Stripe (#138808)
    final greenStripePath = Path()
      ..moveTo(poleX, poleTopY + 24)
      ..cubicTo(
        poleX + 18,
        poleTopY + 18,
        poleX + 36,
        poleTopY + 30,
        poleX + 54,
        poleTopY + 20,
      )
      ..lineTo(poleX + 54, poleTopY + 32)
      ..cubicTo(
        poleX + 36,
        poleTopY + 42,
        poleX + 18,
        poleTopY + 30,
        poleX,
        poleTopY + 36,
      )
      ..close();
    final greenStripePaint = Paint()
      ..color = const Color(0xFF138808)
      ..style = PaintingStyle.fill;
    canvas.drawPath(greenStripePath, greenStripePaint);

    // E) Floating Gold Sparkles around Flag
    final sparklePaint = Paint()
      ..color = const Color(0xFFFFD166)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(flagMonumentPos.dx - 35, flagMonumentPos.dy - 65),
      3.0,
      sparklePaint,
    );
    canvas.drawCircle(
      Offset(flagMonumentPos.dx + 65, flagMonumentPos.dy - 85),
      3.5,
      sparklePaint,
    );
    canvas.drawCircle(
      Offset(flagMonumentPos.dx + 48, flagMonumentPos.dy - 20),
      2.5,
      sparklePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SubtleEnvironmentMapPainter oldDelegate) =>
      false;
}

/// Elevated yellow tile with a curved convex bulge at the top — like the Minion background slope.
class _OnboardingElevatedTile extends StatelessWidget {
  final double screenHeight;
  const _OnboardingElevatedTile({required this.screenHeight});

  @override
  Widget build(BuildContext context) {
    // Tile occupies bottom ~48% of the screen
    final tileHeight = screenHeight * 0.48;
    // Gentle bulge peak height
    final bulgePeakRise = tileHeight * 0.08;

    return SizedBox(
      height: tileHeight + bulgePeakRise,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Offset the tile down by bulgePeakRise so the bulge peeks above
          Positioned(
            top: bulgePeakRise,
            left: 0,
            right: 0,
            child: SizedBox(
              height: tileHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Soft shadow strip above the tile for 3D elevation
                  Positioned(
                    top: -16,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 32,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x00000000),
                            Color(0x25000000),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // The elevated tile with a gentle convex bulge ClipPath
                  ClipPath(
                    clipper: _OnboardingTileClipper(),
                    child: Container(
                      width: double.infinity,
                      height: tileHeight,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFFFD54F), // Luminous Rich Warm Gold
                            Color(0xFFFFB300), // Vibrant Amber Gold
                            Color(0xFFFF8F00), // Deep Golden Orange
                          ],
                          stops: [0.0, 0.50, 1.0],
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Top-right organic white bubble circle highlight
                          Positioned(
                            top: 15,
                            right: -15,
                            child: Container(
                              width: 95,
                              height: 95,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.24),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 75,
                            right: 60,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.20),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          // Top-left organic white bubble accent
                          Positioned(
                            top: 15,
                            left: 20,
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.20),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Inner top-edge shimmer highlight for 3D depth
                  Positioned(
                    top: 24,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 3,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0x00FFFFFF),
                            Color(0x70FFFFFF),
                            Color(0x00FFFFFF),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Blinking eyes positioned comfortably on top of the lower yellow tile!
          Positioned(
            top: 35,
            left: 0,
            right: 0,
            child: Center(
              child: BlinkingEyesWidget(
                accentDark: const Color(0xFF4A2900),
                scale: 1.50,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ClipPath that creates a gentle convex upward-bulge slope at the top of the tile.
class _OnboardingTileClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    // Bottom-left
    path.moveTo(0, size.height);
    // Bottom-right
    path.lineTo(size.width, size.height);
    // Right side up
    path.lineTo(size.width, size.height * 0.08);
    // Gentle convex cubic bezier bulge
    path.cubicTo(
      size.width * 0.72, -size.height * 0.08,
      size.width * 0.28, -size.height * 0.08,
      0, size.height * 0.08,
    );
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Custom Painter drawing TURBULENT wavy distorted grid lines across the onboarding background.
/// Uses multi-frequency sine wave distortion to create an organic, field-like warped grid effect.
class GridLinesBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = const Color(0x289E9E9E); // Visible but soft gray on white bg

    const double step = 32.0;
    const int segments = 80; // Points per line for smooth curves

    // --- Turbulent Horizontal Lines ---
    for (double y = 0; y <= size.height + step; y += step) {
      final path = Path();
      bool started = false;
      for (int i = 0; i <= segments; i++) {
        final double t = i / segments;
        final double x = t * size.width;
        // Multi-layer sine distortion for turbulent look
        final double distortion =
            10.0 * _sin(t * 6.28 + y * 0.04) +
            5.0 * _sin(t * 12.56 + y * 0.09 + 1.3) +
            3.0 * _sin(t * 20.0 + y * 0.02 + 2.7);
        final double dy = y + distortion;
        if (!started) {
          path.moveTo(x, dy);
          started = true;
        } else {
          path.lineTo(x, dy);
        }
      }
      canvas.drawPath(path, paint);
    }

    // --- Turbulent Vertical Lines ---
    for (double x = 0; x <= size.width + step; x += step) {
      final path = Path();
      bool started = false;
      for (int i = 0; i <= segments; i++) {
        final double t = i / segments;
        final double y = t * size.height;
        // Multi-layer sine distortion for turbulent look
        final double distortion =
            10.0 * _sin(t * 6.28 + x * 0.04) +
            5.0 * _sin(t * 12.56 + x * 0.09 + 0.8) +
            3.0 * _sin(t * 20.0 + x * 0.02 + 1.9);
        final double dx = x + distortion;
        if (!started) {
          path.moveTo(dx, y);
          started = true;
        } else {
          path.lineTo(dx, y);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  // Fast sin approximation
  double _sin(double radians) {
    return (radians % (2 * 3.14159265358979))
        .let((r) => r > 3.14159265358979 ? r - 2 * 3.14159265358979 : r)
        .let((r) {
      // Taylor series sin approximation
      final r2 = r * r;
      return r * (1 - r2 / 6.0 * (1 - r2 / 20.0 * (1 - r2 / 42.0)));
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

extension _NumLet<T> on T {
  R let<R>(R Function(T) block) => block(this);
}

/// Custom Painter for Child & Parent In-Card Grid Background
class InCardGridPainter extends CustomPainter {
  final Color gridColor;
  const InCardGridPainter({required this.gridColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0;

    const double step = 12.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom Painter drawing crisp, straight grid lines over the purple category background.
class CategoryGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withValues(alpha: 0.18);

    const double step = 28.0;

    // Draw straight vertical lines
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw straight horizontal lines
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// SPEECH LEVEL & ASSESSMENT QUESTIONNAIRE SELECTOR WIDGET (16 QUESTIONS)
// ─────────────────────────────────────────────────────────────────────────────
class _SpeechLevelSelectorWidget extends StatefulWidget {
  final _AgeTheme theme;
  final int step;
  final String childName;
  final VoidCallback onNextStep;
  final VoidCallback onPrevStep;

  const _SpeechLevelSelectorWidget({
    super.key,
    required this.theme,
    required this.step,
    required this.childName,
    required this.onNextStep,
    required this.onPrevStep,
  });

  @override
  State<_SpeechLevelSelectorWidget> createState() => _SpeechLevelSelectorWidgetState();
}

class _SpeechLevelSelectorWidgetState extends State<_SpeechLevelSelectorWidget> {
  // Store single-select answer per step (Starts empty for clean onboarding!)
  final Map<int, String> _singleAnswers = {};

  // Store multi-select checkbox answers per step
  final Map<int, Set<String>> _multiAnswers = {};

  // Store final speech level slider progress (step 15)
  double _speechLevelSliderValue = 0.5;

  @override
  Widget build(BuildContext context) {
    final questions = _getQuestions(widget.childName);
    final safeStep = widget.step.clamp(0, questions.length - 1);
    final q = questions[safeStep];

    final String tag = q['tag'] as String;
    final String title = q['title'] as String;
    final String subtitle = q['subtitle'] as String;
    final String type = q['type'] as String;
    final List<String> options = List<String>.from(q['options'] as List);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: 440,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 36,
            offset: Offset(0, 14),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 22.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SlothUI Top Header Bar: Logo Badge & Progress Counter
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4F46E5),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          'T',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'TIKO Onboarding',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                Text(
                  '${safeStep + 1}/${questions.length}',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // SlothUI Thin Pill Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (safeStep + 1) / questions.length.toDouble(),
                minHeight: 6,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
              ),
            ),

            const SizedBox(height: 18),

            // 4 Cartoon Avatars & Speech Bubbles Header Illustration
            Center(child: _buildFourAvatarIllustration()),

            const SizedBox(height: 16),

            // Left-aligned Question Title
            Text(
              title,
              textAlign: TextAlign.left,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                height: 1.25,
              ),
            ),

            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.left,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Question Content based on type
            if (type == 'single_radio')
              _buildSingleRadioList(safeStep, options)
            else if (type == 'multi_checkbox')
              _buildMultiCheckboxList(safeStep, options)
            else if (type == 'slider_level')
              _buildSpeechLevelSlider(),

            const SizedBox(height: 24),

            // SlothUI Bottom Row: [< Back] [Continue >]
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      widget.onPrevStep();
                    },
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.chevron_left_rounded, color: Color(0xFF1E293B), size: 20),
                          SizedBox(width: 4),
                          Text(
                            'Back',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      widget.onNextStep();
                    },
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4F46E5), Color(0xFF4338CA)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x354F46E5),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            safeStep == questions.length - 1 ? 'Finish 🎉' : 'Continue',
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 4 Cartoon Avatars & Speech Bubbles Header Illustration (Arranged in 2 Lines / 2x2 Grid)
  Widget _buildFourAvatarIllustration() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Line 1: Green Speech Bubble & Boy Avatar
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                    bottomRight: Radius.circular(4),
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.notes_rounded, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFFED7AA),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFEA580C), width: 1.8),
                ),
                child: const Center(
                  child: Text('👦', style: TextStyle(fontSize: 20)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Line 2: Girl Avatar & Orange Speech Bubble
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFFBCFE8),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFDB2777), width: 1.8),
                ),
                child: const Center(
                  child: Text('👧', style: TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFFF97316),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                    bottomLeft: Radius.circular(4),
                    bottomRight: Radius.circular(14),
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.notes_rounded, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // SlothUI Left Circular Option Icon Helper
  Widget _getOptionIcon(String opt, bool isSelected) {
    IconData iconData = Icons.dashboard_customize_rounded;
    if (opt.contains('🔊') || opt.contains('Spoken') || opt.contains('sounds') || opt.contains('explanations')) {
      iconData = Icons.volume_up_rounded;
    } else if (opt.contains('📖') || opt.contains('Written')) {
      iconData = Icons.menu_book_rounded;
    } else if (opt.contains('🖼️') || opt.contains('Pictures') || opt.contains('icons')) {
      iconData = Icons.photo_library_rounded;
    } else if (opt.contains('💬') || opt.contains('language') || opt.contains('words')) {
      iconData = Icons.chat_bubble_outline_rounded;
    } else if (opt.contains('⚡') || opt.contains('Normal')) {
      iconData = Icons.bolt_rounded;
    } else if (opt.contains('🐢') || opt.contains('Slow') || opt.contains('More time')) {
      iconData = Icons.hourglass_bottom_rounded;
    } else if (opt.contains('🌿') || opt.contains('Very little') || opt.contains('Less busy')) {
      iconData = Icons.eco_rounded;
    } else if (opt.contains('🎵') || opt.contains('Music')) {
      iconData = Icons.music_note_rounded;
    } else if (opt.contains('🔔') || opt.contains('Sounds only')) {
      iconData = Icons.notifications_active_rounded;
    } else if (opt.contains('🔇') || opt.contains('No sounds')) {
      iconData = Icons.volume_off_rounded;
    } else if (opt.contains('🌈') || opt.contains('visual')) {
      iconData = Icons.palette_rounded;
    } else if (opt.contains('⏱️') || opt.contains('time')) {
      iconData = Icons.timer_rounded;
    } else if (opt.contains('∞')) {
      iconData = Icons.all_inclusive_rounded;
    } else if (opt == 'Yes' || opt == 'Yes, always' || opt == 'Yes, anytime') {
      iconData = Icons.check_circle_outline_rounded;
    } else if (opt == 'No') {
      iconData = Icons.cancel_outlined;
    } else if (opt.contains('Autism') || opt.contains('Speech') || opt.contains('ADHD') || opt.contains('Apraxia') || opt.contains('Delay')) {
      iconData = Icons.medical_services_rounded;
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFEEF2FF) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? const Color(0xFFC7D2FE) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      child: Center(
        child: Icon(
          iconData,
          size: 22,
          color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
        ),
      ),
    );
  }

  // Build Single-Radio Choice Options (Matching SlothUI Cards!)
  Widget _buildSingleRadioList(int step, List<String> options) {
    final selectedValue = _singleAnswers[step];

    return Column(
      children: options.map((opt) {
        final isSelected = selectedValue == opt;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _singleAnswers[step] = opt;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFEEF2FF) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
                  width: isSelected ? 1.8 : 1.0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF4F46E5).withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  _getOptionIcon(opt, isSelected),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      opt,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14.5,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                        color: isSelected ? const Color(0xFF1E1B4B) : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? const Color(0xFF4F46E5) : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFCBD5E1),
                        width: 1.8,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // Build Multi-Checkbox Choice Options (Matching SlothUI Cards!)
  Widget _buildMultiCheckboxList(int step, List<String> options) {
    final selectedSet = _multiAnswers.putIfAbsent(step, () => <String>{});

    return Column(
      children: options.map((opt) {
        final isSelected = selectedSet.contains(opt);

        return Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                if (isSelected) {
                  selectedSet.remove(opt);
                } else {
                  selectedSet.add(opt);
                }
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFEEF2FF) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
                  width: isSelected ? 1.8 : 1.0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF4F46E5).withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  _getOptionIcon(opt, isSelected),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      opt,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14.5,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                        color: isSelected ? const Color(0xFF1E1B4B) : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? const Color(0xFF4F46E5) : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFCBD5E1),
                        width: 1.8,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // Build Final Step Interactive Speech Level Slider
  Widget _buildSpeechLevelSlider() {
    String levelLabel;
    if (_speechLevelSliderValue <= 0.33) {
      levelLabel = 'Getting started';
    } else if (_speechLevelSliderValue <= 0.66) {
      levelLabel = 'Great progress';
    } else {
      levelLabel = 'Excellent';
    }

    return Column(
      children: [
        // Level Active Badge Display
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF10B981), width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1510B981),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            levelLabel,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF065F46),
              letterSpacing: 0.3,
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Slider Bar Control
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: const Color(0xFF10B981),
            inactiveTrackColor: const Color(0xFFE2E8F0),
            thumbColor: const Color(0xFF10B981),
            overlayColor: const Color(0x2910B981),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            trackHeight: 8,
          ),
          child: Slider(
            value: _speechLevelSliderValue,
            min: 0.0,
            max: 1.0,
            onChanged: (val) {
              HapticFeedback.selectionClick();
              setState(() {
                _speechLevelSliderValue = val;
              });
            },
          ),
        ),

        const SizedBox(height: 12),

        // Range Label Arrows
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'Getting started',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
              ),
            ),
            Icon(Icons.swap_horiz_rounded, size: 18, color: Color(0xFF94A3B8)),
            Text(
              'Great progress',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
              ),
            ),
            Icon(Icons.swap_horiz_rounded, size: 18, color: Color(0xFF94A3B8)),
            Text(
              'Excellent',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  // 16 Questions Definitions List
  static List<Map<String, dynamic>> _getQuestions(String childName) {
    final String displayName = childName.isNotEmpty ? childName : 'Your child';

    return [
      // 1. Evaluation
      {
        'tag': 'EVALUATION',
        'category': 'Therapist Evaluation',
        'title': 'Has your child ever been evaluated by a therapist?',
        'subtitle': 'Select one answer.',
        'type': 'single_radio',
        'options': ['Yes', 'No'],
      },

      // 3. Developmental Issues
      {
        'tag': 'DEVELOPMENTAL ISSUES',
        'category': 'Developmental Issues',
        'title': 'Developmental Issues',
        'subtitle': 'Please select the diagnoses your child has received.',
        'type': 'multi_checkbox',
        'options': [
          'Speech Delay',
          'Autism Spectrum Disorder',
          'Developmental Delay',
          'ADHD',
          'Apraxia',
          'Premature Birth',
        ],
      },

      // 4. Understanding & Following Instructions - Q1
      {
        'tag': 'UNDERSTANDING & FOLLOWING INSTRUCTIONS',
        'category': 'Understanding & Following Instructions',
        'title': 'Does your child understand words for order, like first, next, and last?',
        'subtitle': 'Select one answer.',
        'type': 'single_radio',
        'options': ['Yes', 'No'],
      },

      // 5. Understanding & Following Instructions - Q2
      {
        'tag': 'UNDERSTANDING & FOLLOWING INSTRUCTIONS',
        'category': 'Understanding & Following Instructions',
        'title': 'Does your child understand words for time, like yesterday, today, and tomorrow?',
        'subtitle': 'Select one answer.',
        'type': 'single_radio',
        'options': ['Yes', 'No'],
      },

      // 6. Understanding & Following Instructions - Q3
      {
        'tag': 'UNDERSTANDING & FOLLOWING INSTRUCTIONS',
        'category': 'Understanding & Following Instructions',
        'title': 'Does your child follow instructions, like "Put your pajamas on, brush your teeth, and then pick out a book."?',
        'subtitle': 'Select one answer.',
        'type': 'single_radio',
        'options': ['Yes', 'No'],
      },

      // 7. Understanding & Following Instructions - Q4
      {
        'tag': 'UNDERSTANDING & FOLLOWING INSTRUCTIONS',
        'category': 'Understanding & Following Instructions',
        'title': 'Does your child listen to and understand most of what he/she hears at home?',
        'subtitle': 'Select one answer.',
        'type': 'single_radio',
        'options': ['Yes', 'No'],
      },

      // 8. Understanding & Following Instructions - Q5
      {
        'tag': 'UNDERSTANDING & FOLLOWING INSTRUCTIONS',
        'category': 'Understanding & Following Instructions',
        'title': 'Does your child respond when you call him/her from another room?',
        'subtitle': 'Select one answer.',
        'type': 'single_radio',
        'options': ['Yes', 'No'],
      },

      // 9. Speaking & Communication - Q1
      {
        'tag': 'SPEAKING & COMMUNICATION',
        'category': 'Speaking & Communication',
        'title': 'Can your child say his/her first and last name?',
        'subtitle': 'Select one answer.',
        'type': 'single_radio',
        'options': ['Yes', 'No'],
      },

      // 10. Speaking & Communication - Q2
      {
        'tag': 'SPEAKING & COMMUNICATION',
        'category': 'Speaking & Communication',
        'title': 'Which of the following sounds does your child need to improve?',
        'subtitle': 'Select all that apply.',
        'type': 'multi_checkbox',
        'options': [
          'b — ball, baby, cub',
          'd — dog, idea, mud',
          'h — hi, ahead, haha',
          'm — moon, lemon, gum',
          'n — no, canoe, nine',
        ],
      },

      // 11. Social & Imaginative Skills - Q1
      {
        'tag': 'SOCIAL & IMAGINATIVE SKILLS',
        'category': 'Social & Imaginative Skills',
        'title': 'Does your child like to sing, dance, or act?',
        'subtitle': 'Select one answer.',
        'type': 'single_radio',
        'options': ['Yes', 'No'],
      },

      // 12. Social & Imaginative Skills - Q2
      {
        'tag': 'SOCIAL & IMAGINATIVE SKILLS',
        'category': 'Social & Imaginative Skills',
        'title': 'Can your child tell apart what\'s real and what\'s make-believe?',
        'subtitle': 'Select one answer.',
        'type': 'single_radio',
        'options': ['Yes', 'No'],
      },

      // 13. Social & Imaginative Skills - Q3
      {
        'tag': 'SOCIAL & IMAGINATIVE SKILLS',
        'category': 'Social & Imaginative Skills',
        'title': 'Does your child prefer to play with other children than by himself?',
        'subtitle': 'Select one answer.',
        'type': 'single_radio',
        'options': ['Yes', 'No'],
      },

      // 14. Communication Challenges - Q1
      {
        'tag': 'COMMUNICATION CHALLENGES',
        'category': 'Communication Challenges',
        'title': 'How does your child react when they are not understood?',
        'subtitle': 'Select one option.',
        'type': 'single_radio',
        'options': [
          'Gets very upset - tantrums or crying',
          'Gets frustrated - but tries again',
          'Stays calm - uses gestures or moves on',
          'Doesn\'t seem to notice or care yet',
        ],
      },

      // 15. Communication Challenges - Q2
      {
        'tag': 'COMMUNICATION CHALLENGES',
        'category': 'Communication Challenges',
        'title': 'What is your biggest challenge when trying to teach your child to speak?',
        'subtitle': 'Select one option.',
        'type': 'single_radio',
        'options': [
          'I don\'t know where to start',
          'I can\'t find the time for practice',
          'I am not sure if I am doing it right',
          'I struggle with their attention',
        ],
      },

      // 16. Accessibility & Sensory: How instructions understood best
      {
        'tag': 'ACCESSIBILITY & SENSORY',
        'category': 'Accessibility & Sensory Preferences',
        'title': 'How does your child understand instructions best?',
        'subtitle': 'Select one option.',
        'type': 'single_radio',
        'options': [
          'Spoken instructions',
          'Written instructions',
          'Spoken and written instructions',
        ],
      },

      // 17. Accessibility & Sensory: Repeat button
      {
        'tag': 'ACCESSIBILITY & SENSORY',
        'category': 'Accessibility & Sensory Preferences',
        'title': 'Would your child benefit from a button to repeat instructions?',
        'subtitle': 'Select one answer.',
        'type': 'single_radio',
        'options': ['Yes', 'No'],
      },

      // 18. Accessibility & Sensory: Easiest instruction type
      {
        'tag': 'ACCESSIBILITY & SENSORY',
        'category': 'Accessibility & Sensory Preferences',
        'title': 'Which type of instruction is easiest for your child to follow?',
        'subtitle': 'Select one option.',
        'type': 'single_radio',
        'options': [
          'Pictures and icons',
          'Short and simple language',
          'Spoken explanations',
          'A combination of these',
        ],
      },

      // 19. Accessibility & Sensory: Text size
      {
        'tag': 'ACCESSIBILITY & SENSORY',
        'category': 'Accessibility & Sensory Preferences',
        'title': 'What text size is most comfortable for your child?',
        'subtitle': 'Select one option.',
        'type': 'single_radio',
        'options': ['Normal', 'Big', 'Very big'],
      },

      // 20. Accessibility & Sensory: Animation speed
      {
        'tag': 'ACCESSIBILITY & SENSORY',
        'category': 'Accessibility & Sensory Preferences',
        'title': 'What animation speed is most comfortable for your child?',
        'subtitle': 'Select one option.',
        'type': 'single_radio',
        'options': [
          'Normal',
          'Slow',
          'Very little movement',
        ],
      },

      // 21. Accessibility & Sensory: Reduced motion
      {
        'tag': 'ACCESSIBILITY & SENSORY',
        'category': 'Accessibility & Sensory Preferences',
        'title': 'Would your child benefit from reduced motion on the screen?',
        'subtitle': 'Select one answer.',
        'type': 'single_radio',
        'options': ['Yes', 'No'],
      },

      // 22. Accessibility & Sensory: Sound level
      {
        'tag': 'ACCESSIBILITY & SENSORY',
        'category': 'Accessibility & Sensory Preferences',
        'title': 'What level of sound or music is most comfortable for your child?',
        'subtitle': 'Select one option.',
        'type': 'single_radio',
        'options': [
          'Music and sounds',
          'Sounds only',
          'No sounds',
        ],
      },

      // 23. Accessibility & Sensory: Subtitles / Text alternatives
      {
        'tag': 'ACCESSIBILITY & SENSORY',
        'category': 'Accessibility & Sensory Preferences',
        'title': 'When TIKO provides spoken instructions, would your child benefit from subtitles or text alternatives?',
        'subtitle': 'Select one option.',
        'type': 'single_radio',
        'options': [
          'Yes, always',
          'Only sometimes',
          'No, I can listen',
        ],
      },

      // 24. Accessibility & Sensory: Visual environment
      {
        'tag': 'ACCESSIBILITY & SENSORY',
        'category': 'Accessibility & Sensory Preferences',
        'title': 'Which type of visual environment is most comfortable for your child?',
        'subtitle': 'Select one option.',
        'type': 'single_radio',
        'options': [
          'Normal',
          'Less busy',
          'Very simple',
        ],
      },

      // 25. Accessibility & Sensory: Pause or break option
      {
        'tag': 'ACCESSIBILITY & SENSORY',
        'category': 'Accessibility & Sensory Preferences',
        'title': 'Would your child benefit from having a pause or break option during activities?',
        'subtitle': 'Select one answer.',
        'type': 'single_radio',
        'options': ['Yes', 'No'],
      },

      // 26. Accessibility & Sensory: Response time
      {
        'tag': 'ACCESSIBILITY & SENSORY',
        'category': 'Accessibility & Sensory Preferences',
        'title': 'How much response time does your child typically need?',
        'subtitle': 'Select one option.',
        'type': 'single_radio',
        'options': [
          'Normal time',
          'More time',
          'Take my time',
        ],
      },

      // 27. Accessibility & Sensory: Predictable screen layout
      {
        'tag': 'ACCESSIBILITY & SENSORY',
        'category': 'Accessibility & Sensory Preferences',
        'title': 'Would your child benefit from consistent navigation and predictable screen layouts?',
        'subtitle': 'Select one answer.',
        'type': 'single_radio',
        'options': ['Yes', 'No'],
      },

      // 28. Accessibility & Sensory: Important information communication
      {
        'tag': 'ACCESSIBILITY & SENSORY',
        'category': 'Accessibility & Sensory Preferences',
        'title': 'How should important information be communicated to your child?',
        'subtitle': 'Select one option.',
        'type': 'single_radio',
        'options': [
          'Pictures and words',
          'Pictures, words, and sounds',
          'Sounds and words',
        ],
      },

      // 29. Accessibility & Sensory: Adjust preferences later
      {
        'tag': 'ACCESSIBILITY & SENSORY',
        'category': 'Accessibility & Sensory Preferences',
        'title': 'Would you like to be able to adjust these preferences later?',
        'subtitle': 'Select one answer.',
        'type': 'single_radio',
        'options': ['Yes, anytime', 'No'],
      },

      // 30. Speech Level — Final Step
      {
        'tag': 'SPEECH LEVEL — FINAL STEP',
        'category': 'Speech Level Assessment',
        'title': '$displayName\'s speech level',
        'subtitle': 'Manually set your child\'s current speech progress level.',
        'type': 'slider_level',
        'options': [],
      },
    ];
  }
}

