const Child = require('../models/Child');

// In-memory data store with seed profiles
const childrenStore = new Map();

// Seed initial profile A001 (Tinna)
const defaultChild = new Child({
  id: 'A001',
  name: 'Tinna',
  ageGroup: '4-6',
  language: 'en',
  xp: 350,
  level: 4,
  streak: 5,
  skills: {
    speech: 80,
    memory: 75,
    sequencing: 65,
    motor: 90,
    recognition: 85,
    attention: 70
  },
  preferences: {
    theme: 'sakura',
    soundEffects: true,
    music: true
  }
});

childrenStore.set(defaultChild.id, defaultChild);

class ChildService {
  static async getChildById(id) {
    if (!childrenStore.has(id)) {
      return null;
    }
    return childrenStore.get(id);
  }

  static async createChild(data) {
    const id = data.id || `C${Date.now().toString().slice(-4)}`;
    const newChild = new Child({ ...data, id });
    childrenStore.set(id, newChild);
    return newChild;
  }

  static async updateChild(id, updates) {
    const child = childrenStore.get(id);
    if (!child) return null;

    if (updates.name !== undefined) child.name = updates.name;
    if (updates.ageGroup !== undefined) child.ageGroup = updates.ageGroup;
    if (updates.language !== undefined) child.language = updates.language;
    if (updates.xp !== undefined) child.xp = updates.xp;
    if (updates.level !== undefined) child.level = updates.level;
    if (updates.streak !== undefined) child.streak = updates.streak;
    if (updates.skills !== undefined) {
      child.skills = { ...child.skills, ...updates.skills };
    }
    if (updates.preferences !== undefined) {
      child.preferences = { ...child.preferences, ...updates.preferences };
    }

    childrenStore.set(id, child);
    return child;
  }

  static async getAllChildren() {
    return Array.from(childrenStore.values());
  }
}

module.exports = ChildService;
