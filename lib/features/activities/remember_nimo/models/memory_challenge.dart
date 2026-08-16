import 'dart:math' as math;
import 'memory_feature.dart';

/// Represents a single round memory challenge with target attributes & distractor options matrix.
class MemoryChallenge {
  final Map<FeatureCategory, MemoryFeatureOption> targetFeatures;
  final Map<FeatureCategory, List<MemoryFeatureOption>> optionsPerCategory;

  const MemoryChallenge({
    required this.targetFeatures,
    required this.optionsPerCategory,
  });

  /// Generates a randomized challenge ensuring 1 target + N-1 unique distractors per category.
  factory MemoryChallenge.generate({
    required List<FeatureCategory> activeCategories,
    required int optionCount,
  }) {
    final random = math.Random();
    final targetMap = <FeatureCategory, MemoryFeatureOption>{};
    final optionsMap = <FeatureCategory, List<MemoryFeatureOption>>{};

    for (final cat in activeCategories) {
      final pool = List<MemoryFeatureOption>.from(MemoryFeatureOption.getOptionsForCategory(cat));
      pool.shuffle(random);

      // Select target
      final target = pool.removeAt(0);
      targetMap[cat] = target;

      // Select distractors
      final categoryOptions = <MemoryFeatureOption>[target];
      while (categoryOptions.length < optionCount && pool.isNotEmpty) {
        categoryOptions.add(pool.removeAt(0));
      }

      // Shuffle options matrix so target position is randomized
      categoryOptions.shuffle(random);
      optionsMap[cat] = categoryOptions;
    }

    return MemoryChallenge(
      targetFeatures: targetMap,
      optionsPerCategory: optionsMap,
    );
  }
}
