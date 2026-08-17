import 'package:flutter_test/flutter_test.dart';
import 'package:peppa_p/qa_pipeline/models/child_profile.dart' as qa;
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
  });
}
