import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../engine/find_nimo_controller.dart';

/// Status Banner & Search Step indicators visualizer for Find NIMO.
class SearchProgressVisualizer extends StatelessWidget {
  final FindNimoPhase phase;
  final int currentSearchStepIndex;
  final int totalSearchSteps;

  const SearchProgressVisualizer({
    super.key,
    required this.phase,
    required this.currentSearchStepIndex,
    required this.totalSearchSteps,
  });

  @override
  Widget build(BuildContext context) {
    final isPreview = phase == FindNimoPhase.previewing || phase == FindNimoPhase.hiding;
    final isSearching = phase == FindNimoPhase.searching;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Turn Status Banner
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: isPreview ? const Color(0xFF14300D) : const Color(0xFFFFFBF0),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF85D64B),
              width: 2.0,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x250F220A),
                offset: Offset(0, 4),
                blurRadius: 6,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPreview ? Icons.visibility_rounded : Icons.search_rounded,
                size: 18,
                color: isPreview ? const Color(0xFF85D64B) : const Color(0xFF14300D),
              ),
              const SizedBox(width: 8),
              Text(
                isPreview
                    ? 'MEMORIZE NIMO\'S LOCATION! 🧠'
                    : (isSearching ? 'WHERE WAS NIMO? 🔍' : 'REASONING...'),
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: isPreview ? Colors.white : const Color(0xFF14300D),
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // 2. Multi-Search Step Indicators
        if (totalSearchSteps > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(totalSearchSteps, (index) {
              final isCompleted = index < currentSearchStepIndex;
              final isCurrent = index == currentSearchStepIndex;

              return Container(
                width: 14,
                height: 14,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? const Color(0xFF85D64B)
                      : (isCurrent ? const Color(0xFFFFBF27) : const Color(0xFFFFFBF0)),
                  border: Border.all(
                    color: isCurrent ? const Color(0xFFE89B00) : const Color(0xFFE2D6B5),
                    width: 1.8,
                  ),
                ),
              );
            }),
          ),
      ],
    );
  }
}
