/**
 * AdaptiveDecision Model Schema Definition & Factory
 */
class AdaptiveDecision {
  constructor({
    decisionId,
    childId,
    skill,
    currentDifficulty = 2,
    recommendedDifficulty = 2,
    reason,
    generatedAt = new Date().toISOString()
  }) {
    const id = decisionId || `DEC_${Date.now()}`;
    this.decisionId = id;
    this.childId = childId;
    this.skill = skill;
    this.currentDifficulty = currentDifficulty;
    this.recommendedDifficulty = recommendedDifficulty;
    this.reason = reason || `Adapting difficulty to Level ${recommendedDifficulty} for ${skill}`;
    this.generatedAt = generatedAt;
  }

  toJSON() {
    return {
      decisionId: this.decisionId,
      childId: this.childId,
      skill: this.skill,
      currentDifficulty: this.currentDifficulty,
      recommendedDifficulty: this.recommendedDifficulty,
      reason: this.reason,
      generatedAt: this.generatedAt,
    };
  }
}

module.exports = AdaptiveDecision;
