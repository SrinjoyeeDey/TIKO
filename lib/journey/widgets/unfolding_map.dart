import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Interactive 3D Paper Unfolding Container.
/// Creates a multi-panel physical parchment sheet unfolding with 3D perspective,
/// dynamic crease shadows, paper curvature, specular highlights, and physics easing.
class UnfoldingMap extends StatelessWidget {
  final double rollProgress;   // 0.0 (compact roll) -> 1.0 (unrolled bundle)
  final double unfoldProgress; // 0.0 (folded tri-panel) -> 1.0 (fully open)
  final double settleProgress; // 0.0 -> 1.0 (flattening bounce)
  final Widget child;          // Map cartography content rendered inside paper

  const UnfoldingMap({
    super.key,
    required this.rollProgress,
    required this.unfoldProgress,
    required this.settleProgress,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final totalHeight = constraints.maxHeight;

        // Tri-fold panel widths (Left: 30%, Center: 40%, Right: 30%)
        final panelWidthLeft = totalWidth * 0.30;
        final panelWidthCenter = totalWidth * 0.40;
        final panelWidthRight = totalWidth * 0.30;

        // Overall map scale based on unrolling and settling curve
        final scaleX = math.min(1.0, 0.2 + (rollProgress * 0.3) + (unfoldProgress * 0.5) + (settleProgress * 0.02));
        final scaleY = math.min(1.0, 0.15 + (rollProgress * 0.65) + (unfoldProgress * 0.2) + (settleProgress * 0.01));

        return Center(
          child: Transform.scale(
            scaleX: scaleX,
            scaleY: scaleY,
            alignment: Alignment.center,
            child: SizedBox(
              width: totalWidth,
              height: totalHeight,
              child: Stack(
                children: [
                  // 1. Cast Soft Physical Shadow under entire map sheet
                  Positioned.fill(
                    child: _buildMapCastShadow(unfoldProgress, settleProgress),
                  ),

                  // 2. Rolled Scroll Cylinder state (shown when rollProgress < 0.6)
                  if (rollProgress < 0.8 && unfoldProgress <= 0.01)
                    Positioned.fill(
                      child: _buildRolledScrollBundle(rollProgress, totalWidth, totalHeight),
                    ),

                  // 3. 3D Tri-Fold Paper Panels (shown when rollProgress >= 0.3)
                  if (rollProgress >= 0.3)
                    Positioned.fill(
                      child: Row(
                        children: [
                          // --- LEFT PANEL (Folds along right edge) ---
                          SizedBox(
                            width: panelWidthLeft,
                            height: totalHeight,
                            child: _buildLeftFoldPanel(
                              panelWidthLeft: panelWidthLeft,
                              totalWidth: totalWidth,
                              totalHeight: totalHeight,
                              unfoldProgress: unfoldProgress,
                            ),
                          ),

                          // --- CENTER PANEL (Anchor base sheet) ---
                          SizedBox(
                            width: panelWidthCenter,
                            height: totalHeight,
                            child: _buildCenterPanel(
                              panelWidthLeft: panelWidthLeft,
                              panelWidthCenter: panelWidthCenter,
                              totalWidth: totalWidth,
                              totalHeight: totalHeight,
                            ),
                          ),

                          // --- RIGHT PANEL (Folds along left edge) ---
                          SizedBox(
                            width: panelWidthRight,
                            height: totalHeight,
                            child: _buildRightFoldPanel(
                              panelWidthRight: panelWidthRight,
                              panelWidthLeft: panelWidthLeft,
                              panelWidthCenter: panelWidthCenter,
                              totalWidth: totalWidth,
                              totalHeight: totalHeight,
                              unfoldProgress: unfoldProgress,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Builds physical soft shadow cast beneath the paper sheet onto the exploration table
  Widget _buildMapCastShadow(double unfold, double settle) {
    final blur = 18.0 + (1.0 - unfold) * 12.0;
    final spread = 2.0 + settle * 4.0;
    final opacity = 0.25 + unfold * 0.20;

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: opacity),
            blurRadius: blur,
            spreadRadius: spread,
            offset: const Offset(0, 10),
          ),
        ],
      ),
    );
  }

  /// Rolled parchment bundle visuals during initial phase
  Widget _buildRolledScrollBundle(double rollProgress, double w, double h) {
    final bundleWidth = w * (0.15 + (1.0 - rollProgress) * 0.2);

    return Center(
      child: Container(
        width: bundleWidth,
        height: h * 0.85,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF8C6D46),
              Color(0xFFE4D1B2),
              Color(0xFFFFF6E5),
              Color(0xFFD6BE98),
              Color(0xFF5D4037),
            ],
            stops: [0.0, 0.25, 0.5, 0.75, 1.0],
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
      ),
    );
  }

  /// Left Tri-Fold Panel: Rotates around Y-axis from 160° to 0°
  Widget _buildLeftFoldPanel({
    required double panelWidthLeft,
    required double totalWidth,
    required double totalHeight,
    required double unfoldProgress,
  }) {
    // Rotation angle: 160 degrees folded inward down to 0 degrees flat
    final angle = (1.0 - unfoldProgress) * (math.pi * 0.88);
    final creaseShadowOpacity = math.sin(angle).abs() * 0.65;

    final transform = Matrix4.identity()
      ..setEntry(3, 2, 0.0012) // 3D Perspective depth factor
      ..rotateY(-angle);

    return Transform(
      transform: transform,
      alignment: Alignment.centerRight, // Anchored to right edge (crease with Center Panel)
      child: Stack(
        children: [
          // Clipped portion of inner map content corresponding to Left panel
          ClipRect(
            child: OverflowBox(
              alignment: Alignment.topLeft,
              maxWidth: totalWidth,
              maxHeight: totalHeight,
              child: SizedBox(
                width: totalWidth,
                height: totalHeight,
                child: child,
              ),
            ),
          ),

          // Dynamic Crease Shadow & Specular Highlight Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: creaseShadowOpacity * 0.4),
                    Colors.transparent,
                    Colors.white.withValues(alpha: (1.0 - unfoldProgress) * 0.25),
                    Colors.black.withValues(alpha: creaseShadowOpacity),
                  ],
                  stops: const [0.0, 0.4, 0.95, 1.0],
                ),
              ),
            ),
          ),

          // Physical Paper Edge Border
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 1.5,
              color: const Color(0xFF8C6D46).withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  /// Center Panel: Flat anchor sheet
  Widget _buildCenterPanel({
    required double panelWidthLeft,
    required double panelWidthCenter,
    required double totalWidth,
    required double totalHeight,
  }) {
    return Stack(
      children: [
        // Clipped portion of inner map content corresponding to Center panel
        ClipRect(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            maxWidth: totalWidth,
            maxHeight: totalHeight,
            child: Transform.translate(
              offset: Offset(-panelWidthLeft, 0),
              child: SizedBox(
                width: totalWidth,
                height: totalHeight,
                child: child,
              ),
            ),
          ),
        ),

        // Subtle paper grain & crease shade lines on left/right edges
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.15),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.15),
                ],
                stops: const [0.0, 0.05, 0.95, 1.0],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Right Tri-Fold Panel: Rotates around Y-axis from -160° to 0°
  Widget _buildRightFoldPanel({
    required double panelWidthRight,
    required double panelWidthLeft,
    required double panelWidthCenter,
    required double totalWidth,
    required double totalHeight,
    required double unfoldProgress,
  }) {
    // Rotation angle: -160 degrees folded inward up to 0 degrees flat
    final angle = (1.0 - unfoldProgress) * (math.pi * 0.88);
    final creaseShadowOpacity = math.sin(angle).abs() * 0.65;

    final transform = Matrix4.identity()
      ..setEntry(3, 2, 0.0012) // 3D Perspective depth factor
      ..rotateY(angle);

    return Transform(
      transform: transform,
      alignment: Alignment.centerLeft, // Anchored to left edge (crease with Center Panel)
      child: Stack(
        children: [
          // Clipped portion of inner map content corresponding to Right panel
          ClipRect(
            child: OverflowBox(
              alignment: Alignment.topLeft,
              maxWidth: totalWidth,
              maxHeight: totalHeight,
              child: Transform.translate(
                offset: Offset(-(panelWidthLeft + panelWidthCenter), 0),
                child: SizedBox(
                  width: totalWidth,
                  height: totalHeight,
                  child: child,
                ),
              ),
            ),
          ),

          // Dynamic Crease Shadow & Specular Highlight Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: creaseShadowOpacity),
                    Colors.white.withValues(alpha: (1.0 - unfoldProgress) * 0.25),
                    Colors.transparent,
                    Colors.black.withValues(alpha: creaseShadowOpacity * 0.4),
                  ],
                  stops: const [0.0, 0.05, 0.6, 1.0],
                ),
              ),
            ),
          ),

          // Physical Paper Edge Border
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 1.5,
              color: const Color(0xFF8C6D46).withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
