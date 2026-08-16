/// Configuration parameters for Catch NIMO difficulty levels (Levels 1 to 6).
class DifficultyConfig {
  final int level;
  final double targetSize;
  final Duration timeout;
  final bool isMoving;
  final double speedMultiplier;
  final int distractorsCount;
  final double baseXP;

  const DifficultyConfig({
    required this.level,
    this.targetSize = 90.0,
    this.timeout = const Duration(seconds: 3),
    this.isMoving = false,
    this.speedMultiplier = 1.0,
    this.distractorsCount = 0,
    this.baseXP = 20.0,
  });

  static const level1 = DifficultyConfig(
    level: 1,
    targetSize: 95.0,
    timeout: Duration(milliseconds: 3000),
    isMoving: false,
    speedMultiplier: 0.0,
    distractorsCount: 0,
    baseXP: 20.0,
  );

  static const level2 = DifficultyConfig(
    level: 2,
    targetSize: 90.0,
    timeout: Duration(milliseconds: 2500),
    isMoving: false,
    speedMultiplier: 0.0,
    distractorsCount: 0,
    baseXP: 25.0,
  );

  static const level3 = DifficultyConfig(
    level: 3,
    targetSize: 85.0,
    timeout: Duration(milliseconds: 2200),
    isMoving: true,
    speedMultiplier: 1.0,
    distractorsCount: 0,
    baseXP: 30.0,
  );

  static const level4 = DifficultyConfig(
    level: 4,
    targetSize: 80.0,
    timeout: Duration(milliseconds: 1800),
    isMoving: true,
    speedMultiplier: 1.6,
    distractorsCount: 0,
    baseXP: 35.0,
  );

  static const level5 = DifficultyConfig(
    level: 5,
    targetSize: 75.0,
    timeout: Duration(milliseconds: 1600),
    isMoving: true,
    speedMultiplier: 2.0,
    distractorsCount: 1,
    baseXP: 40.0,
  );

  static const level6 = DifficultyConfig(
    level: 6,
    targetSize: 70.0,
    timeout: Duration(milliseconds: 1400),
    isMoving: true,
    speedMultiplier: 2.5,
    distractorsCount: 2,
    baseXP: 50.0,
  );

  static DifficultyConfig getForLevel(int lvl) {
    switch (lvl) {
      case 1: return level1;
      case 2: return level2;
      case 3: return level3;
      case 4: return level4;
      case 5: return level5;
      case 6: return level6;
      default: return level6;
    }
  }
}
