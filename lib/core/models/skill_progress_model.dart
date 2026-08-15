/// Represents longitudinal progress, score, and trend for a specific skill.
class SkillProgressModel {
  final String skill;
  final int score;
  final int activitiesCompleted;
  final double averageAccuracy;
  final double averageResponseTime;
  final int lastScore;
  final String trend; // improving, declining, stable

  const SkillProgressModel({
    required this.skill,
    this.score = 50,
    this.activitiesCompleted = 0,
    this.averageAccuracy = 100.0,
    this.averageResponseTime = 5.0,
    this.lastScore = 50,
    this.trend = 'stable',
  });

  factory SkillProgressModel.fromJson(Map<String, dynamic> json) {
    return SkillProgressModel(
      skill: json['skill'] as String? ?? 'recognition',
      score: json['score'] as int? ?? 50,
      activitiesCompleted: json['activitiesCompleted'] as int? ?? 0,
      averageAccuracy: (json['averageAccuracy'] as num?)?.toDouble() ?? 100.0,
      averageResponseTime: (json['averageResponseTime'] as num?)?.toDouble() ?? 5.0,
      lastScore: json['lastScore'] as int? ?? 50,
      trend: json['trend'] as String? ?? 'stable',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'skill': skill,
      'score': score,
      'activitiesCompleted': activitiesCompleted,
      'averageAccuracy': averageAccuracy,
      'averageResponseTime': averageResponseTime,
      'lastScore': lastScore,
      'trend': trend,
    };
  }

  @override
  String toString() {
    return 'SkillProgressModel(skill: $skill, score: $score, trend: $trend, activities: $activitiesCompleted)';
  }
}
