class LevelProgress {
  final String childId;
  final String chapterId;
  final String levelId;
  final bool completed;
  final int stars; // 0 to 3
  final DateTime? completedAt;

  const LevelProgress({
    required this.childId,
    required this.chapterId,
    required this.levelId,
    required this.completed,
    required this.stars,
    this.completedAt,
  });

  factory LevelProgress.fromMap(Map<String, dynamic> map) {
    return LevelProgress(
      childId: map['child_id'] as String,
      chapterId: map['chapter_id'] as String,
      levelId: map['level_id'] as String,
      completed: (map['completed'] as int) == 1,
      stars: map['stars'] as int,
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'child_id': childId,
      'chapter_id': chapterId,
      'level_id': levelId,
      'completed': completed ? 1 : 0,
      'stars': stars,
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'LevelProgress(chapter: $chapterId, level: $levelId, completed: $completed, stars: $stars)';
  }
}
