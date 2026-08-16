import '../../core/models/difficulty_config.dart';

/// Difficulty Configurations for Category Sort FFC Activity.
class CategorySortDifficulty extends DifficultyConfig {
  final int activeCategoryCount;
  final Duration itemDisplayDelay;

  const CategorySortDifficulty({
    required super.level,
    required super.baseXP,
    required super.timeout,
    required this.activeCategoryCount,
    required this.itemDisplayDelay,
  });

  static const List<CategorySortDifficulty> levels = [
    CategorySortDifficulty(
      level: 1,
      baseXP: 30,
      timeout: Duration(seconds: 15),
      activeCategoryCount: 2,
      itemDisplayDelay: Duration(milliseconds: 300),
    ),
    CategorySortDifficulty(
      level: 2,
      baseXP: 40,
      timeout: Duration(seconds: 14),
      activeCategoryCount: 3,
      itemDisplayDelay: Duration(milliseconds: 250),
    ),
    CategorySortDifficulty(
      level: 3,
      baseXP: 55,
      timeout: Duration(seconds: 12),
      activeCategoryCount: 4,
      itemDisplayDelay: Duration(milliseconds: 200),
    ),
    CategorySortDifficulty(
      level: 4,
      baseXP: 70,
      timeout: Duration(seconds: 10),
      activeCategoryCount: 4,
      itemDisplayDelay: Duration(milliseconds: 150),
    ),
    CategorySortDifficulty(
      level: 5,
      baseXP: 90,
      timeout: Duration(seconds: 8),
      activeCategoryCount: 4,
      itemDisplayDelay: Duration(milliseconds: 100),
    ),
  ];

  static CategorySortDifficulty getForLevel(int level) {
    if (level <= 1) return levels[0];
    if (level >= levels.length) return levels.last;
    return levels[level - 1];
  }
}
