import 'activity_session.dart';

/// Result object generated at the end of an activity with encouraging messaging.
class ActivityResult {
  final ActivitySession session;
  final bool isPersonalBest;
  final String headlineFeedback;
  final String detailFeedback;

  const ActivityResult({
    required this.session,
    this.isPersonalBest = false,
    required this.headlineFeedback,
    required this.detailFeedback,
  });

  factory ActivityResult.fromSession(ActivitySession session, {bool isPersonalBest = false}) {
    String headline = 'Great focus!';
    if (session.accuracyPercentage >= 90) {
      headline = 'Outstanding focus!';
    } else if (session.highestStreak >= 5) {
      headline = 'Impressive streak!';
    }

    String detail = 'You reacted faster this round.';
    if (session.bestReactionTimeMs < 800) {
      detail = 'Lightning fast reactions!';
    } else if (session.accuracyPercentage > 75) {
      detail = 'Consistently sharp accuracy.';
    }

    return ActivityResult(
      session: session,
      isPersonalBest: isPersonalBest,
      headlineFeedback: headline,
      detailFeedback: detail,
    );
  }
}
