import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/story_chapter.dart';
import '../data/babur_story_data.dart';
import '../widgets/story_map_animated_background.dart';
import '../widgets/wooden_back_button.dart';
import '../widgets/steampunk_ui_frame_painter.dart';
import '../widgets/steampunk_chains_painter.dart';
import '../widgets/steampunk_gear_node_widget.dart';
import '../widgets/steampunk_scroll_treasure_node.dart';
import 'chapter_detail_screen.dart';
import 'explore_india_screen.dart';

class StoryMapScreen extends StatefulWidget {
  const StoryMapScreen({super.key});

  @override
  State<StoryMapScreen> createState() => _StoryMapScreenState();
}

class _StoryMapScreenState extends State<StoryMapScreen>
    with SingleTickerProviderStateMixin {
  late List<StoryChapter> _chapters;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _chapters = BaburStoryData.getInitialChapters();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  bool get _isTreasureUnlocked => _chapters.every((c) => c.isCompleted);

  void _safePop() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _onChapterTap(int index) async {
    final chapter = _chapters[index];

    if (chapter.isLocked) {
      final prevTitle = index > 0 ? _chapters[index - 1].title : 'previous step';
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.lock_rounded, color: Color(0xFFFFF176)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Complete "$prevTitle" to unlock Chapter ${chapter.id}!',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF3E2716),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFFFD54F), width: 1.2),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // Navigate to Chapter Detail Screen
    final bool? completed = await Navigator.of(context).push<bool>(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ChapterDetailScreen(chapter: chapter),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );

    if (completed == true) {
      setState(() {
        _chapters[index].status = ChapterStatus.completed;

        // Automatically unlock next chapter if available
        if (index + 1 < _chapters.length) {
          if (_chapters[index + 1].isLocked) {
            _chapters[index + 1].status = ChapterStatus.available;
          }
        }
      });

      if (_isTreasureUnlocked) {
        _showTreasureUnlockedDialog();
      }
    }
  }

  void _onTreasureTap() {
    if (_isTreasureUnlocked) {
      _showTreasureUnlockedDialog();
    } else {
      final completedCount = _chapters.where((c) => c.isCompleted).length;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.stars_rounded, color: Color(0xFFFFF176)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Mystery Crown: $completedCount/9 Chapters Explored. Finish all 9 to open!',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF2C1C0F),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFFFD54F), width: 1.2),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showTreasureUnlockedDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C1C0F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFFFFD54F), width: 2.5),
          ),
          title: Column(
            children: const [
              Icon(Icons.emoji_events_rounded, size: 54, color: Color(0xFFFFF176)),
              SizedBox(height: 12),
              Text(
                'MYSTERY CROWN UNLOCKED!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFFFD54F),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Outfit',
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                BaburStoryData.getTreasureTitle(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFFFF176),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                BaburStoryData.getTreasureDescription(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFF3E5AB),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8D5B2A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  side: const BorderSide(color: Color(0xFFFFD54F), width: 1.5),
                ),
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
                child: const Text(
                  'CLAIM CROWN',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StoryMapAnimatedBackground(
        child: FadeTransition(
          opacity: _fadeController,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Stack(
                children: [
                  // 1. Heavy Riveted Bronze Outer UI Frame
                  Positioned.fill(
                    child: CustomPaint(
                      painter: SteampunkUiFramePainter(),
                    ),
                  ),

                  // Content Stack
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Top Header Panel: Warm Bronze Metal Bar
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3D2716),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF8D5B2A), width: 2),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black45,
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Left Back Button (Safe pop)
                              WoodenBackButton(
                                size: 42,
                                onTap: _safePop,
                              ),
                              const SizedBox(width: 12),

                              // Header Title & Subtext
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'UNLEASH YOUR POTENTIAL',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.6,
                                        fontFamily: 'Outfit',
                                        color: Color(0xFFFFF176),
                                        shadows: [
                                          Shadow(color: Colors.black, offset: Offset(1, 1)),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Are you ready to unlock your true self?',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFF3E5AB),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Exact Rolled Parchment Counter Badge from Reference Image (e.g. "0/9")
                              _RolledParchmentCounterBadge(
                                text: '${_chapters.where((c) => c.isCompleted).length}/9',
                              ),

                              const SizedBox(width: 8),

                              // EXPLORE INDIA Button
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation, _) =>
                                          const ExploreIndiaScreen(),
                                      transitionsBuilder:
                                          (context, animation, _, child) =>
                                              FadeTransition(
                                                  opacity: animation, child: child),
                                      transitionDuration:
                                          const Duration(milliseconds: 350),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFD4A843), Color(0xFF8B6914)],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: const Color(0xFFFFF176), width: 1.5),
                                    boxShadow: const [
                                      BoxShadow(
                                          color: Colors.black38,
                                          blurRadius: 4,
                                          offset: Offset(0, 2))
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.map_rounded,
                                          size: 14, color: Color(0xFF2C1C0F)),
                                      SizedBox(width: 5),
                                      Text(
                                        'EXPLORE\nINDIA',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.8,
                                          color: Color(0xFF2C1C0F),
                                          height: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Main Circular Level-Progression Wheel Area
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final w = constraints.maxWidth;
                              final h = constraints.maxHeight;
                              final center = Offset(w / 2, h / 2);
                              final radius = math.min(w, h) * 0.36;

                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  // 1. Interlocking Iron Chains (Perimeter & Radial Spokes)
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: SteampunkChainsPainter(
                                        chapters: _chapters,
                                        radius: radius,
                                        center: center,
                                      ),
                                    ),
                                  ),

                                  // 2. Central Mystery Crown Parchment Scroll Popup
                                  Positioned(
                                    left: center.dx - 105,
                                    top: center.dy - 90,
                                    child: SteampunkScrollTreasureNode(
                                      isUnlocked: _isTreasureUnlocked,
                                      onTap: _onTreasureTap,
                                    ),
                                  ),

                                  // 3. 9 Outer Metallic Steampunk Gear Nodes
                                  ...List.generate(_chapters.length, (index) {
                                    final angle =
                                        (index * 2 * math.pi / _chapters.length) - (math.pi / 2);
                                    final nodeX = center.dx + radius * math.cos(angle);
                                    final nodeY = center.dy + radius * math.sin(angle);

                                    return Positioned(
                                      left: nodeX - 45,
                                      top: nodeY - 45,
                                      child: SizedBox(
                                        width: 90,
                                        child: SteampunkGearNodeWidget(
                                          chapter: _chapters[index],
                                          onTap: () => _onChapterTap(index),
                                          size: 78.0,
                                        ),
                                      ),
                                    );
                                  }),
                                ],
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
      ),
    );
  }
}

