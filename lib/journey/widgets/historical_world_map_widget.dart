import 'package:flutter/material.dart';
import 'historical_world_map_painter.dart';

/// Renders the generated high-resolution historical explorer's World Map image asset.
/// Overlays the Japanese Hanko origin seal, Asia context label, and India spotlight illumination.
class HistoricalWorldMapWidget extends StatelessWidget {
  final double opacity;
  final double indiaHighlightProgress;

  const HistoricalWorldMapWidget({
    super.key,
    required this.opacity,
    this.indiaHighlightProgress = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    if (opacity <= 0.001) return const SizedBox.shrink();

    return Opacity(
      opacity: opacity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. High-Resolution Historical World Map Image Asset
          Image.asset(
            'assets/maps/historical_world_map_parchment.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return CustomPaint(
                painter: HistoricalWorldMapPainter(
                  opacity: opacity,
                  showGraticules: true,
                  indiaHighlightProgress: indiaHighlightProgress,
                ),
                child: const SizedBox.expand(),
              );
            },
          ),

          // 2. Japanese Hanko Vermilion Red Sun Origin Seal Stamp over Japan (East Asia)
          Positioned(
            right: 48,
            top: 95,
            child: _buildJapanHankoSeal(),
          ),

          // 3. Dynamic India Illumination Spotlight Glow within Asia
          if (indiaHighlightProgress > 0.001)
            CustomPaint(
              painter: _IndiaSpotlightPainter(progress: indiaHighlightProgress),
              child: const SizedBox.expand(),
            ),
        ],
      ),
    );
  }

  Widget _buildJapanHankoSeal() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: const Color(0xFFD32F2F).withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFFD32F2F), width: 1.8),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFFD32F2F),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: const Center(
        child: Text(
          '日',
          style: TextStyle(
            color: Color(0xFFB71C1C),
            fontSize: 10,
            fontWeight: FontWeight.w900,
            fontFamily: 'Outfit',
          ),
        ),
      ),
    );
  }
}

class _IndiaSpotlightPainter extends CustomPainter {
  final double progress;

  _IndiaSpotlightPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Center coordinates for India & Asia continent on parchment
    final indiaCenter = Offset(w * 0.64, h * 0.54);
    final asiaLabelCenter = Offset(w * 0.68, h * 0.38);

    // 1. Asia Continental Context Glow
    final asiaGlowShader = RadialGradient(
      colors: [
        const Color(0xFFFFD54F).withValues(alpha: 0.25 * progress),
        const Color(0xFF8C7355).withValues(alpha: 0.12 * progress),
        Colors.transparent,
      ],
      stops: const [0.0, 0.6, 1.0],
    ).createShader(Rect.fromCircle(center: asiaLabelCenter, radius: w * 0.35));

    canvas.drawCircle(asiaLabelCenter, w * 0.35, Paint()..shader = asiaGlowShader);

    // Cartographic ASIA Label
    _drawText(
      canvas,
      'A S I A',
      asiaLabelCenter,
      TextStyle(
        color: const Color(0xFF5D4037).withValues(alpha: 0.85 * progress),
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 4.0,
        fontFamily: 'Outfit',
      ),
    );

    // 2. Focused Golden Spotlight over India Subcontinent (Soft & smooth)
    final spotlightShader = RadialGradient(
      colors: [
        const Color(0xFFFFD54F).withValues(alpha: 0.75 * progress),
        const Color(0xFFFFB300).withValues(alpha: 0.45 * progress),
        const Color(0xFF00E5FF).withValues(alpha: 0.20 * progress),
        Colors.transparent,
      ],
      stops: const [0.0, 0.40, 0.70, 1.0],
    ).createShader(Rect.fromCircle(center: indiaCenter, radius: w * 0.26));

    canvas.drawCircle(
      indiaCenter,
      w * 0.26,
      Paint()
        ..shader = spotlightShader
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );

    // 3. Elegant Glowing Destination Point Marker (Matching Reference Image Panel 6)
    final pointHalo = Paint()
      ..color = const Color(0xFFFFD54F).withValues(alpha: 0.90 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3);

    final pointCore = Paint()
      ..color = const Color(0xFFFFF176).withValues(alpha: 0.95 * progress)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(indiaCenter, 9.0, pointHalo);
    canvas.drawCircle(indiaCenter, 3.8, pointCore);
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
  bool shouldRepaint(covariant _IndiaSpotlightPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
