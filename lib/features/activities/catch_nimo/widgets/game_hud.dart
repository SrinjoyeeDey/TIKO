import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Game HUD Header for Catch NIMO Activity matching NIMO Monster Theme.
class GameHud extends StatelessWidget {
  final int currentRound;
  final int totalRounds;
  final int currentLevel;
  final int comboCount;
  final int currentXP;
  final VoidCallback onBackPressed;

  const GameHud({
    super.key,
    required this.currentRound,
    required this.totalRounds,
    required this.currentLevel,
    required this.comboCount,
    required this.currentXP,
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF0), // Warm Cream / Ivory
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF85D64B), width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x300F220A),
            offset: Offset(0, 5),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Back Button (3D Tactile Green)
              GestureDetector(
                onTap: onBackPressed,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF85D64B),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFF4F8528),
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ATTENTION RUN',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF4F8528),
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    'ROUND $currentRound / $totalRounds',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF14300D),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              // Level Badge (Yellow/Orange Tactile)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFBF27),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE89B00), width: 1.8),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xFFB87800),
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  'LVL $currentLevel',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF3A2200),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Combo Pill
              if (comboCount > 1) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF3B63),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFCC1A40), width: 1.8),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFF5C001A),
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    '🔥 $comboCount',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              // XP Counter (Purple Tactile)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFA855F7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF7C23D4), width: 1.8),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xFF2D0A4E),
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⚡', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 4),
                    Text(
                      '$currentXP',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
