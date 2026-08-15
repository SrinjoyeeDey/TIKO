/**
 * Recommendation Model Schema Definition & Factory
 */
class Recommendation {
  constructor({
    recommendationId,
    childId,
    activityId,
    skill,
    difficulty = 1,
    priority = 0.5,
    reason,
    generatedAt = new Date().toISOString()
  }) {
    const id = recommendationId || `REC_${Date.now()}`;
    this.recommendationId = id;
    this.childId = childId;
    this.activityId = activityId;
    this.skill = skill;
    this.difficulty = difficulty;
    this.priority = priority;
    this.reason = reason || `${skill} activity recommended based on priority scoring.`;
    this.generatedAt = generatedAt;
  }

  toJSON() {
    return {
      recommendationId: this.recommendationId,
      childId: this.childId,
      activityId: this.activityId,
      skill: this.skill,
      difficulty: this.difficulty,
      priority: Math.round(this.priority * 100) / 100,
      reason: this.reason,
      generatedAt: this.generatedAt,
    };
  }
}

module.exports = Recommendation;
