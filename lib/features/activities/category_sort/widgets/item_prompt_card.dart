import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/category_item.dart';

/// Item Prompt Display Card for Category Sort.
class ItemPromptCard extends StatelessWidget {
  final CategoryItem? item;

  const ItemPromptCard({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    if (item == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF0),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF85D64B), width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x250F220A),
            offset: Offset(0, 6),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            item!.emoji,
            style: const TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item!.displayName,
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF14300D),
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF85D64B).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.volume_up_rounded,
                  size: 18,
                  color: Color(0xFF4F8528),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
