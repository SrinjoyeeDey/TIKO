import 'package:flutter/material.dart';
import '../data/west_bengal_stories_database.dart';

/// Staged Asset Preloader Service
/// Ensures instant UI rendering without blocking startup or consuming excessive RAM.
class AppAssetPreloader {
  static final Set<String> _precachedAssets = {};

  /// Stage 1: Preload critical first-screen background assets before main UI launch
  static Future<void> precacheBootAssets(BuildContext context) async {
    const bootImages = [
      'assets/images/story_selection_wb_bg.png',
      'assets/images/nimo_japanese_bg_clean.png',
      'assets/images/nimo_child_avatar.png',
      'assets/images/nimo_parent_avatar.png',
    ];

    for (final imagePath in bootImages) {
      if (!_precachedAssets.contains(imagePath)) {
        try {
          await precacheImage(AssetImage(imagePath), context);
          _precachedAssets.add(imagePath);
        } catch (_) {
          // Ignore missing optional assets gracefully
        }
      }
    }

    // Precache all 48 Panda animation PNG frames for instantaneous Frame-1 reaction
    for (final anim in ['idle', 'thinking', 'correct', 'celebrate', 'wrong_sad', 'appear']) {
      for (int i = 1; i <= 8; i++) {
        if (!context.mounted) return;
        final numStr = i.toString().padLeft(2, '0');
        final pandaPath = 'assets/animations/panda/$anim/frame_$numStr.png';
        if (!_precachedAssets.contains(pandaPath)) {
          try {
            await precacheImage(AssetImage(pandaPath), context);
            _precachedAssets.add(pandaPath);
          } catch (_) {}
        }
      }
    }
  }

  /// Stage 2: Intelligently precache state story thumbnails when state is tapped
  static void precacheStateAssets(BuildContext context, String stateId) {
    final collection = IndianStoriesDatabase.getCollectionForState(stateId);
    if (collection == null) return;

    for (final story in collection.stories) {
      // Precache story asset image if present
      if (story.imagePath.isNotEmpty) {
        if (!_precachedAssets.contains(story.imagePath)) {
          precacheImage(
            ResizeImage(
              AssetImage(story.imagePath),
              width: 600, // Optimize decoded width to exact card scale
            ),
            context,
          ).then((_) {
            _precachedAssets.add(story.imagePath);
          }).catchError((_) {});
        }
      }

      // Precache first scene image if present
      if (story.scenes.isNotEmpty) {
        final firstScene = story.scenes.first;
        if (firstScene.imagePath != null && firstScene.imagePath!.isNotEmpty) {
          if (!_precachedAssets.contains(firstScene.imagePath!)) {
            precacheImage(
              ResizeImage(
                AssetImage(firstScene.imagePath!),
                width: 1080, // Optimized scene resolution
              ),
              context,
            ).then((_) {
              _precachedAssets.add(firstScene.imagePath!);
            }).catchError((_) {});
          }
        }
      }
    }
  }

  /// Stage 3: Precache next scene in an active story while child reads current scene
  static void precacheNextScene(BuildContext context, String imagePath) {
    if (imagePath.isEmpty || _precachedAssets.contains(imagePath)) return;
    precacheImage(
      ResizeImage(
        AssetImage(imagePath),
        width: 1080,
      ),
      context,
    ).then((_) {
      _precachedAssets.add(imagePath);
    }).catchError((_) {});
  }
}
