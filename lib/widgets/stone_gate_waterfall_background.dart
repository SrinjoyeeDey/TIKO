import 'dart:math' as math;
import 'package:flutter/material.dart';

class StoneGateWaterfallBackground extends StatefulWidget {
  final Widget child;
  final bool showNimoSign;

  const StoneGateWaterfallBackground({
    super.key,
    required this.child,
    this.showNimoSign = false,
  });

  @override
  State<StoneGateWaterfallBackground> createState() =>
      _StoneGateWaterfallBackgroundState();
}

class _StoneGateWaterfallBackgroundState
    extends State<StoneGateWaterfallBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  Offset _pointerPos = Offset.zero;
  Offset _targetPointerPos = Offset.zero;

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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    _pointerPos = Offset.lerp(_pointerPos, _targetPointerPos, 0.08)!;

    return MouseRegion(
      onHover: (e) => _onPointerMove(e, size),
      child: Listener(
        onPointerMove: (e) => _onPointerMove(e, size),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // 1. BASE HIGH-RES JAPANESE GARDEN BACKGROUND IMAGE (Nimo Sign Cropped Out!)
            Positioned.fill(
              child: Transform.translate(
                offset: Offset(
                  _pointerPos.dx * -10.0,
                  (widget.showNimoSign ? 0.0 : -170.0) + (_pointerPos.dy * -6.0),
                ),
                child: Transform.scale(
                  scale: widget.showNimoSign ? 1.06 : 1.65,
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

            // 2. VOLUMETRIC SUNBEAMS & CANOPY LIGHT
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _JungleSunbeamsPainter(
                      progress: _animController.value,
                      parallaxOffset: _pointerPos,
                    ),
                  );
                },
              ),
            ),

            // 3. DRIFTING SAKURA (CHERRY) PETALS & GLOWING DUST
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _DriftingSakuraPetalsPainter(
                      progress: _animController.value,
                      parallaxOffset: _pointerPos,
                    ),
                  );
                },
              ),
            ),

            // 4. MAIN UI CHILD OVERLAY
            Positioned.fill(child: widget.child),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VOLUMETRIC SUNBEAMS PAINTER
// ─────────────────────────────────────────────────────────────────────────────
class _JungleSunbeamsPainter extends CustomPainter {
  final double progress;
  final Offset parallaxOffset;

  _JungleSunbeamsPainter({
    required this.progress,
    required this.parallaxOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final sunX = w * 0.68 + (parallaxOffset.dx * -6);
    final sunY = h * 0.10 + (parallaxOffset.dy * -4);

    for (int i = 0; i < 4; i++) {
      final angle = (i * 0.25) + math.pi * 0.32;
      final pulse = math.sin((progress * math.pi * 2) + i) * 0.15 + 0.85;

      final rayPath = Path()
        ..moveTo(sunX, sunY)
        ..lineTo(
          sunX + math.cos(angle - 0.09) * w * 0.85,
          sunY + math.sin(angle - 0.09) * h * 0.85,
        )
        ..lineTo(
          sunX + math.cos(angle + 0.09) * w * 0.85,
          sunY + math.sin(angle + 0.09) * h * 0.85,
        )
        ..close();

      canvas.drawPath(
        rayPath,
        Paint()
          ..color = const Color(0xFFFFF59D).withValues(alpha: 0.05 * pulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _JungleSunbeamsPainter old) => true;
}

// ─────────────────────────────────────────────────────────────────────────────
// DRIFTING SAKURA (CHERRY) PETALS PAINTER
// ─────────────────────────────────────────────────────────────────────────────
class _DriftingSakuraPetalsPainter extends CustomPainter {
  final double progress;
  final Offset parallaxOffset;

  _DriftingSakuraPetalsPainter({
    required this.progress,
    required this.parallaxOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final petalConfigs = [
      (0.12, -0.08, 0.02, 0.9, 0xFFFFB7B2),
      (0.28, -0.18, 0.22, 1.2, 0xFFFF8A80),
      (0.42, -0.05, 0.40, 0.7, 0xFFF8BBD0),
      (0.58, -0.15, 0.58, 1.0, 0xFFFFB7B2),
      (0.72, -0.08, 0.72, 1.3, 0xFFFF8A80),
      (0.88, -0.22, 0.88, 0.8, 0xFFF8BBD0),
    ];

    for (final config in petalConfigs) {
      final startX = w * config.$1;
      final startY = h * config.$2;
      final phase = (progress + config.$3) % 1.0;
      final scale = config.$4;
      final colorHex = config.$5;

      final currentY = startY + (phase * (h * 1.15));
      final sway = math.sin((phase * math.pi * 4) + config.$3) * 40.0;
      final currentX = startX + (phase * (w * 0.18)) + sway + (parallaxOffset.dx * 6);

      if (currentY < 0 || currentY > h) continue;

      final opacity = (math.sin(phase * math.pi) * 0.85).clamp(0.0, 0.85);

      canvas.save();
      canvas.translate(currentX, currentY);
      canvas.rotate(phase * math.pi * 5);
      canvas.scale(scale * 1.8);

      final petalPath = Path()
        ..moveTo(0, -6)
        ..cubicTo(4, -4, 6, 2, 0, 8)
        ..cubicTo(-6, 2, -4, -4, 0, -6)
        ..close();

      canvas.drawPath(
        petalPath,
        Paint()
          ..color = Color(colorHex).withValues(alpha: opacity)
          ..style = PaintingStyle.fill,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _DriftingSakuraPetalsPainter old) => true;
}
