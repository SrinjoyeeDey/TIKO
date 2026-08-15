import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  print('=== DETAILED IDLE FRAME INSPECTION ===');
  for (int i = 1; i <= 8; i++) {
    final frameNum = i.toString().padLeft(2, '0');
    final path = 'assets/animations/panda/idle/frame_$frameNum.png';
    final file = File(path);
    final bytes = file.readAsBytesSync();
    final image = img.decodePng(bytes)!;

    int minX = image.width, minY = image.height, maxX = 0, maxY = 0;
    int nonTransparentPixels = 0;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        if (pixel.a > 10) {
          nonTransparentPixels++;
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;
        }
      }
    }

    final bboxW = maxX - minX + 1;
    final bboxH = maxY - minY + 1;
    print('Frame $frameNum: Canvas=${image.width}x${image.height}, BBox=[($minX,$minY) -> ($maxX,$maxY)], BBoxSize=${bboxW}x$bboxH, NonTransPixels=$nonTransparentPixels');
  }

  print('\n=== CHECKING ALL OTHER STATES BBOX & CANVAS ===');
  for (final state in ['thinking', 'correct', 'celebrate', 'wrong_sad', 'appear']) {
    print('--- State: $state ---');
    for (int i = 1; i <= 8; i++) {
      final frameNum = i.toString().padLeft(2, '0');
      final path = 'assets/animations/panda/$state/frame_$frameNum.png';
      final file = File(path);
      final bytes = file.readAsBytesSync();
      final image = img.decodePng(bytes)!;

      int minX = image.width, minY = image.height, maxX = 0, maxY = 0;
      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          final pixel = image.getPixel(x, y);
          if (pixel.a > 10) {
            if (x < minX) minX = x;
            if (x > maxX) maxX = x;
            if (y < minY) minY = y;
            if (y > maxY) maxY = y;
          }
        }
      }
      final bboxW = maxX - minX + 1;
      final bboxH = maxY - minY + 1;
      print('$state $frameNum: Canvas=${image.width}x${image.height}, BBox=[($minX,$minY) -> ($maxX,$maxY)], BBoxSize=${bboxW}x$bboxH');
    }
  }
}
