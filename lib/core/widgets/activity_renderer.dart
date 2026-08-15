import 'package:flutter/material.dart';
import '../models/activity_model.dart';
import '../models/event_model.dart';
import '../models/child_profile.dart';
import '../api/scoring_api.dart';
import '../services/event_service.dart';
import '../state/child_state.dart';
import '../../qa_pipeline/models/question.dart';
import '../../qa_pipeline/models/mcq_question.dart';
import '../../qa_pipeline/models/sequence_question.dart';
import '../../qa_pipeline/models/image_matching_question.dart';
import '../../qa_pipeline/widgets/mcq_question_widget.dart';
import '../../qa_pipeline/widgets/sequence_question_widget.dart';
import '../../qa_pipeline/widgets/image_matching_widget.dart';

/// Centralized Activity Renderer that dynamically renders the appropriate UI widget
/// based on `activity.type` (`mcq`, `sequencing`, `matching`, `voice`, `memory`, `drag_drop`)
/// and emits standardized interaction telemetry events.
class ActivityRenderer extends StatefulWidget {
  final ActivityModel activity;
  final int questionNumber;
  final ValueChanged<bool> onAnswered;

  const ActivityRenderer({
    super.key,
    required this.activity,
    this.questionNumber = 1,
    required this.onAnswered,
  });

  @override
  State<ActivityRenderer> createState() => _ActivityRendererState();
}

class _ActivityRendererState extends State<ActivityRenderer> {
  int _attemptCount = 0;

  @override
  void initState() {
    super.initState();
    _startActivityTelemetry();
  }

  void _startActivityTelemetry() {
    EventService.instance.startActivityTimer(widget.activity.activityId);
    EventService.logEvent(
      eventType: EventType.activityStarted,
      activityId: widget.activity.activityId,
      data: {
        'title': widget.activity.title,
        'type': widget.activity.type,
        'order': widget.activity.order,
      },
    );
  }

