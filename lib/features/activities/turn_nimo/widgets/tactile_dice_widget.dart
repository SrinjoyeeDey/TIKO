import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 3D Animated Tactile Dice Button with 6 dice faces.
class TactileDiceWidget extends StatefulWidget {
  final int diceValue; // 0 to 5
  final bool isRolling;
  final bool isInteractive;
  final VoidCallback onRollTap;

  const TactileDiceWidget({
    super.key,
    required this.diceValue,
    required this.isRolling,
    required this.isInteractive,
    required this.onRollTap,
  });

  static const List<String> diceFaces = ['⚀', '⚁', '⚂', '⚃', '⚄', '⚅'];

  @override
  State<TactileDiceWidget> createState() => _TactileDiceWidgetState();
}

class _TactileDiceWidgetState extends State<TactileDiceWidget> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final face = TactileDiceWidget.diceFaces[widget.diceValue.clamp(0, 5)];

    return GestureDetector(
      onTapDown: widget.isInteractive
          ? (_) {
              setState(() => _isPressed = true);
              widget.onRollTap();
            }
          : null,
      onTapUp: widget.isInteractive ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: widget.isInteractive ? () => setState(() => _isPressed = false) : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: widget.isRolling ? const Color(0xFFFFBF27) : const Color(0xFFFFFBF0),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: widget.isInteractive ? const Color(0xFF85D64B) : const Color(0xFFE2D6B5),
                width: widget.isInteractive ? 3.5 : 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.isInteractive
                      ? const Color(0xFF4F8528).withValues(alpha: 0.4)
                      : const Color(0x200F220A),
                  offset: Offset(0, _isPressed ? 3 : 6),
                  blurRadius: widget.isInteractive ? 12 : 6,
                ),
              ],
            ),
            child: Center(
              child: AnimatedRotation(
                turns: widget.isRolling ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Text(
                  face,
                  style: const TextStyle(fontSize: 88, height: 1.0),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (widget.isInteractive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF85D64B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white, width: 1.8),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFF4F8528),
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                'TAP TO ROLL 🎲',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF14300D),
                  letterSpacing: 1.2,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
