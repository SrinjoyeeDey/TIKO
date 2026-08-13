import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../../widgets/wooden_back_button.dart';
import '../../widgets/game_textured_text.dart';

import '../database/question_attempt_repository.dart';
import '../models/descriptive_question.dart';
import '../models/image_matching_question.dart';
import '../models/learning_content.dart';
import '../models/mcq_question.dart';
import '../models/question.dart';
import '../models/question_attempt.dart';
import '../models/sequence_question.dart';
import '../services/adaptive_learning_service.dart';
import '../services/question_service.dart';
import '../widgets/descriptive_question_widget.dart';
import '../widgets/image_matching_widget.dart';
import '../widgets/mcq_question_widget.dart';
import '../widgets/sequence_question_widget.dart';
import 'level_clear_screen.dart';

/// Manages the full question flow for a level:
///   MCQ → Descriptive → Sequence (drag-and-drop) → Level Clear.
///
/// Records timing and correctness for each question and persists to the DB.
class QuestionScreen extends StatefulWidget {
  final LearningLevel level;
  final String childId;

  const QuestionScreen({
    super.key,
    required this.level,
    required this.childId,
  });

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  static const _uuid = Uuid();

  QuestionSet? _questionSet;
  String? _errorMessage;

  // Flat ordered list: MCQ → Descriptive → Sequence (drag-and-drop).
  final List<dynamic> _allQuestions = [];

  int _currentIndex = 0;
  DateTime? _questionStartedAt;

