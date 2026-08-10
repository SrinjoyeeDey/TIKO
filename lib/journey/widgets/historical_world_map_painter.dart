import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../data/world_map_data.dart';

/// Custom Painter rendering a 16th-century explorer's World Map driven by REAL GEOGRAPHIC DATA (WorldMapData).
/// Strictly renders authentic continental silhouettes, real India peninsula geometry, graticules, compass rose, and Hanko seal.
class HistoricalWorldMapPainter extends CustomPainter {
  final double opacity;
  final bool showGraticules;
  final double indiaHighlightProgress;

  HistoricalWorldMapPainter({
    required this.opacity,
    this.showGraticules = true,
    this.indiaHighlightProgress = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0.001) return;

    final w = size.width;
    final h = size.height;

    canvas.saveLayer(Rect.fromLTWH(0, 0, w, h), Paint()..color = Colors.white.withValues(alpha: opacity));

    // 1. Parchment Base Texture Fill
    final parchmentGradient = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFFAF0DD), // Washi ivory center
          Color(0xFFF3DFB7), // Parchment gold
          Color(0xFFE5CE9F), // Aged paper margin
          Color(0xFFD6BA86), // Vignette edge
        ],
        stops: [0.0, 0.5, 0.82, 1.0],
        begin: Alignment.center,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), parchmentGradient);

    // Soft Vignette Border
    final vignettePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          const Color(0xFF4A3525).withValues(alpha: 0.14),
          const Color(0xFF2C1C0F).withValues(alpha: 0.35),
        ],
        stops: const [0.65, 0.88, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), vignettePaint);

    // Frame Outer Border
    final borderPaint = Paint()
      ..color = const Color(0xFF3E2A1A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    final innerBorderPaint = Paint()
      ..color = const Color(0xFF7A5C38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRect(Rect.fromLTWH(10, 10, w - 20, h - 20), borderPaint);
    canvas.drawRect(Rect.fromLTWH(14, 14, w - 28, h - 28), innerBorderPaint);

    // 2. Graticule Lat/Long Grid
    if (showGraticules) {
      final graticulePaint = Paint()
        ..color = const Color(0xFF8C7355).withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8;

      for (double y = 0.15; y < 0.9; y += 0.12) {
        final line = Path()
          ..moveTo(16, h * y)
          ..quadraticBezierTo(w * 0.5, h * (y - 0.02), w - 16, h * y);
        canvas.drawPath(line, graticulePaint);
      }

      for (double x = 0.12; x < 0.92; x += 0.13) {
        final line = Path()
          ..moveTo(w * x, 16)
          ..quadraticBezierTo(w * (x + (x - 0.5) * 0.14), h * 0.5, w * x, h - 16);
        canvas.drawPath(line, graticulePaint);
      }
    }

    // 3. Render ALL Continents using Real WorldMapData
    final landFill = Paint()
      ..color = const Color(0xFFECE0C8)
      ..style = PaintingStyle.fill;

    final coastlineStroke = Paint()
      ..color = const Color(0xFF3E2A1A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final region in WorldMapData.regions) {
      final path = region.buildPath(size);

      if (region.id == 'india') {
        // Render India specifically with Highlight logic
        _paintIndiaSubcontinent(canvas, size, path, indiaHighlightProgress);
      } else {
        canvas.drawPath(path, landFill);
        canvas.drawPath(path, coastlineStroke);
      }
    }

    // 4. Hanko Red Sun Seal over Japan Origin
    _drawJapaneseHankoSeal(canvas, Offset(w * 0.88, h * 0.36));

    // 5. Compass Rose & Cartographic Labels
    _drawCompassRose(canvas, Offset(w * 0.16, h * 0.72), 34.0);
    _drawOceanLabels(canvas, size);

    canvas.restore();
  }

  void _paintIndiaSubcontinent(
    Canvas canvas,
    Size size,
    Path indiaPath,
    double highlightProgress,
  ) {
    final w = size.width;
    final h = size.height;

    final baseFill = Paint()..color = const Color(0xFFF4E5C9);

    final highlightFill = Paint()
      ..color = Color.lerp(
        const Color(0xFFF4E5C9),
        const Color(0xFFFFD54F),
        highlightProgress,
      )!;

    canvas.drawPath(indiaPath, highlightProgress > 0 ? highlightFill : baseFill);

    final stroke = Paint()
      ..color = const Color(0xFF2C1C0F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawPath(indiaPath, stroke);

    // Glowing Aura & Spotlight when illuminated
    if (highlightProgress > 0.001) {
      // Glow along the exact real boundary path
      final pathGlow = Paint()
        ..color = const Color(0xFFFFD54F).withValues(alpha: 0.7 * highlightProgress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 6);
      canvas.drawPath(indiaPath, pathGlow);

      // Soft Radial Illumination
      final spotlightCenter = Offset(w * 0.65, h * 0.54);
      final radialGlow = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF00E5FF).withValues(alpha: 0.35 * highlightProgress),
            const Color(0xFFFFD54F).withValues(alpha: 0.25 * highlightProgress),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(center: spotlightCenter, radius: w * 0.20));

      canvas.drawCircle(spotlightCenter, w * 0.20, radialGlow);
    }
  }

  void _drawJapaneseHankoSeal(Canvas canvas, Offset center) {
    final sealRect = Rect.fromCenter(center: center, width: 20, height: 20);
    canvas.drawRRect(
      RRect.fromRectAndRadius(sealRect, const Radius.circular(4)),
      Paint()..color = const Color(0xFFD32F2F).withValues(alpha: 0.15),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(sealRect, const Radius.circular(4)),
      Paint()
        ..color = const Color(0xFFD32F2F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawCircle(center, 4, Paint()..color = const Color(0xFFD32F2F));

    _drawText(
      canvas,
      '日',
      center,
      const TextStyle(color: Color(0xFFB71C1C), fontSize: 8, fontWeight: FontWeight.bold),
    );
  }

  void _drawCompassRose(Canvas canvas, Offset center, double radius) {
    final circlePaint = Paint()
      ..color = const Color(0xFF4A3525)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawCircle(center, radius, circlePaint);
    canvas.drawCircle(center, radius * 0.85, circlePaint);

    for (int i = 0; i < 8; i++) {
      final double angle = i * math.pi / 4;
      final double rLong = (i % 2 == 0) ? radius * 0.95 : radius * 0.6;
      final double rShort = radius * 0.2;

      final p1 = Offset(center.dx + rLong * math.cos(angle), center.dy + rLong * math.sin(angle));
      final pLeft = Offset(
        center.dx + rShort * math.cos(angle - math.pi / 2),
        center.dy + rShort * math.sin(angle - math.pi / 2),
      );
      final pRight = Offset(
        center.dx + rShort * math.cos(angle + math.pi / 2),
        center.dy + rShort * math.sin(angle + math.pi / 2),
      );

      final darkWing = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(p1.dx, p1.dy)
        ..lineTo(pLeft.dx, pLeft.dy)
        ..close();

      final lightWing = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(p1.dx, p1.dy)
        ..lineTo(pRight.dx, pRight.dy)
        ..close();

      canvas.drawPath(darkWing, Paint()..color = const Color(0xFF3E2C1C));
      canvas.drawPath(lightWing, Paint()..color = const Color(0xFFC4AD82));
    }
  }

  void _drawOceanLabels(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    const style = TextStyle(
      color: Color(0xFF6B5137),
      fontSize: 10,
      letterSpacing: 3.0,
      fontWeight: FontWeight.w600,
      fontStyle: FontStyle.italic,
      fontFamily: 'Outfit',
    );
    _drawText(canvas, 'O C E A N U S   A T L A N T I C U S', Offset(w * 0.42, h * 0.50), style);
    _drawText(canvas, 'I N D I A N   O C E A N', Offset(w * 0.54, h * 0.84), style);
    _drawText(canvas, 'A S I A', Offset(w * 0.74, h * 0.28), style);
  }

  void _drawText(Canvas canvas, String text, Offset center, TextStyle style) {
    final textSpan = TextSpan(text: text, style: style);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant HistoricalWorldMapPainter oldDelegate) =>
      oldDelegate.opacity != opacity ||
      oldDelegate.showGraticules != showGraticules ||
      oldDelegate.indiaHighlightProgress != indiaHighlightProgress;
}
