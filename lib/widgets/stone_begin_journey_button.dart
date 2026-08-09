import 'package:flutter/material.dart';

class StoneBeginJourneyButton extends StatefulWidget {
  final VoidCallback onTap;
  final double width;
  final double height;

  const StoneBeginJourneyButton({
    super.key,
    required this.onTap,
    this.width = 280.0,
    this.height = 62.0,
  });

  @override
  State<StoneBeginJourneyButton> createState() => _StoneBeginJourneyButtonState();
}

class _StoneBeginJourneyButtonState extends State<StoneBeginJourneyButton> {
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
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Custom Weathered Stone Tablet Painter
              CustomPaint(
                size: Size(widget.width, widget.height),
                painter: _WeatheredStoneTabletPainter(),
              ),

              // Carved Brackets & Text [ BEGIN JOURNEY ] Outline
              Text(
                '[ BEGIN JOURNEY ]',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.5,
                  fontFamily: 'Outfit',
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 4.5
                    ..strokeJoin = StrokeJoin.round
                    ..color = const Color(0xFF1B140E),
                ),
              ),

              // Radiant Stone Text Shader Fill
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [
                    Color(0xFFFFFDE7), // Ivory highlight top
                    Color(0xFFFFD54F), // Amber stone gold
                    Color(0xFFFFB300), // Deep stone gold base
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ).createShader(bounds),
                child: const Text(
                  '[ BEGIN JOURNEY ]',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.5,
                    fontFamily: 'Outfit',
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        offset: Offset(1.5, 2.0),
                        blurRadius: 3,
                      ),
                    ],
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

class _WeatheredStoneTabletPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Weathered Irregular Stone Tablet Silhouette
    final path = Path()
      ..moveTo(10, 0)
      ..lineTo(w - 12, 0)
      ..cubicTo(w - 2, 4, w, 14, w, h / 2)
      ..cubicTo(w, h - 14, w - 4, h, w - 14, h)
      ..lineTo(14, h)
      ..cubicTo(4, h, 0, h - 14, 0, h / 2)
      ..cubicTo(0, 14, 4, 0, 10, 0)
      ..close();

    // 1. Drop Shadow
    canvas.drawPath(
      path.shift(const Offset(4, 7)),
      Paint()
        ..color = Colors.black54
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // 2. Beveled Dark Slate Granite Frame
    canvas.drawPath(
      path,
      Paint()..color = const Color(0xFF2A231D),
    );

    // 3. Inner Carved Stone Tablet Surface
    final insetPath = Path()
      ..moveTo(12, 3)
      ..lineTo(w - 14, 3)
      ..cubicTo(w - 4, 6, w - 3, 14, w - 3, h / 2)
      ..cubicTo(w - 3, h - 14, w - 6, h - 3, w - 16, h - 3)
      ..lineTo(16, h - 3)
      ..cubicTo(6, h - 3, 3, h - 14, 3, h / 2)
      ..cubicTo(3, 14, 6, 3, 12, 3)
      ..close();

    final stoneGradient = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF7A6D61), // Weathered stone highlight top
          Color(0xFF52483F), // Middle granite body
          Color(0xFF2E2620), // Dark stone base
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(insetPath, stoneGradient);

    // 4. Mossy Accent Patches on Corners
    final mossPaint = Paint()
      ..color = const Color(0xFF558B2F).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(const Offset(16, 12), 5.0, mossPaint);
    canvas.drawCircle(Offset(w - 18, h - 12), 6.0, mossPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
