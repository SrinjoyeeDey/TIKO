import 'package:flutter_test/flutter_test.dart';
import 'package:peppa_p/qa_pipeline/models/child_profile.dart' as qa;
import 'package:peppa_p/qa_pipeline/database/onboarding_assessment_repository.dart';
import 'package:peppa_p/core/models/child_profile.dart' as core;

void main() {
  group('ChildProfile models serialize difficulty fields', () {
    test('qa_pipeline ChildProfile model maps LLM difficulty correctly', () {
      final profile = qa.ChildProfile(
        id: 'child_test_1',
        name: 'Aarav',
        age: 5,
        className: 'Grade 1',
        difficultyPercentage: 50,
        difficultyLevel: 'Curious Adventurer',
        difficultyReasoning: '5-year-old in Grade 1 calibrated by Groq LLM',
        createdAt: DateTime.now(),
      );

      final map = profile.toMap();
      expect(map['difficulty_percentage'], equals(50));
      expect(map['difficulty_level'], equals('Curious Adventurer'));
      expect(map['class_name'], equals('Grade 1'));

      final restored = qa.ChildProfile.fromMap(map);
      expect(restored.difficultyPercentage, equals(50));
      expect(restored.difficultyLevel, equals('Curious Adventurer'));
      expect(restored.standard, equals('Grade 1'));
    });

    test('core ChildProfile model maps LLM difficulty correctly', () {
      final profile = core.ChildProfile(
        id: 'child_test_2',
        name: 'Tinna',
        age: 5,
        className: 'LKG',
        difficultyPercentage: 30,
        difficultyLevel: 'Gentle Starter',
        difficultyReasoning: '5-year-old in LKG calibrated by Groq LLM',
      );

      final json = profile.toJson();
      expect(json['difficultyPercentage'], equals(30));
      expect(json['difficultyLevel'], equals('Gentle Starter'));
      expect(json['className'], equals('LKG'));

      final restored = core.ChildProfile.fromJson(json);
      expect(restored.difficultyPercentage, equals(30));
      expect(restored.difficultyLevel, equals('Gentle Starter'));
    });

    test('ChildOnboardingAssessment model maps 15 questions and LLM difficulty correctly', () {
      final now = DateTime.now();
      final assessment = ChildOnboardingAssessment(
        id: 'assess_test_001',
        childId: 'child_test_1',
        parentId: 'parent_test_1',
        answers: {
          'Therapist Evaluation': 'Yes',
          'Developmental Profile': ['Speech & Language Delay', 'ADHD'],
          'Understanding Instructions': 'Yes, easily',
          'Concept Understanding': 'Yes, consistently',
          'Time Concepts': 'Yes, clearly',
          'Speaking & Expression': 'Yes, speaks in full sentences',
          'Articulation & Phonics': ['Early Consonants (b, d, m, n, p)'],
          'Social & Interaction': 'Enjoys interactive and cooperative activities',
          'Emotional Regulation': 'Stays calm — uses gestures or tries again',
          'Attention & Engagement': 'Maintains good sustained attention (10+ min)',
          'Sensory Modality': 'Combined Visual Stories & Spoken Audio',
          'Voice Guidance': 'Yes, highly helpful',
          'Processing Pace': 'Standard pacing',
          'Visual Comfort': 'Vibrant standard animations & celebrations',
          'Speech Level Rating Slider': 0.75,
        },
        developmentalDiagnoses: ['Speech & Language Delay', 'ADHD'],
        speechLevelSelfRating: 0.75,
        computedDifficultyPercentage: 65,
        computedDifficultyLevel: 'Curious Adventurer',
        computedReasoning: 'Calibrated by Groq Pediatric AI based on 15 milestone answers',
        createdAt: now,
      );

      final map = assessment.toMap();
      expect(map['child_id'], equals('child_test_1'));
      expect(map['computed_difficulty_percentage'], equals(65));
      expect(map['computed_difficulty_level'], equals('Curious Adventurer'));
      expect(map['speech_level_self_rating'], equals(0.75));
      expect(map['developmental_diagnoses'], contains('Speech & Language Delay'));

      final restored = ChildOnboardingAssessment.fromMap(map);
      expect(restored.id, equals('assess_test_001'));
      expect(restored.childId, equals('child_test_1'));
      expect(restored.computedDifficultyPercentage, equals(65));
      expect(restored.computedDifficultyLevel, equals('Curious Adventurer'));
      expect(restored.developmentalDiagnoses.length, equals(2));
      expect(restored.answers['Therapist Evaluation'], equals('Yes'));
      expect(restored.answers['Speech Level Rating Slider'], equals(0.75));
    });
  });
}
