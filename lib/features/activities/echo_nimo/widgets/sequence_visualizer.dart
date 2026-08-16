import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../engine/echo_nimo_controller.dart';
import '../models/echo_symbol.dart';

/// Status Banner & Sequence Step dots visualizer for Echo NIMO.
class SequenceVisualizer extends StatelessWidget {
  final EchoNimoPhase phase;
  final int totalTargetSteps;
  final List<EchoSymbol> playerSequence;

  const SequenceVisualizer({
    super.key,
    required this.phase,
    required this.totalTargetSteps,
    required this.playerSequence,
  });

  @override
  Widget build(BuildContext context) {
    final isPlayback = phase == EchoNimoPhase.playback || phase == EchoNimoPhase.generating;
    final isPlayerTurn = phase == EchoNimoPhase.playerTurn;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Turn Status Pill
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: isPlayback ? const Color(0xFF14300D) : const Color(0xFFFFFBF0),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isPlayback ? const Color(0xFF85D64B) : const Color(0xFF85D64B),
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
                isPlayback ? Icons.graphic_eq_rounded : Icons.touch_app_rounded,
                size: 18,
                color: isPlayback ? const Color(0xFF85D64B) : const Color(0xFF14300D),
              ),
              const SizedBox(width: 8),
              Text(
                isPlayback
                    ? 'NIMO IS PLAYING...'
                    : (isPlayerTurn ? 'YOUR TURN! ECHO THE SEQUENCE ⚡' : 'REASONING...'),
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: isPlayback ? Colors.white : const Color(0xFF14300D),
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 2. Step Progress Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(totalTargetSteps, (index) {
            final isFilled = index < playerSequence.length;
            final symbol = isFilled ? playerSequence[index] : null;

            return Container(
              width: 16,
              height: 16,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isFilled ? symbol?.color : const Color(0xFFFFFBF0),
                border: Border.all(
                  color: isFilled ? Colors.white : const Color(0xFFE2D6B5),
                  width: 1.8,
                ),
                boxShadow: isFilled
                    ? [
                        BoxShadow(
                          color: (symbol?.color ?? Colors.green).withValues(alpha: 0.5),
                          blurRadius: 6,
                        ),
                      ]
                    : null,
              ),
            );
          }),
        ),
      ],
    );
  }
}
