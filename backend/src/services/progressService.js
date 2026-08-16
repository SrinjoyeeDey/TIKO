const SkillProgress = require('../models/SkillProgress');
const ProgressSnapshot = require('../models/ProgressSnapshot');
const ChildService = require('./childService');

const childProgressMap = new Map(); // childId -> Map<skill, SkillProgress>
const snapshotsMap = new Map();     // childId -> List<ProgressSnapshot>

const INITIAL_SKILLS = [
  'speech',
  'memory',
  'attention',
  'sequencing',
  'motor',
  'recognition',
  'problem_solving'
];

/**
 * Initialize default progress state for a child
 */
function getOrCreateChildSkills(childId) {
  if (!childProgressMap.has(childId)) {
    const skillsMap = new Map();
    const defaultChildSkills = {
      speech: 80,
      memory: 75,
      attention: 70,
      sequencing: 65,
      motor: 90,
      recognition: 78,
      problem_solving: 60
    };

    INITIAL_SKILLS.forEach(skill => {
      const initScore = defaultChildSkills[skill] || 60;
      skillsMap.set(skill, new SkillProgress({
        skill,
        score: initScore,
        activitiesCompleted: 1,
        averageAccuracy: 85.0,
        averageResponseTime: 5.0,
        lastScore: initScore,
        trend: 'stable'
      }));
    });

    childProgressMap.set(childId, skillsMap);
  }
  return childProgressMap.get(childId);
}

class ProgressService {
  /**
   * Record a completed ActivityResult and compute longitudinal progress update
   */
  static async recordActivityResult(result) {
    const childId = result.childId || 'A001';
    const skill = result.skill || 'recognition';
    const activityScore = result.score ?? 100;
    const isCorrect = result.correct ?? true;
    const responseTime = result.responseTime ?? 5.0;

    const childSkills = getOrCreateChildSkills(childId);
    let progress = childSkills.get(skill);

    if (!progress) {
      progress = new SkillProgress({
        skill,
        score: activityScore,
        activitiesCompleted: 0,
        averageAccuracy: 100.0,
        averageResponseTime: 5.0,
        lastScore: activityScore,
        trend: 'stable'
      });
    }

    const oldScore = progress.score;
    const oldCount = progress.activitiesCompleted;
    const newCount = oldCount + 1;

    // 1. Weighted Rolling Average: (old * 0.7) + (new * 0.3)
    const newScore = oldCount === 0 
      ? activityScore 
      : Math.round((oldScore * 0.7) + (activityScore * 0.3));

    // 2. Average Accuracy & Response Time
    const attempts = result.attempts || 1;
    const currentAccuracyPct = isCorrect ? Math.round((1 / attempts) * 100.0) : 0.0;

    const newAccuracy = oldCount === 0 
      ? currentAccuracyPct 
      : ((progress.averageAccuracy * oldCount) + currentAccuracyPct) / newCount;

    const newResponseTime = oldCount === 0 
      ? responseTime 
      : ((progress.averageResponseTime * oldCount) + responseTime) / newCount;

    // 3. Historical Snapshots & Trend Calculation
    if (!snapshotsMap.has(childId)) {
      snapshotsMap.set(childId, []);
    }
    const childSnapshots = snapshotsMap.get(childId);

    // Save snapshot
    const snapshot = new ProgressSnapshot({
      snapshotId: `SNP_${Date.now()}_${childSnapshots.length + 1}`,
      childId,
      skill,
      score: newScore,
      timestamp: new Date().toISOString()
    });
    childSnapshots.push(snapshot);

    // Determine trend (+5 or more -> improving, -5 or less -> declining, otherwise -> stable)
    const skillSnapshots = childSnapshots.filter(s => s.skill === skill);
    let trend = 'stable';
    if (skillSnapshots.length >= 2) {
      // Compare against oldest snapshot or snapshot 3 steps prior
      const baselineIdx = Math.max(0, skillSnapshots.length - 4);
      const baselineScore = skillSnapshots[baselineIdx].score;
      const diff = newScore - baselineScore;

      if (diff >= 5) {
        trend = 'improving';
      } else if (diff <= -5) {
        trend = 'declining';
      } else {
        trend = 'stable';
      }
    }

    // 4. Update progress object
    progress.score = newScore;
    progress.activitiesCompleted = newCount;
    progress.averageAccuracy = newAccuracy;
    progress.averageResponseTime = newResponseTime;
    progress.lastScore = activityScore;
    progress.trend = trend;

    childSkills.set(skill, progress);

    // 5. Update Child Profile skills map
    const child = await ChildService.getChildById(childId);
    if (child) {
      const updatedSkills = { ...child.skills, [skill]: newScore };
      await ChildService.updateChild(childId, { skills: updatedSkills });
    }

    console.log(`🧠 [PROGRESS ENGINE] ${childId} | Skill: ${skill} | Old: ${oldScore} → New: ${newScore} | Trend: ${trend} | Activities: ${newCount}`);
    return progress;
  }

