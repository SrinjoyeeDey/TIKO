import '../../core/models/difficulty_config.dart';

/// Difficulty Configurations for Find NIMO spatial working memory activity.
class FindNimoDifficulty extends DifficultyConfig {
  final int gridSize; // N for NxN grid
  final int searchCountPerRound; // Number of search phases per round
  final Duration previewDuration;

  const FindNimoDifficulty({
    required super.level,
    required super.baseXP,
    required super.timeout,
    required this.gridSize,
    required this.searchCountPerRound,
    required this.previewDuration,
  });

  int get totalCells => gridSize * gridSize;

  static const List<FindNimoDifficulty> levels = [
    FindNimoDifficulty(
      level: 1,
      baseXP: 30,
      timeout: Duration(seconds: 25),
      gridSize: 3,
      searchCountPerRound: 1,
      previewDuration: Duration(milliseconds: 2500),
    ),
    FindNimoDifficulty(
      level: 2,
      baseXP: 40,
      timeout: Duration(seconds: 22),
      gridSize: 3,
      searchCountPerRound: 2,
      previewDuration: Duration(milliseconds: 2250),
    ),
    FindNimoDifficulty(
      level: 3,
      baseXP: 55,
      timeout: Duration(seconds: 20),
      gridSize: 4,
      searchCountPerRound: 2,
      previewDuration: Duration(milliseconds: 2000),
    ),
    FindNimoDifficulty(
      level: 4,
      baseXP: 70,
      timeout: Duration(seconds: 18),
      gridSize: 4,
      searchCountPerRound: 3,
      previewDuration: Duration(milliseconds: 1750),
    ),
    FindNimoDifficulty(
      level: 5,
      baseXP: 90,
      timeout: Duration(seconds: 15),
      gridSize: 5,
      searchCountPerRound: 3,
      previewDuration: Duration(milliseconds: 1500),
    ),
  ];

  static FindNimoDifficulty getForLevel(int level) {
    if (level <= 1) return levels[0];
    if (level >= levels.length) return levels.last;
    return levels[level - 1];
  }
}
