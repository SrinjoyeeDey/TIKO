const Session = require('../models/Session');
const Activity = require('../models/Activity');
const ChildService = require('./childService');

const sessionsStore = new Map();
const activitiesStore = new Map();
let sessionCounter = 1;

// Pre-seed default active session SES_001 for child A001
const defaultSession = new Session({
  sessionId: 'SES_001',
  childId: 'A001',
  storyId: 'netaji',
  startedAt: new Date().toISOString(),
  endedAt: null,
  duration: null,
  status: 'active',
  activitiesCompleted: 0,
  currentActivityId: 'ACT_001'
});
sessionsStore.set('SES_001', defaultSession);

class SessionService {
  /**
   * Create and start a new session for a child and story
   */
  static async startSession(childId, storyId = 'netaji') {
    const formattedId = `SES_${String(sessionCounter++).padStart(3, '0')}`;
    const sessionId = formattedId;
    const initialActivityId = `ACT_${Date.now()}`;

    const activity = new Activity({
      id: initialActivityId,
      sessionId: sessionId,
      type: 'story',
      title: `Story Chapter - ${storyId}`,
      score: 0,
      status: 'in_progress'
    });
    activitiesStore.set(initialActivityId, activity);

    const session = new Session({
      sessionId: sessionId,
      childId: childId,
      storyId: storyId || 'netaji',
      startedAt: new Date().toISOString(),
      endedAt: null,
      duration: null,
      status: 'active',
      activitiesCompleted: 0,
      currentActivityId: initialActivityId
    });

    sessionsStore.set(sessionId, session);
    return session;
  }

  /**
   * Get session by sessionId
   */
  static async getSessionById(sessionId) {
    return sessionsStore.get(sessionId) || null;
  }

  /**
   * Increment activities completed count for a session
   */
  static async incrementActivities(sessionId) {
    const session = sessionsStore.get(sessionId);
    if (!session) return null;

    session.incrementActivities();
    sessionsStore.set(sessionId, session);
    return session;
  }

  /**
   * End session: records endedAt, calculates duration = endedAt - startedAt, sets status to completed
   */
  static async endSession(sessionId, customEndedAt = null) {
    const session = sessionsStore.get(sessionId);
    if (!session) return null;

    session.endSession(customEndedAt);
    sessionsStore.set(sessionId, session);

    // Sync XP earned to child profile
    if (session.childId && session.summary && session.summary.xpEarned) {
      const child = await ChildService.getChildById(session.childId);
      if (child) {
        const newXp = child.xp + session.summary.xpEarned;
        const newLevel = Math.floor(newXp / 100) + 1;
        await ChildService.updateChild(session.childId, {
          xp: newXp,
          level: newLevel
        });
      }
    }

    return session;
  }

  /**
   * Log an interaction event during session
   */
  static async logInteraction(sessionId, interactionData) {
    const session = sessionsStore.get(sessionId);
    if (!session) return null;

    const interaction = session.addInteraction(interactionData);
    sessionsStore.set(sessionId, session);
    return { session, interaction };
  }

  /**
   * Update session properties
   */
  static async updateSession(sessionId, updates) {
    const session = sessionsStore.get(sessionId);
    if (!session) return null;

    if (updates.status !== undefined) session.status = updates.status;
    if (updates.endedAt !== undefined) session.endedAt = updates.endedAt;
    if (updates.currentActivityId !== undefined) session.currentActivityId = updates.currentActivityId;
    if (updates.storyId !== undefined) session.storyId = updates.storyId;
    if (updates.activitiesCompleted !== undefined) session.activitiesCompleted = updates.activitiesCompleted;

    sessionsStore.set(sessionId, session);
    return session;
  }
}

module.exports = SessionService;
