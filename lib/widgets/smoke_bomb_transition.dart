import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Custom PageRouteBuilder performing a slow, buttery-smooth Smoky Sugar-Bomb Era Transition.
/// A puff of fluffy sugar-cloud clouds bursts from the tapped button in its vibrant color,
/// swells across the screen while morphing into the rich dark vintage map sepia tone,
/// and smoothly dissipates outward to reveal the destination 1913 world map with ZERO lag!
class SmokeBombPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Offset originOffset;
  final Color buttonColor;
  final Color vintageMapColor;

  SmokeBombPageRoute({
    required this.page,
    required this.originOffset,
    this.buttonColor = const Color(0xFF94D561), // Vibrant Green / Coral / Pink
    this.vintageMapColor = const Color(0xFF140F0A), // Dark Vintage Sepia Map Color
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 2200), // Smooth 2.2s transition
          reverseTransitionDuration: const Duration(milliseconds: 900),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SmokeBombTransitionOverlay(
              animation: animation,
              originOffset: originOffset,
              buttonColor: buttonColor,
              vintageMapColor: vintageMapColor,
              child: child,
            );
          },
        );
}

/// Overlay Widget driving the optimized 60FPS sugar-bomb cloud animation.
class SmokeBombTransitionOverlay extends StatefulWidget {
  final Animation<double> animation;
  final Offset originOffset;
  final Color buttonColor;
  final Color vintageMapColor;
  final Widget child;

  const SmokeBombTransitionOverlay({
    super.key,
    required this.animation,
    required this.originOffset,
    required this.buttonColor,
    required this.vintageMapColor,
    required this.child,
  });

  @override
  State<SmokeBombTransitionOverlay> createState() =>
      _SmokeBombTransitionOverlayState();
}

class _SmokeBombTransitionOverlayState extends State<SmokeBombTransitionOverlay> {
  late final List<_SugarCloudParticle> _cloudParticles;
  late final List<_SugarDustParticle> _sugarDust;

  @override
  void initState() {
    super.initState();
    _generateParticles();
  }

