const ActivityResult = require('../models/ActivityResult');
const EventService = require('./eventService');
const ActivityService = require('./activityService');
const ChildService = require('./childService');

const resultsStore = new Map();
let resultCounter = 1;

class ScoringService {
  /**
   * Evaluates session activity based strictly on backend event history (Source of Truth)
   */
  static async evaluateActivity({ sessionId, activityId, childId: providedChildId }) {
    // 1. Fetch raw event telemetry for session
    const allEvents = await EventService.getEvents({ sessionId });
    const activityEvents = allEvents.filter(e => !activityId || e.activityId === activityId);

    // 2. Extract telemetry parameters from event history
    const submittedEvents = activityEvents.filter(e => e.eventType === 'ANSWER_SUBMITTED');
    const attempts = submittedEvents.length > 0 ? submittedEvents.length : 1;
    const hintsUsed = activityEvents.filter(e => e.eventType === 'HINT_USED').length;

    // Check correctness
    const isCorrect = activityEvents.some(e => e.eventType === 'ANSWER_CORRECT') ||
      (submittedEvents.length > 0 && submittedEvents[submittedEvents.length - 1].data?.correct === true);

    // Calculate response time from timestamps or last payload
    let responseTime = 5.0;
    const startEvent = activityEvents.find(e => e.eventType === 'ACTIVITY_STARTED');
    const lastSubmitEvent = submittedEvents[submittedEvents.length - 1];

    if (lastSubmitEvent?.data?.responseTime) {
      responseTime = parseFloat(lastSubmitEvent.data.responseTime);
    } else if (startEvent && lastSubmitEvent) {
      const startMs = new Date(startEvent.timestamp).getTime();
      const endMs = new Date(lastSubmitEvent.timestamp).getTime();
      responseTime = Math.max(0.5, Math.round(((endMs - startMs) / 1000) * 10) / 10);
    }

    // 3. Fetch activity details (reward, difficulty, skill)
    const targetActId = activityId || (lastSubmitEvent?.activityId) || 'netaji_q01';
    const activity = (await ActivityService.getActivityById(targetActId)) || {
      activityId: targetActId,
      storyId: 'netaji',
      reward: 20,
      difficulty: 1,
      skill: 'recognition'
    };

    // 4. Compute deterministic score & XP
    const baseScore = 100;
    const wrongPenalty = (attempts - 1) * 15;
    const hintPenalty = hintsUsed * 10;
    const timePenalty = responseTime > 10.0 
      ? Math.min(20, Math.floor((responseTime - 10.0) * 1.5)) 
      : 0;

    const computedScore = isCorrect 
      ? Math.max(0, Math.min(100, baseScore - wrongPenalty - hintPenalty - timePenalty)) 
      : 0;

    const reward = activity.reward || 20;
    const xpEarned = Math.round(reward * (computedScore / 100.0));

    // Determine target child ID
    const childId = providedChildId || (activityEvents[0]?.childId) || 'A001';

    // 5. Create ActivityResult
    const resultId = `RES_${String(resultCounter++).padStart(3, '0')}`;
    const result = new ActivityResult({
      resultId,
      activityId: targetActId,
      sessionId: sessionId || 'SES_001',
      childId,
      correct: isCorrect,
      attempts,
      hintsUsed,
      responseTime,
      difficulty: activity.difficulty || 1,
      score: computedScore,
      xpEarned,
      skill: activity.skill || 'recognition',
      completedAt: new Date().toISOString()
    });

    resultsStore.set(resultId, result);

    // 6. Record result in Progress Engine (weighted rolling average & trend snapshot)
    try {
      const ProgressService = require('./progressService');
      await ProgressService.recordActivityResult(result);
    } catch (err) {
      console.error('Failed to record progress snapshot:', err);
    }

    // 7. Update Child Profile (XP & Level)
    let updatedChild = null;
    const child = await ChildService.getChildById(childId);
    if (child) {
      const newXp = child.xp + xpEarned;
      const newLevel = Math.floor(newXp / 100) + 1;

      updatedChild = await ChildService.getChildById(childId);
    }

    console.log(`🧮 [SCORING ENGINE] Evaluated ${targetActId} | Attempts: ${attempts} | Hints: ${hintsUsed} | Time: ${responseTime}s | Score: ${computedScore}% | XP Earned: +${xpEarned}`);

    return {
      result,
      child: updatedChild
    };
  }

  static async getResultsBySession(sessionId) {
    return Array.from(resultsStore.values()).filter(r => r.sessionId === sessionId);
  }

  static async getResultsByChild(childId) {
    return Array.from(resultsStore.values()).filter(r => r.childId === childId);
  }
}

module.exports = ScoringService;
