import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import '../models/session_model.dart';

/// Communication service for Backend Session API endpoints.
class SessionApi {
  /// POST /api/sessions
  static Future<SessionModel?> startSession({
    required String childId,
    String storyId = 'netaji',
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/sessions');
    try {
      final response = await http.post(
        url,
        headers: ApiConfig.defaultHeaders,
        body: json.encode({
          'childId': childId,
          'storyId': storyId,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final body = json.decode(response.body);
        final Map<String, dynamic> data = body is Map<String, dynamic> && body.containsKey('data')
            ? Map<String, dynamic>.from(body['data'] as Map)
            : Map<String, dynamic>.from(body as Map);
        return SessionModel.fromJson(data);
      }
      debugPrint('SessionApi.startSession failed [${response.statusCode}]: ${response.body}');
    } catch (e) {
      debugPrint('SessionApi.startSession network exception: $e');
    }

    // Fallback local session if backend offline
    final fallbackId = 'SES_${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    return SessionModel(
      sessionId: fallbackId,
      childId: childId,
      storyId: storyId,
      startedAt: DateTime.now().toIso8601String(),
      status: 'active',
      activitiesCompleted: 0,
    );
  }

  /// GET /api/sessions/:sessionId
  static Future<SessionModel?> getSession(String sessionId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/sessions/$sessionId');
    try {
      final response = await http.get(url, headers: ApiConfig.defaultHeaders);
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final Map<String, dynamic> data = body is Map<String, dynamic> && body.containsKey('data')
            ? Map<String, dynamic>.from(body['data'] as Map)
            : Map<String, dynamic>.from(body as Map);
        return SessionModel.fromJson(data);
      }
    } catch (e) {
      debugPrint('SessionApi.getSession network exception: $e');
    }
    return null;
  }

  /// PATCH /api/sessions/:sessionId/end
  static Future<SessionModel?> endSession(String sessionId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/sessions/$sessionId/end');
    final endedAtIso = DateTime.now().toIso8601String();
    try {
      final response = await http.patch(
        url,
        headers: ApiConfig.defaultHeaders,
        body: json.encode({'endedAt': endedAtIso}),
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final Map<String, dynamic> data = body is Map<String, dynamic> && body.containsKey('data')
            ? Map<String, dynamic>.from(body['data'] as Map)
            : Map<String, dynamic>.from(body as Map);
        return SessionModel.fromJson(data);
      }
    } catch (e) {
      debugPrint('SessionApi.endSession network exception: $e');
    }
    return null;
  }

  /// POST /api/sessions/:sessionId/interactions
  static Future<bool> logInteraction(String sessionId, Map<String, dynamic> interactionData) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/sessions/$sessionId/interactions');
    try {
      final response = await http.post(
        url,
        headers: ApiConfig.defaultHeaders,
        body: json.encode(interactionData),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('SessionApi.logInteraction exception: $e');
    }
    return false;
  }
}
