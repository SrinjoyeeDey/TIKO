import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/descriptive_question.dart';
import '../models/image_matching_question.dart';
import '../models/mcq_question.dart';
import '../models/question.dart';
import '../models/sequence_question.dart';

/// Result of loading questions — questions grouped by phase.
class QuestionSet {
  final List<McqQuestion> mcqQuestions;
  final List<DescriptiveQuestion> descriptiveQuestions;
  final List<McqQuestion> sequenceQuestions;

  /// Drag-and-drop sequence questions derived from the sequence_test data.
  final List<SequenceQuestion> sequenceDragQuestions;
  final List<ImageMatchingQuestion> imageMatchingQuestions;

  const QuestionSet({
    required this.mcqQuestions,
    required this.descriptiveQuestions,
    required this.sequenceQuestions,
    this.sequenceDragQuestions = const [],
    this.imageMatchingQuestions = const [],
  });

  /// Total number of questions across all phases.
  int get totalCount =>
      mcqQuestions.length +
      descriptiveQuestions.length +
      sequenceQuestions.length +
      imageMatchingQuestions.length;

  /// Whether there are no questions at all.
  bool get isEmpty => totalCount == 0;
}

/// Loads and parses question JSON files from the app's asset bundle.
class QuestionService {
  /// Loads questions from the asset at [assetPath].
  ///
  /// Parses both the `questions` array (MCQ + descriptive) and the
  /// `sequence_test.questions` array (sequence MCQs).
  ///
  /// Returns an empty [QuestionSet] if [assetPath] is null, the file is
  /// missing, or the JSON is malformed.
  static Future<QuestionSet> loadQuestions(String? assetPath) async {
    if (assetPath == null) {
      return const QuestionSet(
        mcqQuestions: [],
        descriptiveQuestions: [],
        sequenceQuestions: [],
        sequenceDragQuestions: [],
        imageMatchingQuestions: [],
      );
    }

    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      return _parseQuestionSet(jsonData);
    } catch (e) {
      // ignore: avoid_print
      print('QuestionService: Failed to load questions at "$assetPath": $e');
      return const QuestionSet(
        mcqQuestions: [],
        descriptiveQuestions: [],
        sequenceQuestions: [],
        sequenceDragQuestions: [],
        imageMatchingQuestions: [],
      );
    }
  }

  /// Parses the full JSON into a [QuestionSet].
  static QuestionSet _parseQuestionSet(Map<String, dynamic> json) {
    final List<McqQuestion> mcqQuestions = [];
    final List<DescriptiveQuestion> descriptiveQuestions = [];
    final List<McqQuestion> sequenceQuestions = [];
    final List<SequenceQuestion> sequenceDragQuestions = [];
    final List<ImageMatchingQuestion> imageMatchingQuestions = [];

    // ── Parse main questions array ──────────────────────────────────
    final questionsRaw = json['questions'] as List<dynamic>? ?? [];
    for (final q in questionsRaw) {
      final map = q as Map<String, dynamic>;
      final type = map['type'] as String?;

      try {
        if (type == 'mcq') {
          mcqQuestions.add(McqQuestion.fromJson(map, QuestionType.mcq));
        } else if (type == 'descriptive') {
          descriptiveQuestions.add(DescriptiveQuestion.fromJson(map));
        }
      } catch (e) {
        // Skip malformed individual questions rather than failing everything.
        // ignore: avoid_print
        print('QuestionService: Skipped malformed question: $e');
      }
    }

    // ── Parse sequence_test questions ───────────────────────────────
    final sequenceTest = json['sequence_test'] as Map<String, dynamic>?;
    if (sequenceTest != null) {
      final seqRaw = sequenceTest['questions'] as List<dynamic>? ?? [];
      for (final q in seqRaw) {
        final map = q as Map<String, dynamic>;
        try {
          sequenceQuestions
              .add(McqQuestion.fromJson(map, QuestionType.sequenceMcq));
          // Also parse as drag-and-drop sequence questions.
          sequenceDragQuestions.add(SequenceQuestion.fromJson(map));
        } catch (e) {
          // ignore: avoid_print
          print('QuestionService: Skipped malformed sequence question: $e');
        }
      }
    }

    // ── Parse image_matching questions ──────────────────────────────
    final imageMatchingRaw = json['image_matching'] as List<dynamic>? ?? [];
    for (final q in imageMatchingRaw) {
      final map = q as Map<String, dynamic>;
      try {
        imageMatchingQuestions.add(ImageMatchingQuestion.fromJson(map));
      } catch (e) {
        // ignore: avoid_print
        print('QuestionService: Skipped malformed image_matching question: $e');
      }
    }

    return QuestionSet(
      mcqQuestions: mcqQuestions,
      descriptiveQuestions: descriptiveQuestions,
      sequenceQuestions: sequenceQuestions,
      sequenceDragQuestions: sequenceDragQuestions,
      imageMatchingQuestions: imageMatchingQuestions,
    );
  }
}

