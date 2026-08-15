import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import '../models/event_model.dart';

/// Communication service for Backend Event API endpoints.
class EventApi {
  /// POST /api/events
  static Future<EventModel?> postEvent(Map<String, dynamic> payload) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/events');
    try {
      final response = await http.post(
        url,
        headers: ApiConfig.defaultHeaders,
        body: json.encode(payload),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['success'] == true && body['event'] != null) {
          final eventMap = Map<String, dynamic>.from(body['event'] as Map);
          return EventModel.fromJson(eventMap);
        }
      }
      debugPrint('EventApi.postEvent failed [${response.statusCode}]: ${response.body}');
    } catch (e) {
      debugPrint('EventApi.postEvent network exception: $e');
    }
    return null;
  }
}
