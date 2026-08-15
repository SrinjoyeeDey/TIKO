import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import '../models/activity_model.dart';

/// Communication service for Backend Activity API endpoints.
class ActivityApi {
  /// GET /api/stories/:storyId/activities
  static Future<List<ActivityModel>> getActivitiesForStory(String storyId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/stories/$storyId/activities');
    try {
      final response = await http.get(url, headers: ApiConfig.defaultHeaders);
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body is Map<String, dynamic> && body['activities'] is List) {
          final list = (body['activities'] as List)
              .map((item) => ActivityModel.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList();
          return list;
        }
      }
      debugPrint('ActivityApi.getActivitiesForStory failed [${response.statusCode}]: ${response.body}');
    } catch (e) {
      debugPrint('ActivityApi.getActivitiesForStory network exception: $e');
    }

    // Fallback seed activities if backend offline
    return [
      const ActivityModel(
        activityId: 'netaji_q01',
        storyId: 'netaji',
        title: 'Who was Netaji?',
        type: 'mcq',
        skill: 'recognition',
        difficulty: 1,
        question: 'Who was known as Netaji?',
        options: ['Subhas Chandra Bose', 'Mahatma Gandhi', 'Sardar Patel', 'Jawaharlal Nehru'],
        correctAnswer: 0,
        reward: 20,
        order: 1,
      ),
      const ActivityModel(
        activityId: 'netaji_q02_speech',
        storyId: 'netaji',
        title: 'Netaji Speech Recognition',
        type: 'speech',
        skill: 'speech',
        difficulty: 1,
        question: 'Speak Netaji Subhas Chandra Bose\'s full name clearly into your microphone:',
        targetPhrase: 'Subhas Chandra Bose',
        reward: 30,
        order: 2,
      ),
      const ActivityModel(
        activityId: 'netaji_q03',
        storyId: 'netaji',
        title: 'Netaji\'s Escape Sequence',
        type: 'sequencing',
        skill: 'sequencing',
        difficulty: 1,
        question: 'Arrange the events of Netaji\'s Great Escape in chronological order.',
        options: [
          'House arrest in Calcutta (1941)',
          'Disguised escape to Gomoh Railway Station',
          'Travel through Afghanistan to Berlin',
          'Formation of Azad Hind Fauj in Singapore'
        ],
        correctAnswer: [0, 1, 2, 3],
        reward: 30,
        order: 3,
      ),
    ];
  }

  /// GET /api/activities/:activityId
  static Future<ActivityModel?> getActivity(String activityId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/activities/$activityId');
    try {
      final response = await http.get(url, headers: ApiConfig.defaultHeaders);
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        return ActivityModel.fromJson(Map<String, dynamic>.from(body as Map));
      }
    } catch (e) {
      debugPrint('ActivityApi.getActivity network exception: $e');
    }
    return null;
  }
}
