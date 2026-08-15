import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import '../models/activity_result_model.dart';
import '../models/child_profile.dart';

/// Communication service for Backend Scoring & Results API endpoints.
class ScoringApi {
  /// POST /api/scoring/evaluate
  static Future<Map<String, dynamic>?> evaluateActivity({
    required String sessionId,
    required String activityId,
    String? childId,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/scoring/evaluate');
    try {
      final Map<String, dynamic> payload = {
        'sessionId': sessionId,
        'activityId': activityId,
      };
      if (childId != null) {
        payload['childId'] = childId;
      }

      final response = await http.post(
        url,
        headers: ApiConfig.defaultHeaders,
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['success'] == true && body['data'] != null) {
          final data = Map<String, dynamic>.from(body['data'] as Map);
          
          final resultJson = Map<String, dynamic>.from(data['result'] as Map);
          final resultModel = ActivityResultModel.fromJson(resultJson);

          ChildProfile? childModel;
          if (data['child'] != null) {
            final childJson = Map<String, dynamic>.from(data['child'] as Map);
            childModel = ChildProfile.fromJson(childJson);
          }

          return {
            'result': resultModel,
            'child': childModel,
          };
        }
      }
      debugPrint('ScoringApi.evaluateActivity failed [${response.statusCode}]: ${response.body}');
    } catch (e) {
      debugPrint('ScoringApi.evaluateActivity network exception: $e');
    }
    return null;
  }
}
