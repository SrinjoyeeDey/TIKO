import 'activity_attempt.dart';

/// Represents a complete gameplay session summary for Catch NIMO.
class ActivitySession {
  final String sessionId;
  final String activityId;
  final DateTime startedAt;
  final DateTime completedAt;
  final int totalRounds;
  final int successfulRounds;
  final int missedRounds;
  final int incorrectTaps;
  final double averageReactionTimeMs;
  final int bestReactionTimeMs;
  final int highestCombo;
  final int difficultyReached;
  final int totalXP;
  final List<ActivityAttempt> attempts;

  const ActivitySession({
    required this.sessionId,
    required this.activityId,
    required this.startedAt,
    required this.completedAt,
    required this.totalRounds,
    required this.successfulRounds,
    required this.missedRounds,
    required this.incorrectTaps,
    required this.averageReactionTimeMs,
    required this.bestReactionTimeMs,
    required this.highestCombo,
    required this.difficultyReached,
    required this.totalXP,
    this.attempts = const [],
  });

  double get accuracyPercentage =>
      totalRounds > 0 ? (successfulRounds / totalRounds) * 100.0 : 0.0;

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'activityId': activityId,
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt.toIso8601String(),
        'totalRounds': totalRounds,
        'successfulRounds': successfulRounds,
        'missedRounds': missedRounds,
        'incorrectTaps': incorrectTaps,
        'averageReactionTimeMs': averageReactionTimeMs,
        'bestReactionTimeMs': bestReactionTimeMs,
        'highestCombo': highestCombo,
        'difficultyReached': difficultyReached,
        'totalXP': totalXP,
        'attempts': attempts.map((a) => a.toJson()).toList(),
      };
}
