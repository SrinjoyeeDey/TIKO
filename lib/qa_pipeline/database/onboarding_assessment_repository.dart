import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

/// Structured model for child sign-up onboarding assessment.
class ChildOnboardingAssessment {
  final String id;
  final String childId;
  final String? parentId;
  final Map<String, dynamic> answers;
  final List<String> developmentalDiagnoses;
  final double speechLevelSelfRating;
  final int computedDifficultyPercentage;
  final String computedDifficultyLevel;
  final String computedReasoning;
  final DateTime createdAt;

  ChildOnboardingAssessment({
    required this.id,
    required this.childId,
    this.parentId,
    required this.answers,
    required this.developmentalDiagnoses,
    required this.speechLevelSelfRating,
    required this.computedDifficultyPercentage,
    required this.computedDifficultyLevel,
    required this.computedReasoning,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'child_id': childId,
      'parent_id': parentId,
      'answers_json': json.encode(answers),
      'developmental_diagnoses': developmentalDiagnoses.join(', '),
      'speech_level_self_rating': speechLevelSelfRating,
      'computed_difficulty_percentage': computedDifficultyPercentage,
      'computed_difficulty_level': computedDifficultyLevel,
      'computed_reasoning': computedReasoning,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ChildOnboardingAssessment.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic> parsedAnswers = {};
    try {
      final rawJson = map['answers_json'] as String?;
      if (rawJson != null && rawJson.isNotEmpty) {
        parsedAnswers = Map<String, dynamic>.from(json.decode(rawJson) as Map);
      }
    } catch (_) {}

    final diagStr = map['developmental_diagnoses'] as String? ?? '';
    final diags = diagStr.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

    return ChildOnboardingAssessment(
      id: map['id'] as String,
      childId: map['child_id'] as String,
      parentId: map['parent_id'] as String?,
      answers: parsedAnswers,
      developmentalDiagnoses: diags,
      speechLevelSelfRating: (map['speech_level_self_rating'] as num?)?.toDouble() ?? 0.5,
      computedDifficultyPercentage: (map['computed_difficulty_percentage'] as num?)?.toInt() ?? 50,
      computedDifficultyLevel: map['computed_difficulty_level'] as String? ?? 'Balanced Explorer',
      computedReasoning: map['computed_reasoning'] as String? ?? '',
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

/// SQLite Repository for persisting and retrieving child onboarding assessments.
class OnboardingAssessmentRepository {
  static const String _table = 'child_onboarding_assessments';

  /// Saves a completed onboarding assessment to SQLite.
  static Future<void> saveAssessment(ChildOnboardingAssessment assessment) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      _table,
      assessment.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Gets the latest onboarding assessment for a specific child from SQLite.
  static Future<ChildOnboardingAssessment?> getLatestAssessment(String childId) async {
    final db = await DatabaseHelper.instance.database;
    final results = await db.query(
      _table,
      where: 'child_id = ?',
      whereArgs: [childId],
      orderBy: 'created_at DESC',
      limit: 1,
    );

    if (results.isEmpty) return null;
    return ChildOnboardingAssessment.fromMap(results.first);
  }
}
