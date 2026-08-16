/// Decision object returned by the AdaptiveLearningService.
class DifficultyDecision {
  final int nextDifficulty;
  final String reason;
  final bool levelChanged;

  const DifficultyDecision({
    required this.nextDifficulty,
    required this.reason,
    this.levelChanged = false,
  });
}
