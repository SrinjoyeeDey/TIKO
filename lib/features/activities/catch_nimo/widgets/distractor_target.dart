import 'package:flutter/material.dart';

/// Star Distractor Target Widget for Levels 3+.
class DistractorTarget extends StatelessWidget {
  final double size;
  final VoidCallback onTap;

  const DistractorTarget({
    super.key,
    this.size = 75.0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF007F).withValues(alpha: 0.45),
              blurRadius: 18,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: size * 0.8,
              height: size * 0.8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [
                    Color(0xFFFF758C),
                    Color(0xFFFF7EB3),
                    Color(0xFF8E0E00),
                  ],
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.8),
              ),
            ),
            const Icon(
              Icons.star_rounded,
              color: Colors.white,
              size: 38,
            ),
          ],
        ),
      ),
    );
  }
}
