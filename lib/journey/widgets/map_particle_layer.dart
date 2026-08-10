import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Atmospheric particle system rendering soft floating sakura petals, sumi ink specks,
/// and warm gold dust floating across deep midnight indigo space.
class MapParticleLayer extends StatefulWidget {
  final bool reducedMotion;

  const MapParticleLayer({
    super.key,
    this.reducedMotion = false,
  });

  @override
  State<MapParticleLayer> createState() => _MapParticleLayerState();
}

class _MapParticleLayerState extends State<MapParticleLayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final math.Random _random = math.Random(108);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    );

    // Generate 32 subtle particles (sakura, sumi ink, warm dust)
    for (int i = 0; i < 32; i++) {
      final typeVal = _random.nextDouble();
      _ParticleType type;
      Color color;
      double radius;

      if (typeVal < 0.35) {
        // Restrained subtle sakura petal speck
        type = _ParticleType.sakura;
        color = const Color(0xFFFFCDD2); // Faint soft cherry blossom pink
        radius = 2.2 + _random.nextDouble() * 2.2;
      } else if (typeVal < 0.70) {
        // Sumi ink speck
        type = _ParticleType.ink;
        color = const Color(0xFF2C3545); // Deep slate indigo ink
        radius = 1.4 + _random.nextDouble() * 2.0;
      } else {
        // Gold parchment dust
        type = _ParticleType.goldDust;
        color = const Color(0xFFFFD54F);
        radius = 1.0 + _random.nextDouble() * 1.8;
      }

      _particles.add(_Particle(
        type: type,
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        radius: radius,
        speedY: 0.015 + _random.nextDouble() * 0.04,
        driftX: (_random.nextDouble() - 0.5) * 0.035,
        rotation: _random.nextDouble() * math.pi * 2,
        opacity: 0.12 + _random.nextDouble() * 0.30,
        color: color,
      ));
    }

    if (!widget.reducedMotion) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant MapParticleLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reducedMotion != oldWidget.reducedMotion) {
      if (widget.reducedMotion) {
        _controller.stop();
      } else {
        _controller.repeat();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.reducedMotion) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ParticlePainter(
            particles: _particles,
            progress: _controller.value,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

enum _ParticleType { sakura, ink, goldDust }

class _Particle {
  final _ParticleType type;
  double x;
  double y;
  final double radius;
  final double speedY;
  final double driftX;
  final double rotation;
  final double opacity;
  final Color color;

  _Particle({
    required this.type,
    required this.x,
    required this.y,
    required this.radius,
    required this.speedY,
    required this.driftX,
    required this.rotation,
    required this.opacity,
    required this.color,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlePainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      final currentY = (p.y - progress * p.speedY) % 1.0;
      final currentX = (p.x + math.sin(progress * 2 * math.pi + p.y * 8) * p.driftX) % 1.0;

      final posX = currentX * size.width;
      final posY = currentY * size.height;

      final paint = Paint()
        ..color = p.color.withValues(alpha: p.opacity)
        ..style = PaintingStyle.fill;

      if (p.type == _ParticleType.sakura) {
        // Draw delicate organic petal shape
        canvas.save();
        canvas.translate(posX, posY);
        canvas.rotate(p.rotation + progress * math.pi);

        final petalPath = Path()
          ..moveTo(0, -p.radius * 1.4)
          ..quadraticBezierTo(p.radius, -p.radius * 0.5, p.radius * 0.6, p.radius * 1.2)
          ..quadraticBezierTo(0, p.radius * 1.6, -p.radius * 0.6, p.radius * 1.2)
          ..quadraticBezierTo(-p.radius, -p.radius * 0.5, 0, -p.radius * 1.4)
          ..close();

        canvas.drawPath(petalPath, paint);
        canvas.restore();
      } else {
        // Draw round dust or ink drop
        canvas.drawCircle(Offset(posX, posY), p.radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}
