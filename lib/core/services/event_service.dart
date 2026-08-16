import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../api/event_api.dart';
import '../models/event_model.dart';
import '../state/child_state.dart';

/// Centralized Event Service for dispatching interaction telemetry events.
class EventService {
  EventService._privateConstructor();
  static final EventService instance = EventService._privateConstructor();

  final Map<String, DateTime> _activityStartTimes = {};

  /// Start timer when an activity launches on screen
  void startActivityTimer(String activityId) {
    _activityStartTimes[activityId] = DateTime.now();
  }

  /// Calculate real measured response time in seconds
  double getElapsedResponseTimeSeconds(String activityId) {
    final start = _activityStartTimes[activityId];
    if (start == null) return 0.0;
    final ms = DateTime.now().difference(start).inMilliseconds;
    return math.max(0.1, double.parse((ms / 1000.0).toStringAsFixed(2)));
  }

  /// Log a standardized telemetry event to the backend.
  /// Automatically injects current `childId` and `sessionId` from `ChildState`.
  static Future<EventModel?> logEvent({
    required String eventType,
    String? activityId,
    Map<String, dynamic>? data,
  }) async {
    final childId = ChildState.instance.currentProfile.id;
    final sessionId = ChildState.instance.currentSessionId ?? 'SES_LOCAL';

    final Map<String, dynamic> payload = {
      'childId': childId,
      'sessionId': sessionId,
      'eventType': eventType,
      'data': data ?? {},
    };

    if (activityId != null) {
      payload['activityId'] = activityId;
    }

    debugPrint('⚡ [EventService] Emitting $eventType (sessionId: $sessionId, activityId: ${activityId ?? "N/A"})');
    final event = await EventApi.postEvent(payload);
    return event;
  }

  /// Fetch all events for a specific child
  static Future<List<EventModel>> getEvents({required String childId}) async {
    return await EventApi.getEvents(childId: childId);
  }
}
