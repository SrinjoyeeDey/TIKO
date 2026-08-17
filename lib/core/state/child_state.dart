import 'package:flutter/foundation.dart';
import '../models/child_profile.dart';
import '../models/parent_account.dart';
import '../models/session_model.dart';
import '../models/event_model.dart';
import '../models/skill_progress_model.dart';
import '../models/adaptive_decision_model.dart';
import '../models/recommendation_model.dart';
import '../models/activity_model.dart';
import '../api/child_api.dart';
import '../api/session_api.dart';
import '../api/progress_api.dart';
import '../api/adaptive_api.dart';
import '../api/recommendation_api.dart';
import '../services/event_service.dart';
import '../services/sync_service.dart';
import '../../qa_pipeline/database/child_repository.dart';

/// Central reactive state store for active Parent Account, Child Profile, Session, Role, & Telemetry.
class ChildState {
  ChildState._privateConstructor();

  static final ChildState instance = ChildState._privateConstructor();

  /// Reactive active Parent Account
  final ValueNotifier<ParentAccount?> activeParentNotifier = ValueNotifier<ParentAccount?>(null);

  /// Reactive active ChildProfile
  final ValueNotifier<ChildProfile?> activeProfileNotifier = ValueNotifier<ChildProfile?>(
    const ChildProfile(
      id: 'child_default',
      name: 'Aarav',
      xp: 350,
      level: 4,
      streak: 5,
    ),
  );

  /// Reactive active Session
  final ValueNotifier<SessionModel?> activeSessionNotifier = ValueNotifier<SessionModel?>(null);

  /// Reactive active Role ('PARENT' or 'CHILD')
  final ValueNotifier<String> activeRoleNotifier = ValueNotifier<String>('CHILD');

  /// Reactive active Skill Progress map (skill -> SkillProgressModel)
  final ValueNotifier<Map<String, SkillProgressModel>> progressNotifier =
      ValueNotifier<Map<String, SkillProgressModel>>({});

  /// Reactive latest Adaptive Decision
  final ValueNotifier<AdaptiveDecisionModel?> activeDecisionNotifier =
      ValueNotifier<AdaptiveDecisionModel?>(null);

  /// Reactive latest Recommendation
  final ValueNotifier<RecommendationModel?> activeRecommendationNotifier =
      ValueNotifier<RecommendationModel?>(null);

  /// Get current active parent
  ParentAccount? get currentParent => activeParentNotifier.value;

  /// Get current active role ('PARENT' or 'CHILD')
  String get currentRole => activeRoleNotifier.value;

  /// Get current active profile synchronously
  ChildProfile get currentProfile =>
      activeProfileNotifier.value ??
      const ChildProfile(
        id: 'child_default',
        name: 'Aarav',
        xp: 350,
        level: 4,
        streak: 5,
      );

  /// Get current session ID
  String? get currentSessionId => activeSessionNotifier.value?.sessionId;

  /// Load child profile from backend by Child ID and store in app state
  Future<ChildProfile> loadProfile(String childId) async {
    final profile = await ChildApi.getChildProfile(childId);
    activeProfileNotifier.value = profile;
    await loadProgress(childId);
    return profile;
  }

  /// Load skill progress from backend by Child ID and update progressNotifier
  Future<Map<String, SkillProgressModel>> loadProgress(String childId) async {
    final progressMap = await ProgressApi.getProgress(childId);
    progressNotifier.value = progressMap;
    return progressMap;
  }

  /// Fetch next adaptive activity & decision from Adaptive Engine
  Future<ActivityModel?> fetchNextAdaptiveActivity({String? skill}) async {
    final childId = currentProfile.id;
    final res = await AdaptiveApi.getNextActivity(childId, skill: skill);
    if (res != null) {
      if (res['decision'] is AdaptiveDecisionModel) {
        activeDecisionNotifier.value = res['decision'] as AdaptiveDecisionModel;
      }
      if (res['recommendedActivity'] is ActivityModel) {
        return res['recommendedActivity'] as ActivityModel;
      }
    }
    return null;
  }

  /// Fetch dynamic activity recommendation from Recommendation Engine
  Future<ActivityModel?> fetchRecommendation() async {
    final childId = currentProfile.id;
    final res = await RecommendationApi.getRecommendation(childId);
    if (res != null) {
      if (res['recommendation'] is RecommendationModel) {
        activeRecommendationNotifier.value = res['recommendation'] as RecommendationModel;
      }
      if (res['activity'] is ActivityModel) {
        return res['activity'] as ActivityModel;
      }
    }
    return null;
  }

  /// Update in-memory profile and notify listeners
  void setProfile(ChildProfile profile, {bool remember = true}) {
    activeProfileNotifier.value = profile;
    loadProgress(profile.id);
    if (remember) {
      ChildRepository.rememberChild(profile.id);
    }
  }

  /// Restore remembered profile from SQLite on app startup
  Future<void> initRememberedProfile() async {
    try {
      final remembered = await ChildRepository.getActiveChild();
      if (remembered != null) {
        activeProfileNotifier.value = ChildProfile(
          id: remembered.id,
          parentId: remembered.parentId,
          name: remembered.name,
          age: remembered.age,
          className: remembered.className,
          difficultyPercentage: remembered.difficultyPercentage,
          difficultyLevel: remembered.difficultyLevel,
          difficultyReasoning: remembered.difficultyReasoning,
          xp: 350,
          level: 4,
          streak: 5,
        );
        loadProgress(remembered.id);
      }
    } catch (e) {
      debugPrint('ChildState: initRememberedProfile error: $e');
    }
  }

