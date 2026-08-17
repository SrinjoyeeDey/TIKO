import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/descriptive_question.dart';
import '../models/image_matching_question.dart';
import '../models/mcq_question.dart';
import '../models/question.dart';
import '../models/sequence_question.dart';
import '../models/speech_question.dart';

/// Result of loading questions — questions grouped by phase.
class QuestionSet {
  final List<McqQuestion> mcqQuestions;
  final List<DescriptiveQuestion> descriptiveQuestions;
  final List<McqQuestion> sequenceQuestions;
  final List<SpeechQuestion> speechQuestions;

  /// Drag-and-drop sequence questions derived from the sequence_test data.
  final List<SequenceQuestion> sequenceDragQuestions;
  final List<ImageMatchingQuestion> imageMatchingQuestions;

  const QuestionSet({
    required this.mcqQuestions,
    required this.descriptiveQuestions,
    required this.sequenceQuestions,
    this.speechQuestions = const [],
    this.sequenceDragQuestions = const [],
    this.imageMatchingQuestions = const [],
  });

  /// Total number of questions across all phases.
  int get totalCount =>
      mcqQuestions.length +
      descriptiveQuestions.length +
      sequenceQuestions.length +
      speechQuestions.length +
      imageMatchingQuestions.length;

  /// Whether there are no questions at all.
  bool get isEmpty => totalCount == 0;
}

/// Loads and parses question JSON files from the app's asset bundle,
/// with intelligent pedagogical difficulty filtering matching the child learner.
class QuestionService {
  /// Loads questions from the asset at [assetPath].
  static Future<QuestionSet> loadQuestions(String? assetPath) async {
    if (assetPath == null) {
      return const QuestionSet(
        mcqQuestions: [],
        descriptiveQuestions: [],
        sequenceQuestions: [],
        speechQuestions: [],
        sequenceDragQuestions: [],
        imageMatchingQuestions: [],
      );
    }

    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      return _parseQuestionSet(jsonData);
    } catch (e) {
      debugPrint('QuestionService: Failed to load questions at "$assetPath": $e');
      return const QuestionSet(
        mcqQuestions: [],
        descriptiveQuestions: [],
        sequenceQuestions: [],
        speechQuestions: [],
        sequenceDragQuestions: [],
        imageMatchingQuestions: [],
      );
    }
  }

  /// Loads and filters questions tailored to the child's calibrated difficulty percentage & level.
  static Future<QuestionSet> loadQuestionsForChild(
    String? assetPath, {
    int? childDifficultyPercentage,
    String? childDifficultyLevel,
  }) async {
    final fullSet = await loadQuestions(assetPath);
    if (childDifficultyPercentage == null && childDifficultyLevel == null) {
      return fullSet;
    }

    final targetPct = childDifficultyPercentage ?? 50;

    bool matchesDifficulty(Question q) {
      final qPct = q.difficultyPercentage ?? Question.derivePercentageFromDifficulty(q.difficulty);

      if (targetPct <= 35) {
        // Gentle Starter (e.g. 25-35%): easy/starter questions
        return qPct <= 45;
      } else if (targetPct <= 50) {
        // Balanced Explorer (e.g. 40-50%): beginner to intermediate
        return qPct >= 25 && qPct <= 60;
      } else if (targetPct <= 65) {
        // Curious Adventurer (e.g. 50-65%): active learning challenges
        return qPct >= 40 && qPct <= 75;
      } else if (targetPct <= 80) {
        // Challenger (e.g. 70-80%): higher complexity questions
        return qPct >= 50 && qPct <= 90;
      } else {
        // Champion (85%+): comprehensive mastery questions
        return qPct >= 65;
      }
    }

    final filteredMcq = fullSet.mcqQuestions.where(matchesDifficulty).toList();
    final filteredDesc = fullSet.descriptiveQuestions.where(matchesDifficulty).toList();
    final filteredSpeech = fullSet.speechQuestions.where(matchesDifficulty).toList();
    final filteredSeqMcq = fullSet.sequenceQuestions.where(matchesDifficulty).toList();
    final filteredSeqDrag = fullSet.sequenceDragQuestions.where(matchesDifficulty).toList();
    final filteredMatching = fullSet.imageMatchingQuestions.where(matchesDifficulty).toList();

    final filteredSet = QuestionSet(
      mcqQuestions: filteredMcq.isNotEmpty ? filteredMcq : fullSet.mcqQuestions,
      descriptiveQuestions: filteredDesc.isNotEmpty ? filteredDesc : fullSet.descriptiveQuestions,
      speechQuestions: filteredSpeech.isNotEmpty ? filteredSpeech : fullSet.speechQuestions,
      sequenceQuestions: filteredSeqMcq.isNotEmpty ? filteredSeqMcq : fullSet.sequenceQuestions,
      sequenceDragQuestions: filteredSeqDrag.isNotEmpty ? filteredSeqDrag : fullSet.sequenceDragQuestions,
      imageMatchingQuestions: filteredMatching.isNotEmpty ? filteredMatching : fullSet.imageMatchingQuestions,
    );

    debugPrint('QuestionService: Filtered questions for child difficulty $targetPct% (${childDifficultyLevel ?? "Custom"}) -> ${filteredSet.totalCount}/${fullSet.totalCount} selected.');
    return filteredSet;
  }

  /// Parses the full JSON into a [QuestionSet].
  static QuestionSet _parseQuestionSet(Map<String, dynamic> json) {
    final List<McqQuestion> mcqQuestions = [];
    final List<DescriptiveQuestion> descriptiveQuestions = [];
    final List<SpeechQuestion> speechQuestions = [];
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
        } else if (type == 'speech') {
          speechQuestions.add(SpeechQuestion.fromJson(map));
        }
      } catch (e) {
        debugPrint('QuestionService: Skipped malformed question: $e');
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
          sequenceDragQuestions.add(SequenceQuestion.fromJson(map));
        } catch (e) {
          debugPrint('QuestionService: Skipped malformed sequence question: $e');
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
        debugPrint('QuestionService: Skipped malformed image_matching question: $e');
      }
    }

    return QuestionSet(
      mcqQuestions: mcqQuestions,
      descriptiveQuestions: descriptiveQuestions,
      sequenceQuestions: sequenceQuestions,
      speechQuestions: speechQuestions,
      sequenceDragQuestions: sequenceDragQuestions,
      imageMatchingQuestions: imageMatchingQuestions,
    );
  }
}
