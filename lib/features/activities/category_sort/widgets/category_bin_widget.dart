import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/semantic_category.dart';

/// 3D Tactile Category Target Button for FFC Categorization.
class CategoryBinWidget extends StatefulWidget {
  final SemanticCategory category;
  final bool isInteractive;
  final bool isSelected;
  final bool? isCorrect;
  final VoidCallback onTap;

  const CategoryBinWidget({
    super.key,
    required this.category,
    required this.isInteractive,
    required this.isSelected,
    required this.isCorrect,
    required this.onTap,
  });

  @override
  State<CategoryBinWidget> createState() => _CategoryBinWidgetState();
}

class _CategoryBinWidgetState extends State<CategoryBinWidget> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final cat = widget.category;
    final isSelected = widget.isSelected;
    final isCorrect = widget.isCorrect;

    Border border = Border.all(color: Colors.white, width: 2.0);
    if (isSelected) {
      if (isCorrect == true) {
        border = Border.all(color: Colors.white, width: 4.0);
      } else if (isCorrect == false) {
        border = Border.all(color: const Color(0xFFFF3B63), width: 3.5);
      }
    }

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
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: isSelected && isCorrect == false
              ? cat.color.withValues(alpha: 0.5)
              : cat.color,
          borderRadius: BorderRadius.circular(24),
          border: border,
          boxShadow: [
            BoxShadow(
              color: cat.darkBevelColor.withValues(alpha: 0.4),
              offset: Offset(0, _isPressed || isSelected ? 4 : 6),
              blurRadius: isSelected ? 12 : 6,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              cat.emoji,
              style: const TextStyle(fontSize: 36),
            ),
            const SizedBox(height: 6),
            Text(
              cat.displayName,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
