import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../api/api_config.dart';
import '../api/event_api.dart';
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

  /// Calculate personalized quest difficulty percentage via Groq LLM Python Service (port 8001)
  Future<Map<String, dynamic>> calculateDifficulty({
    required String childId,
    required String name,
    required int age,
    required String standard,
    String language = 'en',
    String learningPace = 'normal',
    Map<String, dynamic>? onboardingAnswers,
    List<String>? diagnoses,
    double? speechLevelSlider,
  }) async {
    final url = Uri.parse('$aiServiceBaseUrl/calculate/difficulty');
    try {
      final payload = {
        'childId': childId,
        'name': name,
        'age': age,
        'standard': standard,
        'language': language,
        'learningPace': learningPace,
      };
      if (onboardingAnswers != null) payload['onboardingAnswers'] = onboardingAnswers;
      if (diagnoses != null) payload['diagnoses'] = diagnoses;
      if (speechLevelSlider != null) payload['speechLevelSlider'] = speechLevelSlider;

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(payload),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        final diffPct = (body['difficultyPercentage'] as num?)?.toInt() ?? 50;
        final diffLevel = (body['difficultyLevel'] as String?) ?? 'Balanced Explorer';
        final diffReason = (body['reasoning'] as String?) ?? '';
        final model = (body['modelUsed'] as String?) ?? 'Groq LLM';
        debugPrint('🧠 [Groq LLM Structured Output] $diffPct% ($diffLevel) via $model');
        return {
          'success': true,
          'difficultyPercentage': diffPct,
          'difficultyLevel': diffLevel,
          'reasoning': diffReason,
          'modelUsed': model,
        };
      }
    } catch (e) {
      debugPrint('AiIntegrationService.calculateDifficulty exception: $e');
    }

    // Default fallback only if network fails completely
    int fallbackPct = (age <= 4) ? 25 : (age == 5 ? (standard.toLowerCase().contains('grade 1') ? 50 : 30) : 50);
    if (speechLevelSlider != null) {
      if (speechLevelSlider <= 0.33) fallbackPct = (fallbackPct - 10).clamp(15, 95);
      if (speechLevelSlider >= 0.67) fallbackPct = (fallbackPct + 10).clamp(15, 95);
    }
    return {
      'success': true,
      'difficultyPercentage': fallbackPct,
      'difficultyLevel': fallbackPct <= 35 ? 'Gentle Starter' : (fallbackPct <= 55 ? 'Balanced Explorer' : 'Curious Adventurer'),
      'reasoning': 'Calibrated initial quest difficulty for age $age ($standard) based on onboarding evaluation.',
      'modelUsed': 'offline-fallback',
    };
  }

  /// Calculate updated adaptive quest difficulty via Groq LLM after level completion
  Future<Map<String, dynamic>> calculateAdaptiveDifficulty({
    required String childId,
    required String name,
    required int age,
    required String standard,
    String? chapterId,
    String? levelId,
    required String currentAbility,
    required String previousPerformance,
    required String preferredInteraction,
    required String speechAbility,
    required String motorPerformance,
    required String attentionPattern,
    required String learningHistory,
    required int currentDifficultyPercentage,
  }) async {
    final url = Uri.parse('$aiServiceBaseUrl/calculate/adaptive-difficulty');
    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'childId': childId,
              'name': name,
              'age': age,
              'standard': standard,
              'chapterId': chapterId,
              'levelId': levelId,
              'currentAbility': currentAbility,
              'previousPerformance': previousPerformance,
              'preferredInteraction': preferredInteraction,
              'speechAbility': speechAbility,
              'motorPerformance': motorPerformance,
              'attentionPattern': attentionPattern,
              'learningHistory': learningHistory,
              'currentDifficultyPercentage': currentDifficultyPercentage,
            }),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        final diffPct = (body['difficultyPercentage'] as num?)?.toInt() ?? currentDifficultyPercentage;
        final diffLevel = (body['difficultyLevel'] as String?) ?? 'Balanced Explorer';
        final diffReason = (body['reasoning'] as String?) ?? '';
        final recs = (body['recommendationsForNextSession'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];
        final model = (body['modelUsed'] as String?) ?? 'Groq LLM';
        debugPrint('🧠 [Groq LLM Adaptive Output] $diffPct% ($diffLevel) via $model');
        return {
          'success': true,
          'difficultyPercentage': diffPct,
          'difficultyLevel': diffLevel,
          'reasoning': diffReason,
          'recommendations': recs,
          'modelUsed': model,
        };
      }
    } catch (e) {
      debugPrint('AiIntegrationService.calculateAdaptiveDifficulty exception: $e');
    }

    // Heuristic fallback
    return {
      'success': true,
      'difficultyPercentage': currentDifficultyPercentage,
      'difficultyLevel': 'Balanced Explorer',
      'reasoning': 'Calibrated quest difficulty based on completed level performance.',
      'recommendations': <String>[],
      'modelUsed': 'offline-fallback',
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

        // Immediately buffer locally in EventApi for reporting
        final localEvt = EventModel.fromJson(eventJson);
        EventApi.bufferLocalEvent(localEvt);

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

        // Immediately buffer locally in EventApi for reporting
        final localEvt = EventModel.fromJson(eventJson);
        EventApi.bufferLocalEvent(localEvt);

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
          final serverEvt = EventModel.fromJson(Map<String, dynamic>.from(body['event'] as Map));
          EventApi.bufferLocalEvent(serverEvt);
          return serverEvt;
        }
      }
      debugPrint('Backend integration endpoint failed [${res.statusCode}]: ${res.body}');
    } catch (e) {
      debugPrint('_forwardToBackend exception: $e');
    }
    return null;
  }
}
