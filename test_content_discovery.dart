import 'dart:convert';
import 'dart:io';

// We will mock rootBundle by reading AssetManifest.json from build directory
Future<void> main() async {
  final manifestFile = File('build/flutter_assets/AssetManifest.json');
  if (!manifestFile.existsSync()) {
    print('Manifest not found at ${manifestFile.path}. Let me search for it.');
    final result = Process.runSync('powershell', ['Get-ChildItem -Recurse -Filter "AssetManifest.json" | Select-Object -First 1 -ExpandProperty FullName']);
    final path = result.stdout.toString().trim();
    if (path.isEmpty) {
      print('Could not find AssetManifest.json anywhere');
      return;
    }
    print('Found manifest at $path');
    await runTest(path);
  } else {
    await runTest(manifestFile.path);
  }
}

Future<void> runTest(String manifestPath) async {
  final manifestJson = File(manifestPath).readAsStringSync();
  final Map<String, dynamic> manifest = json.decode(manifestJson);
  final assetPaths = manifest.keys.map((k) => Uri.decodeFull(k)).toList();

  print('Total assets found: ${assetPaths.length}');
  
  final ignoredTopLevelDirs = {'images', 'maps', 'audio', 'exploration', '1913-game-map', 'fonts'};
  final Map<String, Map<String, Set<String>>> contentTree = {};

  for (final path in assetPaths) {
    if (!path.startsWith('assets/')) continue;
    final parts = path.split('/');
    if (parts.length < 2) continue;

    final chapterId = parts[1];
    if (ignoredTopLevelDirs.contains(chapterId.toLowerCase())) continue;

    if (parts.length >= 3) {
      if (!contentTree.containsKey(chapterId)) {
        contentTree[chapterId] = {};
      }
    }

    if (parts.length >= 4) {
      final levelId = parts[2];
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

  print('\n=== Chapters Discovered ===');
  for (final chapter in contentTree.entries) {
    print('Chapter: ${chapter.key}');
    for (final level in chapter.value.entries) {
      print('  Level: ${level.key}');
      for (final file in level.value) {
        print('    - $file');
      }
    }
  }
  
  print('\n=== Cover Image Test for Netaji ===');
  final chapterId = 'Netaji';
  final searchPrefix = 'assets/$chapterId/COVER_IMG/'.toLowerCase();
  final altPrefix = 'assets/$chapterId/cover_img/'.toLowerCase();
  
  for (final path in assetPaths) {
    final lowerPath = path.toLowerCase();
    if (lowerPath.startsWith(searchPrefix) || lowerPath.startsWith(altPrefix)) {
      if (lowerPath.endsWith('.jpg') || lowerPath.endsWith('.jpeg') || lowerPath.endsWith('.png') || lowerPath.endsWith('.webp')) {
        print('Found cover image: $path');
      }
    }
  }
}
