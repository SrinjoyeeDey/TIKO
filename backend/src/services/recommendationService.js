const Recommendation = require('../models/Recommendation');
const ProgressService = require('./progressService');
const AdaptiveService = require('./adaptiveService');
const ScoringService = require('./scoringService');
const ActivityService = require('./activityService');

class RecommendationService {
  /**
   * Get dynamic activity recommendation for a child using multi-factor priority scoring
   */
  static async getRecommendation(childId = 'A001') {
    // 1. Fetch child skill progress map
    const progressMap = await ProgressService.getProgress(childId);

    // 2. Fetch adaptive decision for recommended difficulty
    const decision = await AdaptiveService.evaluateChild(childId);
    const targetDifficulty = decision.recommendedDifficulty || 1;

    // 3. Fetch recent activities history to avoid immediate repetition (novelty)
    const recentResults = await ScoringService.getResultsByChild(childId);
    const recentActivityIds = recentResults.slice(-3).map(r => r.activityId);

    // 4. Candidate activities pool
    const baseActivities = await ActivityService.getActivitiesByStory('netaji');
    const extraSkillPool = [
      {
        activityId: 'netaji_q01',
        storyId: 'netaji',
        title: 'Who was Netaji?',
        type: 'mcq',
        skill: 'recognition',
        difficulty: 1,
        question: 'Who was known as Netaji?',
        options: ['Subhas Chandra Bose', 'Mahatma Gandhi', 'Sardar Patel', 'Jawaharlal Nehru'],
        correctAnswer: 0,
        reward: 20
      },
      {
        activityId: 'netaji_q02',
        storyId: 'netaji',
        title: "Netaji's Escape Sequence",
        type: 'sequencing',
        skill: 'sequencing',
        difficulty: 1,
        question: "Arrange the events of Netaji's Great Escape in chronological order.",
        options: ['Great Escape', 'Forming INA', 'Give Me Blood Speech', 'Delhi Chalo'],
        correctAnswer: 0,
        reward: 30
      },
      {
        activityId: 'netaji_q03',
        storyId: 'netaji',
        title: 'Match Netaji Slogans & Symbols',
        type: 'matching',
        skill: 'motor',
        difficulty: 1,
        question: 'Match each famous Netaji quote or emblem with its correct description.',
        reward: 40
      },
      {
        activityId: 'speech_01',
        storyId: 'netaji',
        title: 'Netaji Slogan Speech Challenge',
        type: 'voice',
        skill: 'speech',
        difficulty: 2,
        question: 'Say "Jai Hind!" clearly into your microphone.',
        reward: 25
      },
      {
        activityId: 'memory_01',
        storyId: 'netaji',
        title: 'INA Flag Memory Challenge',
        type: 'memory',
        skill: 'memory',
        difficulty: 2,
        question: 'Remember the sequence of INA flag colors.',
        reward: 25
      }
    ];

    // Combine pool avoiding duplicate activity IDs
    const activityMap = new Map();
    [...baseActivities, ...extraSkillPool].forEach(act => {
      activityMap.set(act.activityId, act);
    });
    const candidates = Array.from(activityMap.values());

    // 5. Evaluate priority for each candidate activity
    candidates.forEach(candidate => {
      const skill = candidate.skill || 'recognition';
      const p = progressMap[skill] || { score: 60, trend: 'stable' };

      // Factor 1: Skill Need (40%) -> Lower score = Higher need
      const skillNeed = (100.0 - (p.score || 50.0)) / 100.0;

      // Factor 2: Trend Factor (20%) -> Declining needs urgency
      let trendFactor = 0.10;
      if (p.trend === 'declining') trendFactor = 0.20;
      else if (p.trend === 'improving') trendFactor = 0.05;

      // Factor 3: Difficulty Match (25%)
      const candDiff = candidate.difficulty || 1;
      const diffMatch = Math.max(0.0, 1.0 - Math.abs(candDiff - targetDifficulty) * 0.4);

      // Factor 4: Novelty (15%) -> Penalize if performed recently
      const novelty = recentActivityIds.includes(candidate.activityId) ? 0.0 : 0.15;

      // Calculate Total Weighted Priority Score
      const totalPriority = Math.min(1.0, 
        (skillNeed * 0.40) + 
        (trendFactor * 0.20) + 
        (diffMatch * 0.25) + 
        (novelty * 0.15)
      );

      candidate.priority = Math.round(totalPriority * 100) / 100;
    });

    // 6. Sort by priority descending
    candidates.sort((a, b) => b.priority - a.priority);

    // 7. Select top recommended activity
    const topCandidate = candidates[0];
    const topSkillProgress = progressMap[topCandidate.skill] || { score: 50, trend: 'stable' };

    const reason = `${topCandidate.skill.toUpperCase()} is currently a priority skill (score: ${topSkillProgress.score}%, trend: ${topSkillProgress.trend}) matching Level ${topCandidate.difficulty} challenge.`;

    const recommendation = new Recommendation({
      recommendationId: `REC_${Date.now()}`,
      childId,
      activityId: topCandidate.activityId,
      skill: topCandidate.skill,
      difficulty: topCandidate.difficulty,
      priority: topCandidate.priority,
      reason,
      generatedAt: new Date().toISOString()
    });

    console.log(`🎯 [RECOMMENDATION ENGINE] Recommended ${topCandidate.activityId} (${topCandidate.skill}) | Priority: ${topCandidate.priority} | Reason: ${reason}`);

    return {
      success: true,
      recommendation: recommendation.toJSON(),
      activity: topCandidate
    };
  }
}

module.exports = RecommendationService;
