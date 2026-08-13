import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 3D Elevated Block Platform & Adventurer Character Widget
/// Displays 3D elevated stone blocks/steps on the ground floor stage
/// with the fantasy traveler character (holding staff, accompanied by black cat)
/// standing on top looking left towards the India map.
class AdventurerPlatformWidget extends StatefulWidget {
  final Offset screenPosition; // 2D projected screen position on ground stage
  final double scale;

  const AdventurerPlatformWidget({
    super.key,
    required this.screenPosition,
    this.scale = 1.0,
  });

  @override
  State<AdventurerPlatformWidget> createState() => _AdventurerPlatformWidgetState();
}

class _AdventurerPlatformWidgetState extends State<AdventurerPlatformWidget>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _windController;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _windController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _glowController.dispose();
    _windController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseScale = widget.scale.clamp(0.8, 1.8);
    final platformWidth = 190.0 * baseScale;
    final platformHeight = 110.0 * baseScale;
    final characterHeight = 270.0 * baseScale;

    final hoverScale = _isHovered ? 1.06 : 1.0;

    return Positioned(
      left: widget.screenPosition.dx - (platformWidth / 2),
      top: widget.screenPosition.dy - platformHeight - (characterHeight * 0.75),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          transform: Matrix4.diagonal3Values(hoverScale, hoverScale, 1.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Stack combining 3D Elevated Stone Pedestal + Child Hero Character Asset
              SizedBox(
                width: platformWidth * 1.5,
                height: characterHeight + 40,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    // Ground Drop Shadow
                    Positioned(
                      bottom: 8,
                      child: Container(
                        width: platformWidth * 0.8,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2C190B).withValues(alpha: 0.60),
                              blurRadius: 16,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Young Child Hero Character Asset (Back-view facing map, red cape waving in wind, on elevated stone blocks)
                    AnimatedBuilder(
                      animation: _windController,
                      builder: (context, child) {
                        final floatY = math.sin(_windController.value * 2 * math.pi) * 3.0;

                        return Positioned(
                          bottom: 12 + floatY,
                          child: Image.asset(
                            'assets/images/adventurer_character.png',
                            height: characterHeight,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: characterHeight,
                                width: 120,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.person_pin_circle_rounded,
                                  size: 60,
                                  color: Color(0xFFFFD54F),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
