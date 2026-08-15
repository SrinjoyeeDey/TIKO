import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import '../models/child_profile.dart';

/// Communication service for Backend Child API endpoints.
class ChildApi {
  /// GET /api/children/:id
  static Future<ChildProfile> getChildProfile(String id) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/children/$id');
    try {
      final response = await http.get(url, headers: ApiConfig.defaultHeaders);
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['success'] == true && body['data'] != null) {
          return ChildProfile.fromJson(body['data']);
        }
      }
      debugPrint('ChildApi.getChildProfile failed [${response.statusCode}]: ${response.body}');
    } catch (e) {
      debugPrint('ChildApi.getChildProfile network exception: $e');
    }

    // Fallback default profile if backend unreachable
    return ChildProfile(
      id: id,
      name: 'Tinna',
      xp: 350,
      level: 4,
      streak: 5,
    );
  }

  /// POST /api/children
  static Future<ChildProfile?> createChildProfile(ChildProfile profile) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/children');
    try {
      final response = await http.post(
        url,
        headers: ApiConfig.defaultHeaders,
        body: json.encode(profile.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['success'] == true && body['data'] != null) {
          return ChildProfile.fromJson(body['data']);
        }
      }
    } catch (e) {
      debugPrint('ChildApi.createChildProfile network exception: $e');
    }
    return profile;
  }

  /// PATCH /api/children/:id
  static Future<ChildProfile?> updateChildProfile(String id, Map<String, dynamic> updates) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/children/$id');
    try {
      final response = await http.patch(
        url,
        headers: ApiConfig.defaultHeaders,
        body: json.encode(updates),
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['success'] == true && body['data'] != null) {
          return ChildProfile.fromJson(body['data']);
        }
      }
    } catch (e) {
      debugPrint('ChildApi.updateChildProfile network exception: $e');
    }
    return null;
  }
}