  /**
   * Get all skill progress for a child
   */
  static async getProgress(childId = 'A001') {
    const childSkills = getOrCreateChildSkills(childId);
    const resultObj = {};
    childSkills.forEach((val, key) => {
      resultObj[key] = val.toJSON();
    });
    return resultObj;
  }

  /**
   * Get progress for a specific skill
   */
  static async getSkillProgress(childId = 'A001', skill = 'recognition') {
    const childSkills = getOrCreateChildSkills(childId);
    const progress = childSkills.get(skill);
    return progress ? progress.toJSON() : null;
  }

  /**
   * Get progress history snapshots for a child
   */
  static async getProgressHistory(childId = 'A001') {
    const list = snapshotsMap.get(childId) || [];
    return list.map(s => s.toJSON());
  }

  /**
   * Generate Post-Play Clinical & Parental Report JSON Schema
   */
  static async generateClinicalReport(childId = 'A001') {
    const skills = await this.getProgress(childId);
    const history = await this.getProgressHistory(childId);

    const memoryScore = skills.memory ? skills.memory.score : null;
    const sequencingScore = skills.sequencing ? skills.sequencing.score : null;
    const motorScore = skills.motor ? skills.motor.score : null;
    const speechScore = skills.speech ? skills.speech.score : null;
    const attentionScore = skills.attention ? skills.attention.score : null;

    let overallEngagement = 'No Data';
    if (attentionScore !== null) {
      overallEngagement = attentionScore >= 75 ? 'High' : (attentionScore >= 50 ? 'Moderate' : 'Low');
    }

    const areasOfStruggle = [];
    if (sequencingScore !== null && sequencingScore < 60) areasOfStruggle.push('Story Sequencing & Chronology');
    if (memoryScore !== null && memoryScore < 60) areasOfStruggle.push('Detail Recall & Memory');
    if (speechScore !== null && speechScore < 60) areasOfStruggle.push('Complex Word Articulation');

    const sensoryPreferences = [];
    if (attentionScore !== null && attentionScore >= 75) {
      sensoryPreferences.push('Visual storytelling engagement');
      sensoryPreferences.push('Preferred high-contrast visual theme');
    }

    const forParents = [];
    if (areasOfStruggle.length > 0) {
      forParents.push(`Child practiced ${areasOfStruggle.join(', ')} today. Try reinforcing these skills at home!`);
    } else if (history.length > 0) {
      forParents.push("Great progress and engagement during recent interactive play sessions!");
    } else {
      forParents.push("Play more story chapters to generate personalized home activities!");
    }

    const forDoctors = [];
    if (attentionScore !== null) {
      forDoctors.push(`Visual engagement score: ${attentionScore.toFixed(1)}/100.`);
    }
    if (speechScore !== null) {
      forDoctors.push(`Pronunciation accuracy: ${speechScore.toFixed(1)}%.`);
    }
    const milestones = [];
    if (memoryScore !== null) milestones.push(`Memory (${memoryScore}%)`);
    if (sequencingScore !== null) milestones.push(`Sequencing (${sequencingScore}%)`);
    if (motorScore !== null) milestones.push(`Motor (${motorScore}%)`);
    if (milestones.length > 0) {
      forDoctors.push(`Cognitive milestones: ${milestones.join(', ')}.`);
    }

    return {
      metadata: {
        reportId: `RPT_${Date.now()}`,
        childId,
        sessionId: 'SES_001',
        date: new Date().toISOString()
      },
      sessionSummary: {
        durationMinutes: history.length > 0 ? Number((history.length * 3.5).toFixed(1)) : 0.0,
        activitiesCompleted: history.length,
        overallEngagement
      },
      sensoryAndAttention: {
        visualEngagementScore: attentionScore !== null ? Number(attentionScore.toFixed(1)) : 0.0,
        distractionEvents: attentionScore !== null && attentionScore < 70 ? 2 : 0,
        sensoryPreferences
      },
      speechAndCommunication: {
        totalVocalizations: speechScore !== null ? 1 : 0,
        pronunciationAccuracy: speechScore !== null ? Number(speechScore.toFixed(1)) : 0.0,
        successfulWords: [],
        averageResponseDelaySeconds: 0.0
      },
      cognitiveAndMotorSkills: {
        memory: memoryScore !== null ? Number(memoryScore.toFixed(1)) : -1.0,
        sequencing: sequencingScore !== null ? Number(sequencingScore.toFixed(1)) : -1.0,
        fineMotorControl: motorScore !== null ? Number(motorScore.toFixed(1)) : -1.0,
        areasOfStruggle
      },
      behavioralObservations: {
        hintsRequested: 0,
        abandonedActivities: 0,
        frustrationIndicators: 0
      },
      actionableInsights: {
        forParents,
        forDoctors
      }
    };
  }
}

module.exports = ProgressService;
