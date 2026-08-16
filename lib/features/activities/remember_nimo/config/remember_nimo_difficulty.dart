import '../../core/models/difficulty_config.dart';
import '../models/memory_feature.dart';

/// Prototype Difficulty Configurations for Remember NIMO.
class RememberNimoDifficulty extends DifficultyConfig {
  final Duration previewDuration;
  final List<FeatureCategory> activeCategories;
  final int optionsPerCategory;

  const RememberNimoDifficulty({
    required super.level,
    required super.baseXP,
    required super.timeout,
    required this.previewDuration,
    required this.activeCategories,
    required this.optionsPerCategory,
  });

  static const List<RememberNimoDifficulty> levels = [
    RememberNimoDifficulty(
      level: 1,
      baseXP: 25,
      timeout: Duration(seconds: 25),
      previewDuration: Duration(milliseconds: 4000),
      activeCategories: [
        FeatureCategory.hairstyle,
        FeatureCategory.eyes,
        FeatureCategory.expression,
      ],
      optionsPerCategory: 3,
    ),
    RememberNimoDifficulty(
      level: 2,
      baseXP: 35,
      timeout: Duration(seconds: 22),
      previewDuration: Duration(milliseconds: 3500),
      activeCategories: [
        FeatureCategory.hairstyle,
        FeatureCategory.eyes,
        FeatureCategory.expression,
        FeatureCategory.accessory,
      ],
      optionsPerCategory: 3,
    ),
    RememberNimoDifficulty(
      level: 3,
      baseXP: 45,
      timeout: Duration(seconds: 20),
      previewDuration: Duration(milliseconds: 3000),
      activeCategories: [
        FeatureCategory.hairstyle,
        FeatureCategory.eyes,
        FeatureCategory.expression,
        FeatureCategory.accessory,
        FeatureCategory.clothing,
      ],
      optionsPerCategory: 4,
    ),
    RememberNimoDifficulty(
      level: 4,
      baseXP: 55,
      timeout: Duration(seconds: 18),
      previewDuration: Duration(milliseconds: 2500),
      activeCategories: [
        FeatureCategory.hairstyle,
        FeatureCategory.eyes,
        FeatureCategory.expression,
        FeatureCategory.accessory,
        FeatureCategory.clothing,
      ],
      optionsPerCategory: 4,
    ),
    RememberNimoDifficulty(
      level: 5,
      baseXP: 70,
      timeout: Duration(seconds: 15),
      previewDuration: Duration(milliseconds: 2000),
      activeCategories: [
        FeatureCategory.hairstyle,
        FeatureCategory.eyes,
        FeatureCategory.expression,
        FeatureCategory.accessory,
        FeatureCategory.clothing,
      ],
      optionsPerCategory: 4,
    ),
  ];

  static RememberNimoDifficulty getForLevel(int level) {
    if (level <= 1) return levels[0];
    if (level >= levels.length) return levels.last;
    return levels[level - 1];
  }
}
