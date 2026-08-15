import 'package:flutter/material.dart';
import '../models/interactive_story_models.dart';
import '../data/west_bengal_stories_database.dart';
import '../qa_pipeline/widgets/panda_animation_widget.dart';
import 'state_story_collection_screen.dart';

/// Quiet & Accomplished Story Completion Screen (Step 10 & 11)
/// Features:
/// - Muted parchment & warm desaturated tones
/// - Soft gold accents & subtle vignette
/// - No giant "FINISH" stamps or arcade noise
/// - Sense of meaningful discovery
class StoryCompletionScreen extends StatefulWidget {
  final StoryData story;

  const StoryCompletionScreen({
    super.key,
    required this.story,
  });

  @override
  State<StoryCompletionScreen> createState() => _StoryCompletionScreenState();
}

class _StoryCompletionScreenState extends State<StoryCompletionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // Mark story completed in database
    IndianStoriesDatabase.markStoryCompleted(widget.story.id);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _returnToMap() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _returnToCollection() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            StateStoryCollectionScreen(stateId: widget.story.stateId),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EB), // Muted parchment background
      body: Stack(
        children: [
          // Subtle Vignette Background overlay
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.9,
                  colors: [
                    Color(0xFFFAF6EE),
                    Color(0xFFECE4D5),
                    Color(0xFFDDD2C0),
                  ],
                ),
              ),
            ),
          ),

          // Main Quiet Completion Container
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 460),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFDF8),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.6), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Celebrating Panda Companion
                        const PandaAnimationWidget(
                          initialState: PandaState.celebrate,
                          size: 130,
                          showShadow: true,
                        ),

                        const SizedBox(height: 12),

                        // Subtle Check Circle
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFF5EBE0),
                            border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.check_rounded,
                              color: Color(0xFF9E7B27),
                              size: 32,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Header Text: STORY COMPLETE
                        const Text(
                          'STORY COMPLETE',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3.0,
                            color: Color(0xFF4A382C),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Story Title
                        Text(
                          widget.story.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF6D5547),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Emotion Tagline
                        const Text(
                          '“You discovered a story from India’s past.”',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF8D705C),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Soft Gold Stars
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (index) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(
                                Icons.star_rounded,
                                color: Color(0xFFD4AF37),
                                size: 24,
                              ),
                            );
                          }),
                        ),

                        const SizedBox(height: 36),

                        // Action Buttons: [ YOUR JOURNEY ] and [ CONTINUE ]
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Return to Map
                            OutlinedButton(
                              onPressed: _returnToMap,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFB09B82), width: 1.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              ),
                              child: const Text(
                                'YOUR JOURNEY',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF5D4537),
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),

                            const SizedBox(width: 14),

                            // Return to Collection
                            ElevatedButton(
                              onPressed: _returnToCollection,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8A6B46),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                                elevation: 2,
                              ),
                              child: const Text(
                                'CONTINUE',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
