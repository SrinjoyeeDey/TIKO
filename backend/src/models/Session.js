/**
 * Session Model Schema Definition & Factory
 */
class Session {
  constructor({
    sessionId,
    id,
    childId,
    storyId = 'netaji',
    startedAt = new Date().toISOString(),
    endedAt = null,
    duration = null,
    status = 'active',
    activitiesCompleted = 0,
    currentActivityId = null,
    interactions = [],
    summary = null
  }) {
    const activeSessionId = sessionId || id || `SES_${Date.now().toString().slice(-4)}`;
    this.sessionId = activeSessionId;
    this.id = activeSessionId;
    this.childId = childId;
    this.storyId = storyId;
    this.startedAt = startedAt;
    this.endedAt = endedAt;
    this.duration = duration;
    this.status = status;
    this.activitiesCompleted = activitiesCompleted;
    this.currentActivityId = currentActivityId;
    this.interactions = Array.isArray(interactions) ? interactions : [];
    this.summary = summary;
  }

  /**
   * Increment count of completed activities in this session
   */
  incrementActivities() {
    this.activitiesCompleted += 1;
    return this.activitiesCompleted;
  }

  /**
   * Log a real interaction event during session
   */
  addInteraction(data) {
    const interaction = {
      timestamp: new Date().toISOString(),
      type: data.type || 'action',
      questionId: data.questionId || null,
      isCorrect: data.isCorrect ?? true,
      timeTakenSeconds: data.timeTakenSeconds || 0,
      details: data.details || {}
    };
    this.interactions.push(interaction);
    return interaction;
  }

  /**
   * End session, calculate duration = endedAt - startedAt, and set status to completed
   */
  endSession(customEndedAt = null) {
    this.endedAt = customEndedAt || new Date().toISOString();
    this.status = 'completed';

    // Compute duration in seconds: duration = endedAt - startedAt
    const startMs = new Date(this.startedAt).getTime();
    const endMs = new Date(this.endedAt).getTime();
    this.duration = Math.max(0, Math.round((endMs - startMs) / 1000));

    // Compute summary
    const totalInteractions = this.interactions.length;
    const correctAnswers = this.interactions.filter(i => i.isCorrect).length;
    const accuracy = totalInteractions > 0 
      ? Math.round((correctAnswers / totalInteractions) * 100) 
      : 100;
    const xpEarned = (correctAnswers * 10) + 50;

    this.summary = {
      totalInteractions,
      correctAnswers,
      accuracy,
      xpEarned
    };

    return this;
  }

  toJSON() {
    return {
      sessionId: this.sessionId,
      childId: this.childId,
      storyId: this.storyId,
      startedAt: this.startedAt,
      endedAt: this.endedAt,
      duration: this.duration,
      status: this.status,
      activitiesCompleted: this.activitiesCompleted,
      ...(this.summary ? { summary: this.summary } : {})
    };
  }
}

module.exports = Session;