// Rolled Parchment Scroll Counter Badge Widget (Exact match to reference screenshot)
class _RolledParchmentCounterBadge extends StatelessWidget {
  final String text;

  const _RolledParchmentCounterBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(76, 44),
            painter: _RolledParchmentPainter(),
          ),
          // Inner Cutout Window Text: e.g. "0/9"
          Positioned(
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF3E2716),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFF5D4037), width: 1.2),
              ),
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Outfit',
                  color: Color(0xFFFFF176),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RolledParchmentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Rolled Scroll Cylinder on Left Edge
    final cylinderPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, 16, h),
        const Radius.circular(8),
      ));

    final cylinderGradient = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFE8D3A7), Color(0xFFF9ECC9), Color(0xFFCBB285)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, 16, h));

    canvas.drawPath(cylinderPath, cylinderGradient);
    canvas.drawPath(
      cylinderPath,
      Paint()
        ..color = const Color(0xFF5D4037)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Bottom Cylinder Spiral Accent
    canvas.drawCircle(Offset(8, h - 6), 4, Paint()..color = const Color(0xFF8D5B2A));

    // 2. Main Parchment Sheet Body
    final sheetPath = Path()
      ..moveTo(16, 4)
      ..lineTo(w - 4, 4)
      ..lineTo(w, 8)
      ..lineTo(w - 2, h / 2)
      ..lineTo(w, h - 8)
      ..lineTo(w - 4, h - 4)
      ..lineTo(16, h - 4)
      ..close();

    final sheetGradient = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFF9ECC9), Color(0xFFE8D3A7)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(16, 0, w - 16, h));

    canvas.drawPath(sheetPath, sheetGradient);
    canvas.drawPath(
      sheetPath,
      Paint()
        ..color = const Color(0xFF5D4037)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
