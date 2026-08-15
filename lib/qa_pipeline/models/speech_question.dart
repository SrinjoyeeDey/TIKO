import 'question.dart';

/// A speech recognition / pronunciation question evaluated via Python AI Service STT & alignment.
class SpeechQuestion extends Question {
  /// The target phrase the learner is asked to speak out loud.
  final String targetPhrase;

  /// Expected reference text or translation for display.
  final String referenceAnswer;

  /// Key words or concepts for phonetic match validation.
  final List<String> keyConcepts;

  /// Pronunciation score threshold (0-100, default 85).
  final int minScoreThreshold;

  const SpeechQuestion({
    required super.id,
    required super.questionText,
    required this.targetPhrase,
    required this.referenceAnswer,
    required this.keyConcepts,
    this.minScoreThreshold = 85,
    super.difficulty,
  }) : super(type: QuestionType.speech);

  factory SpeechQuestion.fromJson(Map<String, dynamic> json) {
    final conceptsRaw = json['key_concepts'] as List<dynamic>? ?? [];

    return SpeechQuestion(
      id: json['id'] as int,
      questionText: json['question'] as String,
      targetPhrase: json['target_phrase'] as String? ?? json['question'] as String,
      referenceAnswer: json['reference_answer'] as String? ?? '',
      keyConcepts: conceptsRaw.map((e) => e.toString()).toList(),
      minScoreThreshold: (json['min_score_threshold'] as num?)?.toInt() ?? 85,
      difficulty: json['difficulty'] as String?,
    );
  }
}
