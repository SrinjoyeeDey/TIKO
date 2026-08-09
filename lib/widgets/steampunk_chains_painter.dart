import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/story_chapter.dart';

class SteampunkChainsPainter extends CustomPainter {
  final List<StoryChapter> chapters;
  final double radius;
  final Offset center;
  final double animationProgress;

  SteampunkChainsPainter({
    required this.chapters,
    required this.radius,
    required this.center,
    this.animationProgress = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (chapters.isEmpty) return;

    final n = chapters.length;

    // 1. Draw 9 Radial Iron Chains Connecting Center Scroll to Outer Nodes
    for (int i = 0; i < n; i++) {
      final angle = (i * 2 * math.pi / n) - (math.pi / 2);
      final nodeX = center.dx + radius * math.cos(angle);
      final nodeY = center.dy + radius * math.sin(angle);

      final isUnlocked = !chapters[i].isLocked;
      _drawRealisticIronChainPath(
        canvas,
        center,
        Offset(nodeX, nodeY),
        isUnlocked: isUnlocked,
      );
    }

    // 2. Draw Outer Circular Iron Chain Links Connecting Perimeter Nodes
    for (int i = 0; i < n; i++) {
      final nextIdx = (i + 1) % n;
      final angle1 = (i * 2 * math.pi / n) - (math.pi / 2);
      final angle2 = (nextIdx * 2 * math.pi / n) - (math.pi / 2);

      final p1 = Offset(
        center.dx + radius * math.cos(angle1),
        center.dy + radius * math.sin(angle1),
      );
      final p2 = Offset(
        center.dx + radius * math.cos(angle2),
        center.dy + radius * math.sin(angle2),
      );

      final isPathUnlocked = chapters[i].isCompleted ||
          (chapters[i].isAvailable && chapters[nextIdx].isAvailable);

      _drawRealisticIronChainPath(canvas, p1, p2, isUnlocked: isPathUnlocked);
    }
  }

  // Draw realistic 3D iron chain links between start and end point
  void _drawRealisticIronChainPath(
    Canvas canvas,
    Offset start,
    Offset end, {
    required bool isUnlocked,
  }) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist < 10) return;

    final angle = math.atan2(dy, dx);
    const linkLength = 12.0;
    final numLinks = (dist / linkLength).floor();

    final darkIronPaint = Paint()
      ..color = isUnlocked ? const Color(0xFF6B4210) : const Color(0xFF2A1F18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;

    final highlightPaint = Paint()
      ..color = isUnlocked ? const Color(0xFFFFD54F) : const Color(0xFF5D483A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    if (isUnlocked) {
      // Glow effect for unlocked chains
      final glowPaint = Paint()
        ..color = const Color(0xFFFFB300).withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawLine(start, end, glowPaint);
    }

    for (int i = 0; i < numLinks; i++) {
      final t = (i + 0.5) / numLinks;
      final cx = start.dx + dx * t;
      final cy = start.dy + dy * t;

      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(angle + (i % 2 == 0 ? 0 : math.pi / 2));

      final rect = RRect.fromRectAndRadius(
        const Rect.fromLTWH(-5, -3, 10, 6),
        const Radius.circular(3),
      );

      // Link Drop Shadow
      canvas.drawRRect(rect.shift(const Offset(0, 1.5)), Paint()..color = Colors.black38);
      canvas.drawRRect(rect, darkIronPaint);
      canvas.drawRRect(rect, highlightPaint);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant SteampunkChainsPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.chapters != chapters;
  }
}
