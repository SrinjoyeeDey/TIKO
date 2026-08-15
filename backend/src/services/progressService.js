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
}

module.exports = ProgressService;
