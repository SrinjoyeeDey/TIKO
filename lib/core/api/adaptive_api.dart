import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import '../models/adaptive_decision_model.dart';
import '../models/activity_model.dart';

/// Communication service for Backend Adaptive Engine endpoints.
class AdaptiveApi {
  /// GET /api/children/:childId/next-activity
  static Future<Map<String, dynamic>?> getNextActivity(String childId, {String? skill}) async {
    final query = skill != null ? '?skill=$skill' : '';
    final url = Uri.parse('${ApiConfig.baseUrl}/children/$childId/next-activity$query');

    try {
      final response = await http.get(url, headers: ApiConfig.defaultHeaders);
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['success'] == true) {
          final decisionJson = Map<String, dynamic>.from(body['decision'] as Map);
          final decisionModel = AdaptiveDecisionModel.fromJson(decisionJson);

          final activityJson = Map<String, dynamic>.from(body['recommendedActivity'] as Map);
          final activityModel = ActivityModel.fromJson(activityJson);

          return {
            'decision': decisionModel,
            'recommendedActivity': activityModel,
          };
        }
      }
      debugPrint('AdaptiveApi.getNextActivity failed [${response.statusCode}]: ${response.body}');
    } catch (e) {
      debugPrint('AdaptiveApi.getNextActivity network exception: $e');
    }
    return null;
  }
}
