import 'package:flutter/material.dart';

/// Premium compact button ("PROCEED →") styled exactly after Reference Image Panel 6.
/// Features a sleek deep midnight-blue pill container, double gold bevel border, and golden typography.
class ProceedButton extends StatefulWidget {
  final VoidCallback onTap;
  final String label;
  final bool isVisible;

  const ProceedButton({
    super.key,
    required this.onTap,
    this.label = 'PROCEED  →',
    this.isVisible = true,
  });

  @override
  State<ProceedButton> createState() => _ProceedButtonState();
}

class _ProceedButtonState extends State<ProceedButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 500),
      opacity: widget.isVisible ? 1.0 : 0.0,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 150),
        scale: _isPressed ? 0.94 : 1.0,
        child: AnimatedBuilder(
          animation: _glowController,
          builder: (context, child) {
            final glowAlpha = 0.25 + _glowController.value * 0.35;
            final glowBlur = 8.0 + _glowController.value * 6.0;

            return GestureDetector(
              onTapDown: (_) => setState(() => _isPressed = true),
              onTapUp: (_) {
                setState(() => _isPressed = false);
                widget.onTap();
              },
              onTapCancel: () => setState(() => _isPressed = false),
              child: Container(
                width: 175,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(21),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF162847), // Deep navy top highlight
                      Color(0xFF0F1E36), // Midnight blue body
                      Color(0xFF081120), // Dark shadow bottom
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  border: Border.all(
                    color: const Color(0xFFD4AF37), // Metallic Gold rim
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD4AF37).withValues(alpha: glowAlpha),
                      blurRadius: glowBlur,
                      spreadRadius: 1,
                    ),
                    const BoxShadow(
                      color: Colors.black54,
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.label,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.2,
                          color: Color(0xFFF5D061), // Warm Gold Text
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              offset: Offset(1, 1),
                              blurRadius: 2,
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
        ),
      ),
    );
  }
}
