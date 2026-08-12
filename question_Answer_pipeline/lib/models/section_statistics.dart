/// Aggregated statistics for a single question section (MCQ, Descriptive, or Sequence).
class SectionStatistics {
  /// Added for Parent Dashboard
  final String title;
  final String sectionKey;

  /// One of 'mcq', 'descriptive', 'sequence'.
  final String sectionType;

  int totalAttempts;
  int correctAttempts;
  int totalTimeSeconds;

  /// Accuracy as a ratio (0.0–1.0).
  double get accuracy =>
      totalAttempts > 0 ? correctAttempts / totalAttempts : 0.0;

  /// Accuracy as a percentage (0–100).
  int get accuracyPercent => (accuracy * 100).round();

  /// Average time per question in seconds.
  double get averageTimeSeconds =>
      totalAttempts > 0 ? totalTimeSeconds / totalAttempts : 0.0;

  SectionStatistics({
    this.title = '',
    this.sectionKey = '',
    required this.sectionType,
    this.totalAttempts = 0,
    this.correctAttempts = 0,
    this.totalTimeSeconds = 0,
  });

  void addAttempt(bool isCorrect, int timeTakenSeconds) {
    totalAttempts++;
    if (isCorrect) correctAttempts++;
    totalTimeSeconds += timeTakenSeconds;
  }

  @override
  String toString() =>
      'SectionStatistics($sectionType: $correctAttempts/$totalAttempts, '
      'avg ${averageTimeSeconds.toStringAsFixed(1)}s)';
}
