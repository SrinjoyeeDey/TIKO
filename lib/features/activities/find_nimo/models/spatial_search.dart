/// Categories of gameplay errors in spatial search.
enum SpatialErrorType {
  none,
  withinSearch,  // Player taps same wrong tile again during current search
  betweenSearch, // Player taps a tile that contained NIMO in an earlier search phase of round
}

/// Represents a single search step in a multi-search round.
class SearchStepResult {
  final int stepIndex;
  final int targetCellIndex;
  final int selectedCellIndex;
  final bool isCorrect;
  final SpatialErrorType errorType;
  final int reactionTimeMs;

  const SearchStepResult({
    required this.stepIndex,
    required this.targetCellIndex,
    required this.selectedCellIndex,
    required this.isCorrect,
    required this.errorType,
    required this.reactionTimeMs,
  });
}
