import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import '../models/event_model.dart';

/// Communication service for Backend Event API endpoints with local cache fallback.
class EventApi {
  static final List<EventModel> _localEventBuffer = [];

  /// In-memory record of an event created locally
  static void bufferLocalEvent(EventModel event) {
    _localEventBuffer.removeWhere((e) => e.eventId == event.eventId);
    _localEventBuffer.add(event);
  }

  /// POST /api/events
  static Future<EventModel?> postEvent(Map<String, dynamic> payload) async {
    // Generate local fallback event immediately
    final localFallback = EventModel(
      eventId: 'EVT_LOC_${DateTime.now().millisecondsSinceEpoch}',
      childId: payload['childId']?.toString() ?? '',
      sessionId: payload['sessionId']?.toString() ?? '',
      activityId: payload['activityId']?.toString(),
      source: payload['source']?.toString() ?? 'flutter',
      eventType: payload['eventType']?.toString() ?? 'UNKNOWN',
      timestamp: payload['timestamp']?.toString() ?? DateTime.now().toUtc().toIso8601String(),
      data: Map<String, dynamic>.from(payload['data'] as Map? ?? {}),
    );
    bufferLocalEvent(localFallback);

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
          final serverEvent = EventModel.fromJson(eventMap);
          bufferLocalEvent(serverEvent);
          return serverEvent;
        }
      }
      debugPrint('EventApi.postEvent failed [${response.statusCode}]: ${response.body}');
    } catch (e) {
      debugPrint('EventApi.postEvent network exception: $e');
    }
    return localFallback;
  }

  /// GET /api/events?childId=...
  static Future<List<EventModel>> getEvents({required String childId}) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/events?childId=$childId');
    try {
      final response = await http.get(
        url,
        headers: ApiConfig.defaultHeaders,
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['success'] == true && body['events'] != null) {
          final eventsList = body['events'] as List;
          final serverEvents = eventsList.map((e) => EventModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
          for (final evt in serverEvents) {
            bufferLocalEvent(evt);
          }
          if (serverEvents.isNotEmpty) {
            return serverEvents;
          }
        }
      }
      debugPrint('EventApi.getEvents failed [${response.statusCode}]: ${response.body}');
    } catch (e) {
      debugPrint('EventApi.getEvents network exception: $e');
    }

    // Return buffered events matching childId or all if childId matches
    final localMatches = _localEventBuffer.where((e) => e.childId == childId || childId.isEmpty).toList();
    return localMatches.isNotEmpty ? localMatches : List.from(_localEventBuffer);
  }
}
