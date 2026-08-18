import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../database/child_repository.dart';
import '../database/session_evaluation_repository.dart';
import '../database/onboarding_assessment_repository.dart';
import '../models/session_evaluation_model.dart';
import '../models/child_profile.dart';
import '../../core/models/child_profile.dart' as core;
import '../../core/state/child_state.dart';
import '../../core/services/ai_integration_service.dart';

/// Service for extracting child profile details from SQLite, orchestrating
/// initial Groq LLM difficulty personalization, and performing Post-Level
/// Adaptive Session Difficulty Evaluations across the 7 clinical dimensions.
class ChildDifficultyService {
  ChildDifficultyService._();
  static final ChildDifficultyService instance = ChildDifficultyService._();

  /// Extracts comprehensive child context from SQLite schema formatted as a clean
  /// JSON dictionary ready for LangChain & Groq API system prompt injection.
  Future<Map<String, dynamic>> extractChildContextForGroq(String childId) async {
    final db = await DatabaseHelper.instance.database;

    // 1. Extract Profile directly from SQLite child_profiles table
    final profileMap = await ChildRepository.getChildById(childId);

    final name = profileMap?.name ?? 'Learner';
    final age = profileMap?.age ?? 5;
    final standard = profileMap?.className ?? 'Grade 1';
    final storedDiff = profileMap?.difficultyPercentage ?? 50;
    final storedLevel = profileMap?.difficultyLevel ?? 'Balanced Explorer';

    // 2. Extract recent question attempt stats from SQLite
    double accuracyAvg = 0.0;
    int totalAttempts = 0;
    int correctAttempts = 0;

    try {
      final attempts = await db.query(
        'question_attempts',
        where: 'child_id = ?',
        whereArgs: [childId],
      );

      totalAttempts = attempts.length;
      if (totalAttempts > 0) {
        for (final row in attempts) {
          if ((row['is_correct'] as int?) == 1) {
            correctAttempts++;
          }
        }
        accuracyAvg = ((correctAttempts / totalAttempts) * 100).clamp(0.0, 100.0);
      }
    } catch (e) {
      debugPrint('ChildDifficultyService: Note reading question_attempts: $e');
    }

    // 3. Extract recent activity events count
    int totalEvents = 0;
    try {
      final events = await db.query(
        'activity_events',
        where: 'child_id = ?',
        whereArgs: [childId],
      );
      totalEvents = events.length;
    } catch (_) {}

    return {
      'childId': childId,
      'name': name,
      'age': age,
      'standard': standard,
      'storedDifficultyPercentage': storedDiff,
      'difficultyLevel': storedLevel,
      'historicalAccuracyPercentage': accuracyAvg.toStringAsFixed(1),
      'totalQuestionsAttempted': totalAttempts,
      'totalActivityEvents': totalEvents,
      'suggestedPromptDirective':
          'Generate curriculum-appropriate questions tailored for a $age-year-old in $standard at $storedDiff% difficulty level ($storedLevel).',
    };
  }

  /// Calls the Groq LLM endpoint to calculate the difficulty percentage,
  /// and persists the LLM returned value directly into SQLite under the child.
  Future<Map<String, dynamic>> assessAndSaveChildDifficulty({
    required String childId,
    required String name,
    required int age,
    required String standard,
    String language = 'en',
    String learningPace = 'normal',
  }) async {
    // 1. Call AI Service (Groq LLM endpoint with LangChain structured output)
    final res = await AiIntegrationService.instance.calculateDifficulty(
      childId: childId,
      name: name,
      age: age,
      standard: standard,
      language: language,
      learningPace: learningPace,
    );

    // 2. Extract LLM returned difficulty percentage
    final diffPct = (res['difficultyPercentage'] as num?)?.toInt() ?? 50;
    final diffLevel = (res['difficultyLevel'] as String?) ?? 'Balanced Explorer';
    final diffReason = (res['reasoning'] as String?) ?? 'Personalized by Groq LLM.';

    // 3. Persist directly into SQLite under this child
    await ChildRepository.updateChildDifficulty(
      childId: childId,
      difficultyPercentage: diffPct,
      difficultyLevel: diffLevel,
      difficultyReasoning: diffReason,
    );

    return {
      'difficultyPercentage': diffPct,
      'difficultyLevel': diffLevel,
      'reasoning': diffReason,
      'modelUsed': res['modelUsed'] ?? 'groq-llm',
    };
  }

