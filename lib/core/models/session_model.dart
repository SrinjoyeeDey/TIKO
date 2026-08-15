/// Represents an active or completed learning session.
class SessionModel {
  final String sessionId;
  final String id;
  final String childId;
  final String storyId;
  final String startedAt;
  final String? endedAt;
  final int? duration;
  final String status;
  final int activitiesCompleted;
  final Map<String, dynamic>? summary;

  const SessionModel({
    required this.sessionId,
    String? id,
    required this.childId,
    this.storyId = 'netaji',
    required this.startedAt,
    this.endedAt,
    this.duration,
    this.status = 'active',
    this.activitiesCompleted = 0,
    this.summary,
  }) : id = id ?? sessionId;

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    final activeSessionId = json['sessionId'] as String? ?? json['id'] as String? ?? 'SES_LOCAL';
    final start = json['startedAt'] as String? ?? json['startTime'] as String? ?? DateTime.now().toIso8601String();
    
    return SessionModel(
      sessionId: activeSessionId,
      id: activeSessionId,
      childId: json['childId'] as String? ?? 'A001',
      storyId: json['storyId'] as String? ?? 'netaji',
      startedAt: start,
      endedAt: json['endedAt'] as String? ?? json['endTime'] as String?,
      duration: json['duration'] as int? ?? json['durationSeconds'] as int?,
      status: json['status'] as String? ?? 'active',
      activitiesCompleted: json['activitiesCompleted'] as int? ?? 0,
      summary: json['summary'] != null ? Map<String, dynamic>.from(json['summary'] as Map) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'childId': childId,
      'storyId': storyId,
      'startedAt': startedAt,
      'endedAt': endedAt,
      'duration': duration,
      'status': status,
      'activitiesCompleted': activitiesCompleted,
      if (summary != null) 'summary': summary,
    };
  }

  SessionModel copyWith({
    String? sessionId,
    String? childId,
    String? storyId,
    String? startedAt,
    String? endedAt,
    int? duration,
    String? status,
    int? activitiesCompleted,
    Map<String, dynamic>? summary,
  }) {
    return SessionModel(
      sessionId: sessionId ?? this.sessionId,
      childId: childId ?? this.childId,
      storyId: storyId ?? this.storyId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      duration: duration ?? this.duration,
      status: status ?? this.status,
      activitiesCompleted: activitiesCompleted ?? this.activitiesCompleted,
      summary: summary ?? this.summary,
    );
  }

  @override
  String toString() {
    return 'SessionModel(sessionId: $sessionId, childId: $childId, storyId: $storyId, duration: $duration, activitiesCompleted: $activitiesCompleted, status: $status)';
  }
}
