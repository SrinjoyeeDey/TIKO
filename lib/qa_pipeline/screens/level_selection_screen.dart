import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../../widgets/wooden_back_button.dart';
import '../../widgets/game_textured_text.dart';
import '../database/progress_repository.dart';
import '../models/learning_content.dart';
import '../models/level_progress.dart';
import 'video_player_screen.dart';

class LevelSelectionScreen extends StatefulWidget {
  final String childId;
  final LearningChapter chapter;

  const LevelSelectionScreen({
    super.key,
    required this.childId,
    required this.chapter,
  });

  @override
  State<LevelSelectionScreen> createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen> {
  Map<String, LevelProgress> _progressMap = {};
  bool _isLoading = true;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _loadProgress();
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    final allProgress = await ProgressRepository.getAllProgress(widget.childId);
    final map = <String, LevelProgress>{};
    for (final p in allProgress) {
      if (p.chapterId == widget.chapter.id) {
        map[p.levelId] = p;
      }
    }
    if (mounted) {
      setState(() {
        _progressMap = map;
        _isLoading = false;
      });
      // Try to scroll to the highest accessible level
      WidgetsBinding.instance.addPostFrameCallback((_) {
         _scrollToHighestLevel();
      });
    }
  }

  int get _highestAccessibleLevelIndex {
    for (int i = 0; i < widget.chapter.levels.length; i++) {
      final level = widget.chapter.levels[i];
      final progress = _progressMap[level.id];
      if (progress == null || !progress.completed) {
        return i; 
      }
    }
    return widget.chapter.levels.length - 1; 
  }
  
  void _scrollToHighestLevel() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final index = _highestAccessibleLevelIndex;
    final count = widget.chapter.levels.length;
    