  /// Assesses child sign-up onboarding questionnaire (15 questions),
  /// calls Groq LLM to compute personalized difficulty percentage,
  /// stores the full assessment in SQLite `child_onboarding_assessments`,
  /// updates SQLite `child_profiles`, and updates in-memory ChildState.
  Future<Map<String, dynamic>> assessOnboardingAndSave({
    required String childId,
    String? parentId,
    required String name,
    required int age,
    required String standard,
    required Map<String, dynamic> answers,
    required List<String> diagnoses,
    required double speechLevelSlider,
    String language = 'en',
    String learningPace = 'normal',
  }) async {
    // 1. Call AI Service (Groq LLM endpoint)
    final res = await AiIntegrationService.instance.calculateDifficulty(
      childId: childId,
      name: name,
      age: age,
      standard: standard,
      language: language,
      learningPace: learningPace,
      onboardingAnswers: answers,
      diagnoses: diagnoses,
      speechLevelSlider: speechLevelSlider,
    );

    final diffPct = (res['difficultyPercentage'] as num?)?.toInt() ?? 50;
    final diffLevel = (res['difficultyLevel'] as String?) ?? 'Balanced Explorer';
    final diffReason = (res['reasoning'] as String?) ?? 'Calibrated via Groq LLM assessment.';

    // 2. Persist Onboarding Assessment to SQLite
    final assessmentId = 'assess_${DateTime.now().millisecondsSinceEpoch}';
    final assessment = ChildOnboardingAssessment(
      id: assessmentId,
      childId: childId,
      parentId: parentId,
      answers: answers,
      developmentalDiagnoses: diagnoses,
      speechLevelSelfRating: speechLevelSlider,
      computedDifficultyPercentage: diffPct,
      computedDifficultyLevel: diffLevel,
      computedReasoning: diffReason,
      createdAt: DateTime.now(),
    );
    await OnboardingAssessmentRepository.saveAssessment(assessment);

    // 3. Update Child Profile in SQLite
    await ChildRepository.updateChildDifficulty(
      childId: childId,
      difficultyPercentage: diffPct,
      difficultyLevel: diffLevel,
      difficultyReasoning: diffReason,
    );

    // 4. Synchronize in-memory ChildState
    try {
      final current = ChildState.instance.currentProfile;
      if (current.id == childId) {
        ChildState.instance.setProfile(
          current.copyWith(
            difficultyPercentage: diffPct,
            difficultyLevel: diffLevel,
            difficultyReasoning: diffReason,
          ),
        );
      }
    } catch (_) {}

    return {
      'difficultyPercentage': diffPct,
      'difficultyLevel': diffLevel,
      'reasoning': diffReason,
      'modelUsed': res['modelUsed'] ?? 'groq-llm',
      'assessmentId': assessmentId,
    };
  }

  /// Evaluates completed level performance across all 7 dimensions
  /// (Current Ability, Previous Performance, Preferred Interaction, Speech Ability,
  /// Motor Performance, Attention Pattern, Learning History),
  /// saves the evaluation to SQLite, calls Groq LLM to calculate the adaptive
  /// difficulty for the next session, and updates the child profile in SQLite.
  Future<SessionClinicalEvaluation> evaluateAndSaveAdaptiveSessionDifficulty({
    required String childId,
    required String sessionId,
    String? chapterId,
    String? levelId,
    required String currentAbility,
    required String previousPerformance,
    required String preferredInteraction,
    required String speechAbility,
    required String motorPerformance,
    required String attentionPattern,
    required String learningHistory,
  }) async {
    // 1. Get current child profile for baseline info
    final active = ChildState.instance.currentProfile;
    final ChildProfile? profile = await ChildRepository.getChildById(childId);
    final name = (profile?.name.isNotEmpty == true) ? profile!.name : (active.name.isNotEmpty ? active.name : 'Explorer');
    final age = profile?.age ?? active.age ?? 5;
    final standard = profile?.className ?? active.className ?? 'Grade 1';
    final currentDiff = profile?.difficultyPercentage ?? active.difficultyPercentage;

    // 2. Send to Groq LLM for adaptive difficulty assessment
    final res = await AiIntegrationService.instance.calculateAdaptiveDifficulty(
      childId: childId,
      name: name,
      age: age,
      standard: standard,
      chapterId: chapterId,
      levelId: levelId,
      currentAbility: currentAbility,
      previousPerformance: previousPerformance,
      preferredInteraction: preferredInteraction,
      speechAbility: speechAbility,
      motorPerformance: motorPerformance,
      attentionPattern: attentionPattern,
      learningHistory: learningHistory,
      currentDifficultyPercentage: currentDiff,
    );

    final updatedDiff = (res['difficultyPercentage'] as num?)?.toInt() ?? currentDiff;
    final updatedLevel = (res['difficultyLevel'] as String?) ?? 'Balanced Explorer';
    final updatedReasoning = (res['reasoning'] as String?) ?? 'Pedagogically adapted by Dr. Nimo.';
    final recs = (res['recommendations'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];

    // 3. Create evaluation record
    final evaluation = SessionClinicalEvaluation(
      id: 'EVAL_${DateTime.now().millisecondsSinceEpoch}',
      childId: childId,
      sessionId: sessionId,
      chapterId: chapterId,
      levelId: levelId,
      currentAbility: currentAbility,
      previousPerformance: previousPerformance,
      preferredInteraction: preferredInteraction,
      speechAbility: speechAbility,
      motorPerformance: motorPerformance,
      attentionPattern: attentionPattern,
      learningHistory: learningHistory,
      difficultyPercentage: updatedDiff,
      difficultyLevel: updatedLevel,
      difficultyReasoning: updatedReasoning,
      recommendations: recs,
      createdAt: DateTime.now(),
    );

    // 4. Save evaluation to SQLite
    try {
      await SessionEvaluationRepository.saveEvaluation(evaluation);
    } catch (e) {
      debugPrint('ChildDifficultyService: Error saving session evaluation: $e');
    }

    // 5. Update child profile in SQLite
    try {
      await ChildRepository.updateChildDifficulty(
        childId: childId,
        difficultyPercentage: updatedDiff,
        difficultyLevel: updatedLevel,
        difficultyReasoning: updatedReasoning,
      );
    } catch (e) {
      debugPrint('ChildDifficultyService: Error updating child profile difficulty: $e');
    }

    // 6. Update ChildState in-memory notifier if active
    if (ChildState.instance.currentProfile.id == childId) {
      final updatedProfile = core.ChildProfile(
        id: childId,
        name: name,
        age: age,
        className: standard,
        difficultyPercentage: updatedDiff,
        difficultyLevel: updatedLevel,
        difficultyReasoning: updatedReasoning,
        parentId: profile?.parentId,
      );
      ChildState.instance.setProfile(updatedProfile);
    }

    return evaluation;
  }
}