  /// Add XP to active child profile
  void addXp(int amount) {
    final cur = currentProfile;
    setProfile(cur.copyWith(xp: cur.xp + amount));
  }

  /// Start a new learning session for current child profile with storyId
  Future<SessionModel?> startNewSession({String storyId = 'netaji'}) async {
    final profile = currentProfile;
    final session = await SessionApi.startSession(
      childId: profile.id,
      storyId: storyId,
    );
    activeSessionNotifier.value = session;
    debugPrint('🚀 [Session Engine] Session Created! sessionId: ${session?.sessionId}, storyId: ${session?.storyId}, status: ${session?.status}, startedAt: ${session?.startedAt}');

    // Emit SESSION_STARTED event telemetry
    if (session != null) {
      await EventService.logEvent(
        eventType: EventType.sessionStarted,
        data: {
          'storyId': storyId,
          'startedAt': session.startedAt,
        },
      );
    }

    return session;
  }

  /// Increment activitiesCompleted count in active session
  void incrementActivitiesCompleted() {
    final session = activeSessionNotifier.value;
    if (session != null) {
      activeSessionNotifier.value = session.copyWith(
        activitiesCompleted: session.activitiesCompleted + 1,
      );
    }
  }

  /// Log real interaction event to backend session
  Future<void> logInteraction({
    required String type,
    String? questionId,
    bool isCorrect = true,
    int timeTakenSeconds = 0,
    Map<String, dynamic>? details,
  }) async {
    final sid = currentSessionId;
    if (sid != null) {
      final interactionData = {
        'type': type,
        'questionId': questionId,
        'isCorrect': isCorrect,
        'timeTakenSeconds': timeTakenSeconds,
        'details': details ?? {},
      };
      await SessionApi.logInteraction(sid, interactionData);
    }
  }

  /// Set active Parent Account
  void setActiveParent(ParentAccount parent) {
    activeParentNotifier.value = parent;
  }

  /// Set active role ('PARENT' or 'CHILD')
  void setRole(String role) {
    activeRoleNotifier.value = role;
  }

  /// Log real activity performance event to local SQLite and sync queue
  Future<void> logActivityEvent({
    required String activityId,
    required String skill,
    int difficulty = 1,
    bool success = true,
    double accuracy = 1.0,
    int reactionTimeMs = 0,
    int errors = 0,
    int attemptNumber = 1,
    String inputType = 'touch',
    Map<String, dynamic>? extraData,
  }) async {
    final childId = currentProfile.id;
    final parentId = currentProfile.parentId ?? currentParent?.id ?? 'parent_default';
    final sessionId = currentSessionId ?? 'session_${DateTime.now().millisecondsSinceEpoch}';

    final event = EventModel(
      eventId: 'evt_${DateTime.now().microsecondsSinceEpoch}',
      childId: childId,
      sessionId: sessionId,
      activityId: activityId,
      eventType: EventType.activityCompleted,
      timestamp: DateTime.now().toIso8601String(),
      data: {
        'skill': skill,
        'difficulty': difficulty,
        'success': success,
        'accuracy': accuracy,
        'reactionTimeMs': reactionTimeMs,
        'errors': errors,
        'attemptNumber': attemptNumber,
        'inputType': inputType,
        'parentId': parentId,
        ...?extraData,
      },
    );

    incrementActivitiesCompleted();
    await SyncService.instance.queueEvent(event);
  }

  /// Formally end active session: backend calculates duration = endedAt - startedAt
  Future<SessionModel?> endCurrentSession() async {
    final sid = currentSessionId;
    if (sid == null) return null;

    final completedSession = await SessionApi.endSession(sid);
    if (completedSession != null) {
      activeSessionNotifier.value = completedSession;
      debugPrint('🏁 [Session Engine] Session Completed! sessionId: ${completedSession.sessionId}, duration: ${completedSession.duration}s, status: ${completedSession.status}, activitiesCompleted: ${completedSession.activitiesCompleted}');

      // Emit SESSION_COMPLETED event telemetry
      await EventService.logEvent(
        eventType: EventType.sessionCompleted,
        data: {
          'duration': completedSession.duration,
          'activitiesCompleted': completedSession.activitiesCompleted,
          'endedAt': completedSession.endedAt,
        },
      );

      // Refresh Child Profile & Progress state with newly earned XP/level from backend
      await loadProfile(currentProfile.id);
    }
    return completedSession;
  }

  /// Update XP, Level, Streak in app state and sync with backend
  Future<void> updateProgress({int? addedXp, int? newLevel, int? newStreak}) async {
    final current = currentProfile;
    final updated = current.copyWith(
      xp: addedXp != null ? current.xp + addedXp : current.xp,
      level: newLevel ?? current.level,
      streak: newStreak ?? current.streak,
    );

    activeProfileNotifier.value = updated;
    await ChildApi.updateChildProfile(updated.id, {
      'xp': updated.xp,
      'level': updated.level,
      'streak': updated.streak,
    });
  }
}
