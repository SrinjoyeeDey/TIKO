import 'package:flutter/material.dart';

class RopePainter extends CustomPainter {
  final List<Offset> topPoints;
  final List<Offset> bottomPoints;
  final double swingAngle;
  final Color ropeColor;

  RopePainter({
    required this.topPoints,
    required this.bottomPoints,
    this.swingAngle = 0.0,
    this.ropeColor = const Color(0xFFC67D33),
  });

  @override
  void paint(Canvas canvas, Size size) {
    assert(topPoints.length == bottomPoints.length);

    final ropePaint = Paint()
      ..color = ropeColor
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final ropeShadowPaint = Paint()
      ..color = Colors.black38
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final knotPaint = Paint()
      ..color = const Color(0xFF8B4513)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < topPoints.length; i++) {
      final start = topPoints[i];
      final end = bottomPoints[i];

      final midX = (start.dx + end.dx) / 2 + (swingAngle * 15);
      final midY = (start.dy + end.dy) / 2;

      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(midX, midY, end.dx, end.dy);

      // Draw shadow first
      canvas.drawPath(path.shift(const Offset(2, 3)), ropeShadowPaint);

      // Draw main rope
      canvas.drawPath(path, ropePaint);

      // Draw knots at joints
      canvas.drawCircle(start, 4.5, knotPaint);
      canvas.drawCircle(end, 4.5, knotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant RopePainter oldDelegate) {
    return oldDelegate.swingAngle != swingAngle ||
        oldDelegate.topPoints != topPoints ||
        oldDelegate.bottomPoints != bottomPoints;
  }
}
