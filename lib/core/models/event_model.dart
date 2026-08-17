/// Standardized Event Sources constant definition
class EventSource {
  static const String flutter = 'flutter';
  static const String pythonSpeech = 'python_speech';
  static const String pythonVision = 'python_vision';
  static const String esp32 = 'esp32';
  static const String mockHardware = 'mock_hardware';
}

/// Standardized Event Types constant definition
class EventType {
  // Learning Events
  static const String sessionStarted = 'SESSION_STARTED';
  static const String sessionCompleted = 'SESSION_COMPLETED';
  static const String activityStarted = 'ACTIVITY_STARTED';
  static const String activityCompleted = 'ACTIVITY_COMPLETED';
  static const String activitySkipped = 'ACTIVITY_SKIPPED';
  static const String answerSubmitted = 'ANSWER_SUBMITTED';
  static const String answerCorrect = 'ANSWER_CORRECT';
  static const String answerWrong = 'ANSWER_WRONG';
  static const String hintUsed = 'HINT_USED';
  static const String retry = 'RETRY';

  // Speech Events
  static const String speechAttempt = 'SPEECH_ATTEMPT';
  static const String speechAnalysis = 'SPEECH_ANALYSIS';
  static const String pronunciationAnalysis = 'PRONUNCIATION_ANALYSIS';

  // Vision Events
  static const String engagementAnalysis = 'ENGAGEMENT_ANALYSIS';
  static const String engagementSummary = 'ENGAGEMENT_SUMMARY';

  // Hardware Events
  static const String gripDetected = 'GRIP_DETECTED';
  static const String rotationDetected = 'ROTATION_DETECTED';
  static const String movementDetected = 'MOVEMENT_DETECTED';
  static const String pressureDetected = 'PRESSURE_DETECTED';
}

/// Represents a standardized interaction telemetry event.
class EventModel {
  final String? eventId;
  final String childId;
  final String sessionId;
  final String? activityId;
  final String source;
  final String eventType;
  final String? timestamp;
  final String? serverReceivedAt;
  final Map<String, dynamic> data;

  const EventModel({
    this.eventId,
    required this.childId,
    required this.sessionId,
    this.activityId,
    this.source = EventSource.flutter,
    required this.eventType,
    this.timestamp,
    this.serverReceivedAt,
    this.data = const {},
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      eventId: json['eventId'] as String?,
      childId: json['childId'] as String? ?? 'A001',
      sessionId: json['sessionId'] as String? ?? 'SES_LOCAL',
      activityId: json['activityId'] as String?,
      source: json['source'] as String? ?? EventSource.flutter,
      eventType: json['eventType'] as String? ?? EventType.answerSubmitted,
      timestamp: json['timestamp'] as String?,
      serverReceivedAt: json['serverReceivedAt'] as String?,
      data: json['data'] != null ? Map<String, dynamic>.from(json['data'] as Map) : const {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (eventId != null) 'eventId': eventId,
      'childId': childId,
      'sessionId': sessionId,
      if (activityId != null) 'activityId': activityId,
      'source': source,
      'eventType': eventType,
      if (timestamp != null) 'timestamp': timestamp,
      if (serverReceivedAt != null) 'serverReceivedAt': serverReceivedAt,
      'skill': data['skill'] ?? 'learning',
      'difficulty': data['difficulty'] ?? 1,
      'success': data['success'] ?? true,
      'accuracy': data['accuracy'] ?? 1.0,
      'reactionTimeMs': data['reactionTimeMs'] ?? 0,
      'errors': data['errors'] ?? 0,
      'attemptNumber': data['attemptNumber'] ?? 1,
      'inputType': data['inputType'] ?? 'touch',
      'data': data,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': eventId ?? 'event_${DateTime.now().microsecondsSinceEpoch}',
      'child_id': childId,
      'session_id': sessionId,
      'activity_id': activityId ?? 'general_activity',
      'skill': data['skill']?.toString() ?? 'learning',
      'difficulty': data['difficulty'] is int ? data['difficulty'] : 1,
      'success': (data['success'] == true || data['success'] == 1) ? 1 : 0,
      'accuracy': (data['accuracy'] is num) ? (data['accuracy'] as num).toDouble() : 1.0,
      'reaction_time_ms': data['reactionTimeMs'] is int ? data['reactionTimeMs'] : 0,
      'errors': data['errors'] is int ? data['errors'] : 0,
      'attempt_number': data['attemptNumber'] is int ? data['attemptNumber'] : 1,
      'input_type': data['inputType']?.toString() ?? 'touch',
      'timestamp': timestamp ?? DateTime.now().toIso8601String(),
      'synced': 0,
    };
  }

  factory EventModel.fromMap(Map<String, dynamic> map) {
    return EventModel(
      eventId: map['id'] as String?,
      childId: map['child_id'] as String? ?? 'child_default',
      sessionId: map['session_id'] as String? ?? 'session_default',
      activityId: map['activity_id'] as String?,
      source: EventSource.flutter,
      eventType: EventType.activityCompleted,
      timestamp: map['timestamp'] as String?,
      data: {
        'skill': map['skill'],
        'difficulty': map['difficulty'],
        'success': map['success'] == 1,
        'accuracy': map['accuracy'],
        'reactionTimeMs': map['reaction_time_ms'],
        'errors': map['errors'],
        'attemptNumber': map['attempt_number'],
        'inputType': map['input_type'],
      },
    );
  }

  @override
  String toString() {
    return 'EventModel(eventId: $eventId, source: $source, eventType: $eventType, childId: $childId, sessionId: $sessionId, activityId: $activityId)';
  }
}
