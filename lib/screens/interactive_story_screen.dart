import 'package:flutter/material.dart';
import '../models/interactive_story_models.dart';
import '../services/app_asset_preloader.dart';
import 'story_completion_screen.dart';

/// Modular Interactive Story Screen (Step 9)
/// Features:
/// - Reusable scene rendering (Introduction, Scene 1..N, Fact callouts, Choices)
/// - Warm storybook parchment frame
/// - Smooth scene-to-scene transitions
class InteractiveStoryScreen extends StatefulWidget {
  final StoryData story;

  const InteractiveStoryScreen({
    super.key,
    required this.story,
  });

  @override
  State<InteractiveStoryScreen> createState() => _InteractiveStoryScreenState();
}

class _InteractiveStoryScreenState extends State<InteractiveStoryScreen>
    with SingleTickerProviderStateMixin {
  int _currentSceneIndex = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _nextScene([String? nextSceneId]) {
    if (nextSceneId != null) {
      final targetIndex = widget.story.scenes.indexWhere((s) => s.id == nextSceneId);
      if (targetIndex != -1) {
        _changeScene(targetIndex);
        return;
      }
    }

    if (_currentSceneIndex < widget.story.scenes.length - 1) {
      _changeScene(_currentSceneIndex + 1);
    } else {
      _finishStory();
    }
  }

  void _changeScene(int newIndex) {
    // Precache upcoming scene artwork while child reads/animates
    if (newIndex + 1 < widget.story.scenes.length) {
      final nextScene = widget.story.scenes[newIndex + 1];
      if (nextScene.imagePath != null && nextScene.imagePath!.isNotEmpty) {
        AppAssetPreloader.precacheNextScene(context, nextScene.imagePath!);
      }
    }

    _fadeController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _currentSceneIndex = newIndex;
        });
        _fadeController.forward();
      }
    });
  }

  void _finishStory() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            StoryCompletionScreen(story: widget.story),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentScene = widget.story.scenes[_currentSceneIndex];
    final isLastScene = _currentSceneIndex == widget.story.scenes.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF4ED),
      body: Stack(
        children: [
          // Background Parchment Texture
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFF9F5EC),
                    Color(0xFFF2EA9F),
                    Color(0xFFEADBCE),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header Bar with Back Button & Progress Dots
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back Button
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF3E2A1E)),
                      ),

                      // Story Title & Scene Dots
                      Column(
                        children: [
                          Text(
                            widget.story.title,
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF3E2A1E),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: List.generate(
                              widget.story.scenes.length,
                              (index) => Container(
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: index == _currentSceneIndex ? 16 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: index == _currentSceneIndex
                                      ? const Color(0xFFEF6C6C)
                                      : const Color(0xFFD8C4B4),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(width: 48), // Balance spacing
                    ],
                  ),
                ),

                // Main Story Card Body
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 580),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFDFB),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Scene Artwork Image (Cache-Optimized Decoded Resolution)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.asset(
                                  currentScene.imagePath ?? widget.story.imagePath,
                                  height: 220,
                                  width: double.infinity,
                                  cacheHeight: 440,
                                  fit: BoxFit.cover,
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Narrative Text
                              Text(
                                currentScene.narrativeText,
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  height: 1.5,
                                  color: Color(0xFF2E1C12),
                                ),
                              ),

                              // Historical Fact Callout Box (if present)
                              if (currentScene.historicalFact != null) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFAF4EE),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFE5D5C5), width: 1),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('📜', style: TextStyle(fontSize: 16)),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          currentScene.historicalFact!,
                                          style: const TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF5D4537),
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 24),

                              // Choices or Next Scene Action Button
                              if (currentScene.choices != null && currentScene.choices!.isNotEmpty)
                                Column(
                                  children: currentScene.choices!.map((choice) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8.0),
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFEF6C6C),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                        ),
                                        onPressed: () => _nextScene(choice.nextSceneId),
                                        child: Text(
                                          '${choice.label}  >',
                                          style: const TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                )
                              else
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isLastScene ? const Color(0xFF8A6B46) : const Color(0xFFEF6C6C),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                  ),
                                  onPressed: () => _nextScene(),
                                  child: Text(
                                    isLastScene ? 'Complete Story  ✓' : 'Continue  >',
                                    style: const TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
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
          ),
        ],
      ),
    );
  }
}
