/**
 * Child Model Schema Definition & Factory
 */
class Child {
  constructor({
    id,
    name,
    ageGroup = '4-6',
    language = 'en',
    xp = 0,
    level = 1,
    streak = 1,
    skills = {},
    preferences = {}
  }) {
    this.id = id;
    this.name = name;
    this.ageGroup = ageGroup;
    this.language = language;
    this.xp = xp;
    this.level = level;
    this.streak = streak;
    this.skills = {
      speech: skills.speech ?? 0,
      memory: skills.memory ?? 0,
      sequencing: skills.sequencing ?? 0,
      motor: skills.motor ?? 0,
      recognition: skills.recognition ?? 0,
      attention: skills.attention ?? 0,
    };
    this.preferences = {
      theme: preferences.theme ?? 'default',
      soundEffects: preferences.soundEffects ?? true,
      music: preferences.music ?? true,
      ...preferences
    };
  }

  toJSON() {
    return {
      id: this.id,
      name: this.name,
      ageGroup: this.ageGroup,
      language: this.language,
      xp: this.xp,
      level: this.level,
      streak: this.streak,
      skills: this.skills,
      preferences: this.preferences,
    };
  }
}

module.exports = Child;
