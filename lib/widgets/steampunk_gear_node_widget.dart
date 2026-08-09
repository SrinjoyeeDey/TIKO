import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/story_chapter.dart';

class SteampunkGearNodeWidget extends StatefulWidget {
  final StoryChapter chapter;
  final VoidCallback onTap;
  final double size;

  const SteampunkGearNodeWidget({
    super.key,
    required this.chapter,
    required this.onTap,
    this.size = 78.0,
  });

  @override
  State<SteampunkGearNodeWidget> createState() => _SteampunkGearNodeWidgetState();
}

class _SteampunkGearNodeWidgetState extends State<SteampunkGearNodeWidget> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final chapter = widget.chapter;
    final isCompleted = chapter.isCompleted;
    final isAvailable = chapter.isAvailable;
    final isUnlocked = isAvailable || isCompleted;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.88 : (_isHovered ? 1.10 : 1.0),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Metallic Gear Node Container
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: widget.size,
                height: widget.size,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Custom Metallic Gear Painter with Smooth Hover Glow
                    CustomPaint(
                      size: Size(widget.size, widget.size),
                      painter: _MetallicGearPainter(
                        isUnlocked: isUnlocked,
                        isHovered: _isHovered,
                      ),
                    ),

                    // Icon (Castle/Fortress for Unlocked, Lock for Locked)
                    Icon(
                      isUnlocked ? Icons.fort_rounded : Icons.lock_rounded,
                      size: isUnlocked ? 32 : 28,
                      color: isUnlocked
                          ? (_isHovered ? const Color(0xFF8D5B2A) : const Color(0xFF6B4210))
                          : const Color(0xFF1E130B),
                    ),

                    // Top-Right Gear Badge Number (e.g. 1, 2, 3...)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isUnlocked ? const Color(0xFFD97706) : const Color(0xFF4A3B32),
                          border: Border.all(
                            color: _isHovered
                                ? const Color(0xFFFFFDE7)
                                : (isUnlocked ? const Color(0xFFFFF176) : const Color(0xFF1E130B)),
                            width: 1.5,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black45,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '${chapter.id}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 4),

              // Realistic Aged Parchment Banner Badge Below Node
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFF9ECC9), // Parchment ivory top
                      Color(0xFFE8D3A7), // Aged paper bottom
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: _isHovered ? const Color(0xFFFFD54F) : const Color(0xFF5D4037),
                    width: _isHovered ? 2.0 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _isHovered
                          ? const Color(0xFFFFD54F).withValues(alpha: 0.4)
                          : Colors.black45,
                      blurRadius: _isHovered ? 8 : 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  chapter.title.length > 10
                      ? '${chapter.title.substring(0, 9)}...'
                      : chapter.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Outfit',
                    color: _isHovered
                        ? const Color(0xFF78350F)
                        : const Color(0xFF2C1C0F), // Dark vintage ink
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom Metallic Gear Painter (Teeth along perimeter + Bevel + Smooth Glow)
class _MetallicGearPainter extends CustomPainter {
  final bool isUnlocked;
  final bool isHovered;

  _MetallicGearPainter({
    required this.isUnlocked,
    required this.isHovered,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final outerR = w / 2 - 2;
    final innerR = outerR - 9;
    final holeR = innerR - 8;

    const numTeeth = 8;

    // 1. Smooth Glow for Unlocked / Hovered Warm Gold Gear
    if (isUnlocked || isHovered) {
      final glowPaint = Paint()
        ..color = (isUnlocked ? const Color(0xFFFFB300) : const Color(0xFFD97706))
            .withValues(alpha: isHovered ? 0.65 : 0.45)
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, isHovered ? 14 : 10);
      canvas.drawCircle(center, outerR, glowPaint);
    }

    // 2. Build Gear Path with Teeth
    final gearPath = Path();
    for (int i = 0; i < numTeeth; i++) {
      final angleStart = (i * 2 * math.pi / numTeeth);
      final angleMid1 = angleStart + (math.pi / (numTeeth * 3));
      final angleMid2 = angleStart + (2 * math.pi / (numTeeth * 3));
      final angleEnd = angleStart + (2 * math.pi / numTeeth);

      final p1 = Offset(center.dx + innerR * math.cos(angleStart), center.dy + innerR * math.sin(angleStart));
      final p2 = Offset(center.dx + outerR * math.cos(angleMid1), center.dy + outerR * math.sin(angleMid1));
      final p3 = Offset(center.dx + outerR * math.cos(angleMid2), center.dy + outerR * math.sin(angleMid2));
      final p4 = Offset(center.dx + innerR * math.cos(angleEnd), center.dy + innerR * math.sin(angleEnd));

      if (i == 0) {
        gearPath.moveTo(p1.dx, p1.dy);
      } else {
        gearPath.lineTo(p1.dx, p1.dy);
      }
      gearPath.lineTo(p2.dx, p2.dy);
      gearPath.lineTo(p3.dx, p3.dy);
      gearPath.lineTo(p4.dx, p4.dy);
    }
    gearPath.close();

    // Shadow
    canvas.drawPath(
      gearPath.shift(const Offset(0, 3)),
      Paint()..color = Colors.black45,
    );

    // Gear Base Fill
    final gearGradient = Paint()
      ..shader = (isUnlocked
          ? const LinearGradient(
              colors: [Color(0xFFFFF176), Color(0xFFFFB300), Color(0xFFD97706)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : const LinearGradient(
              colors: [Color(0xFF6E5646), Color(0xFF4A3B32), Color(0xFF2A1F18)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(gearPath, gearGradient);

    // Bevel Dark Border
    final borderPaint = Paint()
      ..color = isUnlocked ? const Color(0xFF78350F) : const Color(0xFF1E130B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawPath(gearPath, borderPaint);

    // Center Inner Ring Hole Fill
    final innerHolePaint = Paint()
      ..shader = (isUnlocked
          ? const LinearGradient(
              colors: [Color(0xFFFFE082), Color(0xFFFFB300)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            )
          : const LinearGradient(
              colors: [Color(0xFF3E2D23), Color(0xFF261910)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            )).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawCircle(center, holeR, innerHolePaint);
    canvas.drawCircle(center, holeR, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _MetallicGearPainter oldDelegate) =>
      oldDelegate.isUnlocked != isUnlocked || oldDelegate.isHovered != isHovered;
}
