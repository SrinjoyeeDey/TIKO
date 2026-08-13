import 'dart:io';
import 'dart:convert';

void main() {
  final pubspec = File('pubspec.yaml').readAsStringSync();
  print('Pubspec contains COVER_IMG: ${pubspec.contains('COVER_IMG')}');
  
  // The AssetManifest is compiled into flutter_assets in the build directory
  final manifestPath = 'build/windows/x64/runner/Debug/data/flutter_assets/AssetManifest.json';
  if (File(manifestPath).existsSync()) {
    final manifestStr = File(manifestPath).readAsStringSync();
    final manifest = json.decode(manifestStr) as Map<String, dynamic>;
    final paths = manifest.keys.where((k) => k.toLowerCase().contains('cover_img')).toList();
    print('Found ${paths.length} COVER_IMG paths:');
    for (var p in paths) {
      print(' - $p');
    }
  } else {
    print('Manifest not found at $manifestPath');
  }
}
