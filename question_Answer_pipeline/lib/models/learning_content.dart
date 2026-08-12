/// Represents a Chapter containing multiple levels.
class LearningChapter {
  final String id; // e.g., "Netaji"
  final String name; // e.g., "Netaji"
  final List<LearningLevel> levels;

  const LearningChapter({
    required this.id,
    required this.name,
    required this.levels,
  });
}

/// Represents a single learning level inside a Chapter.
class LearningLevel {
  final String id; // e.g., "Netaji_1"
  final String chapterId; // e.g., "Netaji"
  final String chapterName;
  final String levelName;
  
  final String videoPath;
  final String? transcriptPath;
  final String? questionsPath;
  
  final bool isPlayable;

  const LearningLevel({
    required this.id,
    required this.chapterId,
    required this.chapterName,
    required this.levelName,
    required this.videoPath,
    this.transcriptPath,
    this.questionsPath,
    required this.isPlayable,
  });
}