  void _handleAnswerSubmitted(bool isCorrect) {
    _attemptCount++;
    final responseTime = EventService.instance.getElapsedResponseTimeSeconds(widget.activity.activityId);

    // 1. Emit ANSWER_SUBMITTED event with real responseTime
    EventService.logEvent(
      eventType: EventType.answerSubmitted,
      activityId: widget.activity.activityId,
      data: {
        'correct': isCorrect,
        'attempt': _attemptCount,
        'responseTime': responseTime,
      },
    );

    // 2. Emit ANSWER_CORRECT / ANSWER_WRONG / RETRY
    if (isCorrect) {
      EventService.logEvent(
        eventType: EventType.answerCorrect,
        activityId: widget.activity.activityId,
        data: {
          'attempt': _attemptCount,
          'responseTime': responseTime,
        },
      );
    } else {
      EventService.logEvent(
        eventType: EventType.answerWrong,
        activityId: widget.activity.activityId,
        data: {
          'attempt': _attemptCount,
          'responseTime': responseTime,
        },
      );

      if (_attemptCount < widget.activity.maxAttempts) {
        EventService.logEvent(
          eventType: EventType.retry,
          activityId: widget.activity.activityId,
          data: {'previousAttempt': _attemptCount},
        );
      }
    }

    // 3. Emit ACTIVITY_COMPLETED event
    EventService.logEvent(
      eventType: EventType.activityCompleted,
      activityId: widget.activity.activityId,
      data: {
        'score': isCorrect ? widget.activity.reward : 0,
        'timeTaken': responseTime,
      },
    );

    // 4. Trigger backend Scoring Engine evaluation & Child Profile XP/Skill update
    final sid = ChildState.instance.currentSessionId;
    if (sid != null) {
      ScoringApi.evaluateActivity(
        sessionId: sid,
        activityId: widget.activity.activityId,
      ).then((evaluation) {
        if (evaluation != null && evaluation['child'] is ChildProfile) {
          ChildState.instance.setProfile(evaluation['child'] as ChildProfile);
          debugPrint('🧮 [Scoring Engine] Profile Synced! New XP: ${(evaluation['child'] as ChildProfile).xp}');
        }
      });
    }

    widget.onAnswered(isCorrect);
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.activity.type.toLowerCase()) {
      case 'mcq':
        return _buildMcqWidget();
      case 'sequencing':
        return _buildSequenceWidget();
      case 'matching':
        return _buildMatchingWidget();
      case 'voice':
      case 'memory':
      case 'drag_drop':
      default:
        return _buildFallbackWidget();
    }
  }

  Widget _buildMcqWidget() {
    final Map<String, String> optionsMap = {};
    final keys = ['A', 'B', 'C', 'D', 'E', 'F'];
    for (int i = 0; i < widget.activity.options.length; i++) {
      final key = i < keys.length ? keys[i] : '${i + 1}';
      optionsMap[key] = widget.activity.options[i].toString();
    }

    int correctIdx = 0;
    if (widget.activity.correctAnswer is int) {
      correctIdx = widget.activity.correctAnswer as int;
    }

    final correctKey = correctIdx < keys.length ? keys[correctIdx] : 'A';

    final mcq = McqQuestion(
      id: 1,
      type: QuestionType.mcq,
      questionText: widget.activity.question,
      options: optionsMap,
      correctAnswerKey: correctKey,
      answerText: 'Great job completing this activity!',
    );

    return McqQuestionWidget(
      question: mcq,
      questionNumber: widget.questionNumber,
      phaseLabel: widget.activity.title,
      onAnswered: _handleAnswerSubmitted,
    );
  }

  Widget _buildSequenceWidget() {
    final List<String> items = widget.activity.options.map((e) => e.toString()).toList();
    final seq = SequenceQuestion(
      id: 2,
      questionText: widget.activity.question,
      items: List<String>.from(items)..shuffle(),
      correctOrder: items,
      answerText: 'Events ordered chronologically!',
    );

    return SequenceQuestionWidget(
      question: seq,
      questionNumber: widget.questionNumber,
      onAnswered: _handleAnswerSubmitted,
    );
  }

  Widget _buildMatchingWidget() {
    final List<MatchingDescription> descriptions = [];
    final List<MatchingImage> images = [];
    final Map<String, String> correctMatches = {};

    if (widget.activity.options.isNotEmpty && widget.activity.options.first is Map) {
      for (int i = 0; i < widget.activity.options.length; i++) {
        final Map opt = widget.activity.options[i] as Map;
        final id = (opt['id'] ?? '${i + 1}').toString();
        final itemText = (opt['item'] ?? 'Item ${i + 1}').toString();
        final targetText = (opt['target'] ?? 'Target ${i + 1}').toString();

        images.add(MatchingImage(id: id, file: 'netaji_${i + 1}.png'));
        descriptions.add(MatchingDescription(id: id, text: '$itemText - $targetText'));
        correctMatches[id] = id;
      }
    } else {
      images.addAll([
        const MatchingImage(id: '1', file: 'netaji_1.png'),
        const MatchingImage(id: '2', file: 'netaji_2.png'),
      ]);
      descriptions.addAll([
        const MatchingDescription(id: '1', text: 'Give me blood, and I shall give you freedom!'),
        const MatchingDescription(id: '2', text: 'Jai Hind! - National Greeting'),
      ]);
      correctMatches.addAll({'1': '1', '2': '2'});
    }

    final imgQuestion = ImageMatchingQuestion(
      id: 3,
      type: QuestionType.imageMatching,
      questionText: widget.activity.question,
      images: images,
      descriptions: descriptions,
      correctMatches: correctMatches,
      points: 1,
    );

    return ImageMatchingWidget(
      question: imgQuestion,
      chapterId: widget.activity.storyId,
      levelId: widget.activity.activityId,
      onCompleted: (correctMatchesCount, totalMatchesCount) {
        _handleAnswerSubmitted(correctMatchesCount == totalMatchesCount);
      },
    );
  }

  Widget _buildFallbackWidget() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xDD1E100A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFD4AF37), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.activity.title.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFFFF8E1),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.activity.question,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: const Color(0xFF2E1C12),
                ),
                onPressed: () => _handleAnswerSubmitted(true),
                child: const Text('COMPLETE ACTIVITY →'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
