import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
// ignore: depend_on_referenced_packages
import 'package:vector_math/vector_math_64.dart' show Vector3;
import '../data/india_map_data.dart';
import '../data/india_states_data.dart';
import 'adventurer_platform_widget.dart';

/// 3D Horizontal Ground-Laid India Map Widget.
/// Renders the vector map of India lying flat horizontally on a surface with 3D depth,
/// perspective tilt, state selection, hover effects, and automatic responsive scaling.
class GroundIndiaMapWidget extends StatefulWidget {
  final String? selectedStateId;
  final ValueChanged<String>? onStateSelected;
  final ValueChanged<String?>? onStateHovered;
  final double pitchAngle; // Pitch tilt angle (X axis rotation)
  final double yawAngle;   // Yaw rotation angle (Z axis rotation)
  final double zoomLevel;  // Scale zoom multiplier
  final Offset panOffset;  // Pan translation offset
  final bool enableGestures;
  final bool showOuterBorder;
  final ValueChanged<Offset>? onPanUpdate;
  final ValueChanged<double>? onZoomUpdate;

  const GroundIndiaMapWidget({
    super.key,
    this.selectedStateId,
    this.onStateSelected,
    this.onStateHovered,
    this.pitchAngle = 0.95, // ~54 degrees pitch tilt
    this.yawAngle = 0.0,
    this.zoomLevel = 1.0,
    this.panOffset = Offset.zero,
    this.enableGestures = true,
    this.showOuterBorder = true,
    this.onPanUpdate,
    this.onZoomUpdate,
  });

  @override
  State<GroundIndiaMapWidget> createState() => _GroundIndiaMapWidgetState();
}

class _GroundIndiaMapWidgetState extends State<GroundIndiaMapWidget> {
  String? _hoveredStateId;

  // Aspect ratio of map geometry ~ 0.88 (width / height)
  static const double kMapAspectRatio = 0.88;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final containerW = constraints.maxWidth;
        final containerH = constraints.maxHeight;

        // Full-screen coverage: Map expands to fill the entire container edge-to-edge
        double mapW;
        double mapH;

        if (containerW / containerH < kMapAspectRatio) {
          mapW = containerW * 1.08;
          mapH = mapW / kMapAspectRatio;
        } else {
          mapH = containerH * 1.15;
          mapW = mapH * kMapAspectRatio;
        }

        final baseMapSize = Size(mapW, mapH);

        // Bounding box and geometric center of the actual visible India landmass
        final Rect geometryBounds = Rect.fromLTRB(
          IndiaMapData.bounds.left * baseMapSize.width,
          IndiaMapData.bounds.top * baseMapSize.height,
          IndiaMapData.bounds.right * baseMapSize.width,
          IndiaMapData.bounds.bottom * baseMapSize.height,
        );

        // 3D Perspective visual centroid compensation for pitch tilt foreshortening
        final double pitchCompensationY = baseMapSize.height * 0.10 * math.sin(widget.pitchAngle);
        final Offset effectiveIndiaCenter = Offset(
          geometryBounds.center.dx,
          geometryBounds.center.dy + pitchCompensationY,
        );

        // 3D Perspective Matrix transformation anchored to available viewport center
        // ignore: deprecated_member_use
        final Matrix4 transformMatrix = Matrix4.identity()
          ..setEntry(3, 2, 0.0010) // Perspective depth factor
          // ignore: deprecated_member_use
          ..translate(
            containerW / 2 + widget.panOffset.dx,
            containerH / 2 + widget.panOffset.dy,
            0.0,
          )
          ..rotateX(widget.pitchAngle)
          ..rotateZ(widget.yawAngle)
          // ignore: deprecated_member_use
          ..scale(widget.zoomLevel)
          // ignore: deprecated_member_use
          ..translate(-effectiveIndiaCenter.dx, -effectiveIndiaCenter.dy, 0.0);

