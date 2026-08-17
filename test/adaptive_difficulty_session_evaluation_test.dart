import 'package:flutter_test/flutter_test.dart';
import 'package:peppa_p/qa_pipeline/models/session_evaluation_model.dart';

void main() {
  group('Adaptive Session Evaluation Model Tests', () {
    test('SessionClinicalEvaluation maps to and from Map correctly', () {
      final now = DateTime.now();
      final eval = SessionClinicalEvaluation(
        id: 'EVAL_101',
        childId: 'child_aarav',
        sessionId: 'SES_001',
        chapterId: 'Netaji',
        levelId: 'Netaji_0',
        currentAbility: 'High Comprehension (Accuracy: 100%)',
        previousPerformance: '3 Stars (5/5 correct)',
        preferredInteraction: 'Strong screen focus and eye gaze lock',
        speechAbility: '88% pronunciation (3 vocalizations)',
        motorPerformance: 'Sequencing: 100%, Fine Motor: 100%',
        attentionPattern: 'Visual Focus: 92%, Gaze Lock: 95%, Distractions: 0',
        learningHistory: 'Level Netaji_0 completed in 2.1m, 0 hints, 0 frustration indicators',
        difficultyPercentage: 45,
        difficultyLevel: 'Balanced Explorer',
        difficultyReasoning: 'Aarav demonstrated mastery with high visual focus.',
        recommendations: [
          'Practice longer story sequencing cards',
          'Explore audio repetition with new vocabulary',
        ],
        createdAt: now,
      );

      final map = eval.toMap();
      expect(map['id'], 'EVAL_101');
      expect(map['child_id'], 'child_aarav');
      expect(map['difficulty_percentage'], 45);
      expect(map['difficulty_level'], 'Balanced Explorer');

      final fromMap = SessionClinicalEvaluation.fromMap(map);
      expect(fromMap.id, 'EVAL_101');
      expect(fromMap.childId, 'child_aarav');
      expect(fromMap.currentAbility, 'High Comprehension (Accuracy: 100%)');
      expect(fromMap.speechAbility, '88% pronunciation (3 vocalizations)');
      expect(fromMap.difficultyPercentage, 45);
      expect(fromMap.difficultyLevel, 'Balanced Explorer');
      expect(fromMap.recommendations.length, 2);
      expect(fromMap.recommendations[0], 'Practice longer story sequencing cards');
    });
  });
}
