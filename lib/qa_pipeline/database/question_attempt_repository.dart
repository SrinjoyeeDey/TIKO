import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../models/question_attempt.dart';
import 'database_helper.dart';

class QuestionAttemptRepository {
  static const _uuid = Uuid();

  /// Retrieves all question attempts for a given child.
  static Future<List<QuestionAttempt>> getAllAttempts(String childId) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'question_attempts',
      where: 'child_id = ?',
      whereArgs: [childId],
    );

    return result.map((m) => QuestionAttempt.fromMap(m)).toList();
  }

  /// Retrieves all attempts for a specific level.
  static Future<List<QuestionAttempt>> getAttemptsForLevel(
    String childId,
    String chapterId,
    String levelId,
  ) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'question_attempts',
      where: 'child_id = ? AND chapter_id = ? AND level_id = ?',
      whereArgs: [childId, chapterId, levelId],
      orderBy: 'started_at DESC', // Newest first
    );

    return result.map((m) => QuestionAttempt.fromMap(m)).toList();
  }

  /// Retrieves the history for a specific question to power adaptive learning.
  static Future<List<QuestionAttempt>> getQuestionHistory(
    String childId,
    String chapterId,
    String levelId,
    int questionId,
  ) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'question_attempts',
      where: 'child_id = ? AND chapter_id = ? AND level_id = ? AND question_id = ?',
      whereArgs: [childId, chapterId, levelId, questionId],
      orderBy: 'started_at ASC', // Chronological order
    );

    return result.map((m) => QuestionAttempt.fromMap(m)).toList();
  }

  /// Saves a single question attempt to the database.
  static Future<void> saveAttempt(QuestionAttempt attempt) async {
    final db = await DatabaseHelper.instance.database;
    
    // Ensure the attempt has an ID
    final insertMap = attempt.toMap();
    if (insertMap['id'] == null || insertMap['id'] == '') {
      insertMap['id'] = _uuid.v4();
    }

    await db.insert(
      'question_attempts',
      insertMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Batch saves multiple question attempts.
  static Future<void> saveAttempts(List<QuestionAttempt> attempts) async {
    final db = await DatabaseHelper.instance.database;
    final batch = db.batch();

    for (var attempt in attempts) {
      final insertMap = attempt.toMap();
      if (insertMap['id'] == null || insertMap['id'] == '') {
        insertMap['id'] = _uuid.v4();
      }
      batch.insert(
        'question_attempts',
        insertMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Deletes all attempts for a specific child (e.g., when deleting profile).
  static Future<void> deleteAttemptsForChild(String childId) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      'question_attempts',
      where: 'child_id = ?',
      whereArgs: [childId],
    );
  }
  
  /// Gets statistics across question types for a child.
  static Future<Map<String, dynamic>> getTypeStatistics(String childId) async {
    final db = await DatabaseHelper.instance.database;
    
    final result = await db.rawQuery('''
      SELECT 
        question_type,
        COUNT(*) as total_attempts,
        SUM(is_correct) as correct_attempts,
        AVG(time_taken_seconds) as avg_time
      FROM question_attempts
      WHERE child_id = ?
      GROUP BY question_type
    ''', [childId]);

    final Map<String, dynamic> stats = {};
    for (var row in result) {
      stats[row['question_type'] as String] = {
        'total': row['total_attempts'],
        'correct': row['correct_attempts'],
        'avgTime': row['avg_time'],
      };
    }
    
    return stats;
  }
}
