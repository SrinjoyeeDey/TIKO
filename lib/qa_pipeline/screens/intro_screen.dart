import 'package:flutter/material.dart';

import '../../widgets/wooden_back_button.dart';
import '../../widgets/game_textured_text.dart';
import '../widgets/panda_animation_widget.dart';
import 'chapter_selection_screen.dart';
import 'parent_pin_screen.dart';
import 'parent_dashboard.dart';

/// The landing screen with app title, description, and a Start button.
///
/// Now styled to match the base app's Steampunk/Parchment vintage theme.
class IntroScreen extends StatelessWidget {
  final String childId;

  const IntroScreen({super.key, required this.childId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Deep Steampunk Blue
      body: Stack(
        children: [
          // Background Texture/Gradients
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    const Color(0xFF1E293B),
                    const Color(0xFF0F172A),
                    const Color(0xFF000000).withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Top Bar with Back Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      WoodenBackButton(
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
                
                const Spacer(flex: 2),

                // Panda Companion Welcoming Centerpiece
                const Center(
                  child: PandaAnimationWidget(
                    initialState: PandaState.appear,
                    size: 160,
                    showShadow: true,
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                const GameTexturedText(
                  text: 'THE ARCHIVES',
                  fontSize: 38,
                ),
                const SizedBox(height: 16),

                // Subtitle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Unlock the secrets of the past through interactive video records.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.7),
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const Spacer(flex: 3),

                // Start button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ChapterSelectionScreen(childId: childId),
                            settings:
                                const RouteSettings(name: 'chapter_selection'),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        foregroundColor: const Color(0xFF2E1C12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Color(0xFFFFD700), width: 1.5),
                        ),
                        elevation: 12,
                        shadowColor:
                            const Color(0xFFD4AF37).withValues(alpha: 0.4),
                      ),
                      child: const Text(
                        'BEGIN RECORD',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Parent section button
                TextButton.icon(
                  onPressed: () => _openParentSection(context),
                  icon: Icon(Icons.shield_rounded,
                      size: 18,
                      color: Colors.white.withValues(alpha: 0.4)),
                  label: Text(
                    'Overseer Access',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 14,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),

                const Spacer(flex: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openParentSection(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ParentPinScreen(
          onAuthenticated: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => ParentDashboard(childId: childId),
              ),
            );
          },
        ),
      ),
    );
  }
}

