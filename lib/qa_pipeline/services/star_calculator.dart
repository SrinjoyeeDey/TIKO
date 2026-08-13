/// Configurable star rating calculator for level completion.
///
/// Calculates a 1–3 star rating based on overall accuracy across all
/// question sections. Thresholds are configurable constants.
class StarCalculator {
  /// Minimum accuracy for 3 stars (Excellent).
  static const double threeStarMinAccuracy = 0.80;

  /// Minimum accuracy for 2 stars (Good).
  static const double twoStarMinAccuracy = 0.50;

  /// Any completion earns at least 1 star.
  /// 0 stars means not completed.

  /// Calculates the star rating from raw correct/total counts.
  ///
  /// Returns 1–3. Never returns 0 for a completed level.
  static int calculateStars(int correct, int total) {
    if (total == 0) return 3; // Edge case: no questions → 3 stars for watching video.

    final accuracy = correct / total;

    if (accuracy >= threeStarMinAccuracy) return 3;
    if (accuracy >= twoStarMinAccuracy) return 2;
    return 1;
  }

  /// Returns a child-friendly message for the star count.
  static String getMessage(int stars) {
    switch (stars) {
      case 3:
        return 'Amazing job! You\'re a superstar! 🌟';
      case 2:
        return 'Great work! Keep it up! 💪';
      default:
        return 'Good effort! You did it! 🎉';
    }
  }
}
