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
      'data': data,
    };
  }

  @override
  String toString() {
    return 'EventModel(eventId: $eventId, source: $source, eventType: $eventType, childId: $childId, sessionId: $sessionId, activityId: $activityId)';
  }
}
