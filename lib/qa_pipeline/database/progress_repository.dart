import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../models/level_progress.dart';
import 'database_helper.dart';

class ProgressRepository {
  /// Fetches progress for a specific child, chapter, and level.
  static Future<LevelProgress?> getLevelProgress(
    String childId,
    String chapterId,
    String levelId,
  ) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'level_progress',
      where: 'child_id = ? AND chapter_id = ? AND level_id = ?',
      whereArgs: [childId, chapterId, levelId],
    );

    if (result.isEmpty) return null;
    return LevelProgress.fromMap(result.first);
  }

  /// Fetches all progress for a given child.
  static Future<List<LevelProgress>> getAllProgress(String childId) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'level_progress',
      where: 'child_id = ?',
      whereArgs: [childId],
    );

    return result.map((m) => LevelProgress.fromMap(m)).toList();
  }

  /// Marks a level as completed and saves the star rating.
  /// Also updates the `completed_at` timestamp if not previously completed.
  static Future<void> saveLevelCompletion({
    required String childId,
    required String chapterId,
    required String levelId,
    required int stars,
  }) async {
    final db = await DatabaseHelper.instance.database;

    final existing = await getLevelProgress(childId, chapterId, levelId);
    
    // Determine the completedAt timestamp (keep original if it exists)
    final String completedAt;
    if (existing?.completedAt != null) {
      completedAt = existing!.completedAt!.toIso8601String();
    } else {
      completedAt = DateTime.now().toIso8601String();
    }

    // Only update stars if the new score is higher
    final bestStars = existing != null && existing.stars > stars
        ? existing.stars
        : stars;

    await db.insert(
      'level_progress',
      {
        'child_id': childId,
        'chapter_id': chapterId,
        'level_id': levelId,
        'completed': 1,
        'stars': bestStars,
        'completed_at': completedAt,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
