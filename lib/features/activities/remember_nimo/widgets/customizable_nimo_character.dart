import 'package:flutter/material.dart';
import '../models/memory_feature.dart';

/// Renders NIMO with configurable features (hairstyle, eyes, expression, accessory, clothing).
class CustomizableNimoCharacter extends StatelessWidget {
  final Map<FeatureCategory, MemoryFeatureOption> features;
  final double size;
  final bool isHidden;

  const CustomizableNimoCharacter({
    super.key,
    required this.features,
    this.size = 180.0,
    this.isHidden = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isHidden) {
      return SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Container(
            width: size * 0.8,
            height: size * 0.8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF14300D).withValues(alpha: 0.15),
              border: Border.all(color: const Color(0xFF85D64B).withValues(alpha: 0.4), width: 3, style: BorderStyle.solid),
            ),
            child: const Icon(
              Icons.question_mark_rounded,
              size: 64,
              color: Color(0xFF85D64B),
            ),
          ),
        ),
      );
    }

    final hair = features[FeatureCategory.hairstyle];
    final eyes = features[FeatureCategory.eyes];
    final exp = features[FeatureCategory.expression];
    final acc = features[FeatureCategory.accessory];
    final cloth = features[FeatureCategory.clothing];

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Drop Shadow
          Positioned(
            bottom: 4,
            child: Container(
              width: size * 0.65,
              height: 14,
              decoration: BoxDecoration(
                color: const Color(0x350F220A),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // 2. Main NIMO Body (Zesty Leaf Green 3D Gradient)
          Container(
            width: size * 0.72,
            height: size * 0.72,
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
                width: 4.0,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xFF4F8528),
                  offset: Offset(0, 6),
                ),
              ],
            ),
          ),

          // 3. Clothing Layer (Bottom)
          if (cloth != null)
            Positioned(
              bottom: size * 0.10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: cloth.color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(cloth.iconData, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      cloth.name,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 4. Face Features Painter (Eyes & Expression)
          CustomPaint(
            size: Size(size * 0.72, size * 0.72),
            painter: _NimoCustomFacePainter(eyes: eyes, exp: exp),
          ),

          // 5. Hairstyle Layer (Top)
          if (hair != null)
            Positioned(
              top: size * 0.06,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: hair.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.2),
                ),
                child: Icon(hair.iconData, color: Colors.white, size: size * 0.22),
              ),
            ),

          // 6. Accessory Layer (Top Overlays)
          if (acc != null)
            Positioned(
              top: size * 0.02,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: acc.color,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white, width: 2.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(acc.iconData, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      acc.name,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NimoCustomFacePainter extends CustomPainter {
  final MemoryFeatureOption? eyes;
  final MemoryFeatureOption? exp;

  _NimoCustomFacePainter({required this.eyes, required this.exp});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Eye sockets
    final eyePaint = Paint()..color = Colors.white;
    final eyeBorderPaint = Paint()
      ..color = const Color(0xFF14300D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    final leftEye = Offset(cx - 16, cy - 8);
    final rightEye = Offset(cx + 16, cy - 8);

    if (eyes?.id == 'eyes_shades') {
      // Shades bar
      final shadesPaint = Paint()..color = const Color(0xFF14300D);
      final rrect = RRect.fromLTRBR(cx - 24, cy - 14, cx + 24, cy - 2, const Radius.circular(6));
      canvas.drawRRect(rrect, shadesPaint);
    } else {
      canvas.drawCircle(leftEye, 11.0, eyePaint);
      canvas.drawCircle(rightEye, 11.0, eyePaint);
      canvas.drawCircle(leftEye, 11.0, eyeBorderPaint);
      canvas.drawCircle(rightEye, 11.0, eyeBorderPaint);

      final pupilPaint = Paint()..color = const Color(0xFF14300D);
      canvas.drawCircle(Offset(leftEye.dx + 1.5, leftEye.dy + 1.5), 6.0, pupilPaint);
      canvas.drawCircle(Offset(rightEye.dx - 1.5, rightEye.dy + 1.5), 6.0, pupilPaint);

      final shinePaint = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(leftEye.dx - 2, leftEye.dy - 3), 2.5, shinePaint);
      canvas.drawCircle(Offset(rightEye.dx - 2, rightEye.dy - 3), 2.5, shinePaint);
    }

    // Expression Mouth
    final mouthPaint = Paint()
      ..color = const Color(0xFF14300D)
      ..style = PaintingStyle.fill;

    final mouthPath = Path();
    if (exp?.id == 'exp_smirk') {
      mouthPath.moveTo(cx - 8, cy + 12);
      mouthPath.quadraticBezierTo(cx + 4, cy + 18, cx + 12, cy + 8);
    } else if (exp?.id == 'exp_open') {
      canvas.drawCircle(Offset(cx, cy + 12), 7.0, mouthPaint);
      return;
    } else {
      mouthPath.moveTo(cx - 12, cy + 8);
      mouthPath.quadraticBezierTo(cx, cy + 20, cx + 12, cy + 8);
    }
    mouthPath.close();
    canvas.drawPath(mouthPath, mouthPaint);
  }

  @override
  bool shouldRepaint(covariant _NimoCustomFacePainter oldDelegate) =>
      oldDelegate.eyes != eyes || oldDelegate.exp != exp;
}
