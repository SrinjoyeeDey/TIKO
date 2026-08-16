import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/power_card.dart';

/// Tactical Power Cards Bar for Turn NIMO.
class PowerCardBarWidget extends StatelessWidget {
  final bool isPlayerTurn;
  final PowerCardType? activeCardType;
  final Set<PowerCardType> usedCards;
  final Function(PowerCardType) onCardTap;

  const PowerCardBarWidget({
    super.key,
    required this.isPlayerTurn,
    required this.activeCardType,
    required this.usedCards,
    required this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            'TACTICAL POWER CARDS ⚔️',
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF4F8528),
              letterSpacing: 1.2,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: PowerCard.defaultHand.map((card) {
            final isUsed = usedCards.contains(card.type);
            final isActive = activeCardType == card.type;
            final isEnabled = isPlayerTurn && !isUsed && !isActive;

            return Expanded(
              child: GestureDetector(
                onTap: isEnabled ? () => onCardTap(card.type) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                  decoration: BoxDecoration(
                    color: isUsed
                        ? const Color(0xFFE2D6B5).withValues(alpha: 0.5)
                        : (isActive ? card.color : const Color(0xFFFFFBF0)),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isActive ? Colors.white : (isUsed ? Colors.transparent : card.color),
                      width: isActive ? 2.5 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isUsed
                            ? Colors.transparent
                            : (isActive ? card.color.withValues(alpha: 0.5) : const Color(0x150F220A)),
                        offset: Offset(0, isActive ? 4 : 2),
                        blurRadius: isActive ? 8 : 4,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        card.icon,
                        size: 20,
                        color: isActive ? Colors.white : (isUsed ? Colors.grey : card.color),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        card.title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: isActive ? Colors.white : (isUsed ? Colors.grey : const Color(0xFF14300D)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
