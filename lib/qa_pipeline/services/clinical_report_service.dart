import '../../core/services/event_service.dart';
import '../../core/models/event_model.dart';
import '../../core/state/child_state.dart';
import '../database/progress_repository.dart';
import '../database/question_attempt_repository.dart';
import '../models/clinical_report_model.dart';

/// Service responsible for generating the Post-Play Clinical & Parental Report
/// conforming to the standardized JSON schema.
class ClinicalReportService {
  static Future<ClinicalReport> generateReport(String childId) async {
    final List<EventModel> events = await EventService.getEvents(childId: childId);
    final progressList = await ProgressRepository.getAllProgress(childId);
    final attempts = await QuestionAttemptRepository.getAllAttempts(childId);

    final sessionId = ChildState.instance.currentSessionId ??
        (events.isNotEmpty ? events.first.sessionId : 'SES_001');

    if (events.isEmpty && progressList.isEmpty && attempts.isEmpty) {
      return ClinicalReport.empty(childId: childId, sessionId: sessionId);
    }

    // 1. Session Summary Metrics
    int activitiesCompleted = progressList.where((p) => p.completed).length;
    DateTime? firstEventTime;
    DateTime? lastEventTime;

    // 2. Sensory & Attention Metrics
    int engagementEventsCount = 0;
    double sumEngagementScore = 0.0;
    int distractionCount = 0;
    int gazeLockedCount = 0;
    int mouthMovementCount = 0;

    // 3. Speech & Communication Metrics
    int vocalizationsCount = 0;
    double sumPronunciationScore = 0.0;
    int speechScoredEvents = 0;
    double sumResponseTime = 0.0;
    int speechResponseTimeEvents = 0;
    final Set<String> successfulWordsSet = {};

    // 4. Cognitive & Motor Metrics
    double memorySum = 0.0;
    int memoryCount = 0;
    double sequencingSum = 0.0;
    int sequencingCount = 0;
    double motorSum = 0.0;
    int motorCount = 0;

    // 5. Behavioral Metrics
    int hintsRequested = 0;
    int abandonedActivities = 0;
    int frustrationIndicators = 0;

    // Process all events
    for (final event in events) {
      if (event.timestamp != null) {
        final t = DateTime.tryParse(event.timestamp!);
        if (t != null) {
          if (firstEventTime == null || t.isBefore(firstEventTime)) {
            firstEventTime = t;
          }
          if (lastEventTime == null || t.isAfter(lastEventTime)) {
            lastEventTime = t;
          }
        }
      }

      final data = event.data;

      switch (event.eventType) {
        case 'ENGAGEMENT_ANALYSIS':
          engagementEventsCount++;
          final score = (data['engagementScore'] as num?)?.toDouble() ?? 0.0;
          sumEngagementScore += score;
          final looking = data['lookingAtScreen'] == true;
          if (looking) {
            gazeLockedCount++;
          }
          if (!looking || data['faceDetected'] == false) {
            distractionCount++;
          }
          if (data['mouthMovement'] == true) {
            mouthMovementCount++;
          }
          break;

        case 'SPEECH_ATTEMPT':
          vocalizationsCount++;
          mouthMovementCount++;
          break;

        case 'SPEECH_ANALYSIS':
          vocalizationsCount++;
          mouthMovementCount++;
          if (data.containsKey('pronunciationScore')) {
            final score = (data['pronunciationScore'] as num?)?.toDouble() ?? 0.0;
            if (score > 0) {
              sumPronunciationScore += score;
              speechScoredEvents++;
            }
            if (score >= 50.0) {
              final transcript = data['transcript']?.toString().trim();
              if (transcript != null && transcript.isNotEmpty) {
                successfulWordsSet.add(transcript);
              }
            }
          }
          if (data.containsKey('responseTime')) {
            final delay = (data['responseTime'] as num?)?.toDouble() ?? 0.0;
            if (delay > 0) {
              sumResponseTime += delay;
              speechResponseTimeEvents++;
            }
          }
          break;

        case 'ANSWER_SUBMITTED':
        case 'ANSWER_CORRECT':
        case 'ANSWER_WRONG':
          final isCorrect = event.eventType == 'ANSWER_CORRECT' || data['isCorrect'] == true;
          final questionType = data['questionType']?.toString().toLowerCase() ?? '';
          final scoreVal = isCorrect ? 100.0 : 0.0;

          if (questionType.contains('sequence') || questionType.contains('order')) {
            sequencingSum += scoreVal;
            sequencingCount++;
          } else if (questionType.contains('memory') || questionType.contains('recall')) {
            memorySum += scoreVal;
            memoryCount++;
          } else {
            // General cognitive/fine motor interaction
            motorSum += scoreVal;
            motorCount++;
          }
          break;

        case 'HINT_USED':
          hintsRequested++;
          break;

        case 'ACTIVITY_SKIPPED':
          abandonedActivities++;
          break;

        case 'ACTIVITY_COMPLETED':
          activitiesCompleted++;
          break;

        case 'GRIP_DETECTED':
          final force = (data['force'] as num?)?.toDouble() ?? 0.0;
          if (force > 1.4) {
            frustrationIndicators++;
          }
          break;

        case 'RETRY':
          frustrationIndicators++;
          break;
      }
    }

    // Process SQLite question attempts to complement events
    if (speechScoredEvents == 0) {
      for (final attempt in attempts) {
        if (attempt.questionType == 'speech') {
          vocalizationsCount++;
          final score = attempt.similarityScore ?? (attempt.isCorrect ? 100.0 : 0.0);
          sumPronunciationScore += score;
          speechScoredEvents++;
          if (score >= 50.0) {
            final word = attempt.userAnswer?.trim();
            if (word != null && word.isNotEmpty) {
              successfulWordsSet.add(word);
            }
          }
        }
      }
    }

    if (memoryCount == 0 && sequencingCount == 0 && motorCount == 0) {
      for (final attempt in attempts) {
        if (attempt.questionType == 'sequence') {
          sequencingSum += attempt.isCorrect ? 100.0 : 0.0;
          sequencingCount++;
        } else if (attempt.questionType == 'mcq') {
          memorySum += attempt.isCorrect ? 100.0 : 0.0;
          memoryCount++;
        } else if (attempt.questionType != 'speech') {
          motorSum += attempt.isCorrect ? 100.0 : 0.0;
          motorCount++;
        }
      }
    }

    // Derive Timestamps from SQLite attempts
    for (final attempt in attempts) {
      if (firstEventTime == null || attempt.startedAt.isBefore(firstEventTime)) {
        firstEventTime = attempt.startedAt;
      }
      if (lastEventTime == null || attempt.completedAt.isAfter(lastEventTime)) {
        lastEventTime = attempt.completedAt;
      }
    }

    // Derive Duration Minutes
    double durationMinutes = 0.0;
    if (firstEventTime != null && lastEventTime != null) {
      final diff = lastEventTime.difference(firstEventTime).inSeconds;
      durationMinutes = (diff / 60.0).clamp(0.0, 180.0);
    }
    if (durationMinutes <= 0.0 && attempts.isNotEmpty) {
      final sumSec = attempts.fold(0, (sum, a) => sum + a.timeTakenSeconds);
      durationMinutes = (sumSec / 60.0).clamp(0.1, 180.0);
    }

    // Derive Sensory & Attention Scores (-1.0 signifies camera not active / not recorded)
    double visualEngagementScore = engagementEventsCount > 0
        ? (sumEngagementScore / engagementEventsCount).clamp(0.0, 100.0)
        : -1.0;

    double screenGazeAlignment = engagementEventsCount > 0
        ? ((gazeLockedCount / engagementEventsCount) * 100.0).clamp(0.0, 100.0)
        : -1.0;

    double focusStability = engagementEventsCount > 0
        ? ((1.0 - (distractionCount / engagementEventsCount).clamp(0.0, 1.0)) * 100.0).clamp(0.0, 100.0)
        : -1.0;

    String overallEngagement = 'No Camera Data Yet';
    if (engagementEventsCount > 0) {
      if (visualEngagementScore >= 75.0) {
        overallEngagement = 'High';
      } else if (visualEngagementScore >= 50.0) {
        overallEngagement = 'Moderate';
      } else {
        overallEngagement = 'Low';
      }
    } else if (activitiesCompleted > 0) {
      overallEngagement = 'Active ($activitiesCompleted completed)';
    }

    // Derive Speech & Communication (-1.0 signifies not attempted yet)
    double pronunciationAccuracy = speechScoredEvents > 0
        ? (sumPronunciationScore / speechScoredEvents).clamp(0.0, 100.0)
        : -1.0;

    double averageResponseDelay = speechResponseTimeEvents > 0
        ? (sumResponseTime / speechResponseTimeEvents).clamp(0.0, 60.0)
        : -1.0;

    double lipMovementPercent = engagementEventsCount > 0
        ? ((mouthMovementCount / engagementEventsCount) * 100.0).clamp(0.0, 100.0)
        : -1.0;

    List<String> sensoryPreferences = [];
    if (engagementEventsCount > 0) {
      if (visualEngagementScore >= 75.0) {
        sensoryPreferences.add('Strong screen focus and eye gaze lock');
      }
      if (distractionCount == 0 && engagementEventsCount >= 3) {
        sensoryPreferences.add('High focus stability (0 distractions)');
      }
      if (mouthMovementCount > 0) {
        sensoryPreferences.add('Active vocal & physical lip responsiveness');
      }
    }
    if (speechScoredEvents > 0 && pronunciationAccuracy >= 70.0) {
      sensoryPreferences.add('Clear verbal articulation');
    }

    // Derive Cognitive & Motor Skills (-1.0 signifies not attempted yet)
    double memoryScore = memoryCount > 0
        ? (memorySum / memoryCount).clamp(0.0, 100.0)
        : -1.0;
    double sequencingScore = sequencingCount > 0
        ? (sequencingSum / sequencingCount).clamp(0.0, 100.0)
        : -1.0;
    double fineMotorScore = motorCount > 0
        ? (motorSum / motorCount).clamp(0.0, 100.0)
        : -1.0;

    List<String> areasOfStruggle = [];
    if (sequencingCount > 0 && sequencingScore < 60.0) areasOfStruggle.add('Story Sequencing & Chronology');
    if (memoryCount > 0 && memoryScore < 60.0) areasOfStruggle.add('Detail Recall & Memory');
    if (speechScoredEvents > 0 && pronunciationAccuracy < 55.0) areasOfStruggle.add('Complex Word Articulation');
    if (hintsRequested >= 3) areasOfStruggle.add('Multi-step Task Independence');

    // Generate Dynamic Actionable Insights strictly from real data
    final childName = ChildState.instance.currentProfile.name.isNotEmpty
        ? ChildState.instance.currentProfile.name
        : 'Your child';

    List<String> forParents = [];
    if (areasOfStruggle.contains('Story Sequencing & Chronology')) {
      forParents.add('$childName struggled a bit with sequencing today. Try arranging everyday toys or story picture cards in order of events!');
    } else if (sequencingCount > 0) {
      forParents.add('$childName showed excellent story comprehension and followed narrative milestones well.');
    }

    if (successfulWordsSet.isNotEmpty) {
      forParents.add('Successfully pronounced "${successfulWordsSet.take(2).join('", "')}". Try practicing these target words during snack or family story time!');
    } else if (vocalizationsCount > 0) {
      forParents.add('$childName actively vocalized and repeated phrases during story time.');
    }

    if (screenGazeAlignment >= 75.0) {
      forParents.add('Maintained fantastic concentration with ${screenGazeAlignment.toStringAsFixed(0)}% screen gaze alignment and high visual attention.');
    }

    if (mouthMovementCount > 0) {
      forParents.add('Observed active lip and mouth articulation during storytelling checkpoints.');
    }

    if (forParents.isEmpty) {
      forParents.add('Play more story chapters to generate personalized home activities and suggestions!');
    }

    List<String> forDoctors = [];
    if (engagementEventsCount > 0) {
      forDoctors.add('Visual concentration averaged ${visualEngagementScore.toStringAsFixed(1)}/100 across $engagementEventsCount telemetry checks with $distractionCount distraction event(s) and ${screenGazeAlignment.toStringAsFixed(1)}% gaze alignment.');
      forDoctors.add('Physical lip & speech movement was detected in $mouthMovementCount checkpoint(s) (${lipMovementPercent.toStringAsFixed(1)}% articulation activity).');
    } else {
      forDoctors.add('Vision engagement telemetry: Camera tracking pending / no video session recorded yet.');
    }

    if (speechScoredEvents > 0) {
      forDoctors.add('Speech response latency averaged ${averageResponseDelay > 0 ? averageResponseDelay.toStringAsFixed(1) : "0"}s with average pronunciation fidelity of ${pronunciationAccuracy.toStringAsFixed(1)}% across $vocalizationsCount verbal attempt(s).');
    } else {
      forDoctors.add('Speech telemetry: No verbal prompts answered yet.');
    }

    List<String> cognitiveMilestones = [];
    if (memoryCount > 0) cognitiveMilestones.add('Memory (${memoryScore.toStringAsFixed(0)}%)');
    if (sequencingCount > 0) cognitiveMilestones.add('Sequencing (${sequencingScore.toStringAsFixed(0)}%)');
    if (motorCount > 0) cognitiveMilestones.add('Fine Motor (${fineMotorScore.toStringAsFixed(0)}%)');

    if (cognitiveMilestones.isNotEmpty) {
      forDoctors.add('Cognitive milestone performance: ${cognitiveMilestones.join(', ')}.');
    } else {
      forDoctors.add('Cognitive milestones: Activities in progress; comprehensive scoring pending further questions.');
    }

    if (frustrationIndicators > 0) {
      forDoctors.add('Observed $frustrationIndicators potential frustration indicator(s) (rapid retries/high pressure) during challenging tasks.');
    } else {
      forDoctors.add('Demonstrated stable emotional regulation and task persistence with zero high-frustration indicators.');
    }

    final totalEvents = events.length + progressList.length;

    return ClinicalReport(
      metadata: ReportMetadata(
        reportId: 'RPT_${DateTime.now().millisecondsSinceEpoch}',
        childId: childId,
        sessionId: sessionId,
        date: DateTime.now().toUtc().toIso8601String(),
      ),
      sessionSummary: SessionSummary(
        durationMinutes: double.parse(durationMinutes.toStringAsFixed(1)),
        activitiesCompleted: activitiesCompleted,
        overallEngagement: overallEngagement,
      ),
      sensoryAndAttention: SensoryAndAttention(
        visualEngagementScore: double.parse(visualEngagementScore.toStringAsFixed(1)),
        distractionEvents: distractionCount,
        screenGazeAlignment: double.parse(screenGazeAlignment.toStringAsFixed(1)),
        focusStability: double.parse(focusStability.toStringAsFixed(1)),
        sensoryPreferences: sensoryPreferences,
      ),
      speechAndCommunication: SpeechAndCommunication(
        totalVocalizations: vocalizationsCount,
        pronunciationAccuracy: double.parse(pronunciationAccuracy.toStringAsFixed(1)),
        successfulWords: successfulWordsSet.toList(),
        averageResponseDelaySeconds: double.parse(averageResponseDelay.toStringAsFixed(1)),
        mouthMovementDetectedCount: mouthMovementCount,
        lipMovementActivePercent: double.parse(lipMovementPercent.toStringAsFixed(1)),
      ),
      cognitiveAndMotorSkills: CognitiveAndMotorSkills(
        memory: double.parse(memoryScore.toStringAsFixed(1)),
        sequencing: double.parse(sequencingScore.toStringAsFixed(1)),
        fineMotorControl: double.parse(fineMotorScore.toStringAsFixed(1)),
        areasOfStruggle: areasOfStruggle,
      ),
      behavioralObservations: BehavioralObservations(
        hintsRequested: hintsRequested,
        abandonedActivities: abandonedActivities,
        frustrationIndicators: frustrationIndicators,
      ),
      actionableInsights: ActionableInsights(
        forParents: forParents,
        forDoctors: forDoctors,
      ),
      totalEventsAnalyzed: totalEvents,
    );
  }
}
