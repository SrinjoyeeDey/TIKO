import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import '../models/recommendation_model.dart';
import '../models/activity_model.dart';

/// Communication service for Backend Recommendation Engine endpoints.
class RecommendationApi {
  /// GET /api/children/:childId/recommendation
  static Future<Map<String, dynamic>?> getRecommendation(String childId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/children/$childId/recommendation');
    try {
      final response = await http.get(url, headers: ApiConfig.defaultHeaders);
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['success'] == true) {
          final recJson = Map<String, dynamic>.from(body['recommendation'] as Map);
          final recModel = RecommendationModel.fromJson(recJson);

          final actJson = Map<String, dynamic>.from(body['activity'] as Map);
          final actModel = ActivityModel.fromJson(actJson);

          return {
            'recommendation': recModel,
            'activity': actModel,
          };
        }
      }
      debugPrint('RecommendationApi.getRecommendation failed [${response.statusCode}]: ${response.body}');
    } catch (e) {
      debugPrint('RecommendationApi.getRecommendation network exception: $e');
    }
    return null;
  }
}
