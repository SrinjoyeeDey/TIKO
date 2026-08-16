import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Radial Particle Explosion & Score Popup on Catch.
class ParticleBurst extends StatefulWidget {
  final Offset position;
  final String text;

  const ParticleBurst({
    super.key,
    required this.position,
    this.text = '+25 XP',
  });

  @override
  State<ParticleBurst> createState() => _ParticleBurstState();
}

class _ParticleBurstState extends State<ParticleBurst>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();

    final random = math.Random();
    for (int i = 0; i < 14; i++) {
      final angle = random.nextDouble() * math.pi * 2;
      final speed = 40.0 + random.nextDouble() * 70.0;
      _particles.add(_Particle(
        angle: angle,
        speed: speed,
        size: 4.0 + random.nextDouble() * 5.0,
        color: [
          const Color(0xFF00F2FE),
          const Color(0xFFFFD700),
          const Color(0xFF4FACFE),
          Colors.white,
        ][random.nextInt(4)],
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        final opacity = (1.0 - progress).clamp(0.0, 1.0);

        return Positioned(
          left: widget.position.dx - 50,
          top: widget.position.dy - 50 - (progress * 30),
          child: Opacity(
            opacity: opacity,
            child: SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(100, 100),
                    painter: _ParticlePainter(_particles, progress),
                  ),
                  Text(
                    widget.text,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFFFD700),
                      shadows: [
                        const Shadow(
                          color: Colors.black87,
                          blurRadius: 6,
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
}

class _Particle {
  final double angle;
  final double speed;
  final double size;
  final Color color;

  _Particle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.color,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlePainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (final p in particles) {
      final distance = p.speed * progress;
      final dx = center.dx + math.cos(p.angle) * distance;
      final dy = center.dy + math.sin(p.angle) * distance;

      final paint = Paint()..color = p.color;
      canvas.drawCircle(Offset(dx, dy), p.size * (1.0 - progress * 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
