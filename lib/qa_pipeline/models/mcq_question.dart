import 'question.dart';

/// An MCQ question with labelled options (A, B, C, D) and a single correct
/// answer key.
///
/// Also used for `sequence_mcq` questions which share the same JSON structure.
class McqQuestion extends Question {
  /// Options keyed by letter label, e.g. `{"A": "Option text", "B": ...}`.
  final Map<String, String> options;

  /// The correct option's letter key, e.g. `"C"`.
  final String correctAnswerKey;

  /// Explanatory text for the correct answer.
  final String? answerText;

  const McqQuestion({
    required super.id,
    required super.type,
    required super.questionText,
    required this.options,
    required this.correctAnswerKey,
    this.answerText,
    super.difficulty,
    super.difficultyPercentage,
    super.difficultyLevel,
  });

  /// Creates an [McqQuestion] from a JSON map.
  ///
  /// Works for both `"mcq"` and `"sequence_mcq"` types.
  factory McqQuestion.fromJson(Map<String, dynamic> json, QuestionType type) {
    final optionsRaw = json['options'] as Map<String, dynamic>;
    final options =
        optionsRaw.map((key, value) => MapEntry(key, value.toString()));
    final diff = json['difficulty'] as String?;

    return McqQuestion(
      id: json['id'] as int,
      type: type,
      questionText: json['question'] as String,
      options: options,
      correctAnswerKey: json['answer'] as String,
      answerText: json['answer_text'] as String?,
      difficulty: diff,
      difficultyPercentage: (json['difficulty_percentage'] as num?)?.toInt() ??
          Question.derivePercentageFromDifficulty(diff),
      difficultyLevel: json['difficulty_level'] as String? ??
          Question.deriveLevelFromDifficulty(diff),
    );
  }

  /// Returns the full text of the correct answer option.
  String get correctAnswerText => options[correctAnswerKey] ?? '';

  /// Returns `true` if [selectedKey] matches the correct answer.
  bool isCorrect(String selectedKey) => selectedKey == correctAnswerKey;
}
