import 'dart:math' as math;
import 'package:flutter/material.dart';

class StoryMapAnimatedBackground extends StatefulWidget {
  final Widget child;

  const StoryMapAnimatedBackground({
    super.key,
    required this.child,
  });

  @override
  State<StoryMapAnimatedBackground> createState() => _StoryMapAnimatedBackgroundState();
}

class _StoryMapAnimatedBackgroundState extends State<StoryMapAnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final List<_CyanParticle> _particles = [];
  final math.Random _random = math.Random(108);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    // Generate 28 gentle, soothing muted cyan & teal floating particles
    for (int i = 0; i < 28; i++) {
      _particles.add(_CyanParticle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        radius: _random.nextDouble() * 2.8 + 1.2,
        speed: _random.nextDouble() * 0.07 + 0.02,
        opacity: _random.nextDouble() * 0.55 + 0.25,
        phase: _random.nextDouble() * math.pi * 2,
        isTeal: _random.nextBool(),
      ));
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. DEEP NAVY & VIOLET-BLUE & ROYAL BLUE GRADIENT CANVAS
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.15,
                colors: [
                  Color(0xFF1E1B4B), // Violet-Blue center glow
                  Color(0xFF1E293B), // Royal Navy middle
                  Color(0xFF0F172A), // Deep Navy background base
                  Color(0xFF070A12), // Deepest Navy edge
                ],
                stops: [0.0, 0.45, 0.80, 1.0],
              ),
            ),
          ),
        ),

        // 2. SOOTHING FLOATING MUTED CYAN & TEAL PARTICLES & AMBIENT GLOW
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _animController,
            builder: (context, _) {
              return CustomPaint(
                painter: _StoryMapBackgroundPainter(
                  particles: _particles,
                  progress: _animController.value,
                ),
              );
            },
          ),
        ),

        // 3. MAIN UI CONTENT OVERLAY
        Positioned.fill(child: widget.child),
      ],
    );
  }
}

class _CyanParticle {
  double x;
  double y;
  final double radius;
  final double speed;
  final double opacity;
  final double phase;
  final bool isTeal;

  _CyanParticle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.opacity,
    required this.phase,
    required this.isTeal,
  });
}

class _StoryMapBackgroundPainter extends CustomPainter {
  final List<_CyanParticle> particles;
  final double progress;

  _StoryMapBackgroundPainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Soothing Muted Cyan & Royal Blue Central Radial Glow
    final glowPulse = math.sin(progress * math.pi * 2) * 0.15 + 0.85;
    final centerGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF38BDF8).withValues(alpha: 0.10 * glowPulse), // Muted cyan center
          const Color(0xFF4F46E5).withValues(alpha: 0.06 * glowPulse), // Violet-blue middle
          const Color(0xFF0D9488).withValues(alpha: 0.02 * glowPulse), // Teal outer
          Colors.transparent,
        ],
        radius: 0.75,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), centerGlow);

    // 2. Gentle Floating Muted Cyan & Teal Dust Particles
    for (final p in particles) {
      final currentY = (p.y - (progress * p.speed)) % 1.0;
      final px = (p.x * w) + (math.sin((progress * math.pi * 2) + p.phase) * 12.0);
      final py = currentY * h;

      final particleOpacity =
          (p.opacity * (math.sin((progress * math.pi * 2) + p.phase) * 0.25 + 0.75)).clamp(0.1, 0.8);

      final particleColor = p.isTeal ? const Color(0xFF14B8A6) : const Color(0xFF38BDF8);

      final particlePaint = Paint()
        ..color = particleColor.withValues(alpha: particleOpacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);

      canvas.drawCircle(Offset(px, py), p.radius, particlePaint);
    }

    // 3. Subtle Violet-Blue & Teal Corner Arc Accents
    final cornerPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Top-Left Flourish
    canvas.drawArc(
      Rect.fromLTWH(-30, -30, 100, 100),
      0,
      math.pi / 2,
      false,
      cornerPaint,
    );

    // Top-Right Flourish
    canvas.drawArc(
      Rect.fromLTWH(w - 70, -30, 100, 100),
      math.pi / 2,
      math.pi / 2,
      false,
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _StoryMapBackgroundPainter oldDelegate) => true;
}