  void _generateParticles() {
    final rand = math.Random(42); // Seeded for deterministic zero-lag execution
    // 28 fluffy sugar-cloud particles optimized for smooth rendering
    _cloudParticles = List.generate(28, (index) {
      final angle = rand.nextDouble() * math.pi * 2;
      final speed = 150.0 + rand.nextDouble() * 420.0;
      final initialRadius = 35.0 + rand.nextDouble() * 50.0;
      final maxRadius = 200.0 + rand.nextDouble() * 280.0;
      final rotationSpeed = (rand.nextDouble() - 0.5) * 1.4;

      final numLobes = 5 + rand.nextInt(2);
      final lobes = List.generate(numLobes, (l) {
        final lobeAngle = (l / numLobes) * math.pi * 2 + rand.nextDouble() * 0.3;
        final lobeDist = 0.35 + rand.nextDouble() * 0.35;
        return Offset(
          math.cos(lobeAngle) * lobeDist,
          math.sin(lobeAngle) * lobeDist,
        );
      });

      return _SugarCloudParticle(
        angle: angle,
        speed: speed,
        initialRadius: initialRadius,
        maxRadius: maxRadius,
        rotationSpeed: rotationSpeed,
        delay: rand.nextDouble() * 0.15,
        lobes: lobes,
      );
    });

    // 24 floating sugar powder dust sparkles
    _sugarDust = List.generate(24, (index) {
      final angle = rand.nextDouble() * math.pi * 2;
      final dist = 30.0 + rand.nextDouble() * 420.0;
      return _SugarDustParticle(
        offset: Offset(math.cos(angle) * dist, math.sin(angle) * dist),
        size: 3.0 + rand.nextDouble() * 5.0,
        delay: rand.nextDouble() * 0.3,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.animation,
      builder: (context, child) {
        final animVal = widget.animation.value;

        // Smooth Map Fade-In: Starts fading in underneath during cloud cover (0.25 -> 0.65)
        final childOpacity = Curves.easeIn.transform(((animVal - 0.25) / 0.40).clamp(0.0, 1.0));

        return Stack(
          fit: StackFit.expand,
          children: [
            // 1. Destination Vintage 1913 World Map Screen
            Opacity(
              opacity: childOpacity,
              child: widget.child,
            ),

            // 2. High-Performance RepaintBoundary Smoke Overlay
            if (animVal < 0.95)
              RepaintBoundary(
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _SmokySugarBombPainter(
                    animValue: animVal,
                    originOffset: widget.originOffset,
                    buttonColor: widget.buttonColor,
                    vintageMapColor: widget.vintageMapColor,
                    particles: _cloudParticles,
                    sparkles: _sugarDust,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SugarCloudParticle {
  final double angle;
  final double speed;
  final double initialRadius;
  final double maxRadius;
  final double rotationSpeed;
  final double delay;
  final List<Offset> lobes;

  _SugarCloudParticle({
    required this.angle,
    required this.speed,
    required this.initialRadius,
    required this.maxRadius,
    required this.rotationSpeed,
    required this.delay,
    required this.lobes,
  });
}

class _SugarDustParticle {
  final Offset offset;
  final double size;
  final double delay;

  _SugarDustParticle({
    required this.offset,
    required this.size,
    required this.delay,
  });
}

/// CustomPainter rendering smooth 60FPS sugar-bomb clouds with dark map color morphing
class _SmokySugarBombPainter extends CustomPainter {
  final double animValue;
  final Offset originOffset;
  final Color buttonColor;
  final Color vintageMapColor;
  final List<_SugarCloudParticle> particles;
  final List<_SugarDustParticle> sparkles;

  _SmokySugarBombPainter({
    required this.animValue,
    required this.originOffset,
    required this.buttonColor,
    required this.vintageMapColor,
    required this.particles,
    required this.sparkles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final origin = originOffset == Offset.zero
        ? Offset(size.width / 2, size.height / 2)
        : originOffset;

    // Smooth overall curtain opacity: Swells in, holds, dissipates out gracefully
    double curtainAlpha = 1.0;
    if (animValue < 0.30) {
      curtainAlpha = (animValue / 0.30).clamp(0.0, 1.0);
    } else if (animValue > 0.60) {
      curtainAlpha = (1.0 - (animValue - 0.60) / 0.35).clamp(0.0, 1.0);
    }

    if (curtainAlpha <= 0.01) return;

    // Color morphing: Button Color -> Rich Dark Vintage Map Sepia (#140F0A / #24190F)
    final colorMorphT = ((animValue - 0.10) / 0.45).clamp(0.0, 1.0);
    final curCloudColor = Color.lerp(
      buttonColor,
      vintageMapColor,
      Curves.easeInOutCubic.transform(colorMorphT),
    )!;

    final cloudHighlightColor = Color.lerp(
      curCloudColor,
      const Color(0xFFF4E8C1), // Warm parchment highlight on cloud tops
      0.35,
    )!;

    final darkMapCore = Color.lerp(
      buttonColor.withValues(alpha: 0.7),
      const Color(0xFF0F0D0B), // Exact dark 1913 map background color
      colorMorphT,
    )!;

    // ─── 1. BUTTON EXPLOSION RING ───
    if (animValue < 0.40) {
      final ringT = (animValue / 0.40).clamp(0.0, 1.0);
      final ringRadius = 25.0 + ringT * math.max(size.width, size.height) * 0.7;
      final ringOpacity = (1.0 - ringT).clamp(0.0, 1.0) * 0.50 * curtainAlpha;

      final ringPaint = Paint()
        ..color = buttonColor.withValues(alpha: ringOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18.0 * (1.0 - ringT * 0.5);

      canvas.drawCircle(origin, ringRadius, ringPaint);
    }

    // ─── 2. DARK VINTAGE MAP AMBIENT VIGNETTE ───
    final bgOpacity = (curtainAlpha * 0.92).clamp(0.0, 0.96);
    final bgGradient = RadialGradient(
      center: Alignment(
        (origin.dx / size.width) * 2 - 1,
        (origin.dy / size.height) * 2 - 1,
      ),
      radius: 0.35 + animValue * 1.1,
      colors: [
        curCloudColor.withValues(alpha: bgOpacity),
        darkMapCore.withValues(alpha: bgOpacity * 0.95),
        const Color(0xFF0A0806).withValues(alpha: bgOpacity * 0.92),
      ],
      stops: const [0.0, 0.55, 1.0],
    );

    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = bgGradient.createShader(Offset.zero & size),
    );

    // ─── 3. FLUFFY 3D SUGAR CLOUD PARTICLES ───
    for (final p in particles) {
      final pAnim = ((animValue - p.delay) / (1.0 - p.delay)).clamp(0.0, 1.0);
      if (pAnim <= 0.0) continue;

      final expandCurve = Curves.easeOutCubic.transform((pAnim / 0.65).clamp(0.0, 1.0));
      final upwardDrift = pAnim * -35.0;
      final dist = p.speed * expandCurve * (0.55 + animValue * 0.45);
      final pPos = Offset(
        origin.dx + math.cos(p.angle) * dist,
        origin.dy + math.sin(p.angle) * dist + upwardDrift,
      );

      final currentRadius = (p.initialRadius + (p.maxRadius - p.initialRadius) * expandCurve);
      final particleAlpha = curtainAlpha * (0.85 * (1.0 - (pAnim - 0.60) / 0.40).clamp(0.0, 1.0));
      if (particleAlpha <= 0.01) continue;

      canvas.save();
      canvas.translate(pPos.dx, pPos.dy);
      canvas.rotate(p.rotationSpeed * pAnim * math.pi);

      // Cloud path
      final cloudPath = Path();
      for (int i = 0; i < p.lobes.length; i++) {
        final lobeOffset = p.lobes[i] * currentRadius * 0.55;
        final lobeRadius = currentRadius * (0.55 + (i % 3) * 0.15);
        cloudPath.addOval(Rect.fromCircle(center: lobeOffset, radius: lobeRadius));
      }

      // Fast single-pass 3D Radial Shader for cloud puff (Zero Lag)
      final cloudFillPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.4),
          radius: 0.9,
          colors: [
            cloudHighlightColor.withValues(alpha: particleAlpha * 0.90),
            curCloudColor.withValues(alpha: particleAlpha * 0.85),
            darkMapCore.withValues(alpha: particleAlpha * 0.70),
          ],
          stops: const [0.0, 0.50, 1.0],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: currentRadius * 1.2));

      canvas.drawPath(cloudPath, cloudFillPaint);
      canvas.restore();
    }

    // ─── 4. GOLDEN DUST STARDUST SPARKLES ───
    if (colorMorphT > 0.08) {
      final dustAlpha = (colorMorphT * curtainAlpha).clamp(0.0, 1.0);
      for (final sp in sparkles) {
        final spAnim = ((animValue - sp.delay) / (1.0 - sp.delay)).clamp(0.0, 1.0);
        if (spAnim <= 0.0 || spAnim >= 0.88) continue;

        final pos = origin + sp.offset * (0.35 + spAnim * 0.75) + Offset(0, spAnim * -25.0);
        final starPaint = Paint()..color = const Color(0xFFFFD54F).withValues(alpha: dustAlpha * 0.80);

        final sSize = sp.size * (1.0 + math.sin(spAnim * math.pi * 3) * 0.25);
        final starPath = Path()
          ..moveTo(pos.dx, pos.dy - sSize)
          ..quadraticBezierTo(pos.dx, pos.dy, pos.dx + sSize, pos.dy)
          ..quadraticBezierTo(pos.dx, pos.dy, pos.dx, pos.dy + sSize)
          ..quadraticBezierTo(pos.dx, pos.dy, pos.dx - sSize, pos.dy)
          ..quadraticBezierTo(pos.dx, pos.dy, pos.dx, pos.dy - sSize)
          ..close();

        canvas.drawPath(starPath, starPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SmokySugarBombPainter oldDelegate) {
    return oldDelegate.animValue != animValue ||
        oldDelegate.originOffset != originOffset ||
        oldDelegate.buttonColor != buttonColor ||
        oldDelegate.vintageMapColor != vintageMapColor;
  }
}
