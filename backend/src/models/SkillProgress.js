/**
 * SkillProgress Model Schema Definition & Factory
 */
class SkillProgress {
  constructor({
    skill,
    score = 50,
    activitiesCompleted = 0,
    averageAccuracy = 100.0,
    averageResponseTime = 5.0,
    lastScore = 50,
    trend = 'stable'
  }) {
    this.skill = skill;
    this.score = score;
    this.activitiesCompleted = activitiesCompleted;
    this.averageAccuracy = averageAccuracy;
    this.averageResponseTime = averageResponseTime;
    this.lastScore = lastScore;
    this.trend = trend;
  }

  toJSON() {
    return {
      skill: this.skill,
      score: this.score,
      activitiesCompleted: this.activitiesCompleted,
      averageAccuracy: Math.round(this.averageAccuracy * 10) / 10,
      averageResponseTime: Math.round(this.averageResponseTime * 10) / 10,
      lastScore: this.lastScore,
      trend: this.trend,
    };
  }
}

module.exports = SkillProgress;
