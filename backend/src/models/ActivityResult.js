/**
 * ActivityResult Model Schema Definition & Factory
 */
class ActivityResult {
  constructor({
    resultId,
    activityId,
    sessionId,
    childId,
    correct = true,
    attempts = 1,
    hintsUsed = 0,
    responseTime = 0.0,
    difficulty = 1,
    score = 100,
    xpEarned = 20,
    skill = 'recognition',
    completedAt = new Date().toISOString()
  }) {
    const id = resultId || `RES_${Date.now()}`;
    this.resultId = id;
    this.activityId = activityId;
    this.sessionId = sessionId;
    this.childId = childId;
    this.correct = correct;
    this.attempts = attempts;
    this.hintsUsed = hintsUsed;
    this.responseTime = responseTime;
    this.difficulty = difficulty;
    this.score = score;
    this.xpEarned = xpEarned;
    this.skill = skill;
    this.completedAt = completedAt;
  }

  toJSON() {
    return {
      resultId: this.resultId,
      activityId: this.activityId,
      sessionId: this.sessionId,
      childId: this.childId,
      correct: this.correct,
      attempts: this.attempts,
      hintsUsed: this.hintsUsed,
      responseTime: this.responseTime,
      difficulty: this.difficulty,
      score: this.score,
      xpEarned: this.xpEarned,
      skill: this.skill,
      completedAt: this.completedAt,
    };
  }
}

module.exports = ActivityResult;
