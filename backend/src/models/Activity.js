/**
 * Activity Model Schema Definition & Factory
 */
class Activity {
  constructor({
    id,
    activityId,
    storyId = 'netaji',
    title = 'Interactive Activity',
    type = 'mcq',
    skill = 'recognition',
    difficulty = 1,
    question = '',
    options = [],
    correctAnswer = 0,
    maxAttempts = 3,
    reward = 20,
    order = 1
  }) {
    const activeId = activityId || id || `ACT_${Date.now()}`;
    this.activityId = activeId;
    this.id = activeId;
    this.storyId = storyId;
    this.title = title;
    this.type = type;
    this.skill = skill;
    this.difficulty = difficulty;
    this.question = question;
    this.options = Array.isArray(options) ? options : [];
    this.correctAnswer = correctAnswer;
    this.maxAttempts = maxAttempts;
    this.reward = reward;
    this.order = order;
  }

  toJSON() {
    return {
      activityId: this.activityId,
      storyId: this.storyId,
      title: this.title,
      type: this.type,
      skill: this.skill,
      difficulty: this.difficulty,
      question: this.question,
      options: this.options,
      correctAnswer: this.correctAnswer,
      maxAttempts: this.maxAttempts,
      reward: this.reward,
      order: this.order
    };
  }
}

module.exports = Activity;
