/// Represents a backend-driven learning activity.
class ActivityModel {
  final String activityId;
  final String storyId;
  final String title;
  final String type; // mcq, sequencing, matching, voice, memory, drag_drop
  final String skill; // recognition, sequencing, motor, speech, etc.
  final int difficulty;
  final String question;
  final List<dynamic> options;
  final dynamic correctAnswer;
  final int maxAttempts;
  final int reward;
  final int order;

  final String? targetPhrase;

  const ActivityModel({
    required this.activityId,
    required this.storyId,
    required this.title,
    required this.type,
    required this.skill,
    this.difficulty = 1,
    required this.question,
    this.targetPhrase,
    this.options = const [],
    this.correctAnswer = 0,
    this.maxAttempts = 3,
    this.reward = 20,
    this.order = 1,
  });

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      activityId: json['activityId'] as String? ?? json['id'] as String? ?? 'act_01',
      storyId: json['storyId'] as String? ?? 'netaji',
      title: json['title'] as String? ?? 'Activity',
      type: json['type'] as String? ?? 'mcq',
      skill: json['skill'] as String? ?? 'recognition',
      difficulty: json['difficulty'] as int? ?? 1,
      question: json['question'] as String? ?? '',
      targetPhrase: json['targetPhrase'] as String? ?? json['target_phrase'] as String?,
      options: json['options'] is List ? List<dynamic>.from(json['options'] as List) : const [],
      correctAnswer: json['correctAnswer'],
      maxAttempts: json['maxAttempts'] as int? ?? 3,
      reward: json['reward'] as int? ?? 20,
      order: json['order'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'activityId': activityId,
      'storyId': storyId,
      'title': title,
      'type': type,
      'skill': skill,
      'difficulty': difficulty,
      'question': question,
      'targetPhrase': targetPhrase,
      'options': options,
      'correctAnswer': correctAnswer,
      'maxAttempts': maxAttempts,
      'reward': reward,
      'order': order,
    };
  }

  @override
  String toString() {
    return 'ActivityModel(activityId: $activityId, type: $type, title: $title, order: $order)';
  }
}
