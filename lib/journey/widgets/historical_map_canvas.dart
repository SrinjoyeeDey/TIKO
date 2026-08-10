import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Renders a hand-illustrated 16th-century explorer's parchment map with Japanese Sumi-e ink styling.
/// Features Japanese archipelago cartography, vermilion Hanko red sun origin seal,
/// graticules, compass rose, and detailed Asian landmasses.
class HistoricalMapCanvas extends StatelessWidget {
  final double mapOpacity;
  final bool showGraticules;

  const HistoricalMapCanvas({
    super.key,
    this.mapOpacity = 1.0,
    this.showGraticules = true,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _HistoricalMapPainter(
        opacity: mapOpacity,
        showGraticules: showGraticules,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _HistoricalMapPainter extends CustomPainter {
  final double opacity;
  final bool showGraticules;

  _HistoricalMapPainter({
    required this.opacity,
    required this.showGraticules,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0.001) return;

    final w = size.width;
    final h = size.height;

    canvas.saveLayer(Rect.fromLTWH(0, 0, w, h), Paint()..color = Colors.white.withValues(alpha: opacity));

    // 1. Washi Parchment Material Background Base
    final parchmentGradient = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFF9EEDC), // Warm Washi ivory center
          Color(0xFFF0DFB6), // Warm parchment
          Color(0xFFE4CF9E), // Aged paper margin
          Color(0xFFD4B882), // Vignette edge
        ],
        stops: [0.0, 0.5, 0.82, 1.0],
        begin: Alignment.center,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), parchmentGradient);

    // Washi paper fiber texture spots
    final fiberPaint = Paint()
      ..color = const Color(0xFF7A5C38).withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.22, h * 0.28), w * 0.20, fiberPaint);
    canvas.drawCircle(Offset(w * 0.78, h * 0.68), w * 0.25, fiberPaint);

    // Vignette Shadow border
    final vignettePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          const Color(0xFF4A3525).withValues(alpha: 0.12),
          const Color(0xFF2C1C0F).withValues(alpha: 0.32),
        ],
        stops: const [0.65, 0.88, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), vignettePaint);

    // Cartographic Frame Border
    final borderPaint = Paint()
      ..color = const Color(0xFF3E2C1C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final innerBorderPaint = Paint()
      ..color = const Color(0xFF7A5C38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRect(Rect.fromLTWH(12, 12, w - 24, h - 24), borderPaint);
    canvas.drawRect(Rect.fromLTWH(16, 16, w - 32, h - 32), innerBorderPaint);

    // 2. Graticule Lat/Long Lines
    if (showGraticules) {
      final graticulePaint = Paint()
        ..color = const Color(0xFF8C7355).withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8;

      for (double y = 0.15; y < 0.9; y += 0.12) {
        final Path line = Path()
          ..moveTo(20, h * y)
          ..quadraticBezierTo(w * 0.5, h * (y - 0.02), w - 20, h * y);
        canvas.drawPath(line, graticulePaint);
      }

      for (double x = 0.15; x < 0.9; x += 0.15) {
        final Path line = Path()
          ..moveTo(w * x, 20)
          ..quadraticBezierTo(w * (x + (x - 0.5) * 0.15), h * 0.5, w * x, h - 20);
        canvas.drawPath(line, graticulePaint);
      }
    }

    // 3. Sumi-e Ink Cartographic Landmasses (Asia, India & Japan Archipelago)
    _drawLandmassesWithJapan(canvas, size);

    // 4. Japanese Hanko Red Sun Origin Seal Stamp over Japan
    _drawJapaneseHankoSeal(canvas, Offset(w * 0.86, h * 0.38));

    // 5. Compass Rose (West Sea)
    _drawCompassRose(canvas, Offset(w * 0.18, h * 0.28), 36.0);

    // 6. Calligraphy Labels
    _drawLabels(canvas, size);

    canvas.restore();
  }

  void _drawLandmassesWithJapan(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final landFill = Paint()
      ..color = const Color(0xFFECE0C8)
      ..style = PaintingStyle.fill;

    // Sumi-e Ink brush coastline stroke
    final sumiInkStroke = Paint()
      ..color = const Color(0xFF2C2219)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final waterShading = Paint()
      ..color = const Color(0xFF7A6044).withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // --- EURASIA & MAINLAND ASIA ---
    final eurasiaPath = Path()
      ..moveTo(w * 0.28, h * 0.20)
      ..cubicTo(w * 0.45, h * 0.18, w * 0.68, h * 0.22, w * 0.82, h * 0.26)
      ..cubicTo(w * 0.85, h * 0.38, w * 0.78, h * 0.52, w * 0.74, h * 0.56) // China/East Asia coast
      ..cubicTo(w * 0.68, h * 0.50, w * 0.62, h * 0.45, w * 0.56, h * 0.40)
      ..cubicTo(w * 0.46, h * 0.38, w * 0.36, h * 0.36, w * 0.28, h * 0.20)
      ..close();

    canvas.drawPath(eurasiaPath, landFill);
    canvas.drawPath(eurasiaPath, sumiInkStroke);

    // --- INDIAN SUBCONTINENT ---
    final indiaPath = Path()
      ..moveTo(w * 0.50, h * 0.40)
      ..cubicTo(w * 0.55, h * 0.38, w * 0.65, h * 0.39, w * 0.71, h * 0.42) // Himalayas
      ..cubicTo(w * 0.73, h * 0.45, w * 0.75, h * 0.49, w * 0.72, h * 0.52) // Calcutta / Bengal
      ..cubicTo(w * 0.68, h * 0.60, w * 0.64, h * 0.72, w * 0.61, h * 0.78) // Coromandel
      ..cubicTo(w * 0.59, h * 0.76, w * 0.54, h * 0.64, w * 0.51, h * 0.55) // Malabar
      ..cubicTo(w * 0.47, h * 0.50, w * 0.48, h * 0.44, w * 0.50, h * 0.40)
      ..close();

    final indiaLandPaint = Paint()..color = const Color(0xFFF2E6CD);
    canvas.drawPath(indiaPath, indiaLandPaint);
    canvas.drawPath(indiaPath, sumiInkStroke);
    canvas.drawPath(indiaPath, waterShading);

    // --- JAPANESE ARCHIPELAGO (NIPPON) ---
    // Honshu Island (Main curve)
    final honshuPath = Path()
      ..moveTo(w * 0.83, h * 0.43)
      ..cubicTo(w * 0.85, h * 0.39, w * 0.88, h * 0.35, w * 0.90, h * 0.34)
      ..cubicTo(w * 0.91, h * 0.36, w * 0.88, h * 0.42, w * 0.85, h * 0.46)
      ..close();

    // Hokkaido Island (North)
    final hokkaidoPath = Path()
      ..addOval(Rect.fromCenter(
        center: Offset(w * 0.91, h * 0.31),
        width: 14,
        height: 12,
      ));

    // Kyushu & Shikoku (Southwest)
    final kyushuPath = Path()
      ..addOval(Rect.fromCenter(
        center: Offset(w * 0.82, h * 0.47),
        width: 10,
        height: 8,
      ));

    final japanLandPaint = Paint()..color = const Color(0xFFF9EEDC);
    final japanStroke = Paint()
      ..color = const Color(0xFF1E1610)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawPath(honshuPath, japanLandPaint);
    canvas.drawPath(honshuPath, japanStroke);
    canvas.drawPath(hokkaidoPath, japanLandPaint);
    canvas.drawPath(hokkaidoPath, japanStroke);
    canvas.drawPath(kyushuPath, japanLandPaint);
    canvas.drawPath(kyushuPath, japanStroke);

    // Himalayas Hatching
    final mountainPaint = Paint()
      ..color = const Color(0xFF5D4037)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (double i = 0.54; i <= 0.68; i += 0.028) {
      final mx = w * i;
      final my = h * 0.40 - math.sin((i - 0.54) * 15) * 6;
      final peak = Path()
        ..moveTo(mx - 5, my + 6)
        ..lineTo(mx, my)
        ..lineTo(mx + 5, my + 6);
      canvas.drawPath(peak, mountainPaint);
    }
  }

  void _drawJapaneseHankoSeal(Canvas canvas, Offset center) {
    // Red Sun / Hanko Vermilion Stamp (Traditional Japanese Origin Seal)
    final sealPaint = Paint()
      ..color = const Color(0xFFD32F2F).withValues(alpha: 0.85) // Cinnabar vermilion red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final sealFill = Paint()
      ..color = const Color(0xFFD32F2F).withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    final sealRect = Rect.fromCenter(center: center, width: 22, height: 22);

    canvas.drawRRect(RRect.fromRectAndRadius(sealRect, const Radius.circular(4)), sealFill);
    canvas.drawRRect(RRect.fromRectAndRadius(sealRect, const Radius.circular(4)), sealPaint);

    // Inner Red Sun Circle Accent
    canvas.drawCircle(center, 5, Paint()..color = const Color(0xFFD32F2F).withValues(alpha: 0.7));

    // Calligraphy character stamp indicator
    const style = TextStyle(
      color: Color(0xFFB71C1C),
      fontSize: 8,
      fontWeight: FontWeight.w900,
      fontFamily: 'Outfit',
    );
    _drawText(canvas, '日', center, style);
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

    canvas.drawCircle(center, 3, Paint()..color = const Color(0xFFFFC107));
  }

  void _drawLabels(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Japan Origin Label
    const japanStyle = TextStyle(
      color: Color(0xFF8C2D19),
      fontSize: 10,
      letterSpacing: 2.0,
      fontWeight: FontWeight.w900,
      fontFamily: 'Outfit',
    );
    _drawText(canvas, 'NIPPON 🇯🇵', Offset(w * 0.86, h * 0.44), japanStyle);

    // Ocean Label
    const oceanStyle = TextStyle(
      color: Color(0xFF6B5137),
      fontSize: 11,
      letterSpacing: 3.5,
      fontWeight: FontWeight.w600,
      fontStyle: FontStyle.italic,
      fontFamily: 'Outfit',
    );
    _drawText(canvas, 'O C E A N U S   I N D I C U S', Offset(w * 0.45, h * 0.85), oceanStyle);
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
  bool shouldRepaint(covariant _HistoricalMapPainter oldDelegate) =>
      oldDelegate.opacity != opacity || oldDelegate.showGraticules != showGraticules;
}
