import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../database/progress_repository.dart';
import '../models/learning_content.dart';
import '../services/star_calculator.dart';
import '../widgets/level_clear_animation.dart';

/// Full-screen celebration screen shown after completing a level's questions.
///
/// Displays confetti, animated star rating, and a friendly message.
/// Saves level completion to the local database.
class LevelClearScreen extends StatefulWidget {
  final String childId;
  final LearningLevel level;
  final int totalCorrect;
  final int totalQuestions;

  const LevelClearScreen({
    super.key,
    required this.childId,
    required this.level,
    required this.totalCorrect,
    required this.totalQuestions,
  });

  @override
  State<LevelClearScreen> createState() => _LevelClearScreenState();
}

class _LevelClearScreenState extends State<LevelClearScreen>
    with SingleTickerProviderStateMixin {
  late final ConfettiController _confettiController;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  late final int _stars;
  late final String _message;

  @override
  void initState() {
    super.initState();
    _stars = StarCalculator.calculateStars(
      widget.totalCorrect,
      widget.totalQuestions,
    );
    _message = StarCalculator.getMessage(_stars);

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 5),
    )..play();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    // Start fade-in after a short delay.
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _fadeController.forward();
    });

    // Save completion to database.
    _saveCompletion();
  }

  Future<void> _saveCompletion() async {
    await ProgressRepository.saveLevelCompletion(
      childId: widget.childId,
      chapterId: widget.level.chapterId,
      levelId: widget.level.id,
      stars: _stars,
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Stack(
          children: [
            // Background gradient
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0F0C29),
                    Color(0xFF302B63),
                    Color(0xFF24243E),
                  ],
                ),
              ),
            ),

            // Main content
            SafeArea(
              child: Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),

                        // Sparkle decoration
                        Text(
                          '✨  ⭐  ✨',
                          style: GoogleFonts.outfit(fontSize: 32),
                        ),
                        const SizedBox(height: 24),

                        // YAY! title
                        Text(
                          '🎉 YAY! 🎉',
                          style: GoogleFonts.outfit(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFFFD700),
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Level complete text
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF6C63FF).withValues(alpha: 0.3),
                                const Color(0xFF6C63FF).withValues(alpha: 0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF6C63FF)
                                  .withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            '${widget.level.levelName}\nCOMPLETE!',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.3,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Animated stars
                        LevelClearAnimation(starCount: _stars),
                        const SizedBox(height: 32),

                        // Friendly message
                        Text(
                          _message,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.8),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 48),

                        // Continue button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _onContinue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6C63FF),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 8,
                              shadowColor: const Color(0xFF6C63FF)
                                  .withValues(alpha: 0.5),
                            ),
                            child: Text(
                              'Continue',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Confetti — top center
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                numberOfParticles: 30,
                maxBlastForce: 20,
                minBlastForce: 5,
                emissionFrequency: 0.06,
                gravity: 0.2,
                colors: const [
                  Color(0xFF6C63FF),
                  Color(0xFFFFD700),
                  Color(0xFF4CAF50),
                  Color(0xFFFF6B6B),
                  Color(0xFF00BCD4),
                  Color(0xFFFF9800),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onContinue() {
    // Pop back to the level selection screen.
    // The question screen and video player screen are already on the stack.
    Navigator.of(context).popUntil((route) {
      // Pop until we reach the level selection screen (3rd from top).
      return route.isFirst ||
          route.settings.name == 'level_selection';
    });
    // If popUntil didn't find a named route, pop 3 times.
    if (Navigator.of(context).canPop()) {
      // Already popped enough via popUntil.
    }
  }
}
