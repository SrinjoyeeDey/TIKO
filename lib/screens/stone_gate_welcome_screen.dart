import 'package:flutter/material.dart';
import '../widgets/stone_gate_waterfall_background.dart';
import '../widgets/stone_begin_journey_button.dart';
import '../widgets/game_textured_text.dart';

class StoneGateWelcomeScreen extends StatelessWidget {
  final VoidCallback onBeginJourney;

  const StoneGateWelcomeScreen({
    super.key,
    required this.onBeginJourney,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: StoneGateWaterfallBackground(
        showNimoSign: true,
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 34.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Top Spacing so content starts cleanly BELOW the top wooden NIMO sign board
                  const SizedBox(height: 115),

                  // 1. "WELCOME TO THE" Gamified Title Line 1
                  const GameTexturedText(
                    text: 'WELCOME TO THE',
                    fontSize: 20,
                    letterSpacing: 3.5,
                    strokeWidth: 5.5,
                    gradientColors: [
                      Color(0xFFFFF9C4),
                      Color(0xFFFFD54F),
                      Color(0xFFFFB300),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // 2. "ADVENTUROUS WORLD OF NIMO" Gamified Title Line 2
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const GameTexturedText(
                        text: 'ADVENTUROUS WORLD OF NIMO',
                        fontSize: 20,
                        letterSpacing: 2.2,
                        strokeWidth: 6.0,
                        gradientColors: [
                          Color(0xFFFFFDE7), // Golden ivory top
                          Color(0xFFFFD54F), // Amber gold middle
                          Color(0xFFFF8F00), // Rich gold-orange base
                        ],
                      ),
                      const SizedBox(width: 6),
                      // Glowing Cyan Diamond Crest Gem
                      Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00E5FF),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF00E5FF),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 3. Subtitle: EXPLORE • CHOOSE • DISCOVER
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFFFD54F).withValues(alpha: 0.7),
                        width: 1.4,
                      ),
                    ),
                    child: const Text(
                      'EXPLORE   •   CHOOSE   •   DISCOVER',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.2,
                        fontFamily: 'Outfit',
                        color: Color(0xFFFFF59D),
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // 4. Clickable [ BEGIN JOURNEY ] Stone Tablet Button
                  StoneBeginJourneyButton(
                    width: (size.width * 0.78).clamp(260.0, 330.0),
                    height: 64.0,
                    onTap: onBeginJourney,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
