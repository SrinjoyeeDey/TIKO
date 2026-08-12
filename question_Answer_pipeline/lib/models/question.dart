/// The three types of questions supported by the question engine.
enum QuestionType {
  mcq,
  descriptive,
  sequenceMcq,
  imageMatching,
}

/// Base class for all question types.
///
/// Subclassed by [McqQuestion] and [DescriptiveQuestion].
abstract class Question {
  final int id;
  final QuestionType type;
  final String questionText;
  final String? difficulty;

  const Question({
    required this.id,
    required this.type,
    required this.questionText,
    this.difficulty,
  });
}
