import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  print('Generating 2x high-resolution super-sampled idle frames...');
  final srcDir = Directory('assets/animations/panda/idle');
  final backupDir = Directory('panda/idle/original_87x95');
  if (!backupDir.existsSync()) {
    backupDir.createSync(recursive: true);
  }

  for (int i = 1; i <= 8; i++) {
    final frameNum = i.toString().padLeft(2, '0');
    final srcPath = 'assets/animations/panda/idle/frame_$frameNum.png';
    final backupPath = 'panda/idle/original_87x95/frame_$frameNum.png';

    final file = File(srcPath);
    final bytes = file.readAsBytesSync();
    
    // Backup original
    File(backupPath).writeAsBytesSync(bytes);

    final image = img.decodePng(bytes)!;
    // Resize to 2x (174x190) using cubic interpolation for smooth anti-aliased edges
    final resized = img.copyResize(
      image,
      width: image.width * 2,
      height: image.height * 2,
      interpolation: img.Interpolation.cubic,
    );

    // Save super-sampled frame to assets/animations/panda/idle
    final encoded = img.encodePng(resized);
    file.writeAsBytesSync(encoded);
    print('Frame $frameNum: Original 87x95 (${bytes.length} B) -> 2x Super-sampled 174x190 (${encoded.length} B)');
  }
  print('Super-sampling complete. Originals backed up in panda/idle/original_87x95/');
}
