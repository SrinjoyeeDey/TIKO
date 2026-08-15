/**
 * ProgressSnapshot Model Schema Definition & Factory
 */
class ProgressSnapshot {
  constructor({
    snapshotId,
    childId,
    skill,
    score,
    timestamp = new Date().toISOString()
  }) {
    const id = snapshotId || `SNP_${Date.now()}`;
    this.snapshotId = id;
    this.childId = childId;
    this.skill = skill;
    this.score = score;
    this.timestamp = timestamp;
  }

  toJSON() {
    return {
      snapshotId: this.snapshotId,
      childId: this.childId,
      skill: this.skill,
      score: this.score,
      timestamp: this.timestamp,
    };
  }
}

module.exports = ProgressSnapshot;
