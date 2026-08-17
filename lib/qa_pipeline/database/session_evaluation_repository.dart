import 'package:sqflite/sqflite.dart';
import '../models/session_evaluation_model.dart';
import 'database_helper.dart';

/// Repository for persisting and querying post-level clinical evaluations in SQLite.
class SessionEvaluationRepository {
  static const _table = 'session_clinical_evaluations';

  /// Saves a newly generated post-level clinical evaluation to SQLite.
  static Future<void> saveEvaluation(SessionClinicalEvaluation evaluation) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      _table,
      evaluation.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieves the most recent post-level clinical evaluation for a given child.
  static Future<SessionClinicalEvaluation?> getLatestEvaluation(String childId) async {
    final db = await DatabaseHelper.instance.database;
    final results = await db.query(
      _table,
      where: 'child_id = ?',
      whereArgs: [childId],
      orderBy: 'created_at DESC',
      limit: 1,
    );

    if (results.isEmpty) return null;
    return SessionClinicalEvaluation.fromMap(results.first);
  }

  /// Retrieves all session evaluations for a child, ordered by date descending.
  static Future<List<SessionClinicalEvaluation>> getAllEvaluations(String childId) async {
    final db = await DatabaseHelper.instance.database;
    final results = await db.query(
      _table,
      where: 'child_id = ?',
      whereArgs: [childId],
      orderBy: 'created_at DESC',
    );

    return results.map((m) => SessionClinicalEvaluation.fromMap(m)).toList();
  }
}
