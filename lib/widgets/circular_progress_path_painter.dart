import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/story_chapter.dart';

class CircularProgressPathPainter extends CustomPainter {
  final List<StoryChapter> chapters;
  final double radius;
  final Offset center;
  final double animationProgress;

  CircularProgressPathPainter({
    required this.chapters,
    required this.radius,
    required this.center,
    this.animationProgress = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (chapters.isEmpty) return;

    final n = chapters.length;

    // 1. Background Deep Navy Orbit Groove Base
    final bgRingPaint = Paint()
      ..color = const Color(0xFF0F172A).withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0;

    canvas.drawCircle(center, radius, bgRingPaint);

    // Muted Cyan Outer Halo Glow Ring
    final glowRingPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawCircle(center, radius, glowRingPaint);

    // 2. Radial Connector Beams (Center Hub to Nodes)
    for (int i = 0; i < n; i++) {
      final angle = (i * 2 * math.pi / n) - (math.pi / 2);
      final nodeX = center.dx + radius * math.cos(angle);
      final nodeY = center.dy + radius * math.sin(angle);

      final isNodeUnlocked = !chapters[i].isLocked;

      final radialPaint = Paint()
        ..color = isNodeUnlocked
            ? const Color(0xFF00E5FF).withValues(alpha: 0.55 * animationProgress)
            : const Color(0xFF334155).withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isNodeUnlocked ? 3.0 : 1.5;

      if (isNodeUnlocked) {
        // Glowing Muted Cyan & Teal Beam Effect
        final glowSpoke = Paint()
          ..color = const Color(0xFF14B8A6).withValues(alpha: 0.30 * animationProgress)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
        canvas.drawLine(center, Offset(nodeX, nodeY), glowSpoke);
      }

      canvas.drawLine(center, Offset(nodeX, nodeY), radialPaint);
    }

    // 3. Active Glowing Royal Blue & Cyan Progress Arc Along outer Ring
    for (int i = 0; i < n; i++) {
      final nextIdx = (i + 1) % n;
      final angle1 = (i * 2 * math.pi / n) - (math.pi / 2);
      final angle2 = (nextIdx * 2 * math.pi / n) - (math.pi / 2);

      final isPathUnlocked = chapters[i].isCompleted ||
          (chapters[i].isAvailable && chapters[nextIdx].isAvailable);

      if (isPathUnlocked) {
        final arcPath = Path();
        arcPath.addArc(
          Rect.fromCircle(center: center, radius: radius),
          angle1,
          (angle2 > angle1 ? angle2 - angle1 : (2 * math.pi + angle2 - angle1)) *
              animationProgress,
        );

        final activeArcGlow = Paint()
          ..color = const Color(0xFF00E5FF).withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawPath(arcPath, activeArcGlow);

        final activeArcLine = Paint()
          ..color = const Color(0xFF38BDF8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.0
          ..strokeCap = StrokeCap.round;
        canvas.drawPath(arcPath, activeArcLine);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CircularProgressPathPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.chapters != chapters;
  }
}