        return MouseRegion(
          onHover: (event) => _handlePointerHover(event.localPosition, baseMapSize, transformMatrix),
          child: Listener(
            onPointerSignal: (pointerSignal) {
              if (widget.enableGestures && pointerSignal is PointerScrollEvent && widget.onZoomUpdate != null) {
                final zoomDelta = pointerSignal.scrollDelta.dy > 0 ? -0.1 : 0.1;
                widget.onZoomUpdate!((widget.zoomLevel + zoomDelta).clamp(0.6, 2.5));
              }
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) => _handleTap(details.localPosition, baseMapSize, transformMatrix),
              onPanUpdate: widget.enableGestures && widget.onPanUpdate != null
                  ? (details) => widget.onPanUpdate!(widget.panOffset + details.delta)
                  : null,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Full-screen background canvas
                  SizedBox(
                    width: containerW,
                    height: containerH,
                  ),

                  // 3D Transformed Vintage Map Canvas
                  Transform(
                    transform: transformMatrix,
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: baseMapSize.width,
                      height: baseMapSize.height,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Custom Painter for Map Base, Vintage Parchment, Cartography & States
                          CustomPaint(
                            size: baseMapSize,
                            painter: _GroundMapPainter(
                              selectedStateId: widget.selectedStateId,
                              hoveredStateId: _hoveredStateId,
                              pitchAngle: widget.pitchAngle,
                              showOuterBorder: widget.showOuterBorder,
                            ),
                          ),

                          // State Marker Pins Overlay
                          ..._buildStateMarkers(baseMapSize),
                        ],
                      ),
                    ),
                  ),

                  // 3D Elevated Blocks Platform & Adventurer Character (Positioned in illuminated parchment space next to Bay of Bengal)
                  AdventurerPlatformWidget(
                    screenPosition: Offset(
                      (transformMatrix.perspectiveTransform(
                        Vector3(baseMapSize.width * 0.52, baseMapSize.height * 0.50, 0.0),
                      )).x,
                      (transformMatrix.perspectiveTransform(
                        Vector3(baseMapSize.width * 0.52, baseMapSize.height * 0.50, 0.0),
                      )).y,
                    ),
                    scale: (widget.zoomLevel * 0.95).clamp(0.9, 1.6),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _handlePointerHover(Offset localPos, Size mapSize, Matrix4 transformMatrix) {
    final stateId = _hitTestState(localPos, mapSize, transformMatrix);
    if (stateId != _hoveredStateId) {
      setState(() {
        _hoveredStateId = stateId;
      });
      if (widget.onStateHovered != null) {
        widget.onStateHovered!(stateId);
      }
    }
  }

  void _handleTap(Offset localPos, Size mapSize, Matrix4 transformMatrix) {
    final stateId = _hitTestState(localPos, mapSize, transformMatrix);
    if (stateId != null && widget.onStateSelected != null) {
      widget.onStateSelected!(stateId);
    }
  }

  String? _hitTestState(Offset screenPos, Size mapSize, Matrix4 transformMatrix) {
    try {
      final Matrix4 inverted = Matrix4.inverted(transformMatrix);
      final mapCoord3D = inverted.perspectiveTransform(Vector3(screenPos.dx, screenPos.dy, 0.0));
      final Offset mapCoord = Offset(mapCoord3D.x, mapCoord3D.y);

      if (mapCoord.dx < 0 || mapCoord.dx > mapSize.width || mapCoord.dy < 0 || mapCoord.dy > mapSize.height) {
        return null;
      }

      for (final state in IndiaMapData.states) {
        if (state.containsPoint(mapCoord, mapSize)) {
          return state.id;
        }
      }
    } catch (_) {}
    return null;
  }

  List<Widget> _buildStateMarkers(Size mapSize) {
    if (widget.selectedStateId == null) return [];

    final selectedState = IndiaMapData.states.firstWhere(
      (s) => s.id == widget.selectedStateId,
      orElse: () => IndiaMapData.states.first,
    );

    final px = selectedState.labelPos.dx * mapSize.width;
    final py = selectedState.labelPos.dy * mapSize.height;

    final stateData = IndiaStatesDatabase.getState(selectedState.id);
    if (stateData == null) return [];

    return [
      Positioned(
        left: px - 60,
        top: py - 55,
        child: IgnorePointer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF3E2716),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFFD54F), width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 3)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(stateData.illustrationIcon, size: 14, color: const Color(0xFFFFD54F)),
                    const SizedBox(width: 5),
                    Text(
                      stateData.name.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFF176),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.location_on, size: 28, color: Color(0xFFE53935)),
            ],
          ),
        ),
      ),
    ];
  }
}

/// Custom Painter rendering Full-Screen Vintage Cartographic Map Canvas
class _GroundMapPainter extends CustomPainter {
  final String? selectedStateId;
  final String? hoveredStateId;
  final double pitchAngle;
  final bool showOuterBorder;

  _GroundMapPainter({
    required this.selectedStateId,
    required this.hoveredStateId,
    required this.pitchAngle,
    this.showOuterBorder = true,
  });

  static const List<Color> kVintageStateColors = [
    Color(0xFFD9825B), // Terracotta
    Color(0xFFE5B869), // Aged Gold / Ochre
    Color(0xFF9BB080), // Sage Green
    Color(0xFFC7B18B), // Tea Sepia
    Color(0xFF779E9D), // Antique Teal
    Color(0xFFC98B8B), // Muted Rose
    Color(0xFFC47B62), // Soft Clay
    Color(0xFFDEC083), // Warm Mustard
    Color(0xFFA3B899), // Olive Pastel
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    if (showOuterBorder) {
      // 1. 3D Ground Slab Thickness Slices
      final depthOffset = math.max(4.0, pitchAngle.abs() * 14.0);
      for (double d = depthOffset; d >= 0; d -= 2.0) {
        final depthRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(-8, -8 + d, w + 16, h + 16),
          const Radius.circular(16),
        );
        canvas.drawRRect(
          depthRect,
          Paint()..color = Color.lerp(const Color(0xFF2C190B), const Color(0xFF4A3425), d / depthOffset)!,
        );
      }

      // 2. Vintage Parchment Canvas Surface
      final boardRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(-4, -4, w + 8, h + 8),
        const Radius.circular(14),
      );

