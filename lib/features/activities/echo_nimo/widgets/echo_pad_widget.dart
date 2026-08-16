import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/echo_symbol.dart';

/// 3D Tactile Echo Pad Button matching NIMO's monster theme & tactile design.
class EchoPadWidget extends StatefulWidget {
  final EchoSymbol symbol;
  final bool isActivePlayback;
  final bool isInteractive;
  final VoidCallback onTap;
  final double size;

  const EchoPadWidget({
    super.key,
    required this.symbol,
    required this.isActivePlayback,
    required this.isInteractive,
    required this.onTap,
    this.size = 100.0,
  });

  @override
  State<EchoPadWidget> createState() => _EchoPadWidgetState();
}

class _EchoPadWidgetState extends State<EchoPadWidget> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final symbol = widget.symbol;
    final isHighlighted = widget.isActivePlayback || _isPressed;

    return GestureDetector(
      onTapDown: widget.isInteractive
          ? (_) {
              setState(() => _isPressed = true);
              widget.onTap();
            }
          : null,
      onTapUp: widget.isInteractive ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: widget.isInteractive ? () => setState(() => _isPressed = false) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: isHighlighted ? symbol.color : const Color(0xFFFFFBF0),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isHighlighted ? Colors.white : symbol.color,
            width: isHighlighted ? 3.0 : 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isHighlighted ? symbol.color.withValues(alpha: 0.6) : symbol.darkBevelColor.withValues(alpha: 0.35),
              offset: Offset(0, isHighlighted ? 6 : 4),
              blurRadius: isHighlighted ? 12 : 4,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isHighlighted ? 1.25 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: Icon(
                symbol.icon,
                size: widget.size * 0.36,
                color: isHighlighted ? Colors.white : symbol.color,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              symbol.displayName,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: isHighlighted ? Colors.white : const Color(0xFF14300D),
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
