import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../api/api_config.dart';
import '../models/event_model.dart';

enum AiServiceStatus {
  online,
  offline,
  unreachable,
}

/// Service handling Flutter communication with the local Python AI Microservice (Port 8001)
/// and forwarding telemetry events to the NIMO Express Backend (Port 3000).
class AiIntegrationService {
  AiIntegrationService._privateConstructor();
  static final AiIntegrationService instance = AiIntegrationService._privateConstructor();

  static const String aiServiceBaseUrl = 'http://localhost:8001';

  /// Health check endpoint for Python AI Microservice
  Future<Map<String, dynamic>> checkHealth() async {
    final url = Uri.parse('$aiServiceBaseUrl/health');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        return {
          'status': 'online',
          'speechModel': 'ready',
          'visionModel': 'ready',
          'raw': body,
        };
      }
    } catch (e) {
      debugPrint('AiIntegrationService.checkHealth offline: $e');
    }
    return {
      'status': 'offline',
      'speechModel': 'unavailable',
      'visionModel': 'unavailable',
      'reason': 'Python AI service on port 8001 is unreachable'
    };
  }

  /// Analyze WAV speech audio via Python AI Service (port 8001) and forward event to NIMO Express Backend (port 3000)
  Future<Map<String, dynamic>> analyzeSpeech({
    required List<int> audioBytes,
    required String childId,
    required String sessionId,
    required String activityId,
    String targetPhrase = '',
  }) async {
    final url = Uri.parse('$aiServiceBaseUrl/analyze/speech');
    try {
      final request = http.MultipartRequest('POST', url)
        ..fields['childId'] = childId
        ..fields['sessionId'] = sessionId
        ..fields['activityId'] = activityId
        ..fields['targetPhrase'] = targetPhrase
        ..files.add(http.MultipartFile.fromBytes('file', audioBytes, filename: 'audio.wav'));

      final streamedResponse = await request.send().timeout(const Duration(seconds: 10));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final eventJson = json.decode(response.body) as Map<String, dynamic>;
        debugPrint('🎙️ [AI Service] Speech Analyzed: ${eventJson['data']}');

        // Automatically forward observation event to NIMO Express Backend
        final backendRes = await _forwardToBackend(eventJson);

        return {
          'success': true,
          'aiEvent': eventJson,
          'forwardedToBackend': backendRes != null,
          'backendEvent': backendRes?.toJson(),
        };
      }
      return {
        'success': false,
        'error': 'Python AI service returned status ${response.statusCode}: ${response.body}'
      };
    } catch (e) {
      debugPrint('AiIntegrationService.analyzeSpeech exception: $e');
      return {
        'success': false,
        'error': 'Python AI service speech analysis failed: $e'
      };
    }
  }

  /// Analyze camera frame image via Python AI Service (port 8001) and forward event to NIMO Express Backend (port 3000)
  Future<Map<String, dynamic>> analyzeEngagement({
    required List<int> imageBytes,
    required String childId,
    required String sessionId,
    required String activityId,
  }) async {
    final url = Uri.parse('$aiServiceBaseUrl/analyze/engagement');
    try {
      final request = http.MultipartRequest('POST', url)
        ..fields['childId'] = childId
        ..fields['sessionId'] = sessionId
        ..fields['activityId'] = activityId
        ..files.add(http.MultipartFile.fromBytes('file', imageBytes, filename: 'frame.jpg'));

      final streamedResponse = await request.send().timeout(const Duration(seconds: 5));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final eventJson = json.decode(response.body) as Map<String, dynamic>;
        debugPrint('👁️ [AI Service] Engagement Analyzed: ${eventJson['data']}');

        // Automatically forward observation event to NIMO Express Backend
        final backendRes = await _forwardToBackend(eventJson);

        return {
          'success': true,
          'aiEvent': eventJson,
          'forwardedToBackend': backendRes != null,
          'backendEvent': backendRes?.toJson(),
        };
      }
      return {
        'success': false,
        'error': 'Python AI service returned status ${response.statusCode}: ${response.body}'
      };
    } catch (e) {
      debugPrint('AiIntegrationService.analyzeEngagement exception: $e');
      return {
        'success': false,
        'error': 'Python AI service vision analysis failed: $e'
      };
    }
  }

  /// Internal helper to forward Python AI observation event to NIMO Backend (POST /api/integrations/events)
  Future<EventModel?> _forwardToBackend(Map<String, dynamic> aiEventJson) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/integrations/events');
    try {
      final res = await http.post(
        url,
        headers: ApiConfig.defaultHeaders,
        body: json.encode(aiEventJson),
      );

      if (res.statusCode == 201 || res.statusCode == 200) {
        final body = json.decode(res.body);
        if (body['success'] == true && body['event'] != null) {
          return EventModel.fromJson(Map<String, dynamic>.from(body['event'] as Map));
        }
      }
      debugPrint('Backend integration endpoint failed [${res.statusCode}]: ${res.body}');
    } catch (e) {
      debugPrint('_forwardToBackend exception: $e');
    }
    return null;
  }
}
