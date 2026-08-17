import 'package:flutter_test/flutter_test.dart';
import 'package:peppa_p/qa_pipeline/models/mcq_question.dart';
import 'package:peppa_p/qa_pipeline/models/question.dart';
import 'package:peppa_p/qa_pipeline/models/descriptive_question.dart';
import 'package:peppa_p/qa_pipeline/models/speech_question.dart';
import 'package:peppa_p/qa_pipeline/models/sequence_question.dart';
import 'package:peppa_p/qa_pipeline/models/image_matching_question.dart';

void main() {
  group('Question Difficulty Serialization and Calibration Tests', () {
    test('MCQ question parses difficulty, percentage, and level', () {
      final json = {
        'id': 1,
        'type': 'mcq',
        'question': 'When was Netaji born?',
        'options': {'A': '1897', 'B': '1947'},
        'answer': 'A',
        'difficulty': 'easy',
        'difficulty_percentage': 30,
        'difficulty_level': 'Gentle Starter',
      };

      final q = McqQuestion.fromJson(json, QuestionType.mcq);
      expect(q.id, 1);
      expect(q.difficulty, 'easy');
      expect(q.difficultyPercentage, 30);
      expect(q.difficultyLevel, 'Gentle Starter');
    });

    test('Descriptive question derives fallback percentage from difficulty', () {
      final json = {
        'id': 6,
        'type': 'descriptive',
        'question': 'Describe Netaji family',
        'reference_answer': 'Born to Janaki Bose',
        'key_concepts': ['Janaki Bose'],
        'difficulty': 'medium',
      };

      final q = DescriptiveQuestion.fromJson(json);
      expect(q.difficultyPercentage, 50);
      expect(q.difficultyLevel, 'Balanced Explorer');
    });

    test('Speech question parses customized percentage', () {
      final json = {
        'id': 8,
        'type': 'speech',
        'question': 'Pronounce Subhas Chandra Bose',
        'target_phrase': 'Subhas Chandra Bose',
        'reference_answer': 'Subhas Chandra Bose',
        'key_concepts': ['Subhas'],
        'difficulty': 'easy',
        'difficulty_percentage': 30,
        'difficulty_level': 'Gentle Starter',
      };

      final q = SpeechQuestion.fromJson(json);
      expect(q.difficultyPercentage, 30);
      expect(q.difficultyLevel, 'Gentle Starter');
    });

    test('Sequence question parses difficulty', () {
      final json = {
        'id': 11,
        'type': 'sequence_mcq',
        'question': 'What happened first?',
        'options': {'A': 'Birth', 'B': 'College'},
        'difficulty': 'easy',
        'difficulty_percentage': 30,
        'difficulty_level': 'Gentle Starter',
      };

      final q = SequenceQuestion.fromJson(json);
      expect(q.difficultyPercentage, 30);
      expect(q.difficultyLevel, 'Gentle Starter');
    });

    test('Image matching question parses difficulty', () {
      final json = {
        'id': 15,
        'type': 'image_matching',
        'question': 'Match pictures',
        'images': [
          {'id': '1', 'file': 'img.png', 'label': 'Netaji'}
        ],
        'descriptions': [
          {'id': 'd1', 'text': 'Leader'}
        ],
        'correct_matches': {'1': 'd1'},
        'points': 3,
        'difficulty': 'easy',
        'difficulty_percentage': 35,
        'difficulty_level': 'Gentle Starter',
      };

      final q = ImageMatchingQuestion.fromJson(json);
      expect(q.difficultyPercentage, 35);
      expect(q.difficultyLevel, 'Gentle Starter');
    });
  });
}
