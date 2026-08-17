import 'question.dart';

/// A sequence question where the child must arrange items in the correct order
/// using drag-and-drop reordering.
class SequenceQuestion extends Question {
  /// The items to reorder, initially presented in shuffled order.
  final List<String> items;

  /// The items in the correct order.
  final List<String> correctOrder;

  /// Optional explanation for the correct ordering.
  final String? answerText;

  const SequenceQuestion({
    required super.id,
    required super.questionText,
    required this.items,
    required this.correctOrder,
    this.answerText,
    super.difficulty,
    super.difficultyPercentage,
    super.difficultyLevel,
  }) : super(type: QuestionType.sequenceMcq);

  /// Creates a [SequenceQuestion] from a `sequence_test` JSON question.
  factory SequenceQuestion.fromJson(Map<String, dynamic> json) {
    final optionsRaw = json['options'] as Map<String, dynamic>;
    final sortedKeys = optionsRaw.keys.toList()..sort();

    // The correct order is the options listed by their key order (A, B, C, D).
    final correctOrder =
        sortedKeys.map((k) => optionsRaw[k].toString()).toList();

    // Shuffle the items for presentation.
    final shuffled = List<String>.from(correctOrder)..shuffle();
    final diff = json['difficulty'] as String?;

    return SequenceQuestion(
      id: json['id'] as int,
      questionText: json['question'] as String? ??
          'Arrange these events in the correct order:',
      items: shuffled,
      correctOrder: correctOrder,
      answerText: json['answer_text'] as String?,
      difficulty: diff,
      difficultyPercentage: (json['difficulty_percentage'] as num?)?.toInt() ??
          Question.derivePercentageFromDifficulty(diff),
      difficultyLevel: json['difficulty_level'] as String? ??
          Question.deriveLevelFromDifficulty(diff),
    );
  }

  /// Returns `true` if [userOrder] matches the correct sequence.
  bool isCorrect(List<String> userOrder) {
    if (userOrder.length != correctOrder.length) return false;
    for (int i = 0; i < correctOrder.length; i++) {
      if (userOrder[i] != correctOrder[i]) return false;
    }
    return true;
  }
}