    // Total height approx calculation. The scroll max extent represents the top of the map.
    // The highest level index starts from 0 (bottom).
    // The higher the index, the closer to the top of the map (scroll offset 0).
    final double fraction = index / (count > 1 ? count - 1 : 1);
    final targetOffset = maxScroll * (1.0 - fraction);
    
    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
    );
  }
  
  void _onLevelTap(LearningLevel level, int index, bool isLocked) {
    if (isLocked) return;
    
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => VideoPlayerScreen(
          childId: widget.childId,
          level: level,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ).then((_) {
      _loadProgress();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC5AE79), // Vintage paper color
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B6914)))
        : LayoutBuilder(
          builder: (context, constraints) {
            final count = widget.chapter.levels.length;
            final verticalSpacing = 140.0;
            final mapHeight = (count * verticalSpacing) + 200.0;
            final totalHeight = mapHeight < constraints.maxHeight ? constraints.maxHeight : mapHeight;
            
            // Generate node positions (bottom to top)
            List<Offset> nodePositions = [];
            final startY = totalHeight - 120.0;
            
            for (int i = 0; i < count; i++) {
              int mod = i % 4;
              double xFrac = 0.5;
              if (mod == 1) xFrac = 0.25;
              if (mod == 3) xFrac = 0.75;
              
              // Organic wiggle
              if (i % 2 == 0 && i != 0) xFrac += (i % 3 == 0 ? 0.08 : -0.08);
              
              nodePositions.add(Offset(constraints.maxWidth * xFrac, startY - (i * verticalSpacing)));
            }

            return Stack(
              children: [
                // 1. Scrollable Map View
                SingleChildScrollView(
                  controller: _scrollController,
                  child: SizedBox(
                    width: constraints.maxWidth,
                    height: totalHeight,
                    child: Stack(
                      children: [
                        // Vintage Background Texture
                        Positioned.fill(
                          child: Opacity(
                            opacity: 0.85,
                            child: Image.asset(
                              'assets/images/story_selection_wb_bg.png',
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => Image.asset(
                                'assets/images/nimo_japanese_bg_clean.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        
                        // Path Painter
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _MapPathPainter(positions: nodePositions),
                          ),
                        ),
                        
                        // Nodes
                        ...List.generate(count, (index) {
                          final level = widget.chapter.levels[index];
                          final pos = nodePositions[index];
                          final progress = _progressMap[level.id];
                          final isLocked = index > _highestAccessibleLevelIndex;
                          final isChallenge = (index + 1) % 5 == 0; // Every 5th level is a challenge node
                          
                          int stars = 0;
                          if (progress != null && progress.completed) {
                            stars = progress.stars > 0 ? progress.stars : 3;
                          }

                          return Positioned(
                            left: pos.dx - 45, // Center align (width 90)
                            top: pos.dy - 45,
                            child: _MapNodeWidget(
                              index: index,
                              level: level,
                              isLocked: isLocked,
                              isChallenge: isChallenge,
                              stars: stars,
                              onTap: () => _onLevelTap(level, index, isLocked),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                
                // 2. Top UI (Back button and Title overlay)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 12,
                      left: 16,
                      right: 16,
                      bottom: 16,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.6),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        WoodenBackButton(
                          onTap: () => Navigator.of(context).pop(),
                        ),
                        Expanded(
                          child: Center(
                            child: GameTexturedText(
                              text: widget.chapter.name.toUpperCase(),
                              fontSize: 26,
                            ),
                          ),
                        ),
                        const SizedBox(width: 52), // Balance spacing
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
    );
  }
}

class _MapNodeWidget extends StatelessWidget {
  final int index;
  final LearningLevel level;
  final bool isLocked;
  final bool isChallenge;
  final int stars;
  final VoidCallback onTap;

  const _MapNodeWidget({
    required this.index,
    required this.level,
    required this.isLocked,
    required this.isChallenge,
    required this.stars,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Challenge nodes are larger
    final double size = isChallenge ? 85.0 : 65.0;
    
    // Border colors based on state
    final Color borderColor = isLocked 
        ? const Color(0xFF6B6B6B) 
        : const Color(0xFFD4AF37); // Gold
        
    final Color bgColor = isLocked 
        ? const Color(0xFF333333)
        : (isChallenge ? const Color(0xFF8B1C1C) : const Color(0xFF234B23)); // Dark Red vs Dark Green

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Node Circle
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: bgColor,
                  border: Border.all(color: borderColor, width: 3.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                    if (!isLocked)
                      BoxShadow(
                        color: borderColor.withValues(alpha: 0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                  ],
                ),
                alignment: Alignment.center,
                child: isLocked
                    ? const Icon(Icons.lock_rounded, color: Colors.white60, size: 28)
                    : Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          shadows: [
                            Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(1, 2)),
                          ],
                        ),
                      ),
              ),
              
              // Decorative ribbon for challenge nodes
              if (isChallenge && !isLocked)
                Positioned(
                  bottom: -8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B1C1C),
                      border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'CHALLENGE',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 10),
          
          // Star rating: placed on a dark badge so it remains legible over the
          // detailed map artwork.
          if (!isLocked)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF1B120C).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.75),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  final earned = i < stars;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Icon(
                      earned ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: earned
                          ? const Color(0xFFFFD700)
                          : const Color(0xFFFFE6A3).withValues(alpha: 0.55),
                      size: 18,
                      shadows: const [
                        Shadow(
                          color: Colors.black87,
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

class _MapPathPainter extends CustomPainter {
  final List<Offset> positions;

  _MapPathPainter({required this.positions});

  @override
  void paint(Canvas canvas, Size size) {
    if (positions.length < 2) return;

    final paint = Paint()
      ..color = const Color(0xCCFFFFFF) // Semi-transparent white
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(positions[0].dx, positions[0].dy);

    for (int i = 0; i < positions.length - 1; i++) {
      final p1 = positions[i];
      final p2 = positions[i + 1];

      // Control points for a cubic bezier (smooth curves)
      // Since it's vertical, we pull the control points horizontally and vertically
      final dx = (p2.dx - p1.dx).abs();
      final dy = (p1.dy - p2.dy).abs();
      
      final cp1 = Offset(p1.dx, p1.dy - (dy * 0.4));
      final cp2 = Offset(p2.dx, p2.dy + (dy * 0.4));

      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
    }

    // Draw dashed path
    _drawDashedPath(canvas, path, paint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    for (ui.PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double dashLen = 8.0;
        final double gapLen = 8.0;
        final extractPath = metric.extractPath(distance, distance + dashLen);
        canvas.drawPath(extractPath, paint);
        distance += dashLen + gapLen;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