  // Session scores
  int _totalCorrect = 0;
  int _totalQuestions = 0;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    try {
      final qs =
          await QuestionService.loadQuestions(widget.level.questionsPath);

      if (qs.isEmpty) {
        if (mounted) {
          _navigateToLevelClear();
        }
        return;
      }

      // Check adaptive learning to see if any sections should be skipped.
      final activeSections =
          await AdaptiveLearningService.getActiveSections(widget.childId);

      // Build the flat ordered list: MCQ → Descriptive → Sequence drag-and-drop.
      if (activeSections.contains('mcq')) {
        _allQuestions.addAll(qs.mcqQuestions);
      }
      if (activeSections.contains('descriptive')) {
        _allQuestions.addAll(qs.descriptiveQuestions);
      }
      if (activeSections.contains('sequence')) {
        _allQuestions.addAll(qs.sequenceDragQuestions);
      }
      if (activeSections.contains('imageMatching')) {
        _allQuestions.addAll(qs.imageMatchingQuestions);
      }

      // If adaptive filtering removed everything, fall back to all questions.
      if (_allQuestions.isEmpty) {
        _allQuestions
          ..addAll(qs.mcqQuestions)
          ..addAll(qs.descriptiveQuestions)
          ..addAll(qs.sequenceDragQuestions)
          ..addAll(qs.imageMatchingQuestions);
      }

      _totalQuestions = _allQuestions.length;

      setState(() {
        _questionSet = qs;
        _questionStartedAt = DateTime.now();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load questions.\n\n$e';
      });
    }
  }

  Future<void> _onQuestionAnswered(bool isCorrect,
      {double? similarityScore, String? userAnswer, int? correctMatches, int? totalMatches}) async {
    final question = _allQuestions[_currentIndex];
    final now = DateTime.now();
    final startedAt = _questionStartedAt ?? now;
    final timeTaken = now.difference(startedAt).inSeconds;

    if (isCorrect) _totalCorrect++;

    // Determine question type and ID.
    String questionType;
    int questionId;

    if (question is McqQuestion) {
      questionType = question.type == QuestionType.sequenceMcq
          ? 'sequence'
          : 'mcq';
      questionId = question.id;
    } else if (question is DescriptiveQuestion) {
      questionType = 'descriptive';
      questionId = question.id;
    } else if (question is SequenceQuestion) {
      questionType = 'sequence';
      questionId = question.id;
    } else if (question is ImageMatchingQuestion) {
      questionType = 'imageMatching';
      questionId = question.id;
    } else {
      questionType = 'unknown';
      questionId = _currentIndex;
    }

    // Save the attempt to the database.
    final attempt = QuestionAttempt(
      id: _uuid.v4(),
      childId: widget.childId,
      chapterId: widget.level.chapterId,
      levelId: widget.level.id,
      questionId: questionId,
      questionType: questionType,
      startedAt: startedAt,
      completedAt: now,
      timeTakenSeconds: timeTaken,
      isCorrect: isCorrect,
      similarityScore: similarityScore,
      userAnswer: userAnswer,
      correctMatches: correctMatches,
      totalMatches: totalMatches,
    );

    await QuestionAttemptRepository.saveAttempt(attempt);

    // Advance to next question or level-clear.
    if (_currentIndex < _allQuestions.length - 1) {
      setState(() {
        _currentIndex++;
        _questionStartedAt = DateTime.now();
      });
    } else {
      _navigateToLevelClear();
    }
  }

  void _navigateToLevelClear() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => LevelClearScreen(
          childId: widget.childId,
          level: widget.level,
          totalCorrect: _totalCorrect,
          totalQuestions: _totalQuestions,
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark Steampunk Blue
      body: Stack(
        children: [
          // Background Texture
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: Image.asset(
                'assets/images/story_selection_bg.png',
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => const SizedBox(),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Custom Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      WoodenBackButton(
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Center(
                          child: GameTexturedText(
                            text: 'EXAM RECORD',
                            fontSize: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 52), // Balance for back button
                    ],
                  ),
                ),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    // Error
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 56),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 15),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: const Color(0xFF2E1C12),
                ),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    // Loading
    if (_questionSet == null) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
      );
    }

    // Current question
    return _buildQuestion();
  }

  Widget _buildQuestion() {
    final question = _allQuestions[_currentIndex];
    final phaseInfo = _getPhaseInfo(question);
    final widgetKey = ValueKey('q_${_currentIndex}_${question.hashCode}');

    if (question is ImageMatchingQuestion) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }

    return Column(
      children: [
        // Progress bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    phaseInfo.phaseLabel,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${_currentIndex + 1} / ${_allQuestions.length}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_currentIndex + 1) / _allQuestions.length,
                  minHeight: 4,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFFD4AF37),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Question content
        Expanded(
          child: _buildQuestionWidget(question, phaseInfo, widgetKey),
        ),
      ],
    );
  }

  Widget _buildQuestionWidget(
    dynamic question,
    _PhaseInfo phaseInfo,
    Key widgetKey,
  ) {
    if (question is McqQuestion) {
      return McqQuestionWidget(
        key: widgetKey,
        question: question,
        questionNumber: phaseInfo.numberInPhase,
        phaseLabel: phaseInfo.phaseLabel,
        onAnswered: (isCorrect) =>
            _onQuestionAnswered(isCorrect),
      );
    }

    if (question is DescriptiveQuestion) {
      return DescriptiveQuestionWidget(
        key: widgetKey,
        question: question,
        questionNumber: phaseInfo.numberInPhase,
        onAnswered: (isCorrect) =>
            _onQuestionAnswered(isCorrect),
        onAnsweredDetailed: (isCorrect, score, answer) =>
            _onQuestionAnswered(
          isCorrect,
          similarityScore: score,
          userAnswer: answer,
        ),
      );
    }

    if (question is SequenceQuestion) {
      return SequenceQuestionWidget(
        key: widgetKey,
        question: question,
        questionNumber: phaseInfo.numberInPhase,
        onAnswered: (isCorrect) =>
            _onQuestionAnswered(isCorrect),
      );
    }

    if (question is ImageMatchingQuestion) {
      return ImageMatchingWidget(
        key: widgetKey,
        question: question,
        chapterId: widget.level.chapterId,
        levelId: widget.level.id,
        onCompleted: (correctMatches, totalMatches) {
          _onQuestionAnswered(
            correctMatches == totalMatches,
            correctMatches: correctMatches,
            totalMatches: totalMatches,
          );
        },
      );
    }

    // Fallback — should never happen.
    return Center(
      child: Text(
        'Unknown question type',
        style: TextStyle(color: Colors.white70),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────

  _PhaseInfo _getPhaseInfo(dynamic question) {
    if (question is McqQuestion && question.type == QuestionType.mcq) {
      final idx = _allQuestions
          .whereType<McqQuestion>()
          .where((q) => q.type == QuestionType.mcq)
          .toList()
          .indexOf(question);
      return _PhaseInfo('MCQ', idx + 1);
    }
    if (question is DescriptiveQuestion) {
      final idx =
          _allQuestions.whereType<DescriptiveQuestion>().toList().indexOf(question);
      return _PhaseInfo('Descriptive', idx + 1);
    }
    if (question is SequenceQuestion) {
      final idx =
          _allQuestions.whereType<SequenceQuestion>().toList().indexOf(question);
      return _PhaseInfo('Sequence', idx + 1);
    }
    if (question is ImageMatchingQuestion) {
      final idx =
          _allQuestions.whereType<ImageMatchingQuestion>().toList().indexOf(question);
      return _PhaseInfo('Matching', idx + 1);
    }
    return _PhaseInfo('Question', _currentIndex + 1);
  }
}

class _PhaseInfo {
  final String phaseLabel;
  final int numberInPhase;

  const _PhaseInfo(this.phaseLabel, this.numberInPhase);
}
