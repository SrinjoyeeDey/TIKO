import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/transcript_segment.dart';

/// Loads and parses transcript JSON files from the app's asset bundle.
class TranscriptService {
  /// Loads transcript segments from the asset at [assetPath].
  ///
  /// Returns an empty list if [assetPath] is `null`, the file is missing,
  /// the JSON is malformed, or the segments array is absent/empty.
  static Future<List<TranscriptSegment>> loadTranscript(
      String? assetPath) async {
    if (assetPath == null) return [];

    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      final segmentsJson = jsonData['segments'];
      if (segmentsJson == null || segmentsJson is! List) {
        return [];
      }

      final segments = segmentsJson
          .map((s) => TranscriptSegment.fromJson(s as Map<String, dynamic>))
          .toList();

      // Sort by start time to guarantee correct lookup order.
      segments.sort((a, b) => a.start.compareTo(b.start));

      return segments;
    } catch (e) {
      // Asset not found, JSON parse error, or unexpected structure.
      // Return empty list so the video still plays without captions.
      debugPrintTranscriptError(assetPath, e);
      return [];
    }
  }

  /// Finds the transcript segment active at [positionSeconds].
  ///
  /// Returns `null` if no segment covers the given position.
  static TranscriptSegment? getActiveSegment(
    List<TranscriptSegment> segments,
    double positionSeconds,
  ) {
    for (final segment in segments) {
      if (segment.isActiveAt(positionSeconds)) {
        return segment;
      }
    }
    return null;
  }

  /// Prints a debug-friendly error message when transcript loading fails.
  static void debugPrintTranscriptError(String path, Object error) {
    // ignore: avoid_print
    print('TranscriptService: Failed to load transcript at "$path": $error');
  }
}
