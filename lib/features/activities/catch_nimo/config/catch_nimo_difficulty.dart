import '../../core/models/difficulty_config.dart';

/// Catch NIMO specific difficulty level configurations (Levels 1 to 6).
class CatchNimoDifficulty extends DifficultyConfig {
  const CatchNimoDifficulty({
    required super.level,
    super.targetSize = 90.0,
    super.timeout = const Duration(seconds: 3),
    super.isMoving = false,
    super.speedMultiplier = 1.0,
    super.distractorsCount = 0,
    super.baseXP = 20.0,
  });

  static const level1 = CatchNimoDifficulty(
    level: 1,
    targetSize: 95.0,
    timeout: Duration(milliseconds: 3000),
    isMoving: false,
    speedMultiplier: 0.0,
    distractorsCount: 0,
    baseXP: 20.0,
  );

  static const level2 = CatchNimoDifficulty(
    level: 2,
    targetSize: 85.0,
    timeout: Duration(milliseconds: 2500),
    isMoving: false,
    speedMultiplier: 0.0,
    distractorsCount: 0,
    baseXP: 25.0,
  );

  static const level3 = CatchNimoDifficulty(
    level: 3,
    targetSize: 75.0,
    timeout: Duration(milliseconds: 2000),
    isMoving: true,
    speedMultiplier: 1.0,
    distractorsCount: 1,
    baseXP: 30.0,
  );

  static const level4 = CatchNimoDifficulty(
    level: 4,
    targetSize: 70.0,
    timeout: Duration(milliseconds: 1800),
    isMoving: true,
    speedMultiplier: 1.5,
    distractorsCount: 1,
    baseXP: 35.0,
  );

  static const level5 = CatchNimoDifficulty(
    level: 5,
    targetSize: 65.0,
    timeout: Duration(milliseconds: 1500),
    isMoving: true,
    speedMultiplier: 2.0,
    distractorsCount: 2,
    baseXP: 45.0,
  );

  static const level6 = CatchNimoDifficulty(
    level: 6,
    targetSize: 60.0,
    timeout: Duration(milliseconds: 1300),
    isMoving: true,
    speedMultiplier: 2.5,
    distractorsCount: 2,
    baseXP: 55.0,
  );

  static CatchNimoDifficulty getForLevel(int lvl) {
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
