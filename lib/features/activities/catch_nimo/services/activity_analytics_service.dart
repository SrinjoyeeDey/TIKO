import 'package:flutter/foundation.dart';
import '../models/activity_session.dart';

/// Repository & Service for logging Catch NIMO session analytics silently.
class ActivityAnalyticsService {
  static final List<ActivitySession> _sessionHistory = [];

  /// Saves a completed session to history and returns whether it set a Personal Best.
  static bool logSession(ActivitySession session) {
    bool isPersonalBest = false;

    if (_sessionHistory.isNotEmpty) {
      final previousBestTime = _sessionHistory
          .where((s) => s.bestReactionTimeMs > 0)
          .fold<int>(999999, (best, s) => s.bestReactionTimeMs < best ? s.bestReactionTimeMs : best);

      if (session.bestReactionTimeMs > 0 && session.bestReactionTimeMs < previousBestTime) {
        isPersonalBest = true;
      }
    } else {
      isPersonalBest = session.bestReactionTimeMs > 0;
    }

    _sessionHistory.add(session);
    debugPrint('ActivityAnalyticsService: Logged session ${session.sessionId}. Accuracy: ${session.accuracyPercentage.toStringAsFixed(1)}%, Best Time: ${session.bestReactionTimeMs}ms');
    
    return isPersonalBest;
  }

  static List<ActivitySession> get history => List.unmodifiable(_sessionHistory);
}
