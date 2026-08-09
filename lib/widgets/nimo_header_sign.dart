import 'package:flutter/material.dart';

class NimoHeaderSign extends StatelessWidget {
  final double width;
  final double height;

  const NimoHeaderSign({
    super.key,
    this.width = 300,
    this.height = 115,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        size: Size(width, height),
        painter: _OrganicChunkyWoodSignPainter(),
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Dark Chocolate Outline / 3D Shadow for NIMO Text
              Text(
                'NIMO',
                style: TextStyle(
                  fontSize: height * 0.44,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4.5,
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 9.0
                    ..strokeJoin = StrokeJoin.round
                    ..color = const Color(0xFF2D1604),
                ),
              ),

              // 2. Inner Dark Drop Shadow Offset
              Text(
                'NIMO',
                style: TextStyle(
                  fontSize: height * 0.44,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4.5,
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 6.0
                    ..strokeJoin = StrokeJoin.round
                    ..color = const Color(0xFF4A2506),
                ),
              ),

              // 3. Cream / Ivory Bubbly Text Fill with Soft Highlight
              Text(
                'NIMO',
                style: TextStyle(
                  fontSize: height * 0.44,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4.5,
                  color: const Color(0xFFFFF8E1), // Creamy Ivory Fill
                  shadows: const [
                    Shadow(
                      color: Color(0xFFFFD54F),
                      offset: Offset(-1.5, -1.5),
                      blurRadius: 2,
                    ),
                    Shadow(
                      color: Colors.black45,
                      offset: Offset(2, 3),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrganicChunkyWoodSignPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // A. Irregular Organic Hand-Carved Silhouette Path
    final organicPath = Path()
      ..moveTo(w * 0.15, h * 0.12)
      ..cubicTo(w * 0.35, -h * 0.05, w * 0.65, h * 0.02, w * 0.85, h * 0.10) // Top uneven curve
      ..cubicTo(w * 1.02, h * 0.25, w * 0.98, h * 0.75, w * 0.88, h * 0.90) // Right bulging contour
      ..cubicTo(w * 0.68, h * 1.04, w * 0.32, h * 0.96, w * 0.12, h * 0.88) // Bottom irregular curve
      ..cubicTo(-w * 0.02, h * 0.70, w * 0.02, h * 0.28, w * 0.15, h * 0.12) // Left organic curve
      ..close();

    // B. Outer Drop Shadow for 3D Depth
    final shadowPaint = Paint()
      ..color = Colors.black45
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawPath(organicPath.shift(const Offset(3, 8)), shadowPaint);

    // C. Deep Chocolate Wood Bevel Border
    final borderPaint = Paint()
      ..color = const Color(0xFF2D1604)
      ..style = PaintingStyle.fill;
    canvas.drawPath(organicPath, borderPaint);

    // D. Inset Organic Wood Body Path (Layered 3D carved wood surface)
    final insetPath = Path()
      ..moveTo(w * 0.16, h * 0.15)
      ..cubicTo(w * 0.35, h * 0.02, w * 0.65, h * 0.06, w * 0.84, h * 0.13)
      ..cubicTo(w * 0.96, h * 0.27, w * 0.94, h * 0.73, w * 0.85, h * 0.86)
      ..cubicTo(w * 0.66, h * 0.98, w * 0.33, h * 0.92, w * 0.14, h * 0.85)
      ..cubicTo(w * 0.02, h * 0.68, w * 0.04, h * 0.30, w * 0.16, h * 0.15)
      ..close();

    final woodGradient = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFDB8D3E), // Top warm chestnut highlight
          Color(0xFFC0702B), // Rich golden wood body
          Color(0xFF8B4513), // Deep mahogany wood base
          Color(0xFF5A2A08), // Dark bottom wood shadow
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: [0.0, 0.35, 0.75, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    canvas.drawPath(insetPath, woodGradient);

    // E. Wood Grain Texture Curves
    final grainPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final grain1 = Path()
      ..moveTo(w * 0.08, h * 0.32)
      ..cubicTo(w * 0.35, h * 0.22, w * 0.68, h * 0.36, w * 0.92, h * 0.28);

    final grain2 = Path()
      ..moveTo(w * 0.06, h * 0.68)
      ..cubicTo(w * 0.30, h * 0.76, w * 0.70, h * 0.60, w * 0.90, h * 0.72);

    canvas.drawPath(grain1, grainPaint);
    canvas.drawPath(grain2, grainPaint);

    // F. Mossy Green Organic Patches on Top Corners
    final mossPaint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..style = PaintingStyle.fill;

    final mossHighlightPaint = Paint()
      ..color = const Color(0xFF81C784)
      ..style = PaintingStyle.fill;

    // Top-Left Moss Patch
    final moss1 = Path()
      ..moveTo(w * 0.14, h * 0.12)
      ..quadraticBezierTo(w * 0.22, h * 0.02, w * 0.30, h * 0.10)
      ..quadraticBezierTo(w * 0.24, h * 0.22, w * 0.14, h * 0.12)
      ..close();
    canvas.drawPath(moss1, mossPaint);
    canvas.drawCircle(Offset(w * 0.20, h * 0.08), 5, mossHighlightPaint);

    // Top-Right Moss Patch
    final moss2 = Path()
      ..moveTo(w * 0.72, h * 0.08)
      ..quadraticBezierTo(w * 0.82, h * 0.04, w * 0.88, h * 0.15)
      ..quadraticBezierTo(w * 0.78, h * 0.22, w * 0.72, h * 0.08)
      ..close();
    canvas.drawPath(moss2, mossPaint);
    canvas.drawCircle(Offset(w * 0.80, h * 0.10), 6, mossHighlightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
