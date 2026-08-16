/// Represents a single attempt/round within a Catch NIMO session.
class ActivityAttempt {
  final String attemptId;
  final String sessionId;
  final int roundNumber;
  final DateTime targetSpawnTime;
  final DateTime? targetTappedTime;
  final int reactionTimeMs;
  final bool correct;
  final bool missed;
  final bool incorrectTarget;
  final int difficultyLevel;

  const ActivityAttempt({
    required this.attemptId,
    required this.sessionId,
    required this.roundNumber,
    required this.targetSpawnTime,
    this.targetTappedTime,
    required this.reactionTimeMs,
    required this.correct,
    required this.missed,
    required this.incorrectTarget,
    required this.difficultyLevel,
  });

  Map<String, dynamic> toJson() => {
        'attemptId': attemptId,
        'sessionId': sessionId,
        'roundNumber': roundNumber,
        'targetSpawnTime': targetSpawnTime.toIso8601String(),
        'targetTappedTime': targetTappedTime?.toIso8601String(),
        'reactionTimeMs': reactionTimeMs,
        'correct': correct,
        'missed': missed,
        'incorrectTarget': incorrectTarget,
        'difficultyLevel': difficultyLevel,
      };

  factory ActivityAttempt.fromJson(Map<String, dynamic> json) =>
      ActivityAttempt(
        attemptId: json['attemptId'] as String,
        sessionId: json['sessionId'] as String,
        roundNumber: json['roundNumber'] as int,
        targetSpawnTime: DateTime.parse(json['targetSpawnTime'] as String),
        targetTappedTime: json['targetTappedTime'] != null
            ? DateTime.parse(json['targetTappedTime'] as String)
            : null,
        reactionTimeMs: json['reactionTimeMs'] as int,
        correct: json['correct'] as bool,
        missed: json['missed'] as bool,
        incorrectTarget: json['incorrectTarget'] as bool,
        difficultyLevel: json['difficultyLevel'] as int,
      );
}
