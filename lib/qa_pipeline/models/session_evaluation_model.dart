import 'dart:convert';

/// Data model representing a post-level clinical and cognitive session evaluation,
/// stored in SQLite and sent to Groq LLM to calculate adaptive difficulty.
class SessionClinicalEvaluation {
  final String id;
  final String childId;
  final String sessionId;
  final String? chapterId;
  final String? levelId;
  final String currentAbility;
  final String previousPerformance;
  final String preferredInteraction;
  final String speechAbility;
  final String motorPerformance;
  final String attentionPattern;
  final String learningHistory;
  final int difficultyPercentage;
  final String difficultyLevel;
  final String difficultyReasoning;
  final List<String> recommendations;
  final DateTime createdAt;

  SessionClinicalEvaluation({
    required this.id,
    required this.childId,
    required this.sessionId,
    this.chapterId,
    this.levelId,
    required this.currentAbility,
    required this.previousPerformance,
    required this.preferredInteraction,
    required this.speechAbility,
    required this.motorPerformance,
    required this.attentionPattern,
    required this.learningHistory,
    required this.difficultyPercentage,
    required this.difficultyLevel,
    required this.difficultyReasoning,
    required this.recommendations,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'child_id': childId,
      'session_id': sessionId,
      'chapter_id': chapterId,
      'level_id': levelId,
      'current_ability': currentAbility,
      'previous_performance': previousPerformance,
      'preferred_interaction': preferredInteraction,
      'speech_ability': speechAbility,
      'motor_performance': motorPerformance,
      'attention_pattern': attentionPattern,
      'learning_history': learningHistory,
      'difficulty_percentage': difficultyPercentage,
      'difficulty_level': difficultyLevel,
      'difficulty_reasoning': difficultyReasoning,
      'recommendations': json.encode(recommendations),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SessionClinicalEvaluation.fromMap(Map<String, dynamic> map) {
    List<String> recs = [];
    if (map['recommendations'] != null) {
      try {
        final decoded = json.decode(map['recommendations'] as String);
        if (decoded is List) {
          recs = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }

    return SessionClinicalEvaluation(
      id: map['id'] as String,
      childId: map['child_id'] as String,
      sessionId: map['session_id'] as String,
      chapterId: map['chapter_id'] as String?,
      levelId: map['level_id'] as String?,
      currentAbility: (map['current_ability'] as String?) ?? '',
      previousPerformance: (map['previous_performance'] as String?) ?? '',
      preferredInteraction: (map['preferred_interaction'] as String?) ?? '',
      speechAbility: (map['speech_ability'] as String?) ?? '',
      motorPerformance: (map['motor_performance'] as String?) ?? '',
      attentionPattern: (map['attention_pattern'] as String?) ?? '',
      learningHistory: (map['learning_history'] as String?) ?? '',
      difficultyPercentage: (map['difficulty_percentage'] as num?)?.toInt() ?? 50,
      difficultyLevel: (map['difficulty_level'] as String?) ?? 'Balanced Explorer',
      difficultyReasoning: (map['difficulty_reasoning'] as String?) ?? '',
      recommendations: recs,
      createdAt: DateTime.tryParse((map['created_at'] as String?) ?? '') ?? DateTime.now(),
    );
  }
}
