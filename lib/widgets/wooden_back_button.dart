import 'package:flutter/material.dart';

class WoodenBackButton extends StatefulWidget {
  final VoidCallback onTap;
  final double size;

  const WoodenBackButton({
    super.key,
    required this.onTap,
    this.size = 64.0,
  });

  @override
  State<WoodenBackButton> createState() => _WoodenBackButtonState();
}

class _WoodenBackButtonState extends State<WoodenBackButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () => widget.onTap(),
      child: AnimatedScale(
        scale: _isPressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _WoodenBackButtonPainter(),
          ),
        ),
      ),
    );
  }
}

class _WoodenBackButtonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Shadow for Carved Wooden Outer Left Triangle
    final shadowPaint = Paint()
      ..color = Colors.black38
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final outerPath = Path()
      ..moveTo(w * 0.82, h * 0.12)
      ..lineTo(w * 0.08, h * 0.50)
      ..lineTo(w * 0.82, h * 0.88)
      ..close();

    canvas.drawPath(outerPath.shift(const Offset(-2, 4)), shadowPaint);

    // 2. Carved Wooden Outer Triangle Frame
    final woodGradient = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF8D5B2A), Color(0xFF5D3A1A), Color(0xFF3E230C)],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    canvas.drawPath(outerPath, woodGradient);

    // Dark Wooden Bevel Border
    final woodBorder = Paint()
      ..color = const Color(0xFF2A1505)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(outerPath, woodBorder);

    // 3. Inner Carved Inset Path (Left Pointing Tip)
    final insetPath = Path()
      ..moveTo(w * 0.70, h * 0.24)
      ..lineTo(w * 0.22, h * 0.50)
      ..lineTo(w * 0.70, h * 0.76)
      ..close();

    final insetDarkPaint = Paint()
      ..color = const Color(0xFF231104)
      ..style = PaintingStyle.fill;
    canvas.drawPath(insetPath, insetDarkPaint);

    // 4. Glossy Golden Yellow Arrow Triangle (Left Pointing)
    final yellowPath = Path()
      ..moveTo(w * 0.66, h * 0.28)
      ..lineTo(w * 0.26, h * 0.50)
      ..lineTo(w * 0.66, h * 0.72)
      ..close();

    final yellowGradient = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFF176), Color(0xFFFFB300), Color(0xFFF57F17)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    canvas.drawPath(yellowPath, yellowGradient);

    // Glossy Top Highlight Line
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final highlightPath = Path()
      ..moveTo(w * 0.64, h * 0.32)
      ..lineTo(w * 0.32, h * 0.48);

    canvas.drawPath(highlightPath, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
