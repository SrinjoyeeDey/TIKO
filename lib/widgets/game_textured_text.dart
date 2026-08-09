import 'package:flutter/material.dart';

class GameTexturedText extends StatelessWidget {
  final String text;
  final double fontSize;
  final double letterSpacing;
  final List<Color>? gradientColors;
  final Color strokeColor;
  final double strokeWidth;

  const GameTexturedText({
    super.key,
    required this.text,
    this.fontSize = 32,
    this.letterSpacing = 2.0,
    this.gradientColors,
    this.strokeColor = const Color(0xFF2D1604),
    this.strokeWidth = 7.0,
  });

  @override
  Widget build(BuildContext context) {
    final colors = gradientColors ?? const [
      Color(0xFFFFF59D), // Bright golden yellow top
      Color(0xFFFFB300), // Vibrant amber middle
      Color(0xFFF57F17), // Rich orange-gold base
    ];

    return Stack(
      alignment: Alignment.center,
      children: [
        // 1. Deep 3D Drop Shadow Layer
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            letterSpacing: letterSpacing,
            fontFamily: 'Outfit',
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth + 3.0
              ..strokeJoin = StrokeJoin.round
              ..color = Colors.black.withValues(alpha: 0.5),
          ),
        ),

        // 2. Dark Chocolate Outer Stroke / Outline
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            letterSpacing: letterSpacing,
            fontFamily: 'Outfit',
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth
              ..strokeJoin = StrokeJoin.round
              ..color = strokeColor,
          ),
        ),

        // 3. Inner Dark Offset Bevel
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            letterSpacing: letterSpacing,
            fontFamily: 'Outfit',
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth * 0.5
              ..strokeJoin = StrokeJoin.round
              ..color = const Color(0xFF4A2506),
          ),
        ),

        // 4. Vibrant Gradient Fill with Highlights & Shadows
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: colors,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(bounds),
          child: Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              letterSpacing: letterSpacing,
              fontFamily: 'Outfit',
              color: Colors.white,
              shadows: const [
                Shadow(
                  color: Color(0xFFFFF9C4),
                  offset: Offset(-1.0, -1.0),
                  blurRadius: 1,
                ),
                Shadow(
                  color: Colors.black38,
                  offset: Offset(1.5, 2.5),
                  blurRadius: 3,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