      // Warm Parchment Base Color
      canvas.drawRRect(
        boardRect,
        Paint()..color = const Color(0xFFF4E6C8),
      );

      // Tea-Stained Vignette Paper Aging Shader
      final vignetteShader = RadialGradient(
        colors: [
          Colors.transparent,
          const Color(0xFFC4A470).withValues(alpha: 0.20),
          const Color(0xFF8C6239).withValues(alpha: 0.45),
        ],
        stops: const [0.55, 0.85, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

      canvas.drawRRect(
        boardRect,
        Paint()..shader = vignetteShader,
      );

      // Antique Brass/Wood Trim Double Border
      canvas.drawRRect(
        boardRect,
        Paint()
          ..color = const Color(0xFF5D4037)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5,
      );
      canvas.drawRRect(
        boardRect,
        Paint()
          ..color = const Color(0xFFB8860B)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    } else {
      // Extended Parchment Base Surface (Seamless 3D perspective coverage)
      final extendedRect = Rect.fromLTWH(-w * 1.5, -h * 2.5, w * 4.0, h * 5.0);
      canvas.drawRect(
        extendedRect,
        Paint()..color = const Color(0xFFF4E6C8),
      );

      // Compact Spotlight Vignette (Hugs the India landmass closely with dark dimmed outer tiles)
      final Rect mapBoundsRect = Rect.fromLTRB(
        IndiaMapData.bounds.left * w - w * 0.08,
        IndiaMapData.bounds.top * h - h * 0.08,
        IndiaMapData.bounds.right * w + w * 0.08,
        IndiaMapData.bounds.bottom * h + h * 0.08,
      );

      final dimmedTilesShader = RadialGradient(
        colors: [
          Colors.transparent,
          const Color(0xFF6D4C41).withValues(alpha: 0.35),
          const Color(0xFF4E342E).withValues(alpha: 0.70),
          const Color(0xFF2C190B).withValues(alpha: 0.90),
        ],
        stops: const [0.25, 0.55, 0.80, 1.0],
      ).createShader(mapBoundsRect);

      canvas.drawRect(
        extendedRect,
        Paint()..shader = dimmedTilesShader,
      );
    }

    // 3. Cartographic Coordinate Grid of Squared Boxes & Compass Rose
    _drawCoordinateGrid(canvas, size);
    _drawNauticalCompass(canvas, size);
    _drawTradeRouteArcs(canvas, size);

    // 4. Render State Polygons with Vintage Color Palette
    final borderStroke = Paint()
      ..color = const Color(0xFF4A3425).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    for (int i = 0; i < IndiaMapData.states.length; i++) {
      final state = IndiaMapData.states[i];
      final path = state.buildPath(size);
      final isSelected = state.id == selectedStateId;
      final isHovered = state.id == hoveredStateId;

      final vintageColor = kVintageStateColors[i % kVintageStateColors.length];

      if (isSelected || (selectedStateId == null && state.id == 'madhya_pradesh')) {
        // Selected State (or default Madhya Pradesh): Mystical Light Beam Pillar rising into the sky
        final Rect stateBounds = path.getBounds();
        final Offset stateCenter = stateBounds.center;

        final double beamW = (stateBounds.width * 1.1).clamp(45.0, 150.0);
        final double beamH = size.height * 1.1;

        final beamRect = Rect.fromLTWH(
          stateCenter.dx - beamW / 2,
          stateCenter.dy - beamH,
          beamW,
          beamH,
        );

        final lightBeamGrad = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            const Color(0xFFFFF59D).withValues(alpha: 0.90),
            const Color(0xFFFFD54F).withValues(alpha: 0.55),
            const Color(0xFFFFB74D).withValues(alpha: 0.22),
            Colors.transparent,
          ],
          stops: const [0.0, 0.25, 0.65, 1.0],
        ).createShader(beamRect);

        final lightBeamPath = Path()
          ..moveTo(stateCenter.dx - beamW * 0.5, stateCenter.dy)
          ..lineTo(stateCenter.dx + beamW * 0.5, stateCenter.dy)
          ..lineTo(stateCenter.dx + beamW * 0.35, stateCenter.dy - beamH)
          ..lineTo(stateCenter.dx - beamW * 0.35, stateCenter.dy - beamH)
          ..close();

        // Draw Mystical Light Pillar Behind/On Top of State
        canvas.drawPath(lightBeamPath, Paint()..shader = lightBeamGrad);

        // Radiant Golden State Fill & Outline
        canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0xFFFFD54F)
            ..style = PaintingStyle.fill,
        );
        canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0xFFE65100)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.8,
        );
      } else if (isHovered) {
        // Hovered State Highlight
        canvas.drawPath(
          path,
          Paint()
            ..color = Color.lerp(vintageColor, const Color(0xFFFFF176), 0.55)!
            ..style = PaintingStyle.fill,
        );
        canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0xFFE65100)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0,
        );
      } else {
        // Vintage Muted Fill & Sepia Border
        canvas.drawPath(
          path,
          Paint()
            ..color = vintageColor.withValues(alpha: 0.88)
            ..style = PaintingStyle.fill,
        );
        canvas.drawPath(path, borderStroke);
      }
    }
  }

  void _drawCoordinateGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF8D6E63).withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    const stepX = 50.0;
    const stepY = 50.0;

    final minX = showOuterBorder ? 0.0 : -size.width * 1.5;
    final maxX = showOuterBorder ? size.width : size.width * 2.5;
    final minY = showOuterBorder ? 0.0 : -size.height * 2.5;
    final maxY = showOuterBorder ? size.height : size.height * 2.0;

    for (double x = minX; x <= maxX; x += stepX) {
      canvas.drawLine(Offset(x, minY), Offset(x, maxY), gridPaint);
    }
    for (double y = minY; y <= maxY; y += stepY) {
      canvas.drawLine(Offset(minX, y), Offset(maxX, y), gridPaint);
    }
  }

  void _drawNauticalCompass(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.82, size.height * 0.18);
    const radius = 32.0;

    final brassPaint = Paint()
      ..color = const Color(0xFF8D6E63).withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    canvas.drawCircle(center, radius, brassPaint);
    canvas.drawCircle(center, radius * 0.72, brassPaint);
    canvas.drawCircle(center, radius * 0.25, Paint()..color = const Color(0xFF5D4037));

    // North Crimson Pointer
    final northPath = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(center.dx - 6, center.dy)
      ..lineTo(center.dx, center.dy - radius + 3)
      ..close();
    canvas.drawPath(northPath, Paint()..color = const Color(0xFFC62828));

    // South Dark Pointer
    final southPath = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(center.dx + 6, center.dy)
      ..lineTo(center.dx, center.dy + radius - 3)
      ..close();
    canvas.drawPath(southPath, Paint()..color = const Color(0xFF3E2716));

    // East Pointer
    final eastPath = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(center.dx, center.dy + 6)
      ..lineTo(center.dx + radius - 3, center.dy)
      ..close();
    canvas.drawPath(eastPath, Paint()..color = const Color(0xFF8D6E63));

    // West Pointer
    final westPath = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(center.dx, center.dy - 6)
      ..lineTo(center.dx - radius + 3, center.dy)
      ..close();
    canvas.drawPath(westPath, Paint()..color = const Color(0xFF8D6E63));
  }

  void _drawTradeRouteArcs(Canvas canvas, Size size) {
    final routePaint = Paint()
      ..color = const Color(0xFF8D6E63).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Major trade route arcs connecting key geography (Delhi, Mumbai, Kolkata, Chennai, Kochi)
    final pDelhi = Offset(size.width * 0.36, size.height * 0.28);
    final pMumbai = Offset(size.width * 0.24, size.height * 0.58);
    final pKolkata = Offset(size.width * 0.72, size.height * 0.48);
    final pChennai = Offset(size.width * 0.44, size.height * 0.78);

    // Curved Flight Arcs
    final route1 = Path()
      ..moveTo(pDelhi.dx, pDelhi.dy)
      ..quadraticBezierTo(size.width * 0.28, size.height * 0.40, pMumbai.dx, pMumbai.dy);

    final route2 = Path()
      ..moveTo(pDelhi.dx, pDelhi.dy)
      ..quadraticBezierTo(size.width * 0.55, size.height * 0.32, pKolkata.dx, pKolkata.dy);

    final route3 = Path()
      ..moveTo(pMumbai.dx, pMumbai.dy)
      ..quadraticBezierTo(size.width * 0.32, size.height * 0.72, pChennai.dx, pChennai.dy);

    canvas.drawPath(route1, routePaint);
    canvas.drawPath(route2, routePaint);
    canvas.drawPath(route3, routePaint);
  }

  @override
  bool shouldRepaint(covariant _GroundMapPainter oldDelegate) {
    return oldDelegate.selectedStateId != selectedStateId ||
        oldDelegate.hoveredStateId != hoveredStateId ||
        oldDelegate.pitchAngle != pitchAngle;
  }
}
