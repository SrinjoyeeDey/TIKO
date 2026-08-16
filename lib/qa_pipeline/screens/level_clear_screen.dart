import 'dart:math' as math;
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../database/progress_repository.dart';
import '../models/learning_content.dart';
import '../services/content_discovery_service.dart';
import '../services/star_calculator.dart';
import 'video_player_screen.dart';
import 'parent_dashboard.dart';
import '../../core/state/child_state.dart';
import '../../core/services/media_capture_service.dart';
import '../../core/services/event_service.dart';
import '../../core/models/event_model.dart';
import '../../core/widgets/panda_character.dart';
import '../services/clinical_report_service.dart';

/// Full-screen Celebration screen showing crystal prism lesson badge with specular light glare,
/// lesson progress (e.g. Lesson 1 of 5), remaining count, and reward stats.
class LevelClearScreen extends StatefulWidget {
  final String childId;
  final LearningLevel level;
  final int totalCorrect;
  final int totalQuestions;

  const LevelClearScreen({
    super.key,
    required this.childId,
    required this.level,
    required this.totalCorrect,
    required this.totalQuestions,
  });

  @override
  State<LevelClearScreen> createState() => _LevelClearScreenState();
}

class _LevelClearScreenState extends State<LevelClearScreen>
    with TickerProviderStateMixin {
  late final ConfettiController _confettiController;
  late final AnimationController _badgePulseController;
  late final AnimationController _glareController;
  late final int _stars;
  late final String _message;
  int _currentLevelIndex = 1;
  int _totalLevels = 5;

  @override
  void initState() {
    super.initState();
    _stars = StarCalculator.calculateStars(
      widget.totalCorrect,
      widget.totalQuestions,
    );
    _message = StarCalculator.getMessage(_stars);
    _currentLevelIndex = _parseLevelNumber(widget.level);

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 5),
    )..play();

    // Pulse & scale entrance animation controller for the diamond badge
    _badgePulseController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);

    // Continuous 3-second specular glare beam sweep controller
    _glareController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _saveCompletion();
    _loadChapterProgress();
  }

  int _parseLevelNumber(LearningLevel level) {
    final RegExp regExp = RegExp(r'\d+');
    final match = regExp.firstMatch(level.id) ?? regExp.firstMatch(level.levelName);
    if (match != null) {
      return int.tryParse(match.group(0)!) ?? 1;
    }
    return 1;
  }

  Future<void> _loadChapterProgress() async {
    try {
      final chapters = await ContentDiscoveryService.discoverContent();
      final chapter = chapters.where((c) => c.id == widget.level.chapterId).firstOrNull;
      if (chapter != null && chapter.levels.isNotEmpty) {
        final idx = chapter.levels.indexWhere((l) => l.id == widget.level.id);
        if (mounted) {
          setState(() {
            _totalLevels = chapter.levels.length;
            _currentLevelIndex = idx != -1 ? idx + 1 : _currentLevelIndex;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _saveCompletion() async {
    // 1. Immediately stop and release the camera hardware
    await MediaCaptureService.instance.disposeCamera();

    // 2. Persist level progress to SQLite database
    await ProgressRepository.saveLevelCompletion(
      childId: widget.childId,
      chapterId: widget.level.chapterId,
      levelId: widget.level.id,
      stars: _stars,
    );

    // 3. Log real interaction and complete session
    ChildState.instance.incrementActivitiesCompleted();
    await ChildState.instance.logInteraction(
      type: 'level_complete',
      questionId: widget.level.id,
      isCorrect: widget.totalCorrect == widget.totalQuestions,
      details: {
        'totalCorrect': widget.totalCorrect,
        'totalQuestions': widget.totalQuestions,
        'stars': _stars,
      },
    );

    // 4. Record ACTIVITY_COMPLETED telemetry event
    await EventService.logEvent(
      eventType: EventType.activityCompleted,
      activityId: widget.level.id,
      data: {
        'chapterId': widget.level.chapterId,
        'levelId': widget.level.id,
        'stars': _stars,
        'totalCorrect': widget.totalCorrect,
        'totalQuestions': widget.totalQuestions,
      },
    );

    await ChildState.instance.endCurrentSession();

    // 5. Trigger generation of Post-Play Clinical & Parental Report
    try {
      await ClinicalReportService.generateReport(widget.childId);
    } catch (e) {
      debugPrint('LevelClearScreen: Error generating clinical report: $e');
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _badgePulseController.dispose();
    _glareController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int remainingLessons = math.max(0, _totalLevels - _currentLevelIndex);
    final bool hasNextLesson = _currentLevelIndex < _totalLevels;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D1117), // Deep Celestial Space
        body: Stack(
          alignment: Alignment.center,
          children: [
            // 1. 1913 West Bengal Map Background Wallpaper
            Positioned.fill(
              child: Opacity(
                opacity: 0.22,
                child: Image.asset(
                  'assets/images/story_selection_wb_bg.png',
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => const SizedBox(),
                ),
              ),
            ),

            // 2. Radial Dark Vignette Overlay
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.9,
                    colors: [
                      Color(0x330F172A),
                      Color(0xEE0B0F19),
                      Color(0xFF05080E),
                    ],
                  ),
                ),
              ),
            ),

            // 3. Main Lesson Progress Content Layer
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),

                      // CELEBRATING PANDA COMPANION
                      const PandaCharacterWidget(
                        initialAnimation: PandaAnimation.celebrate,
                        size: 110,
                        showSpeechBubble: true,
                        speechText: 'You did it! Amazing! 🌟',
                      ),
                      const SizedBox(height: 12),

                      // CRYSTAL PRISM DIAMOND LESSON BADGE WITH SPECULAR GLARE & LIGHT FLARES
                      _buildCrystalDiamondBadge(),

                      const SizedBox(height: 14),

                      // "Lesson Completed" Cursive Floating Text Banner
                      const Text(
                        'Lesson Complete!',
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 32,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFF8E1),
                          shadows: [
                            Shadow(color: Color(0xFFD4AF37), blurRadius: 16),
                            Shadow(color: Colors.black, blurRadius: 8, offset: Offset(2, 2)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Lesson Progress Pill (e.g. LESSON 1 OF 5 COMPLETED)
                      _buildLessonProgressPill(remainingLessons),

                      const SizedBox(height: 14),

                      // Segmented Progress Dots (1 of 5 filled)
                      _buildSegmentedProgressDots(),

                      const SizedBox(height: 12),

                      // Friendly performance message
                      Text(
                        _message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFF5EAD4),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Reward & Remaining Progress Cards
                      _buildRewardStatCards(remainingLessons),

                      const SizedBox(height: 24),

                      // Action Button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _onContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD4AF37), // Vintage Gold
                            foregroundColor: const Color(0xFF2E1C12),
                            elevation: 10,
                            shadowColor: const Color(0xFFD4AF37).withValues(alpha: 0.6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(color: Color(0xFFFFF8E1), width: 1.8),
                            ),
                          ),
                          child: Text(
                            hasNextLesson
                                ? 'START LESSON ${_currentLevelIndex + 1} OF $_totalLevels →'
                                : 'FINISH STORY →',
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // View Parent Dashboard Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ParentDashboard(childId: widget.childId),
                              ),
                            );
                          },
                          icon: const Icon(Icons.analytics_outlined, color: Color(0xFFD4AF37), size: 20),
                          label: const Text(
                            'VIEW PARENT DASHBOARD',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              color: Color(0xFFFFF8E1),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0x88D4AF37), width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            backgroundColor: const Color(0x552E1C12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),

            // 4. Confetti Celebration Cannon
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                numberOfParticles: 40,
                maxBlastForce: 25,
                minBlastForce: 8,
                gravity: 0.18,
                colors: const [
                  Color(0xFFFFD700),
                  Color(0xFFD4AF37),
                  Color(0xFF8B6914),
                  Color(0xFFFFF8E1),
                  Color(0xFF4CAF50),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Refractive Crystal Diamond Lesson Badge with Specular Light Glare Sweep & 4-Point Star Flares
  Widget _buildCrystalDiamondBadge() {
    return AnimatedBuilder(
      animation: _badgePulseController,
      builder: (context, child) {
        final scale = 1.0 + 0.03 * math.sin(_badgePulseController.value * math.pi * 2);
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: SizedBox(
        width: 230,
        height: 230,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // 1. Radiant Background Gold Aura Glow
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.45),
                    blurRadius: 42,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),

            // 2. Rotated Smoked Crystal Diamond (45 Degrees)
            Transform.rotate(
              angle: math.pi / 4,
              child: Container(
                width: 172,
                height: 172,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xEE4E3624), // Frosted Sepia Crystal Edge
                      Color(0xEE2A1E14),
                      Color(0xEE1E100A), // Smoked Glass Center
                      Color(0xEE3E2B1D),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFD4AF37),
                    width: 3.5,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black87,
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      // Inner Bevel Facet Glass Line
                      Container(
                        margin: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xDDFFF8E1),
                            width: 1.5,
                          ),
                        ),
                      ),

                      // Specular Light Glare Beam Sweep
                      AnimatedBuilder(
                        animation: _glareController,
                        builder: (context, _) {
                          return CustomPaint(
                            size: const Size(172, 172),
                            painter: _CrystalGlarePainter(_glareController.value),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 3. Specular 4-Point Crystal Lens Flare Star at Top-Left Vertex
            Positioned(
              top: 8,
              left: 20,
              child: _buildCrystalStarFlare(size: 34),
            ),

            // 4. Soft Golden Sparkle Star at Bottom-Right Vertex
            Positioned(
              bottom: 12,
              right: 24,
              child: _buildCrystalStarFlare(size: 24, isGold: true),
            ),

            // 5. Unrotated Central Lesson Badge Content (LESSON 1 / 5)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'LESSON',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFD4AF37),
                    letterSpacing: 2.0,
                    shadows: [
                      Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1)),
                    ],
                  ),
                ),
                Text(
                  '$_currentLevelIndex',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 66,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.0,
                    shadows: [
                      Shadow(color: Color(0xFFD4AF37), blurRadius: 20),
                      Shadow(color: Colors.black, blurRadius: 8, offset: Offset(3, 4)),
                    ],
                  ),
                ),
                Text(
                  'OF $_totalLevels',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFD5C4A1),
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Brilliant 4-Point Specular Crystal Lens Flare Star
  Widget _buildCrystalStarFlare({double size = 30, bool isGold = false}) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Radial Glow Aura
          Container(
            width: size * 0.8,
            height: size * 0.8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: isGold
                      ? const Color(0xFFFFD700).withValues(alpha: 0.9)
                      : Colors.white.withValues(alpha: 0.95),
                  blurRadius: 12,
                  spreadRadius: 3,
                ),
              ],
            ),
          ),
          // 4-Point Star Icon
          Icon(
            Icons.auto_awesome,
            size: size,
            color: isGold ? const Color(0xFFFFF8E1) : Colors.white,
          ),
        ],
      ),
    );
  }

  /// Lesson Progress Pill (e.g. LESSON 1 OF 5  •  4 LESSONS LEFT)
  Widget _buildLessonProgressPill(int remainingLessons) {
    final String remainingText = remainingLessons > 0
        ? '$remainingLessons ${remainingLessons == 1 ? "LESSON" : "LESSONS"} REMAINING'
        : 'ALL LESSONS COMPLETED!';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x992E1C12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x88D4AF37), width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Text(
        'LESSON $_currentLevelIndex OF $_totalLevels  •  $remainingText',
        style: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: Color(0xFFFFF8E1),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  /// Segmented Progress Dots (5 nodes)
  Widget _buildSegmentedProgressDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_totalLevels, (index) {
        final bool isDone = index < _currentLevelIndex;
        final bool isCurrent = index == _currentLevelIndex - 1;

        return Container(
          width: isCurrent ? 28 : 12,
          height: 12,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isDone ? const Color(0xFFD4AF37) : Colors.black45,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDone ? const Color(0xFFFFF8E1) : const Color(0xAA8B6914),
              width: 1.5,
            ),
            boxShadow: isDone
                ? const [BoxShadow(color: Color(0xFFD4AF37), blurRadius: 6)]
                : null,
          ),
        );
      }),
    );
  }

  /// Reward Stats Cards List
  Widget _buildRewardStatCards(int remainingLessons) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 360),
      child: Column(
        children: [
          _buildStatRow('Lessons Completed', '$_currentLevelIndex / $_totalLevels', const Color(0xFFFFF8E1)),
          const SizedBox(height: 8),
          _buildStatRow(
            'Remaining Lessons',
            remainingLessons > 0 ? '$remainingLessons More Left' : 'Story Complete! 🎉',
            const Color(0xFFFFF8E1),
          ),
          const SizedBox(height: 8),
          _buildStatRow('Quiz Performance', '$_stars Stars (${widget.totalCorrect}/${widget.totalQuestions})', const Color(0xFFFFCC80)),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xEE2E1C12), // High Contrast Sepia
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onContinue() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final chapters = await ContentDiscoveryService.discoverContent();
      final chapter = chapters.where((c) => c.id == widget.level.chapterId).firstOrNull;

      if (chapter != null && chapter.levels.isNotEmpty) {
        final currentIndex = chapter.levels.indexWhere((l) => l.id == widget.level.id);
        if (currentIndex != -1 && currentIndex + 1 < chapter.levels.length) {
          final nextLevel = chapter.levels[currentIndex + 1];
          if (!mounted) return;
          navigator.pushReplacement(
            MaterialPageRoute(
              builder: (_) => VideoPlayerScreen(
                childId: widget.childId,
                level: nextLevel,
              ),
            ),
          );
          return;
        }
      }
    } catch (e) {
      debugPrint('Error advancing to next level: $e');
    }

    if (!mounted) return;
    messenger.showSnackBar(
      const SnackBar(
        content: Text('🎉 Congratulations! You completed all lessons in this story!'),
        backgroundColor: Color(0xFF8B4513),
      ),
    );

    navigator.popUntil((route) => route.isFirst);
  }
}

/// Custom Painter for continuous specular light glare beam sweep across crystal facet
class _CrystalGlarePainter extends CustomPainter {
  final double progress;

  _CrystalGlarePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final sweepPos = size.width * (progress * 1.8 - 0.4);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: 0.15),
          Colors.white.withValues(alpha: 0.85),
          Colors.white.withValues(alpha: 0.15),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
      ).createShader(Rect.fromLTWH(sweepPos - 40, sweepPos - 40, 80, 80))
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(20),
    );

    canvas.drawRRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _CrystalGlarePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
