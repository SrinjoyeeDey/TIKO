import 'package:flutter/material.dart';

enum WoodenPlankVariant {
  standard,
  menuHeader,
  exit,
  golden,
  arrowLeft,
  arrowRight,
}

class WoodenPlankButton extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  final WoodenPlankVariant variant;
  final double width;
  final double height;
  final bool hasLeafLeft;
  final bool hasLeafRight;

  const WoodenPlankButton({
    super.key,
    required this.text,
    required this.onTap,
    this.variant = WoodenPlankVariant.standard,
    this.width = 240,
    this.height = 48,
    this.hasLeafLeft = false,
    this.hasLeafRight = false,
  });

  @override
  State<WoodenPlankButton> createState() => _WoodenPlankButtonState();
}

class _WoodenPlankButtonState extends State<WoodenPlankButton> {
  bool _isPressed = false;

  Color _getGradientStart() {
    switch (widget.variant) {
      case WoodenPlankVariant.golden:
        return const Color(0xFFFFE082); // Vibrant Golden Warm Amber
      case WoodenPlankVariant.exit:
        return const Color(0xFFD4E157); // Yellowish green tint for EXIT
      case WoodenPlankVariant.menuHeader:
        return const Color(0xFFC0702B);
      default:
        return const Color(0xFFC87830); // Rich golden brown wood
    }
  }

  Color _getGradientEnd() {
    switch (widget.variant) {
      case WoodenPlankVariant.golden:
        return const Color(0xFFFF8F00); // Deep Amber Gold
      case WoodenPlankVariant.exit:
        return const Color(0xFF9E9D24);
      case WoodenPlankVariant.menuHeader:
        return const Color(0xFF7A3E10);
      default:
        return const Color(0xFF8B4513);
    }
  }

  Color _getTextColor() {
    if (widget.variant == WoodenPlankVariant.menuHeader) {
      return const Color(0xFFFFD54F); // Golden yellow for main MENU header
    }
    if (widget.variant == WoodenPlankVariant.golden) {
      return const Color(0xFF3E1F07); // Dark rich brown text for Golden variant
    }
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final scale = _isPressed ? 0.95 : 1.0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 100),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Outer shadow container
            Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.variant == WoodenPlankVariant.menuHeader ? 16 : 24),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.variant == WoodenPlankVariant.menuHeader ? 16 : 24),
                  border: Border.all(
                    color: const Color(0xFF4A2506),
                    width: 2.5,
                  ),
                  gradient: LinearGradient(
                    colors: [_getGradientStart(), _getGradientEnd()],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Stack(
                  children: [
                    // Wood Grain Texture Lines
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _WoodGrainPainter(
                          isExit: widget.variant == WoodenPlankVariant.exit,
                        ),
                      ),
                    ),

                    // Metallic Bolts / Nails
                    Positioned(
                      left: 10,
                      top: widget.height / 2 - 3,
                      child: _buildBolt(),
                    ),
                    Positioned(
                      right: 10,
                      top: widget.height / 2 - 3,
                      child: _buildBolt(),
                    ),

                    // Text Content
                    Center(
                      child: Text(
                        widget.text.toUpperCase(),
                        style: TextStyle(
                          fontSize: widget.variant == WoodenPlankVariant.menuHeader ? 28 : 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                          color: _getTextColor(),
                          shadows: [
                            const Shadow(
                              color: Color(0xFF3E1F07),
                              offset: Offset(1.5, 2.0),
                              blurRadius: 3,
                            ),
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.6),
                              offset: const Offset(-1, -1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Optional Leaf Sprouts
            if (widget.hasLeafLeft)
              Positioned(
                left: -6,
                top: -6,
                child: _buildLeafIcon(),
              ),
            if (widget.hasLeafRight)
              Positioned(
                right: -6,
                top: -6,
                child: _buildLeafIcon(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBolt() {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: Color(0xFFD7CCC8),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
    );
  }

  Widget _buildLeafIcon() {
    return const Icon(
      Icons.eco,
      size: 20,
      color: Color(0xFF4CAF50),
    );
  }
}

class _WoodGrainPainter extends CustomPainter {
  final bool isExit;
  _WoodGrainPainter({required this.isExit});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isExit ? Colors.black.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.12)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final path1 = Path()
      ..moveTo(0, size.height * 0.3)
      ..cubicTo(size.width * 0.3, size.height * 0.2, size.width * 0.6, size.height * 0.4, size.width, size.height * 0.35);

    final path2 = Path()
      ..moveTo(0, size.height * 0.7)
      ..cubicTo(size.width * 0.4, size.height * 0.8, size.width * 0.7, size.height * 0.6, size.width, size.height * 0.75);

    canvas.drawPath(path1, paint);
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
