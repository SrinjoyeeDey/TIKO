/// Represents an explainable adaptation decision made by NIMO's Adaptive Engine.
class AdaptiveDecisionModel {
  final String decisionId;
  final String childId;
  final String skill;
  final int currentDifficulty;
  final int recommendedDifficulty;
  final String reason;
  final String generatedAt;

  const AdaptiveDecisionModel({
    required this.decisionId,
    required this.childId,
    required this.skill,
    this.currentDifficulty = 2,
    this.recommendedDifficulty = 2,
    required this.reason,
    required this.generatedAt,
  });

  factory AdaptiveDecisionModel.fromJson(Map<String, dynamic> json) {
    return AdaptiveDecisionModel(
      decisionId: json['decisionId'] as String? ?? 'DEC_LOCAL',
      childId: json['childId'] as String? ?? 'A001',
      skill: json['skill'] as String? ?? 'sequencing',
      currentDifficulty: json['currentDifficulty'] as int? ?? 2,
      recommendedDifficulty: json['recommendedDifficulty'] as int? ?? 2,
      reason: json['reason'] as String? ?? 'Maintaining level practice.',
      generatedAt: json['generatedAt'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'decisionId': decisionId,
      'childId': childId,
      'skill': skill,
      'currentDifficulty': currentDifficulty,
      'recommendedDifficulty': recommendedDifficulty,
      'reason': reason,
      'generatedAt': generatedAt,
    };
  }

  @override
  String toString() {
    return 'AdaptiveDecisionModel(skill: $skill, curr: $currentDifficulty -> rec: $recommendedDifficulty, reason: $reason)';
  }
}
