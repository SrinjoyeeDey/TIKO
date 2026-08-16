import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../engine/turn_nimo_controller.dart';

/// Status Banner displaying current turn state (NIMO vs Player).
class TurnIndicatorBanner extends StatelessWidget {
  final TurnNimoPhase phase;

  const TurnIndicatorBanner({
    super.key,
    required this.phase,
  });

  @override
  Widget build(BuildContext context) {
    final isNimoTurn = phase == TurnNimoPhase.nimoTurn || phase == TurnNimoPhase.nimoRolling;
    final isPlayerTurn = phase == TurnNimoPhase.playerTurn || phase == TurnNimoPhase.playerRolling;

    final color = isNimoTurn ? const Color(0xFFA855F7) : const Color(0xFF85D64B);
    final text = isNimoTurn
        ? '🤖 NIMO\'S TURN (WAITING...)'
        : (isPlayerTurn ? '🧒 YOUR TURN! ROLL THE DICE 🎲' : 'TURN COMPLETE');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isNimoTurn ? const Color(0xFF14300D) : const Color(0xFFFFFBF0),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color, width: 2.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x250F220A),
            offset: Offset(0, 4),
            blurRadius: 6,
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: isNimoTurn ? Colors.white : const Color(0xFF14300D),
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
