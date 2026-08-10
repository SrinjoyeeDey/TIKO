import 'package:flutter/material.dart';
import '../../data/world_map_data.dart';
import '../models/journey_destination.dart';
import 'destination_marker.dart';

/// Layer responsible for rendering Japan origin marker, animating the travel route from
/// Japan to Calcutta, and highlighting India upon arrival.
class IndiaHighlightLayer extends StatelessWidget {
  final JourneyDestination destination;
  final double highlightOpacity;
  final double routeProgress;
  final bool showMarker;

  const IndiaHighlightLayer({
    super.key,
    required this.destination,
    required this.highlightOpacity,
    required this.routeProgress,
    required this.showMarker,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Japan Origin Marker & Animated Ocean/Land Route Line Painter
        CustomPaint(
          painter: _JapanToIndiaRoutePainter(
            highlightOpacity: highlightOpacity,
            routeProgress: routeProgress,
            originRelativeCoord: destination.originRelativeCoord,
            targetRelativeCoord: destination.relativeTargetCoord,
          ),
          child: const SizedBox.expand(),
        ),

        // 2. Calcutta Destination Marker Positioned at Target Coordinates
        if (showMarker)
          LayoutBuilder(
            builder: (context, constraints) {
              final targetX = constraints.maxWidth * destination.relativeTargetCoord.dx;
              final targetY = constraints.maxHeight * destination.relativeTargetCoord.dy;

              return Positioned(
                left: targetX - 65,
                top: targetY - 45,
                child: SizedBox(
                  width: 130,
                  child: DestinationMarker(
                    label: destination.city,
                    isVisible: showMarker,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _JapanToIndiaRoutePainter extends CustomPainter {
  final double highlightOpacity;
  final double routeProgress;
  final Offset originRelativeCoord;
  final Offset targetRelativeCoord;

  _JapanToIndiaRoutePainter({
    required this.highlightOpacity,
    required this.routeProgress,
    required this.originRelativeCoord,
    required this.targetRelativeCoord,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final originOffset = Offset(w * originRelativeCoord.dx, h * originRelativeCoord.dy);
    final targetOffset = Offset(w * targetRelativeCoord.dx, h * targetRelativeCoord.dy);

    // 1. Japan Origin Glow Pin Marker (Vermilion Cinnabar Red Beacon)
    final japanGlowPaint = Paint()
      ..color = const Color(0xFFD32F2F).withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(originOffset, 12, japanGlowPaint);
    canvas.drawCircle(originOffset, 5, Paint()..color = const Color(0xFFD32F2F));
    canvas.drawCircle(originOffset, 2, Paint()..color = Colors.white);

    // 2. India Warm Golden Radial Spotlight Glow & Real Path Outline
    if (highlightOpacity > 0.001) {
      final indiaRegion = WorldMapData.getRegion('india');
      if (indiaRegion != null) {
        final indiaPath = indiaRegion.buildPath(size);

        canvas.drawPath(
          indiaPath,
          Paint()
            ..color = const Color(0xFFFFD54F).withValues(alpha: 0.7 * highlightOpacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.5
            ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 8),
        );
      }

      final spotlightCenter = Offset(w * 0.65, h * 0.54);
      final spotlightShader = RadialGradient(
        colors: [
          const Color(0xFFFFD54F).withValues(alpha: 0.45 * highlightOpacity),
          const Color(0xFF00E5FF).withValues(alpha: 0.25 * highlightOpacity),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: spotlightCenter, radius: w * 0.26));

      canvas.drawCircle(
        spotlightCenter,
        w * 0.26,
        Paint()
          ..shader = spotlightShader
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
      );
    }

    // 3. Animated Golden Route Line Traveling from Japan (Origin) to Calcutta (Target)
    if (routeProgress > 0.001) {
      final routePath = Path()
        ..moveTo(originOffset.dx, originOffset.dy)
        ..quadraticBezierTo(w * 0.82, h * 0.54, w * 0.74, h * 0.52) // East China Sea -> South Asia
        ..quadraticBezierTo(w * 0.70, h * 0.50, targetOffset.dx, targetOffset.dy); // Bay of Bengal -> Calcutta

      final pms = routePath.computeMetrics();
      for (var pm in pms) {
        final extractLength = pm.length * routeProgress;
        final animatedPath = pm.extractPath(0, extractLength);

        // Underglow Shadow
        canvas.drawPath(
          animatedPath,
          Paint()
            ..color = const Color(0xFF00E5FF).withValues(alpha: 0.55)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4.0
            ..strokeCap = StrokeCap.round
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );

        // Core Golden Dashed Route
        _drawDashedPath(
          canvas,
          animatedPath,
          Paint()
            ..color = const Color(0xFFFFD54F)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..strokeCap = StrokeCap.round,
          dashWidth: 6.0,
          dashSpace: 4.0,
        );
      }
    }
  }

  void _drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint, {
    double dashWidth = 6.0,
    double dashSpace = 4.0,
  }) {
    final metrics = path.computeMetrics();
    for (var metric in metrics) {
      double distance = 0.0;
      bool draw = true;
      while (distance < metric.length) {
        final double length = draw ? dashWidth : dashSpace;
        if (draw) {
          final Path extract = metric.extractPath(distance, distance + length);
          canvas.drawPath(extract, paint);
        }
        distance += length;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _JapanToIndiaRoutePainter oldDelegate) =>
      oldDelegate.highlightOpacity != highlightOpacity ||
      oldDelegate.routeProgress != routeProgress ||
      oldDelegate.originRelativeCoord != originRelativeCoord ||
      oldDelegate.targetRelativeCoord != targetRelativeCoord;
}
