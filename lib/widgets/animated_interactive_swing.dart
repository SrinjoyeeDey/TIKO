import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnimatedInteractiveSwing extends StatefulWidget {
  final double topPadding;
  final double ropeLength;
  final double seatWidth;
  final double seatHeight;

  const AnimatedInteractiveSwing({
    super.key,
    this.topPadding = 216.0, // Fixed directly at bottom edge of NIMO board
    this.ropeLength = 280.0,
    this.seatWidth = 260.0,
    this.seatHeight = 42.0,
  });

  @override
  State<AnimatedInteractiveSwing> createState() =>
      _AnimatedInteractiveSwingState();
}

class _AnimatedInteractiveSwingState extends State<AnimatedInteractiveSwing>
    with SingleTickerProviderStateMixin {
  late AnimationController _idleController;

  // Extra swing displacement induced by drag/tap interaction
  double _extraDisplacement = 0.0;
  double _velocity = 0.0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _idleController.addListener(_updatePhysics);
  }

  void _updatePhysics() {
    if (!_isDragging) {
      // Damped spring oscillation for interactive drag displacement
      final springForce = -12.0 * _extraDisplacement;
      final dampingForce = -2.5 * _velocity;
      final accel = springForce + dampingForce;

      setState(() {
        _velocity += accel * 0.016;
        _extraDisplacement += _velocity * 0.016;
      });
    }
  }

  @override
  void dispose() {
    _idleController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      _velocity = 0.0;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _extraDisplacement += details.delta.dx;
      _extraDisplacement = _extraDisplacement.clamp(-90.0, 90.0);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
      _velocity = details.velocity.pixelsPerSecond.dx / 40.0;
    });
  }

  void _onTap() {
    // Impulse nudge on tap
    setState(() {
      _velocity += 35.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _idleController,
      builder: (context, child) {
        // Natural pendulum idle displacement (-14px to +14px at seat level)
        final idleDisplacement = (math.sin(_idleController.value * math.pi * 2) * 14.0);
        final totalDisplacement = idleDisplacement + _extraDisplacement;

        return Positioned(
          top: widget.topPadding,
          left: 0,
          right: 0,
          child: GestureDetector(
            onTap: _onTap,
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            behavior: HitTestBehavior.translucent,
            child: Center(
              child: SizedBox(
                width: widget.seatWidth + 180,
                height: widget.ropeLength + widget.seatHeight + 50,
                child: CustomPaint(
                  painter: _SwingPainter(
                    ropeLength: widget.ropeLength,
                    seatWidth: widget.seatWidth,
                    seatHeight: widget.seatHeight,
                    swingDisplacement: totalDisplacement,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SWING PAINTER (Fixed top anchors at board + Swaying seat at bottom)
// ─────────────────────────────────────────────────────────────────────────────
class _SwingPainter extends CustomPainter {
  final double ropeLength;
  final double seatWidth;
  final double seatHeight;
  final double swingDisplacement;

  _SwingPainter({
    required this.ropeLength,
    required this.seatWidth,
    required this.seatHeight,
    required this.swingDisplacement,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final topY = 0.0; // FIXED ANCHOR AT BOTTOM EDGE OF NIMO BOARD

    // FIXED TOP ANCHOR POINTS ON THE NIMO BOARD (They NEVER move!)
    final leftTopX = cx - (seatWidth / 2) + 20.0;
    final rightTopX = cx + (seatWidth / 2) - 20.0;

    // SWAYING BOTTOM POINTS AT SEAT LEVEL
    final leftBotX = leftTopX + swingDisplacement;
    final rightBotX = rightTopX + swingDisplacement;

    // Calculate seat tilt angle based on displacement
    final seatAngle = math.atan2(swingDisplacement, ropeLength) * 0.75;
    final seatTopY = topY + ropeLength;

    // 1. Drop shadow under seat (follows seat displacement)
    final shadowX = cx + swingDisplacement;
    final shadowY = seatTopY + seatHeight + 12.0;
    final shadowWidth = seatWidth * 0.95;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(shadowX, shadowY),
          width: shadowWidth,
          height: 14.0,
        ),
        const Radius.circular(10.0),
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // 2. Ropes (Anchored FIXED at topY, swaying at bottom)
    final ropePairs = [
      (Offset(leftTopX, topY), Offset(leftBotX, seatTopY + seatHeight * 0.5)),
      (Offset(rightTopX, topY), Offset(rightBotX, seatTopY + seatHeight * 0.5)),
    ];

    for (final pair in ropePairs) {
      final topPt = pair.$1;
      final botPt = pair.$2;

      // Rope Shadow
      canvas.drawLine(
        topPt + const Offset(2.5, 2),
        botPt + const Offset(2.5, 2),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.2)
          ..strokeWidth = 6.0,
      );

      final ropeRect = Rect.fromLTWH(
        math.min(topPt.dx, botPt.dx) - 5.0,
        topPt.dy,
        (topPt.dx - botPt.dx).abs() + 10.0,
        (botPt.dy - topPt.dy).abs() + 1.0,
      );

      // Main Braided Rope (Anchored firmly at topPt)
      canvas.drawLine(
        topPt,
        botPt,
        Paint()
          ..shader = LinearGradient(
            colors: const [Color(0xFFD4A843), Color(0xFF8B6914), Color(0xFFD4A843)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(ropeRect)
          ..strokeWidth = 5.5,
      );

      // Rope Twist Highlight
      canvas.drawLine(
        topPt,
        botPt,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.22)
          ..strokeWidth = 1.5,
      );

      // FIXED Top Attachment Contact Shadow (under NIMO board edge)
      canvas.drawCircle(
        topPt + const Offset(0, 1.5),
        4.5,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0),
      );

      // Knots ONLY at seat connection points (bottom of ropes)
      for (final ky in [seatTopY - 4, seatTopY + seatHeight + 4]) {
        final kx = botPt.dx;
        canvas.drawCircle(
          Offset(kx, ky),
          5.0,
          Paint()..color = const Color(0xFF7A5520)..style = PaintingStyle.fill,
        );
        canvas.drawCircle(
          Offset(kx, ky),
          5.0,
          Paint()
            ..color = Colors.black.withValues(alpha: 0.18)
            ..strokeWidth = 1.0
            ..style = PaintingStyle.stroke,
        );
      }
    }

    // 3. Wooden Plank Seat Body (Rotates slightly with swing displacement)
    canvas.save();
    canvas.translate(cx + swingDisplacement, seatTopY + (seatHeight / 2));
    canvas.rotate(seatAngle);

    final localSeatRect = Rect.fromCenter(
      center: Offset.zero,
      width: seatWidth,
      height: seatHeight,
    );

    // Beveled outer edge (dark mahogany)
    canvas.drawRRect(
      RRect.fromRectAndRadius(localSeatRect.inflate(2.0), const Radius.circular(10.0)),
      Paint()..color = const Color(0xFF4A2506),
    );

    // Main Warm Chestnut Wood Gradient Fill
    canvas.drawRRect(
      RRect.fromRectAndRadius(localSeatRect, const Radius.circular(8.0)),
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFFE8A048),
            Color(0xFFC07828),
            Color(0xFF956020),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(localSeatRect),
    );

    // 4. Wood Grain & Ring Details
    final grainPaint = Paint()
      ..color = const Color(0xFF6B3808).withValues(alpha: 0.45)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 9; i++) {
      final ringX = (-seatWidth / 2 + 20) + (i * (seatWidth - 40) / 8);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(ringX, 0),
          width: 14.0,
          height: seatHeight * 0.75,
        ),
        grainPaint,
      );
    }

    // 5. Top Edge Sun Highlight
    canvas.drawLine(
      Offset(-seatWidth / 2 + 12, -seatHeight / 2 + 3),
      Offset(seatWidth / 2 - 12, -seatHeight / 2 + 3),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // 6. Cute Corner Moss Patches
    final mossPaint = Paint()
      ..color = const Color(0xFF558B2F).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(-seatWidth / 2 + 10, -seatHeight / 2 + 4), 6.0, mossPaint);
    canvas.drawCircle(Offset(seatWidth / 2 - 12, seatHeight / 2 - 4), 5.0, mossPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SwingPainter old) => true;
}
