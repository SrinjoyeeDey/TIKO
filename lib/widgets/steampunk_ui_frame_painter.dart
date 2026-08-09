import 'package:flutter/material.dart';

class SteampunkUiFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Base Outer Frame (Dark Mahogany Wood & Bronze Rim)
    final outerRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      const Radius.circular(20),
    );

    final innerRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(16, 16, w - 32, h - 32),
      const Radius.circular(14),
    );

    final woodFrameGradient = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF3E230C), Color(0xFF2E1C0C), Color(0xFF1E130B)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawRRect(outerRRect, woodFrameGradient);

    // Inner Dark Canvas Background
    final darkCanvasPaint = Paint()..color = const Color(0xFF120B06);
    canvas.drawRRect(innerRRect, darkCanvasPaint);

    // Metallic Outer Rim Borders
    final metalRimPaint = Paint()
      ..color = const Color(0xFF8D5B2A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawRRect(outerRRect, metalRimPaint);
    canvas.drawRRect(innerRRect, metalRimPaint);

    // 2. Draw 4 Heavy L-Shaped Riveted Bronze Corner Brackets (Exact match to reference screenshot)
    _drawLShapedCornerBracket(canvas, 0, 0, w, h, isTop: true, isLeft: true);
    _drawLShapedCornerBracket(canvas, w, 0, w, h, isTop: true, isLeft: false);
    _drawLShapedCornerBracket(canvas, 0, h, w, h, isTop: false, isLeft: true);
    _drawLShapedCornerBracket(canvas, w, h, w, h, isTop: false, isLeft: false);

    // 3. Draw 4 Intricate Golden Filigree Scrollwork Lace Corners
    _drawGoldenFiligreeLace(canvas, 16, 16, isTop: true, isLeft: true);
    _drawGoldenFiligreeLace(canvas, w - 16, 16, isTop: true, isLeft: false);
    _drawGoldenFiligreeLace(canvas, 16, h - 16, isTop: false, isLeft: true);
    _drawGoldenFiligreeLace(canvas, w - 16, h - 16, isTop: false, isLeft: false);
  }

  // Draw Heavy L-Shaped Bronze Corner Bracket with Metallic Screws & Bevels
  void _drawLShapedCornerBracket(
    Canvas canvas,
    double x,
    double y,
    double totalW,
    double totalH, {
    required bool isTop,
    required bool isLeft,
  }) {
    canvas.save();
    canvas.translate(x, y);

    // Scale direction based on corner
    final sx = isLeft ? 1.0 : -1.0;
    final sy = isTop ? 1.0 : -1.0;
    canvas.scale(sx, sy);

    const bracketW = 75.0;
    const bracketH = 85.0;
    const armThickness = 18.0;

    // Build L-Shaped Bracket Path
    final lPath = Path()
      ..moveTo(0, 0)
      ..lineTo(bracketW, 0)
      ..cubicTo(bracketW - 4, armThickness, bracketW - 10, armThickness, bracketW - 14, armThickness)
      ..lineTo(armThickness, armThickness)
      ..lineTo(armThickness, bracketH - 14)
      ..cubicTo(armThickness, bracketH - 10, armThickness, bracketH - 4, 0, bracketH)
      ..close();

    // Shadow under L-Bracket
    canvas.drawPath(
      lPath.shift(const Offset(2, 3)),
      Paint()
        ..color = Colors.black54
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Metallic Bronze/Copper Gradient Fill
    final bronzeGradient = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFA66E38), Color(0xFF8D5B2A), Color(0xFF5D3A1A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(const Rect.fromLTWH(0, 0, bracketW, bracketH));

    canvas.drawPath(lPath, bronzeGradient);

    // Metallic Bevel Border
    final bevelPaint = Paint()
      ..color = const Color(0xFFD97706)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawPath(lPath, bevelPaint);

    // Chisel Scratch Marks on Bronze Plate
    final scratchPaint = Paint()
      ..color = const Color(0xFF3E230C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawLine(const Offset(28, 4), const Offset(36, 12), scratchPaint);
    canvas.drawLine(const Offset(6, 45), const Offset(12, 54), scratchPaint);

    // Draw 4 Screws along L-Bracket (Vertex, Horizontal Arm, Vertical Leg)
    _drawMetallicScrew(canvas, const Offset(14, 14), size: 7.0); // Large Vertex Screw
    _drawMetallicScrew(canvas, const Offset(52, 9), size: 5.5); // Horizontal Arm Screw
    _drawMetallicScrew(canvas, const Offset(9, 48), size: 5.5); // Vertical Upper Screw
    _drawMetallicScrew(canvas, const Offset(9, 72), size: 5.5); // Vertical Lower Screw

    canvas.restore();
  }

  // Draw Slotted Metallic Screw with Bevel Highlight
  void _drawMetallicScrew(Canvas canvas, Offset center, {double size = 6.0}) {
    final screwFill = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFD6C0A0), Color(0xFF8D6E53), Color(0xFF4A3423)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: center, radius: size));

    final screwBorder = Paint()
      ..color = const Color(0xFF2A1505)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Screw Head
    canvas.drawCircle(center, size, screwFill);
    canvas.drawCircle(center, size, screwBorder);

    // Screw Slotted Groove Line
    final slotPaint = Paint()
      ..color = const Color(0xFF1B0F07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(center.dx - size * 0.6, center.dy - size * 0.6),
      Offset(center.dx + size * 0.6, center.dy + size * 0.6),
      slotPaint,
    );
  }

  // Draw Intricate Antique Golden Filigree Scrollwork Lace under Corner
  void _drawGoldenFiligreeLace(
    Canvas canvas,
    double x,
    double y, {
    required bool isTop,
    required bool isLeft,
  }) {
    canvas.save();
    canvas.translate(x, y);

    final sx = isLeft ? 1.0 : -1.0;
    final sy = isTop ? 1.0 : -1.0;
    canvas.scale(sx, sy);

    final lacePaint = Paint()
      ..color = const Color(0xFFFFD54F) // Radiant Antique Gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final laceGlow = Paint()
      ..color = const Color(0xFFFFF176).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    // Intricate Scrollwork Curlicues Path
    final lacePath = Path()
      ..moveTo(2, 45)
      ..cubicTo(12, 38, 22, 28, 28, 22)
      ..cubicTo(32, 18, 38, 12, 45, 2)
      // Leaf Tip Motif
      ..moveTo(24, 24)
      ..cubicTo(32, 22, 36, 26, 30, 32)
      ..cubicTo(26, 36, 22, 32, 24, 24)
      // Additional Curlicue Loop
      ..moveTo(12, 30)
      ..cubicTo(18, 26, 20, 20, 16, 16)
      ..cubicTo(12, 12, 8, 18, 12, 22);

    canvas.drawPath(lacePath, laceGlow);
    canvas.drawPath(lacePath, lacePaint);

    // Central Leaf Fill Motif
    final leafPath = Path()
      ..moveTo(26, 26)
      ..quadraticBezierTo(34, 22, 32, 30)
      ..quadraticBezierTo(26, 32, 26, 26)
      ..close();

    final leafFill = Paint()..color = const Color(0xFFFFD54F).withValues(alpha: 0.85);
    canvas.drawPath(leafPath, leafFill);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
