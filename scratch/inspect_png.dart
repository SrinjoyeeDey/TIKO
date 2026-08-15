import 'dart:io';
import 'dart:typed_data';

void main() {
  final baseDir = Directory('assets/animations/panda');
  final dirs = baseDir.listSync().whereType<Directory>().toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  for (final dir in dirs) {
    final folderName = dir.path.split(Platform.pathSeparator).last;
    print('=== Folder: $folderName ===');
    final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.png')).toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    for (final file in files) {
      final bytes = file.readAsBytesSync();
      if (bytes.length > 24) {
        final byteData = ByteData.sublistView(bytes);
        final width = byteData.getUint32(16);
        final height = byteData.getUint32(20);
        final bitDepth = bytes[24];
        final colorType = bytes[25];
        final fileName = file.path.split(Platform.pathSeparator).last;
        print('$fileName: ${width}x${height}, bitDepth=$bitDepth, colorType=$colorType, fileBytes=${bytes.length}');
      }
    }
  }
}
