import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Friendly NIMO Monster Character matching the Sego Concept & Monster Theme.
class NimoCharacter extends StatefulWidget {
  final double size;
  final VoidCallback onTap;
  final bool isCaught;

  const NimoCharacter({
    super.key,
    this.size = 90.0,
    required this.onTap,
    this.isCaught = false,
  });

  @override
  State<NimoCharacter> createState() => _NimoCharacterState();
}

class _NimoCharacterState extends State<NimoCharacter>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounceController,
      builder: (context, child) {
        final bounceOffset = math.sin(_bounceController.value * math.pi) * 6.0;
        final scale = widget.isCaught ? 1.3 : (1.0 + math.sin(_bounceController.value * math.pi) * 0.05);

        return Transform.translate(
          offset: Offset(0, -bounceOffset),
          child: Transform.scale(
            scale: scale,
            child: GestureDetector(
              onTap: widget.onTap,
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 1. 3D Monster Drop Shadow
                    Positioned(
                      bottom: 2,
                      child: Container(
                        width: widget.size * 0.65,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0x350F220A),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    // 2. Main Monster Body (Zesty Leaf Green 3D Gradient)
                    Container(
                      width: widget.size * 0.85,
                      height: widget.size * 0.85,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF98E65B),
                            Color(0xFF85D64B),
                            Color(0xFF65B52E),
                          ],
                        ),
                        border: Border.all(
                          color: const Color(0xFFB5F28A),
                          width: 3.5,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0xFF4F8528),
                            offset: Offset(0, 6),
                            blurRadius: 0, // 3D Tactile bevel
                          ),
                        ],
                      ),
                    ),

                    // 3. Cute Monster Ears / Little Horns
                    Positioned(
                      top: 4,
                      left: widget.size * 0.18,
                      child: _buildMonsterEar(angle: -0.3),
                    ),
                    Positioned(
                      top: 4,
                      right: widget.size * 0.18,
                      child: _buildMonsterEar(angle: 0.3),
                    ),

                    // 4. Monster Eyes & Cute Mouth Painter
                    CustomPaint(
                      size: Size(widget.size * 0.85, widget.size * 0.85),
                      painter: _MonsterFacePainter(isCaught: widget.isCaught),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonsterEar({required double angle}) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: 14,
        height: 18,
        decoration: BoxDecoration(
          color: const Color(0xFFFFBF27),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE89B00), width: 2),
        ),
      ),
    );
  }
}

class _MonsterFacePainter extends CustomPainter {
  final bool isCaught;

  _MonsterFacePainter({required this.isCaught});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Big White Monster Eye Sockets
    final eyePaint = Paint()..color = Colors.white;
    final eyeBorderPaint = Paint()
      ..color = const Color(0xFF14300D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final leftEyePos = Offset(cx - 13, cy - 6);
    final rightEyePos = Offset(cx + 13, cy - 6);

    canvas.drawCircle(leftEyePos, 10.0, eyePaint);
    canvas.drawCircle(rightEyePos, 10.0, eyePaint);
    canvas.drawCircle(leftEyePos, 10.0, eyeBorderPaint);
    canvas.drawCircle(rightEyePos, 10.0, eyeBorderPaint);

    // Dark Pupils
    final pupilPaint = Paint()..color = const Color(0xFF14300D);
    canvas.drawCircle(Offset(leftEyePos.dx + (isCaught ? 0 : 1.5), leftEyePos.dy + 1.5), 5.5, pupilPaint);
    canvas.drawCircle(Offset(rightEyePos.dx + (isCaught ? 0 : -1.5), rightEyePos.dy + 1.5), 5.5, pupilPaint);

    // Eye Shine Dots
    final shinePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(leftEyePos.dx - 1.5, leftEyePos.dy - 2.5), 2.2, shinePaint);
    canvas.drawCircle(Offset(rightEyePos.dx - 1.5, rightEyePos.dy - 2.5), 2.2, shinePaint);

    // Cheerful Monster Mouth
    final mouthPaint = Paint()
      ..color = const Color(0xFF14300D)
      ..style = PaintingStyle.fill;

    final mouthPath = Path()
      ..moveTo(cx - 10, cy + 8)
      ..quadraticBezierTo(cx, cy + 18, cx + 10, cy + 8)
      ..close();

    canvas.drawPath(mouthPath, mouthPaint);

    // Little Cute Monster Tooth
    final toothPaint = Paint()..color = Colors.white;
    final toothPath = Path()
      ..moveTo(cx - 4, cy + 8)
      ..lineTo(cx - 1, cy + 13)
      ..lineTo(cx + 2, cy + 8)
      ..close();

    canvas.drawPath(toothPath, toothPaint);
  }

  @override
  bool shouldRepaint(covariant _MonsterFacePainter oldDelegate) =>
      oldDelegate.isCaught != isCaught;
}
