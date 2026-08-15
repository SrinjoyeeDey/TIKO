const AdaptiveDecision = require('../models/AdaptiveDecision');
const ProgressService = require('./progressService');
const ScoringService = require('./scoringService');
const ActivityService = require('./activityService');

const decisionsStore = new Map(); // childId -> AdaptiveDecision

class AdaptiveService {
  /**
   * Evaluates child's performance over a 5-activity window and computes adaptive decision
   */
  static async evaluateChild(childId = 'A001', explicitSkill = null) {
    // 1. Fetch all skill progress to find weakest skill if not explicitly specified
    const progressMap = await ProgressService.getProgress(childId);
    let targetSkill = explicitSkill;

    if (!targetSkill) {
      let minScore = Infinity;
      Object.keys(progressMap).forEach(skillKey => {
        const p = progressMap[skillKey];
        if (p.score < minScore) {
          minScore = p.score;
          targetSkill = skillKey;
        }
      });
    }
    if (!targetSkill) targetSkill = 'sequencing';

    // 2. Fetch recent activity results window (last 5 results for target skill)
    const allResults = await ScoringService.getResultsByChild(childId);
    const skillResults = allResults.filter(r => r.skill === targetSkill);
    const window = skillResults.slice(-5);

    // 3. Compute window metrics
    let avgScore = 60;
    let avgAccuracy = 80;
    let avgHints = 0;
    let currentDifficulty = 2;

    if (window.length > 0) {
      avgScore = Math.round(window.reduce((acc, r) => acc + (r.score || 0), 0) / window.length);
      avgAccuracy = Math.round(window.reduce((acc, r) => {
        const attempts = r.attempts || 1;
        const accPct = r.correct ? (1 / attempts) * 100.0 : 0.0;
        return acc + accPct;
      }, 0) / window.length);
      avgHints = Math.round((window.reduce((acc, r) => acc + (r.hintsUsed || 0), 0) / window.length) * 10) / 10;
      currentDifficulty = window[window.length - 1].difficulty || 2;
    } else {
      const p = progressMap[targetSkill];
      if (p) {
        avgScore = p.score;
        avgAccuracy = Math.round(p.averageAccuracy || 80);
      }
    }

    // 4. Rule-Based Decision Logic
    let recommendedDifficulty = currentDifficulty;
    let reason = '';

    if (avgScore < 50 || avgAccuracy < 55) {
      // Struggling Child Rule
      recommendedDifficulty = Math.max(1, currentDifficulty - 1);
      reason = `Recent ${targetSkill} accuracy (${avgAccuracy}%) and score (${avgScore}%) are below target. Adjusting difficulty to Level ${recommendedDifficulty} for skill reinforcement.`;
    } else if (avgScore > 80 && avgAccuracy > 85 && avgHints === 0) {
      // Thriving Child Rule
      recommendedDifficulty = Math.min(3, currentDifficulty + 1);
      reason = `Child is excelling at ${targetSkill} (score: ${avgScore}%, accuracy: ${avgAccuracy}%). Advancing challenge to Level ${recommendedDifficulty}!`;
    } else {
      // Steady Child Rule
      recommendedDifficulty = currentDifficulty;
      reason = `Child shows steady performance in ${targetSkill} (score: ${avgScore}%). Maintaining Level ${recommendedDifficulty} practice.`;
    }

    // Clamp difficulty to range [1, 3]
    recommendedDifficulty = Math.max(1, Math.min(3, recommendedDifficulty));

    // 5. Create and store decision
    const decision = new AdaptiveDecision({
      decisionId: `DEC_${Date.now()}`,
      childId,
      skill: targetSkill,
      currentDifficulty,
      recommendedDifficulty,
      reason,
      generatedAt: new Date().toISOString()
    });

    decisionsStore.set(childId, decision);
    console.log(`🔥 [ADAPTIVE ENGINE] ${childId} | Skill: ${targetSkill} | Curr: Diff ${currentDifficulty} → Rec: Diff ${recommendedDifficulty} | Reason: ${reason}`);

    return decision;
  }

  /**
   * Generates the next tailored activity & adaptation rationale for a child
   */
  static async getNextActivity(childId = 'A001', explicitSkill = null) {
    const decision = await AdaptiveService.evaluateChild(childId, explicitSkill);

    // Fetch existing activity matching skill and difficulty
    const storyActivities = await ActivityService.getActivitiesByStory('netaji');
    let matchingAct = storyActivities.find(a => 
      a.skill === decision.skill && a.difficulty === decision.recommendedDifficulty
    );

    if (!matchingAct) {
      // Construct fallback tailored activity
      matchingAct = {
        activityId: `netaji_${decision.skill}_diff${decision.recommendedDifficulty}`,
        storyId: 'netaji',
        title: `Netaji ${decision.skill.toUpperCase()} Challenge`,
        type: decision.skill === 'sequencing' ? 'sequencing' : (decision.skill === 'motor' ? 'matching' : 'mcq'),
        skill: decision.skill,
        difficulty: decision.recommendedDifficulty,
        question: `Level ${decision.recommendedDifficulty} ${decision.skill} activity tailored for child performance.`,
        options: decision.skill === 'sequencing'
          ? ["Great Escape", "Forming INA", "Give Me Blood Speech", "Delhi Chalo"]
          : ["Subhas Chandra Bose", "Mahatma Gandhi", "Sardar Patel", "Jawaharlal Nehru"],
        correctAnswer: 0,
        maxAttempts: 3,
        reward: decision.recommendedDifficulty * 10 + 10,
        order: 1
      };
    }

    return {
      success: true,
      decision: decision.toJSON(),
      recommendedActivity: matchingAct
    };
  }
}

module.exports = AdaptiveService;
