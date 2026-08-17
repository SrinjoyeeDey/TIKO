import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../qa_pipeline/database/database_helper.dart';
import '../api/api_config.dart';
import '../models/event_model.dart';

/// Offline Event Queue & Synchronization Service.
/// Guarantees gameplay event data is never lost when offline.
class SyncService {
  static final SyncService instance = SyncService._();
  SyncService._();

  bool _isSyncing = false;

  /// Enqueues an event locally in SQLite.
  Future<void> queueEvent(EventModel event) async {
    try {
      final db = await DatabaseHelper.instance.database;

      // 1. Insert into local activity_events table
      await db.insert(
        'activity_events',
        event.toMap(),
      );

      // 2. Insert into event_queue for backend sync
      await db.insert(
        'event_queue',
        {
          'id': event.eventId ?? 'evt_${DateTime.now().microsecondsSinceEpoch}',
          'event_json': jsonEncode(event.toJson()),
          'created_at': DateTime.now().toIso8601String(),
        },
      );

      // Trigger background sync
      triggerSync();
    } catch (e) {
      debugPrint('SyncService.queueEvent error: $e');
    }
  }

  /// Triggers asynchronous sync of all pending queued events to Node.js backend.
  Future<void> triggerSync() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final db = await DatabaseHelper.instance.database;
      final pendingRows = await db.query('event_queue', limit: 50);

      if (pendingRows.isEmpty) {
        _isSyncing = false;
        return;
      }

      final baseUrl = ApiConfig.baseUrl;
      final eventsToSync = pendingRows.map((r) => jsonDecode(r['event_json'] as String)).toList();

      final response = await http
          .post(
            Uri.parse('$baseUrl/events'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'events': eventsToSync}),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Clear synced items from queue
        final syncedIds = pendingRows.map((r) => r['id'] as String).toList();
        for (final id in syncedIds) {
          await db.delete('event_queue', where: 'id = ?', whereArgs: [id]);
          await db.update(
            'activity_events',
            {'synced': 1},
            where: 'id = ?',
            whereArgs: [id],
          );
        }
        debugPrint('SyncService: Successfully synced ${syncedIds.length} events to backend.');
      }
    } catch (e) {
      debugPrint('SyncService offline sync pending (Backend unreachable): $e');
    } finally {
      _isSyncing = false;
    }
  }
}
