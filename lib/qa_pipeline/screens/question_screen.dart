import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../../widgets/wooden_back_button.dart';
import '../../widgets/game_textured_text.dart';
import '../../widgets/child_profile_badge.dart';

import '../database/question_attempt_repository.dart';
import '../database/child_repository.dart';
import '../models/descriptive_question.dart';
import '../models/image_matching_question.dart';
import '../models/learning_content.dart';
import '../models/mcq_question.dart';
import '../models/question.dart';
import '../models/question_attempt.dart';
import '../models/sequence_question.dart';
import '../models/speech_question.dart';
import '../services/question_service.dart';
import '../widgets/camera_engagement_overlay.dart';
import '../widgets/descriptive_question_widget.dart';
import '../widgets/image_matching_widget.dart';
import '../widgets/mcq_question_widget.dart';
import '../widgets/sequence_question_widget.dart';
import '../widgets/speech_question_widget.dart';
import 'level_clear_screen.dart';
import '../../core/api/activity_api.dart';
import '../../core/models/activity_model.dart';
import '../../core/widgets/activity_renderer.dart';
import '../../core/widgets/panda_character.dart';
import '../../core/services/event_service.dart';
import '../../core/services/ai_voice_service.dart';
import '../../core/state/child_state.dart';

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

  late final PandaController _pandaController;

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
    _pandaController = PandaController(initialAnimation: PandaAnimation.appear);
    _loadQuestions();
  }

  @override
  void dispose() {
    AiVoiceService.instance.stop();
    _pandaController.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  void _handlePandaReaction(bool isCorrect) {
    if (isCorrect) {
      _pandaController.playCorrect(speech: 'Great job! ⭐');
    } else {
      _pandaController.playWrongSad(speech: 'Oops! Try again! 🤗');
      _speakRetryCurrentQuestion();
    }
  }

  void _speakCurrentQuestion() {
    if (_allQuestions.isEmpty || _currentIndex >= _allQuestions.length) return;
    final question = _allQuestions[_currentIndex];

    if (question is McqQuestion) {
      AiVoiceService.instance.readQuestion(
        questionText: question.questionText,
        questionNumber: _currentIndex + 1,
        questionType: 'mcq',
        options: question.options,
      );
    } else if (question is DescriptiveQuestion) {
      AiVoiceService.instance.readQuestion(
        questionText: question.questionText,
        questionNumber: _currentIndex + 1,
        questionType: 'descriptive',
      );
    } else if (question is SpeechQuestion) {
      AiVoiceService.instance.pronounceWord(
        targetPhrase: question.targetPhrase,
        context: question.questionText,
      );
    } else if (question is SequenceQuestion) {
      AiVoiceService.instance.readQuestion(
        questionText: question.questionText,
        questionNumber: _currentIndex + 1,
        questionType: 'sequence',
      );
    } else if (question is ImageMatchingQuestion) {
      AiVoiceService.instance.readQuestion(
        questionText: question.questionText,
        questionNumber: _currentIndex + 1,
        questionType: 'imageMatching',
      );
    }
  }

  void _speakRetryCurrentQuestion() {
    if (_allQuestions.isEmpty || _currentIndex >= _allQuestions.length) return;
    final question = _allQuestions[_currentIndex];
    final targetPhrase = question is SpeechQuestion ? question.targetPhrase : '';
    final questionText = question is Question ? question.questionText : '';

    AiVoiceService.instance.playRetryPrompt(
      targetPhrase: targetPhrase,
      questionText: questionText,
      retryCount: 2,
    );
  }

  Future<void> _loadQuestions() async {
    try {
      // 0. Fetch child's calibrated difficulty from SQLite / ChildState
      final profile = await ChildRepository.getChildProfile(widget.childId);
      final diffPct = profile?.difficultyPercentage ?? ChildState.instance.currentProfile.difficultyPercentage;
      final diffLevel = profile?.difficultyLevel ?? ChildState.instance.currentProfile.difficultyLevel;

      // 1. Load local level JSON questions tailored to child's calibrated difficulty level
      final qs = await QuestionService.loadQuestionsForChild(
        widget.level.questionsPath,
        childDifficultyPercentage: diffPct,
        childDifficultyLevel: diffLevel,
      );

      _allQuestions
        ..addAll(qs.mcqQuestions)
        ..addAll(qs.descriptiveQuestions)
        ..addAll(qs.speechQuestions)
        ..addAll(qs.sequenceDragQuestions)
        ..addAll(qs.imageMatchingQuestions);

      // 2. Also append backend activities if available
      final backendActivities = await ActivityApi.getActivitiesForStory(widget.level.chapterId);
      if (backendActivities.isNotEmpty) {
        _allQuestions.addAll(backendActivities);
      }

      _totalQuestions = _allQuestions.length;

      setState(() {
        _questionSet = const QuestionSet(
          mcqQuestions: [],
          descriptiveQuestions: [],
          sequenceQuestions: [],
          sequenceDragQuestions: [],
          imageMatchingQuestions: [],
        );
        _questionStartedAt = DateTime.now();
      });

      // Trigger initial dynamic question voice reading
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) _speakCurrentQuestion();
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
    } else if (question is SpeechQuestion) {
      questionType = 'speech';
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

    EventService.logEvent(
      activityId: 'netaji_${widget.level.id}_q$questionId',
      eventType: isCorrect ? 'ANSWER_CORRECT' : 'ANSWER_WRONG',
      data: {
        'questionType': questionType,
        'isCorrect': isCorrect,
        'similarityScore': similarityScore,
        'userAnswer': userAnswer,
        'timeTakenSeconds': timeTaken,
      },
    );

    // Advance to next question or level-clear.
    if (_currentIndex < _allQuestions.length - 1) {
      setState(() {
        _currentIndex++;
        _questionStartedAt = DateTime.now();
      });
      // Speak next question dynamically
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _speakCurrentQuestion();
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

  void _onBackPressed() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _questionStartedAt = DateTime.now();
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  // ─── Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC5AE79), // Vintage Paper Canvas
      body: CameraEngagementOverlay(
        activityId: 'netaji_${widget.level.id}',
        child: Stack(
        children: [

          // 1. GENERATED WEST BENGAL HISTORY MAP BACKGROUND
          Positioned.fill(
            child: Image.asset(
              'assets/images/story_selection_wb_bg.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (ctx, err, stack) => Image.asset(
                'assets/images/nimo_japanese_bg_clean.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 2. Vintage Sepia Dark Vignette Overlay
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.95,
                    colors: [
                      Colors.transparent,
                      const Color(0xFF2E1C12).withValues(alpha: 0.35),
                      const Color(0xFF1E100A).withValues(alpha: 0.65),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Elevated Blurred Glassmorphic Top Bar
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  decoration: BoxDecoration(
                    color: const Color(0x882E1C12), // Vintage Sepia Glass
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xAA8B6914), width: 1.8),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 14,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            WoodenBackButton(
                              onTap: _onBackPressed,
                            ),
                            const SizedBox(width: 10),
                            ChildProfileBadge(
                              childId: widget.childId,
                            ),
                             Expanded(
                              child: Center(
                                child: GameTexturedText(
                                  text: widget.level.chapterName.toUpperCase(),
                                  fontSize: 22,
                                ),
                              ),
                            ),
                            // Interactive AI Voice Question Reader Button
                            ListenableBuilder(
                              listenable: AiVoiceService.instance,
                              builder: (context, _) {
                                final isSpeaking = AiVoiceService.instance.isSpeaking;
                                final isMuted = AiVoiceService.instance.isMuted;
                                return InkWell(
                                  onTap: () {
                                    if (isSpeaking) {
                                      AiVoiceService.instance.stop();
                                    } else {
                                      _speakCurrentQuestion();
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isSpeaking ? const Color(0xFFEF6C6C) : const Color(0x33FFFFFF),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSpeaking ? const Color(0xFFFFD700) : const Color(0x66FFFFFF),
                                        width: 1.2,
                                      ),
                                      boxShadow: isSpeaking
                                          ? const [BoxShadow(color: Color(0x66EF6C6C), blurRadius: 8)]
                                          : null,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isSpeaking
                                              ? Icons.volume_up_rounded
                                              : (isMuted ? Icons.volume_off_rounded : Icons.record_voice_over_rounded),
                                          color: Colors.white,
                                          size: 15,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isSpeaking ? 'READING' : 'READ AI',
                                          style: const TextStyle(
                                            fontFamily: 'Outfit',
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => LevelClearScreen(
                                      childId: widget.childId,
                                      level: widget.level,
                                      totalCorrect: 3,
                                      totalQuestions: 3,
                                    ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD4AF37),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFFFF8E1), width: 1.2),
                                  boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.emoji_events_rounded, color: Color(0xFF2E1C12), size: 15),
                                    SizedBox(width: 4),
                                    Text(
                                      'REWARDS',
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        color: Color(0xFF2E1C12),
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(child: _buildBody()),
              ],
            ),
          ),

          // 4. LARGE RESPONSIVE PANDA CHARACTER COMPANION IN BOTTOM-RIGHT
          Builder(
            builder: (context) {
              final media = MediaQuery.of(context);
              final isLandscape = media.size.width > media.size.height;
              final double pandaSize = (isLandscape
                  ? math.min(media.size.width * 0.22, media.size.height * 0.36)
                  : media.size.width * 0.30).clamp(135.0, 240.0);

              return Positioned(
                right: 16,
                bottom: 16,
                child: SafeArea(
                  child: PandaCharacterWidget(
                    controller: _pandaController,
                    size: pandaSize,
                    showSpeechBubble: true,
                  ),
                ),
              );
            },
          ),
        ],
      ),
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

    return Column(
      children: [
        // Vintage Brass Compass & Progress Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0x992E1C12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
              boxShadow: const [
                BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 3)),
              ],
            ),
            child: Row(
              children: [
                // Phase Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    phaseInfo.phaseLabel.toUpperCase(),
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2E1C12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Animated Progress Bar
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (_currentIndex + 1) / _allQuestions.length,
                      minHeight: 8,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Counter Badge with Star Icon
                Row(
                  children: [
                    const Icon(Icons.stars_rounded, color: Color(0xFFFFD700), size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '${_currentIndex + 1} / ${_allQuestions.length}',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
    if (question is ActivityModel) {
      return ActivityRenderer(
        key: widgetKey,
        activity: question,
        questionNumber: phaseInfo.numberInPhase,
        onAnswered: (isCorrect) => _onQuestionAnswered(isCorrect),
        onPandaReaction: _handlePandaReaction,
      );
    }

    if (question is McqQuestion) {
      return McqQuestionWidget(
        key: widgetKey,
        question: question,
        questionNumber: phaseInfo.numberInPhase,
        phaseLabel: phaseInfo.phaseLabel,
        onAnswered: (isCorrect) =>
            _onQuestionAnswered(isCorrect),
        onPandaReaction: _handlePandaReaction,
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
        onPandaReaction: _handlePandaReaction,
      );
    }

    if (question is SpeechQuestion) {
      return SpeechQuestionWidget(
        key: widgetKey,
        question: question,
        questionNumber: phaseInfo.numberInPhase,
        onAnswered: (isCorrect) => _onQuestionAnswered(isCorrect),
        onAnsweredDetailed: (isCorrect, score, transcript) => _onQuestionAnswered(
          isCorrect,
          similarityScore: score.toDouble(),
          userAnswer: transcript,
        ),
        onPandaReaction: _handlePandaReaction,
      );
    }

    if (question is SequenceQuestion) {
      return SequenceQuestionWidget(
        key: widgetKey,
        question: question,
        questionNumber: phaseInfo.numberInPhase,
        onAnswered: (isCorrect) =>
            _onQuestionAnswered(isCorrect),
        onPandaReaction: _handlePandaReaction,
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
        onPandaReaction: _handlePandaReaction,
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
    if (question is ActivityModel) {
      final idx = _allQuestions.indexOf(question);
      return _PhaseInfo(question.type.toUpperCase(), idx != -1 ? idx + 1 : 1);
    }
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
    if (question is SpeechQuestion) {
      final idx =
          _allQuestions.whereType<SpeechQuestion>().toList().indexOf(question);
      return _PhaseInfo('Speech', idx + 1);
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
