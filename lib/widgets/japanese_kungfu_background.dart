import 'dart:math' as math;
import 'package:flutter/material.dart';

class JapaneseKungFuBackground extends StatefulWidget {
  final Widget child;
  final bool showNimoSign;

  const JapaneseKungFuBackground({
    super.key,
    required this.child,
    this.showNimoSign = false,
  });

  @override
  State<JapaneseKungFuBackground> createState() =>
      _JapaneseKungFuBackgroundState();
}

class _JapaneseKungFuBackgroundState extends State<JapaneseKungFuBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  Offset _pointerPos = Offset.zero; // Normalized -1.0 to 1.0
  Offset _targetPointerPos = Offset.zero;

  // Interactive tap sparkles
  final List<_TapSparkle> _tapSparkles = [];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onPointerMove(PointerEvent event, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    setState(() {
      _targetPointerPos = Offset(
        ((event.position.dx - cx) / cx).clamp(-1.0, 1.0),
        ((event.position.dy - cy) / cy).clamp(-1.0, 1.0),
      );
    });
  }

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _tapSparkles.add(_TapSparkle(
        position: details.localPosition,
        startTime: _animController.value,
      ));
      if (_tapSparkles.length > 8) {
        _tapSparkles.removeAt(0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Smoothly lerp pointer position for silky interactive parallax
    _pointerPos = Offset.lerp(_pointerPos, _targetPointerPos, 0.08)!;

    return MouseRegion(
      onHover: (e) => _onPointerMove(e, size),
      child: Listener(
        onPointerMove: (e) => _onPointerMove(e, size),
        child: GestureDetector(
          onTapDown: _onTapDown,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // ── 1. BACKGROUND PARALLAX LAYER (Deep 3D Image - Nimo Sign Cropped Out!) ─
              Positioned.fill(
                child: Transform.translate(
                  offset: Offset(
                    _pointerPos.dx * -14.0,
                    (widget.showNimoSign ? 0.0 : -170.0) + (_pointerPos.dy * -10.0),
                  ),
                  child: Transform.scale(
                    scale: widget.showNimoSign ? 1.08 : 1.65,
                    child: Image.asset(
                      'assets/images/japanese_garden_bg.png',
                      fit: BoxFit.cover,
                      alignment: widget.showNimoSign
                          ? Alignment.center
                          : const Alignment(0.0, 1.0),
                    ),
                  ),
                ),
              ),

              // ── 2. VOLUMETRIC SUNBEAMS & MIST LAYER ─────────────────────────
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _animController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _SunbeamAndMistPainter(
                        progress: _animController.value,
                        parallaxOffset: _pointerPos,
                      ),
                    );
                  },
                ),
              ),

              // ── 3. FLOATING FALLING MAPLE LEAVES LAYER ─────────────────────
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _animController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _FallingLeavesPainter(
                        progress: _animController.value,
                        parallaxOffset: _pointerPos,
                      ),
                    );
                  },
                ),
              ),

              // ── 4. GLOWING FIREFLIES & MAGIC DUST LAYER ────────────────────
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _animController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _FirefliesPainter(
                        progress: _animController.value,
                        parallaxOffset: _pointerPos,
                      ),
                    );
                  },
                ),
              ),

              // ── 5. INTERACTIVE TAP SPARKLES & RIPPLES LAYER ────────────────
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _animController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _InteractiveTapPainter(
                        sparkles: _tapSparkles,
                        progress: _animController.value,
                      ),
                    );
                  },
                ),
              ),

              // ── 6. FOREGROUND FRAMING & VIGNETTE LAYER (Fast Parallax) ──────
              Positioned.fill(
                child: Transform.translate(
                  offset: Offset(
                    _pointerPos.dx * 12.0,
                    _pointerPos.dy * 8.0,
                  ),
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 1.1,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.15),
                            Colors.black.withValues(alpha: 0.35),
                          ],
                          stops: const [0.6, 0.85, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── 7. MAIN UI CHILD CONTENT OVERLAY ───────────────────────────
              Positioned.fill(child: widget.child),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAP SPARKLE MODEL
// ─────────────────────────────────────────────────────────────────────────────
class _TapSparkle {
  final Offset position;
  final double startTime;

  _TapSparkle({required this.position, required this.startTime});
}

// ─────────────────────────────────────────────────────────────────────────────
// SUNBEAMS & MIST PAINTER
// ─────────────────────────────────────────────────────────────────────────────
class _SunbeamAndMistPainter extends CustomPainter {
  final double progress;
  final Offset parallaxOffset;

  _SunbeamAndMistPainter({
    required this.progress,
    required this.parallaxOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Volumetric Sunbeams in upper-right corner
    final sunX = w * 0.75 + parallaxOffset.dx * -8;
    final sunY = h * 0.12 + parallaxOffset.dy * -6;

    for (int i = 0; i < 5; i++) {
      final angle = (i * 0.22) + math.pi * 0.28;
      final pulse = math.sin((progress * math.pi * 2) + i) * 0.15 + 0.85;

      final rayPath = Path()
        ..moveTo(sunX, sunY)
        ..lineTo(
          sunX + math.cos(angle - 0.08) * w * 0.9,
          sunY + math.sin(angle - 0.08) * h * 0.9,
        )
        ..lineTo(
          sunX + math.cos(angle + 0.08) * w * 0.9,
          sunY + math.sin(angle + 0.08) * h * 0.9,
        )
        ..close();

      canvas.drawPath(
        rayPath,
        Paint()
          ..color = const Color(0xFFFFF9C4).withValues(alpha: 0.06 * pulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15),
      );
    }

    // 2. Animated Floating Mist over ground stream
    final mistY = h * 0.65 + parallaxOffset.dy * -4;
    for (int m = 0; m < 3; m++) {
      final drift = math.sin((progress * math.pi * 2) + (m * 2.0)) * 25.0;
      final mistRect = Rect.fromLTWH(
        -50 + drift,
        mistY + (m * 20),
        w + 100,
        35,
      );

      canvas.drawOval(
        mistRect,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.08 - (m * 0.02))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SunbeamAndMistPainter old) => true;
}

// ─────────────────────────────────────────────────────────────────────────────
// FALLING MAPLE LEAVES PAINTER
// ─────────────────────────────────────────────────────────────────────────────
class _FallingLeavesPainter extends CustomPainter {
  final double progress;
  final Offset parallaxOffset;

  _FallingLeavesPainter({
    required this.progress,
    required this.parallaxOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 12 Maple leaves falling from top right red maple tree
    final leafConfigs = [
      (0.82, 0.05, 0.0, 1.0, 0xFFE53935),
      (0.75, -0.1, 0.15, 0.8, 0xFFC0392B),
      (0.88, -0.05, 0.32, 1.2, 0xFFFF7043),
      (0.68, -0.2, 0.48, 0.9, 0xFFD81B60),
      (0.92, 0.0, 0.60, 1.1, 0xFFE53935),
      (0.78, -0.15, 0.75, 0.7, 0xFFFF8A65),
      (0.85, -0.25, 0.88, 1.0, 0xFFC0392B),
      (0.70, 0.05, 0.08, 1.3, 0xFFE53935),
      (0.95, -0.1, 0.42, 0.85, 0xFFFF7043),
      (0.62, -0.3, 0.55, 1.15, 0xFFD81B60),
    ];

    for (final config in leafConfigs) {
      final baseStartX = w * config.$1;
      final startY = h * config.$2;
      final phase = (progress + config.$3) % 1.0;
      final scale = config.$4;
      final colorHex = config.$5;

      // Downward path with gentle sine sway
      final currentY = startY + (phase * (h * 1.2));
      final sway = math.sin((phase * math.pi * 4) + config.$3) * 35.0;
      final currentX = baseStartX - (phase * (w * 0.35)) + sway + (parallaxOffset.dx * 6);

      if (currentY < 0 || currentY > h) continue;

      final opacity = (math.sin(phase * math.pi) * 0.9).clamp(0.0, 0.9);
      final rotation = phase * math.pi * 6;

      canvas.save();
      canvas.translate(currentX, currentY);
      canvas.rotate(rotation);
      canvas.scale(scale * 2.4);

      // Draw stylized 5-pointed maple leaf shape
      final leafPaint = Paint()
        ..color = Color(colorHex).withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      final leafPath = Path();
      leafPath.moveTo(0, -6);
      leafPath.quadraticBezierTo(2, -4, 5, -5);
      leafPath.quadraticBezierTo(3, -2, 6, 0);
      leafPath.quadraticBezierTo(3, 1, 4, 4);
      leafPath.quadraticBezierTo(1, 2, 0, 6);
      leafPath.quadraticBezierTo(-1, 2, -4, 4);
      leafPath.quadraticBezierTo(-3, 1, -6, 0);
      leafPath.quadraticBezierTo(-3, -2, -5, -5);
      leafPath.quadraticBezierTo(-2, -4, 0, -6);
      leafPath.close();

      canvas.drawPath(leafPath, leafPaint);

      // Stem line
      canvas.drawLine(
        Offset.zero,
        const Offset(0, 8),
        Paint()
          ..color = Colors.brown.shade800.withValues(alpha: opacity * 0.6)
          ..strokeWidth = 0.8,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _FallingLeavesPainter old) => true;
}

// ─────────────────────────────────────────────────────────────────────────────
// FIREFLIES & MAGIC DUST PAINTER
// ─────────────────────────────────────────────────────────────────────────────
class _FirefliesPainter extends CustomPainter {
  final double progress;
  final Offset parallaxOffset;

  _FirefliesPainter({
    required this.progress,
    required this.parallaxOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 18 Glowing Fireflies scattered across garden
    final fireflyPositions = [
      (0.20, 0.45, 0.05, 12.0),
      (0.35, 0.55, 0.18, 9.0),
      (0.48, 0.62, 0.32, 14.0),
      (0.65, 0.48, 0.45, 10.0),
      (0.80, 0.58, 0.58, 11.0),
      (0.15, 0.70, 0.72, 8.0),
      (0.30, 0.38, 0.85, 13.0),
      (0.72, 0.35, 0.92, 10.0),
      (0.55, 0.42, 0.22, 15.0),
      (0.40, 0.75, 0.65, 11.0),
      (0.85, 0.68, 0.38, 9.0),
      (0.25, 0.60, 0.50, 12.0),
      (0.60, 0.70, 0.12, 10.0),
      (0.50, 0.32, 0.78, 13.0),
      (0.10, 0.52, 0.40, 9.0),
    ];

    for (final ff in fireflyPositions) {
      final baseFx = w * ff.$1;
      final baseFy = h * ff.$2;
      final seed = ff.$3;
      final maxRadius = ff.$4;

      // Floating sine wave orbit
      final fx = baseFx + (math.sin((progress * math.pi * 2) + (seed * 10)) * 18.0) + (parallaxOffset.dx * 8);
      final fy = baseFy + (math.cos((progress * math.pi * 3) + (seed * 8)) * 12.0) + (parallaxOffset.dy * 6);

      // Pulsing glow
      final pulse = (math.sin((progress * math.pi * 4) + (seed * 20)) * 0.5 + 0.5);
      final alpha = pulse * 0.85;

      if (alpha < 0.05) continue;

      // Outer radial glow
      canvas.drawCircle(
        Offset(fx, fy),
        maxRadius * (0.8 + (pulse * 0.4)),
        Paint()
          ..color = const Color(0xFFFFD54F).withValues(alpha: alpha * 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );

      // Inner bright halo
      canvas.drawCircle(
        Offset(fx, fy),
        maxRadius * 0.4,
        Paint()
          ..color = const Color(0xFFFFF59D).withValues(alpha: alpha * 0.7)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );

      // Core white light spot
      canvas.drawCircle(
        Offset(fx, fy),
        1.8,
        Paint()..color = Colors.white.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FirefliesPainter old) => true;
}

// ─────────────────────────────────────────────────────────────────────────────
// INTERACTIVE TAP SPARKLE & RIPPLE PAINTER
// ─────────────────────────────────────────────────────────────────────────────
class _InteractiveTapPainter extends CustomPainter {
  final List<_TapSparkle> sparkles;
  final double progress;

  _InteractiveTapPainter({
    required this.sparkles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final tap in sparkles) {
      // Calculate age of tap (0.0 to 1.0)
      double age = progress - tap.startTime;
      if (age < 0) age += 1.0;
      if (age > 0.4) continue; // Fade out after 40% loop time

      final normAge = age / 0.4; // 0.0 to 1.0
      final opacity = (1.0 - normAge).clamp(0.0, 1.0);
      final radius = normAge * 65.0;

      // 1. Expanding Golden Water Ripple Ring
      canvas.drawCircle(
        tap.position,
        radius,
        Paint()
          ..color = const Color(0xFFFFD54F).withValues(alpha: opacity * 0.5)
          ..strokeWidth = 2.5 * (1.0 - normAge)
          ..style = PaintingStyle.stroke,
      );

      // 2. Star Sparkle Burst
      for (int i = 0; i < 8; i++) {
        final angle = (i * math.pi / 4) + (normAge * 0.5);
        final dist = radius * 0.85;
        final sx = tap.position.dx + math.cos(angle) * dist;
        final sy = tap.position.dy + math.sin(angle) * dist;
        final starSize = (1.0 - normAge) * 6.0;

        // Draw 4-point golden star particle
        final starPaint = Paint()
          ..color = const Color(0xFFFFF59D).withValues(alpha: opacity)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke;

        canvas.drawLine(
          Offset(sx - starSize, sy),
          Offset(sx + starSize, sy),
          starPaint,
        );
        canvas.drawLine(
          Offset(sx, sy - starSize),
          Offset(sx, sy + starSize),
          starPaint,
        );

        // Core white dot
        canvas.drawCircle(
          Offset(sx, sy),
          1.5 * (1.0 - normAge),
          Paint()..color = Colors.white.withValues(alpha: opacity),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _InteractiveTapPainter old) => true;
}
