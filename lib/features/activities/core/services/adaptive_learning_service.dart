import 'package:flutter/foundation.dart';
import '../models/activity_attempt.dart';
import '../models/difficulty_decision.dart';

/// Configurable Adaptive Learning Engine for NIMO Activities.
///
/// NOTE: The initial parameters (increaseThreshold = 0.80, decreaseThreshold = 0.50)
/// are PROTOTYPE CONFIGURATION parameters. They are not hard-coded clinical truth
/// and can be dynamically calibrated per child profile or activity context.
class AdaptiveLearningService {
  final double increaseThreshold;
  final double decreaseThreshold;
  final int minDifficulty;
  final int maxDifficulty;
  final int windowSize;

  const AdaptiveLearningService({
    this.increaseThreshold = 0.80,
    this.decreaseThreshold = 0.50,
    this.minDifficulty = 1,
    this.maxDifficulty = 6,
    this.windowSize = 3,
  });

  /// Evaluates recent attempt history and calculates the next difficulty level.
  DifficultyDecision evaluatePerformance({
    required List<ActivityAttempt> attempts,
    required int currentDifficulty,
  }) {
    if (attempts.length < windowSize) {
      return DifficultyDecision(
        nextDifficulty: currentDifficulty,
        reason: 'Gathering initial performance baseline',
        levelChanged: false,
      );
    }

    // Sliding window of recent attempts
    final recentWindow = attempts.sublist(attempts.length - windowSize);
    final correctCount = recentWindow.where((a) => a.isCorrect).length;
    final accuracy = correctCount / windowSize;

    final avgReactionMs = recentWindow
            .where((a) => a.isCorrect)
            .fold(0, (sum, a) => sum + a.reactionTimeMs) /
        (correctCount > 0 ? correctCount : 1);

    debugPrint('AdaptiveLearningEngine: Window accuracy: ${(accuracy * 100).toStringAsFixed(0)}%, avg reaction: ${avgReactionMs.toStringAsFixed(0)}ms');

    // Promotion Evaluation
    if (accuracy >= increaseThreshold && avgReactionMs < 1200) {
      if (currentDifficulty < maxDifficulty) {
        final next = currentDifficulty + 1;
        return DifficultyDecision(
          nextDifficulty: next,
          reason: 'High accuracy (${(accuracy * 100).toStringAsFixed(0)}%) & fast reaction time',
          levelChanged: true,
        );
      } else {
        return DifficultyDecision(
          nextDifficulty: currentDifficulty,
          reason: 'Maximum challenge level reached',
          levelChanged: false,
        );
      }
    }

    // Demotion Evaluation
    if (accuracy < decreaseThreshold) {
      if (currentDifficulty > minDifficulty) {
        final next = currentDifficulty - 1;
        return DifficultyDecision(
          nextDifficulty: next,
          reason: 'Recent accuracy (${(accuracy * 100).toStringAsFixed(0)}%) dropped below threshold',
          levelChanged: true,
        );
      } else {
        return DifficultyDecision(
          nextDifficulty: currentDifficulty,
          reason: 'Minimum difficulty baseline maintained',
          levelChanged: false,
        );
      }
    }

    return DifficultyDecision(
      nextDifficulty: currentDifficulty,
      reason: 'Steady performance within target challenge zone',
      levelChanged: false,
    );
  }
}
