import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/learning_content.dart';

/// Dynamically discovers chapters and levels from the `assets/` directory
/// using the AssetManifest.
class ContentDiscoveryService {
  static List<LearningChapter>? _cachedChapters;
  static List<String>? _assetPaths;

  /// Known top-level asset directories that are NOT learning content chapters.
  static const _ignoredTopLevelDirs = {
    'images',
    'maps',
    'audio',
    'exploration',
    '1913-game-map',
    'fonts',
  };

  static Future<List<String>> _getAssetPaths() async {
    if (_assetPaths != null) return _assetPaths!;
    debugPrint("ContentDiscoveryService: Loading asset paths...");
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      _assetPaths = manifest.listAssets();
      debugPrint("ContentDiscoveryService: Loaded ${_assetPaths?.length} assets using modern API");
    } catch (e) {
      debugPrint("ContentDiscoveryService: Modern API failed, fallback to JSON: $e");
      // Fallback for older Flutter versions
      final manifestJson = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifest = json.decode(manifestJson);
      _assetPaths = manifest.keys.map((k) => Uri.decodeFull(k)).toList();
      debugPrint("ContentDiscoveryService: Loaded ${_assetPaths?.length} assets using JSON API");
    }
    return _assetPaths!;
  }

  /// Loads, parses, and returns the list of available chapters and their levels.
  /// Result is cached after the first successful load.
  static Future<List<LearningChapter>> discoverContent() async {
    debugPrint("ContentDiscoveryService: discoverContent started");
    if (_cachedChapters != null) {
      debugPrint("ContentDiscoveryService: Returning cached chapters");
      return _cachedChapters!;
    }

    try {
      final assetPaths = await _getAssetPaths();

      // Structure: chapterId -> levelId -> Set<FileName>
      final Map<String, Map<String, Set<String>>> contentTree = {};

      for (final path in assetPaths) {
        // We only care about assets in the 'assets/' folder that match our pattern.
        // E.g., assets/ChapterName/LevelName/filename.ext
        if (!path.startsWith('assets/')) continue;

        final parts = path.split('/');
        if (parts.length < 2) continue;

        final chapterId = parts[1];

        // Skip non-content top-level directories
        if (_ignoredTopLevelDirs.contains(chapterId.toLowerCase())) continue;

        // Register chapter
        if (parts.length >= 3) {
          if (!contentTree.containsKey(chapterId)) {
            contentTree[chapterId] = {};
          }
        }

        if (parts.length >= 4) {
          final levelId = parts[2];

          // Skip COVER_IMG (case-insensitive)
          if (levelId.toLowerCase() == 'cover_img') continue;

          final fileName = parts.sublist(3).join('/');

          if (!contentTree.containsKey(chapterId)) {
            contentTree[chapterId] = {};
          }
          if (!contentTree[chapterId]!.containsKey(levelId)) {
            contentTree[chapterId]![levelId] = {};
          }
          contentTree[chapterId]![levelId]!.add(fileName);
        }
      }

      final List<LearningChapter> chapters = [];

      for (final chapterEntry in contentTree.entries) {
        final chapterId = chapterEntry.key;
        final levelsMap = chapterEntry.value;
        final List<LearningLevel> levels = [];

        for (final levelEntry in levelsMap.entries) {
          final levelId = levelEntry.key;
          final files = levelEntry.value;

          final videoFileName = files.where((f) => f.endsWith('.mp4') || f.endsWith('.mkv') || f.endsWith('.avi')).firstOrNull;
          final hasVideo = videoFileName != null;
          final hasTranscript = files.contains('transcript.json');
          final hasQuestions = files.contains('questions.json');

          // As long as there is a video, the level is playable.
          final isPlayable = hasVideo;

          final level = LearningLevel(
            id: levelId,
            chapterId: chapterId,
            chapterName: _formatName(chapterId),
            levelName: _formatName(levelId),
            videoPath: hasVideo ? 'assets/$chapterId/$levelId/$videoFileName' : 'assets/$chapterId/$levelId/video.mp4',
            transcriptPath: hasTranscript ? 'assets/$chapterId/$levelId/transcript.json' : null,
            questionsPath: hasQuestions ? 'assets/$chapterId/$levelId/questions.json' : null,
            isPlayable: isPlayable,
          );

          levels.add(level);
        }

        // Sort levels naturally (e.g. Netaji_2 comes before Netaji_10)
        levels.sort((a, b) => _compareNatural(a.id, b.id));

        // Only include chapters that have at least one level
        if (levels.isNotEmpty) {
          chapters.add(LearningChapter(
            id: chapterId,
            name: _formatName(chapterId),
            levels: levels,
          ));
        }
      }

      // Sort chapters naturally
      chapters.sort((a, b) => _compareNatural(a.id, b.id));

      _cachedChapters = chapters;
      return chapters;
    } catch (e) {
      // Return empty list on failure
      debugPrint('ContentDiscoveryService: discoverContent failed: $e');
      return [];
    }
  }

  static int _compareNatural(String a, String b) {
    final regex = RegExp(r'(\d+)$');
    final matchA = regex.firstMatch(a);
    final matchB = regex.firstMatch(b);

    if (matchA != null && matchB != null) {
      final numA = int.parse(matchA.group(1)!);
      final numB = int.parse(matchB.group(1)!);
      
      final prefixA = a.substring(0, matchA.start);
      final prefixB = b.substring(0, matchB.start);
      
      final prefixCompare = prefixA.compareTo(prefixB);
      if (prefixCompare != 0) return prefixCompare;
      
      return numA.compareTo(numB);
    }
    return a.compareTo(b);
  }

  static String _formatName(String raw) {
    final parts = raw.split('_');
    if (parts.length > 1) {
      final lastPart = parts.last;
      final number = int.tryParse(lastPart);
      if (number != null) {
        parts[parts.length - 1] = (number + 1).toString();
      }
    }
    
    return parts.map((p) {
      if (p.isEmpty) return p;
      return '${p[0].toUpperCase()}${p.substring(1)}';
    }).join(' ');
  }

  /// Dynamically finds an image asset ignoring its hardcoded extension in JSON.
  /// e.g. jsonPath 'images/netaji.png' might resolve to 'assets/Netaji/Netaji_0/images/netaji.jpg'
  static Future<String?> findImageAsset(String chapterId, String levelId, String jsonPath) async {
    try {
      final assetPaths = await _getAssetPaths();
      
      final lastDot = jsonPath.lastIndexOf('.');
      final basePath = lastDot != -1 ? jsonPath.substring(0, lastDot) : jsonPath;
      final searchPrefix = 'assets/$chapterId/$levelId/$basePath.';

      for (final path in assetPaths) {
        if (path.startsWith(searchPrefix)) {
          return path;
        }
      }
      
      // Case-insensitive fallback
      final lowerSearchPrefix = searchPrefix.toLowerCase();
      for (final path in assetPaths) {
        if (path.toLowerCase().startsWith(lowerSearchPrefix)) {
          return path;
        }
      }

      // Global fallback: if not found in the chapter's folder, search everywhere for the base path
      final lowerBasePath = '${basePath.toLowerCase()}.';
      for (final path in assetPaths) {
        if (path.toLowerCase().contains(lowerBasePath)) {
          return path;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Finds the first image in the COVER_IMG folder for a given chapter.
  static Future<String?> findCoverImage(String chapterId) async {
    try {
      final assetPaths = await _getAssetPaths();
      final searchPrefix = 'assets/$chapterId/COVER_IMG/'.toLowerCase();
      
      debugPrint("ContentDiscoveryService: Searching for cover image for $chapterId with prefix $searchPrefix");

      for (final path in assetPaths) {
        if (path.toLowerCase().contains('cover_img')) {
          debugPrint("ContentDiscoveryService: Found cover_img path in assets: $path");
        }
        
        final lowerPath = path.toLowerCase();
        if (lowerPath.startsWith(searchPrefix) && 
            (lowerPath.endsWith('.jpg') || lowerPath.endsWith('.jpeg') || lowerPath.endsWith('.png') || lowerPath.endsWith('.webp'))) {
          debugPrint("ContentDiscoveryService: MATCHED $path");
          return path;
        }
      }
      
      // Also try case-insensitive for the directory name 'cover_img'
      final altPrefix = 'assets/$chapterId/cover_img/'.toLowerCase();
      for (final path in assetPaths) {
        final lowerPath = path.toLowerCase();
        if (lowerPath.startsWith(altPrefix) &&
            (lowerPath.endsWith('.jpg') || lowerPath.endsWith('.jpeg') || lowerPath.endsWith('.png') || lowerPath.endsWith('.webp'))) {
          debugPrint("ContentDiscoveryService: MATCHED ALT $path");
          return path;
        }
      }
    } catch (e) {
      debugPrint('ContentDiscoveryService: findCoverImage failed for $chapterId: $e');
    }
    debugPrint("ContentDiscoveryService: NO COVER IMAGE FOUND FOR $chapterId");
    return null;
  }

  /// Finds the first image in the images folder for a given level.
  static Future<String?> findLevelImage(String chapterId, String levelId) async {
    try {
      final assetPaths = await _getAssetPaths();
      final searchPrefix = 'assets/$chapterId/$levelId/images/'.toLowerCase();

      for (final path in assetPaths) {
        final lowerPath = path.toLowerCase();
        if (lowerPath.startsWith(searchPrefix) && 
            (lowerPath.endsWith('.jpg') || lowerPath.endsWith('.jpeg') || lowerPath.endsWith('.png') || lowerPath.endsWith('.webp') || lowerPath.endsWith('.avif'))) {
          return path;
        }
      }
      
      // Fallback: look for any image directly in the level folder
      final levelPrefix = 'assets/$chapterId/$levelId/'.toLowerCase();
      for (final path in assetPaths) {
        final lowerPath = path.toLowerCase();
        if (lowerPath.startsWith(levelPrefix) && 
            !lowerPath.contains('/images/') &&
            (lowerPath.endsWith('.jpg') || lowerPath.endsWith('.jpeg') || lowerPath.endsWith('.png') || lowerPath.endsWith('.webp'))) {
          return path;
        }
      }
    } catch (e) {
      debugPrint('ContentDiscoveryService: findLevelImage failed for $chapterId/$levelId: $e');
    }
    return null;
  }
}
