/// Supported question types in the QA pipeline.
enum QuestionType {
  mcq,
  descriptive,
  sequenceMcq,
  imageMatching,
  speech,
}

/// Base class for all question types.
abstract class Question {
  final int id;
  final QuestionType type;
  final String questionText;
  final String? difficulty;
  final int? difficultyPercentage;
  final String? difficultyLevel;

  const Question({
    required this.id,
    required this.type,
    required this.questionText,
    this.difficulty,
    this.difficultyPercentage,
    this.difficultyLevel,
  });

  /// Helper to derive baseline difficulty percentage from text difficulty label
  static int derivePercentageFromDifficulty(String? diff) {
    if (diff == null) return 50;
    final lower = diff.toLowerCase();
    if (lower.contains('easy') || lower.contains('gentle') || lower.contains('starter')) return 30;
    if (lower.contains('medium') || lower.contains('moderate') || lower.contains('balanced')) return 50;
    if (lower.contains('curious') || lower.contains('adventurer')) return 55;
    if (lower.contains('hard') || lower.contains('challeng')) return 75;
    if (lower.contains('champion') || lower.contains('expert')) return 85;
    return 50;
  }

  /// Helper to derive baseline difficulty level name from text difficulty label
  static String deriveLevelFromDifficulty(String? diff) {
    if (diff == null) return 'Balanced Explorer';
    final lower = diff.toLowerCase();
    if (lower.contains('easy') || lower.contains('gentle') || lower.contains('starter')) return 'Gentle Starter';
    if (lower.contains('medium') || lower.contains('balanced')) return 'Balanced Explorer';
    if (lower.contains('moderate') || lower.contains('curious') || lower.contains('adventurer')) return 'Curious Adventurer';
    if (lower.contains('hard') || lower.contains('challeng')) return 'Challenger';
    if (lower.contains('champion')) return 'Champion';
    return diff;
  }
}
