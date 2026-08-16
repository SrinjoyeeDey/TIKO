/// Base configuration parameters for dynamic difficulty adaptation.
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
}
