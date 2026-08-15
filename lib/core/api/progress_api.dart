import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import '../models/skill_progress_model.dart';

/// Communication service for Backend Progress API endpoints.
class ProgressApi {
  /// GET /api/children/:childId/progress
  static Future<Map<String, SkillProgressModel>> getProgress(String childId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/children/$childId/progress');
    try {
      final response = await http.get(url, headers: ApiConfig.defaultHeaders);
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['success'] == true && body['skills'] is Map) {
          final Map rawMap = body['skills'] as Map;
          final Map<String, SkillProgressModel> resultMap = {};
          rawMap.forEach((key, val) {
            resultMap[key.toString()] = SkillProgressModel.fromJson(Map<String, dynamic>.from(val as Map));
          });
          return resultMap;
        }
      }
      debugPrint('ProgressApi.getProgress failed [${response.statusCode}]: ${response.body}');
    } catch (e) {
      debugPrint('ProgressApi.getProgress network exception: $e');
    }
    return {};
  }

  /// GET /api/children/:childId/progress/history
  static Future<List<Map<String, dynamic>>> getProgressHistory(String childId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/children/$childId/progress/history');
    try {
      final response = await http.get(url, headers: ApiConfig.defaultHeaders);
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['success'] == true && body['history'] is List) {
          return (body['history'] as List)
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('ProgressApi.getProgressHistory exception: $e');
    }
    return [];
  }
}
