/// Represents a single timestamped caption segment from a transcript.
class TranscriptSegment {
  final double start;
  final double end;
  final String text;

  const TranscriptSegment({
    required this.start,
    required this.end,
    required this.text,
  });
  

  /// Creates a [TranscriptSegment] from a JSON map.
  ///
  /// Expects keys: `start` (num), `end` (num), `text` (String).
  factory TranscriptSegment.fromJson(Map<String, dynamic> json) {
    return TranscriptSegment(
      start: (json['start'] as num).toDouble(),
      end: (json['end'] as num).toDouble(),
      text: json['text'] as String,
    );
  }

  /// Returns `true` if [positionSeconds] falls within this segment's time range.
  bool isActiveAt(double positionSeconds) {
    return positionSeconds >= start && positionSeconds < end;
  }

  @override
  String toString() =>
      'TranscriptSegment(start: $start, end: $end, text: "$text")';
}
