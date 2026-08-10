import 'package:flutter/material.dart';
import '../../data/india_map_data.dart';
import 'destination_marker.dart';

/// Renders the existing application's detailed vector India map using IndiaMapData.states.
/// Highlights West Bengal and places the Calcutta location pin at its exact position.
class DetailedIndiaMapWidget extends StatelessWidget {
  final bool highlightCalcutta;
  final double routeProgress;
  final VoidCallback? onCalcuttaTap;

  const DetailedIndiaMapWidget({
    super.key,
    this.highlightCalcutta = true,
    this.routeProgress = 1.0,
    this.onCalcuttaTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mapWidth = constraints.maxWidth;
        final mapHeight = constraints.maxHeight;
        final mapSize = Size(mapWidth, mapHeight);

        // Find West Bengal state position for pin marker
        final wbState = IndiaMapData.states.firstWhere(
          (s) => s.id == 'west_bengal',
          orElse: () => IndiaMapData.states.first,
        );

        final calcuttaX = mapWidth * wbState.labelPos.dx;
        final calcuttaY = mapHeight * wbState.labelPos.dy;

        return Stack(
          children: [
            // 1. Vector Detailed India Map Painter
            CustomPaint(
              size: mapSize,
              painter: _DetailedIndiaMapPainter(
                highlightWestBengal: highlightCalcutta,
                routeProgress: routeProgress,
                calcuttaOffset: Offset(calcuttaX, calcuttaY),
              ),
            ),

            // 2. Calcutta Pin Marker
            if (highlightCalcutta)
              Positioned(
                left: calcuttaX - 65,
                top: calcuttaY - 45,
                child: SizedBox(
                  width: 130,
                  child: DestinationMarker(
                    label: 'CALCUTTA',
                    isVisible: highlightCalcutta,
                    onTap: onCalcuttaTap,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _DetailedIndiaMapPainter extends CustomPainter {
  final bool highlightWestBengal;
  final double routeProgress;
  final Offset calcuttaOffset;

  _DetailedIndiaMapPainter({
    required this.highlightWestBengal,
    required this.routeProgress,
    required this.calcuttaOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Parchment base tint
    final bgPaint = Paint()..color = const Color(0xFFF9EEDC);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    final borderStroke = Paint()
      ..color = const Color(0xFF5D4037)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final defaultStateFill = Paint()
      ..color = const Color(0xFFF0DFB6)
      ..style = PaintingStyle.fill;

    final wbHighlightFill = Paint()
      ..color = const Color(0xFFFFD54F)
      ..style = PaintingStyle.fill;

    // Draw all state polygons from IndiaMapData.states
    for (final state in IndiaMapData.states) {
      final path = state.buildPath(size);
      final isWB = state.id == 'west_bengal';

      if (isWB && highlightWestBengal) {
        canvas.drawPath(path, wbHighlightFill);
        canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0xFFFF8F00)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4,
        );

        // Underglow around West Bengal
        canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0xFFFFD54F).withValues(alpha: 0.6)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4.0
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
      } else {
        canvas.drawPath(path, defaultStateFill);
        canvas.drawPath(path, borderStroke);
      }
    }

    // Animated Route Line terminating at Calcutta
    if (routeProgress > 0.001) {
      final start = Offset(w * 0.90, h * 0.40); // Route coming from East Ocean into Bay of Bengal / Calcutta

      final routePath = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(w * 0.85, h * 0.50, calcuttaOffset.dx, calcuttaOffset.dy);

      final pms = routePath.computeMetrics();
      for (var pm in pms) {
        final animatedPath = pm.extractPath(0, pm.length * routeProgress);

        canvas.drawPath(
          animatedPath,
          Paint()
            ..color = const Color(0xFF00E5FF).withValues(alpha: 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4.0
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );

        _drawDashedPath(
          canvas,
          animatedPath,
          Paint()
            ..color = const Color(0xFFFFD54F)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4
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
  bool shouldRepaint(covariant _DetailedIndiaMapPainter oldDelegate) =>
      oldDelegate.highlightWestBengal != highlightWestBengal ||
      oldDelegate.routeProgress != routeProgress ||
      oldDelegate.calcuttaOffset != calcuttaOffset;
}
