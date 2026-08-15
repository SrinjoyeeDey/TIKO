/// Represents the evaluated performance result for a completed activity.
class ActivityResultModel {
  final String resultId;
  final String activityId;
  final String sessionId;
  final String childId;
  final bool correct;
  final int attempts;
  final int hintsUsed;
  final double responseTime;
  final int difficulty;
  final int score;
  final int xpEarned;
  final String skill;
  final String completedAt;

  const ActivityResultModel({
    required this.resultId,
    required this.activityId,
    required this.sessionId,
    required this.childId,
    this.correct = true,
    this.attempts = 1,
    this.hintsUsed = 0,
    this.responseTime = 0.0,
    this.difficulty = 1,
    this.score = 100,
    this.xpEarned = 20,
    this.skill = 'recognition',
    required this.completedAt,
  });

  factory ActivityResultModel.fromJson(Map<String, dynamic> json) {
    return ActivityResultModel(
      resultId: json['resultId'] as String? ?? 'RES_LOCAL',
      activityId: json['activityId'] as String? ?? 'netaji_q01',
      sessionId: json['sessionId'] as String? ?? 'SES_LOCAL',
      childId: json['childId'] as String? ?? 'A001',
      correct: json['correct'] as bool? ?? true,
      attempts: json['attempts'] as int? ?? 1,
      hintsUsed: json['hintsUsed'] as int? ?? 0,
      responseTime: (json['responseTime'] as num?)?.toDouble() ?? 0.0,
      difficulty: json['difficulty'] as int? ?? 1,
      score: json['score'] as int? ?? 100,
      xpEarned: json['xpEarned'] as int? ?? 20,
      skill: json['skill'] as String? ?? 'recognition',
      completedAt: json['completedAt'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'resultId': resultId,
      'activityId': activityId,
      'sessionId': sessionId,
      'childId': childId,
      'correct': correct,
      'attempts': attempts,
      'hintsUsed': hintsUsed,
      'responseTime': responseTime,
      'difficulty': difficulty,
      'score': score,
      'xpEarned': xpEarned,
      'skill': skill,
      'completedAt': completedAt,
    };
  }

  @override
  String toString() {
    return 'ActivityResultModel(resultId: $resultId, score: $score, xpEarned: $xpEarned, attempts: $attempts, responseTime: ${responseTime}s)';
  }
}
