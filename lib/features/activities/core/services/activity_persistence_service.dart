import 'package:flutter/foundation.dart';
import '../../../../core/state/child_state.dart';
import '../models/activity_session.dart';

/// Service for persisting activity session metrics and syncing progress with NIMO ChildState.
class ActivityPersistenceService {
  static final List<ActivitySession> _savedSessions = [];

  /// Saves session metrics and syncs earned XP to active NIMO ChildProfile.
  static Future<bool> saveSession(ActivitySession session) async {
    _savedSessions.add(session);

    // Evaluate Personal Best
    bool isPersonalBest = false;
    if (_savedSessions.length > 1) {
      final previousBestTime = _savedSessions
          .sublist(0, _savedSessions.length - 1)
          .where((s) => s.bestReactionTimeMs > 0)
          .fold<int>(999999, (best, s) => s.bestReactionTimeMs < best ? s.bestReactionTimeMs : best);

      if (session.bestReactionTimeMs > 0 && session.bestReactionTimeMs < previousBestTime) {
        isPersonalBest = true;
      }
    } else {
      isPersonalBest = session.bestReactionTimeMs > 0;
    }

    // Sync XP and Telemetry Event to NIMO ChildState store
    try {
      await ChildState.instance.updateProgress(addedXp: session.totalXP);

      final calcAccuracy = session.totalRounds > 0 ? session.successfulRounds / session.totalRounds : 0.0;

      await ChildState.instance.logActivityEvent(
        activityId: session.activityId,
        skill: 'cognition',
        difficulty: session.difficultyReached,
        success: calcAccuracy >= 0.5,
        accuracy: calcAccuracy,
        reactionTimeMs: session.averageReactionTimeMs.toInt(),
        errors: session.incorrectTaps,
        attemptNumber: 1,
        inputType: 'touch',
        extraData: {
          'totalXP': session.totalXP,
          'bestReactionTimeMs': session.bestReactionTimeMs,
          'successfulRounds': session.successfulRounds,
          'totalRounds': session.totalRounds,
          'accuracyPercentage': session.accuracyPercentage,
        },
      );

      debugPrint('ActivityPersistenceService: Logged telemetry & synced +${session.totalXP} XP for ${session.activityId}');
    } catch (e) {
      debugPrint('ActivityPersistenceService: Local ChildState update warning: $e');
    }

    return isPersonalBest;
  }

  static List<ActivitySession> get history => List.unmodifiable(_savedSessions);
}
