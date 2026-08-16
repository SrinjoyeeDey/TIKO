import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Level video prioritization logic', () {
    final files = {
      'images/video1.mp4',
      'questions.json',
      'transcript.json',
      'video.mp4',
    };

    final directVideos = files
        .where((f) => !f.contains('/') && (f.endsWith('.mp4') || f.endsWith('.mkv') || f.endsWith('.avi')))
        .toList();

    final videoFileName = (directVideos.contains('video.mp4') ? 'video.mp4' : directVideos.firstOrNull)
        ?? files.where((f) => f.endsWith('.mp4') || f.endsWith('.mkv') || f.endsWith('.avi')).firstOrNull;

    expect(videoFileName, equals('video.mp4'));
  });
}
