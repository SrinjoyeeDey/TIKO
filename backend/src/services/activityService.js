const Activity = require('../models/Activity');

const activitiesStore = new Map();

// Seed initial Netaji activities
const seedActivities = [
  new Activity({
    activityId: 'netaji_q01',
    storyId: 'netaji',
    title: 'Who was Netaji?',
    type: 'mcq',
    skill: 'recognition',
    difficulty: 1,
    question: 'Who was known as Netaji?',
    options: [
      'Subhas Chandra Bose',
      'Mahatma Gandhi',
      'Sardar Patel',
      'Jawaharlal Nehru'
    ],
    correctAnswer: 0,
    maxAttempts: 3,
    reward: 20,
    order: 1
  }),
  new Activity({
    activityId: 'netaji_q02',
    storyId: 'netaji',
    title: 'Netaji\'s Escape Sequence',
    type: 'sequencing',
    skill: 'sequencing',
    difficulty: 1,
    question: 'Arrange the events of Netaji\'s Great Escape in chronological order.',
    options: [
      'House arrest in Calcutta (1941)',
      'Disguised escape to Gomoh Railway Station',
      'Travel through Afghanistan to Berlin',
      'Formation of Azad Hind Fauj in Singapore'
    ],
    correctAnswer: [0, 1, 2, 3],
    maxAttempts: 3,
    reward: 30,
    order: 2
  }),
  new Activity({
    activityId: 'netaji_q03',
    storyId: 'netaji',
    title: 'Match Netaji Slogans & Symbols',
    type: 'matching',
    skill: 'motor',
    difficulty: 1,
    question: 'Match each famous Netaji quote or emblem with its correct description.',
    options: [
      { id: '1', item: 'Give me blood, and I shall give you freedom!', target: 'Famous Call to Action' },
      { id: '2', item: 'Jai Hind!', target: 'National Greeting & Slogan' },
      { id: '3', item: 'Springing Tiger', target: 'Symbol of INA (Azad Hind Fauj)' }
    ],
    correctAnswer: 0,
    maxAttempts: 3,
    reward: 40,
    order: 3
  })
];

seedActivities.forEach(act => activitiesStore.set(act.activityId, act));

class ActivityService {
  /**
   * Get single activity by activityId
   */
  static async getActivityById(activityId) {
    return activitiesStore.get(activityId) || null;
  }

  /**
   * Get all activities for a story, sorted by order
   */
  static async getActivitiesByStory(storyId) {
    const list = Array.from(activitiesStore.values())
      .filter(act => act.storyId === storyId || storyId === 'netaji') // default fallback
      .sort((a, b) => a.order - b.order);
    return list;
  }

  /**
   * Create a new activity
   */
  static async createActivity(data) {
    const activityId = data.activityId || `ACT_${Date.now()}`;
    const activity = new Activity({ ...data, activityId });
    activitiesStore.set(activityId, activity);
    return activity;
  }
}

module.exports = ActivityService;
