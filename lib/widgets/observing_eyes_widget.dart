import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Full-Page Observing Happy Eyes Widget
/// Displays giant glowing eyes in a pitch black void that blink open and close slowly,
/// observing the realm with a warm, friendly, happy gaze when scrolled up.
class ObservingEyesWidget extends StatefulWidget {
  const ObservingEyesWidget({super.key});

  @override
  State<ObservingEyesWidget> createState() => _ObservingEyesWidgetState();
}

class _ObservingEyesWidgetState extends State<ObservingEyesWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;
  Offset _pointerOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    // 4.5 second loop for slow, peaceful, happy blinking
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    )..repeat();
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height,
      color: Colors.black,
      child: MouseRegion(
        onHover: (event) {
          final size = MediaQuery.of(context).size;
          setState(() {
            _pointerOffset = Offset(
              (event.position.dx / size.width - 0.5) * 40.0,
              (event.position.dy / size.height - 0.5) * 20.0,
            );
          });
        },
        child: AnimatedBuilder(
          animation: _blinkController,
          builder: (context, child) {
            // Blink curve: Open most of the time, blinks closed slowly between 0.85 and 1.0
            final val = _blinkController.value;
            double openAmount = 1.0;
            if (val > 0.80) {
              final blinkPhase = (val - 0.80) / 0.20;
              openAmount = (math.cos(blinkPhase * math.pi * 2) + 1.0) / 2.0;
            }

            return Stack(
              alignment: Alignment.center,
              children: [
                // 1. Giant Glowing Observing Eyes Custom Painter
                CustomPaint(
                  size: Size(
                    MediaQuery.of(context).size.width,
                    MediaQuery.of(context).size.height * 0.6,
                  ),
                  painter: _HappyBlinkingEyesPainter(
                    openAmount: openAmount,
                    pointerOffset: _pointerOffset,
                  ),
                ),

                // 2. Subtitle Text Below Eyes
                Positioned(
                  bottom: 50,
                  child: Column(
                    children: [
                      Text(
                        'THE GUARDIAN OBSERVES',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4.0,
                          color: const Color(0xFFFFF176).withValues(alpha: 0.85),
                          shadows: const [
                            Shadow(color: Color(0xFFFFD54F), blurRadius: 12),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Watching over your legendary journey with a happy gaze',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.2,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Custom Painter drawing giant glowing happy observing eyes
class _HappyBlinkingEyesPainter extends CustomPainter {
  final double openAmount; // 1.0 = fully open, 0.0 = fully closed
  final Offset pointerOffset;

  _HappyBlinkingEyesPainter({
    required this.openAmount,
    required this.pointerOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final eyeWidth = (size.width * 0.22).clamp(110.0, 240.0);
    final eyeHeight = eyeWidth * 0.65;
    final eyeSpacing = eyeWidth * 0.75;

    final leftEyeCenter = Offset(cx - eyeSpacing, cy);
    final rightEyeCenter = Offset(cx + eyeSpacing, cy);

    _drawEye(canvas, leftEyeCenter, eyeWidth, eyeHeight, isLeft: true);
    _drawEye(canvas, rightEyeCenter, eyeWidth, eyeHeight, isLeft: false);
  }

  void _drawEye(Canvas canvas, Offset center, double width, double height, {required bool isLeft}) {
    final rx = width / 2;
    final ry = (height / 2) * openAmount.clamp(0.05, 1.0);

    final eyeRect = Rect.fromCenter(center: center, width: width, height: height);

    // 1. Warm Golden Ambient Glow (Friendly spirit aura)
    final glowPaint = Paint()
      ..color = const Color(0xFFFFD54F).withValues(alpha: 0.40 * openAmount)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
    canvas.drawOval(eyeRect.inflate(30), glowPaint);

    // 2. Happy Smiling Eyebrows Above Each Eye
    final eyebrowPath = Path();
    final browY = center.dy - height * 0.70;
    eyebrowPath.moveTo(center.dx - rx * 0.8, browY + 6);
    eyebrowPath.quadraticBezierTo(
      center.dx,
      browY - 14, // Curved upward into a happy arch!
      center.dx + rx * 0.8,
      browY + 6,
    );
    final eyebrowPaint = Paint()
      ..color = const Color(0xFFFFF176).withValues(alpha: 0.90 * openAmount)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(eyebrowPath, eyebrowPaint);

    if (openAmount < 0.12) {
      // Closed Eye Curve: Happy Smiling Crescent Arch (⌒ ⌒)
      final happySmilePath = Path();
      happySmilePath.moveTo(center.dx - rx, center.dy + 8);
      happySmilePath.quadraticBezierTo(
        center.dx,
        center.dy - 24, // Arching UPWARDS into a happy smiling eye crescent!
        center.dx + rx,
        center.dy + 8,
      );
      final happySmilePaint = Paint()
        ..color = const Color(0xFFFFF176)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7.0
        ..strokeCap = StrokeCap.round;

      // Glow behind closed happy eyelid
      final smileGlow = Paint()
        ..color = const Color(0xFFFFD54F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawPath(happySmilePath, smileGlow);
      canvas.drawPath(happySmilePath, happySmilePaint);
      return;
    }

    // 3. Crisp Pure White Sclera Fill (Happy Rounded Eye)
    final scleraPath = Path();
    scleraPath.moveTo(center.dx - rx, center.dy);
    scleraPath.quadraticBezierTo(
      center.dx,
      center.dy - ry * 1.35,
      center.dx + rx,
      center.dy,
    );
    scleraPath.quadraticBezierTo(
      center.dx,
      center.dy + ry * 1.35,
      center.dx - rx,
      center.dy,
    );

    // Pure White Clean Eye Base (No yellow tint that looks teary/crying)
    canvas.drawPath(scleraPath, Paint()..color = Colors.white);

    // Deep Dark Outline around Eye Shape
    canvas.drawPath(
      scleraPath,
      Paint()
        ..color = const Color(0xFF1E1005)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5,
    );

    // 4. Large Cute Iris & Pupil (Friendly observing gaze)
    final pupilRadius = rx * 0.52;
    final pupilOffset = Offset(
      center.dx + (pointerOffset.dx * 0.35) + (isLeft ? 4 : -4),
      center.dy + (pointerOffset.dy * 0.25),
    );

    canvas.save();
    canvas.clipPath(scleraPath);

    // Dark Iris Gradient
    final irisPaint = Paint()
      ..shader = RadialGradient(
        colors: const [
          Color(0xFF111111),
          Color(0xFF2C190B),
          Color(0xFF4E342E),
        ],
        stops: const [0.4, 0.8, 1.0],
      ).createShader(Rect.fromCircle(center: pupilOffset, radius: pupilRadius * 1.1));
    canvas.drawCircle(pupilOffset, pupilRadius * 1.1, irisPaint);

    // Dark Central Pupil
    canvas.drawCircle(pupilOffset, pupilRadius * 0.75, Paint()..color = Colors.black);

    // 5. Classic Cute Top-Left Catchlight Glint (Creates happy sparkling eyes, NO bottom tear dots)
    final glintPos = Offset(pupilOffset.dx - pupilRadius * 0.32, pupilOffset.dy - pupilRadius * 0.32);
    canvas.drawCircle(glintPos, pupilRadius * 0.32, Paint()..color = Colors.white);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HappyBlinkingEyesPainter oldDelegate) {
    return oldDelegate.openAmount != openAmount || oldDelegate.pointerOffset != pointerOffset;
  }
}
