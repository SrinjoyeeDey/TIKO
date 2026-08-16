/// Generic trial attempt model for all NIMO activities.
class ActivityAttempt {
  final String attemptId;
  final String sessionId;
  final int roundNumber;
  final DateTime timestamp;
  final DateTime? responseTime;
  final int reactionTimeMs;
  final bool isCorrect;
  final bool isMissed;
  final bool isIncorrectTarget;
  final int score;
  final int difficultyLevel;

  const ActivityAttempt({
    required this.attemptId,
    required this.sessionId,
    required this.roundNumber,
    required this.timestamp,
    this.responseTime,
    required this.reactionTimeMs,
    required this.isCorrect,
    required this.isMissed,
    this.isIncorrectTarget = false,
    this.score = 0,
    required this.difficultyLevel,
  });

  Map<String, dynamic> toJson() => {
        'attemptId': attemptId,
        'sessionId': sessionId,
        'roundNumber': roundNumber,
        'timestamp': timestamp.toIso8601String(),
        'responseTime': responseTime?.toIso8601String(),
        'reactionTimeMs': reactionTimeMs,
        'isCorrect': isCorrect,
        'isMissed': isMissed,
        'isIncorrectTarget': isIncorrectTarget,
        'score': score,
        'difficultyLevel': difficultyLevel,
      };

  factory ActivityAttempt.fromJson(Map<String, dynamic> json) =>
      ActivityAttempt(
        attemptId: json['attemptId'] as String,
        sessionId: json['sessionId'] as String,
        roundNumber: json['roundNumber'] as int,
        timestamp: DateTime.parse(json['timestamp'] as String),
        responseTime: json['responseTime'] != null
            ? DateTime.parse(json['responseTime'] as String)
            : null,
        reactionTimeMs: json['reactionTimeMs'] as int,
        isCorrect: json['isCorrect'] as bool,
        isMissed: json['isMissed'] as bool,
        isIncorrectTarget: json['isIncorrectTarget'] as bool? ?? false,
        score: json['score'] as int? ?? 0,
        difficultyLevel: json['difficultyLevel'] as int,
      );
}
