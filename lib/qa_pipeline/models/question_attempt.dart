class QuestionAttempt {
  final String id;
  final String childId;
  final String chapterId;
  final String levelId;
  final int questionId;
  final String questionType; // 'mcq', 'descriptive', 'sequence', 'drag'
  final DateTime startedAt;
  final DateTime completedAt;
  final int timeTakenSeconds;

  // Evaluation
  final bool isCorrect;
  final double? similarityScore; // for descriptive
  final String? userAnswer;
  final int? correctMatches; // for image matching
  final int? totalMatches; // for image matching

  const QuestionAttempt({
    required this.id,
    required this.childId,
    required this.chapterId,
    required this.levelId,
    required this.questionId,
    required this.questionType,
    required this.startedAt,
    required this.completedAt,
    required this.timeTakenSeconds,
    required this.isCorrect,
    this.similarityScore,
    this.userAnswer,
    this.correctMatches,
    this.totalMatches,
  });

  factory QuestionAttempt.fromMap(Map<String, dynamic> map) {
    return QuestionAttempt(
      id: map['id'] as String,
      childId: map['child_id'] as String,
      chapterId: map['chapter_id'] as String,
      levelId: map['level_id'] as String,
      questionId: map['question_id'] as int,
      questionType: map['question_type'] as String,
      startedAt: DateTime.parse(map['started_at'] as String),
      completedAt: DateTime.parse(map['completed_at'] as String),
      timeTakenSeconds: map['time_taken_seconds'] as int,
      isCorrect: (map['is_correct'] as int) == 1,
      similarityScore: map['similarity_score'] as double?,
      userAnswer: map['user_answer'] as String?,
      correctMatches: map['correct_matches'] as int?,
      totalMatches: map['total_matches'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'child_id': childId,
      'chapter_id': chapterId,
      'level_id': levelId,
      'question_id': questionId,
      'question_type': questionType,
      'started_at': startedAt.toIso8601String(),
      'completed_at': completedAt.toIso8601String(),
      'time_taken_seconds': timeTakenSeconds,
      'is_correct': isCorrect ? 1 : 0,
      'similarity_score': similarityScore,
      'user_answer': userAnswer,
      'correct_matches': correctMatches,
      'total_matches': totalMatches,
    };
  }
}
