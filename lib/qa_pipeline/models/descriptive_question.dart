import 'question.dart';

/// A descriptive/free-text question evaluated via keyword matching.
class DescriptiveQuestion extends Question {
  /// The expected/reference answer for display or comparison.
  final String referenceAnswer;

  /// Key concepts that the learner's answer should contain.
  ///
  /// Each concept may be a single word or multi-word phrase.
  final List<String> keyConcepts;

  /// The similarity threshold from the JSON (0.0–1.0).
  ///
  /// Scores at or above this value are considered acceptable.
  final double similarityThreshold;

  const DescriptiveQuestion({
    required super.id,
    required super.questionText,
    required this.referenceAnswer,
    required this.keyConcepts,
    required this.similarityThreshold,
    super.difficulty,
    super.difficultyPercentage,
    super.difficultyLevel,
  }) : super(type: QuestionType.descriptive);

  /// Creates a [DescriptiveQuestion] from a JSON map.
  factory DescriptiveQuestion.fromJson(Map<String, dynamic> json) {
    final conceptsRaw = json['key_concepts'] as List<dynamic>? ?? [];
    final diff = json['difficulty'] as String?;

    return DescriptiveQuestion(
      id: json['id'] as int,
      questionText: json['question'] as String,
      referenceAnswer: json['reference_answer'] as String? ?? '',
      keyConcepts: conceptsRaw.map((e) => e.toString()).toList(),
      similarityThreshold:
          (json['cosine_similarity_threshold'] as num?)?.toDouble() ?? 0.6,
      difficulty: diff,
      difficultyPercentage: (json['difficulty_percentage'] as num?)?.toInt() ??
          Question.derivePercentageFromDifficulty(diff),
      difficultyLevel: json['difficulty_level'] as String? ??
          Question.deriveLevelFromDifficulty(diff),
    );
  }
}
