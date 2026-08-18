// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'state_story_collection_screen.dart';

Widget getPlatformGameMap1913View({String? chapterId}) {
  return WebGameMapView(chapterId: chapterId);
}

class WebGameMapView extends StatefulWidget {
  final String? chapterId;
  const WebGameMapView({super.key, this.chapterId});

  @override
  State<WebGameMapView> createState() => _WebGameMapViewState();
}

class _WebGameMapViewState extends State<WebGameMapView> {
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _sub = html.window.onMessage.listen((event) {
      final data = event.data?.toString();
      debugPrint("WEB WINDOW MESSAGE RECEIVED: $data");
      if (data == null || data.isEmpty) return;

      String targetStateId = 'west_bengal';
      bool shouldOpen = false;

      try {
        final decoded = jsonDecode(data);
        if (decoded is Map && (decoded['action'] == 'open_state' || decoded.containsKey('stateId'))) {
          targetStateId = decoded['stateId']?.toString() ?? 'west_bengal';
          shouldOpen = true;
        }
      } catch (_) {
        if (data.startsWith('open_state_')) {
          targetStateId = data.replaceFirst('open_state_', '');
          shouldOpen = true;
        } else if (data == 'open_calcutta' || data == '"open_calcutta"') {
          targetStateId = 'west_bengal';
          shouldOpen = true;
        }
      }

      if (shouldOpen) {
        final currentChapter = (widget.chapterId ?? '').toLowerCase();
        
        // Enforce strict chapter-state routing:
        // - Bharatnatyam level: ONLY Tamil Nadu is clickable!
        // - Netaji level: ONLY West Bengal is clickable!
        if (currentChapter.contains('bharat') || currentChapter.contains('tamil')) {
          if (!targetStateId.contains('tamil')) {
            debugPrint("Blocked non-Tamil Nadu state ($targetStateId) for Bharatnatyam level");
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🎭 Bharatanatyam originates in Tamil Nadu! Tap Tamil Nadu on the map to begin your quest.'),
                backgroundColor: Color(0xFF2E1C12),
                duration: Duration(seconds: 2),
              ),
            );
            return;
          }
        } else if (currentChapter.contains('netaji') || currentChapter.contains('bengal')) {
          if (!targetStateId.contains('bengal')) {
            debugPrint("Blocked non-West Bengal state ($targetStateId) for Netaji level");
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🇮🇳 Netaji Subhas Chandra Bose story begins in West Bengal! Tap West Bengal on the map.'),
                backgroundColor: Color(0xFF2E1C12),
                duration: Duration(seconds: 2),
              ),
            );
            return;
          }
        }

        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => StateStoryCollectionScreen(
              stateId: targetStateId,
              chapterId: widget.chapterId,
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chapterParam = Uri.encodeComponent(widget.chapterId ?? '');
    final String viewTypeId = '1913-game-map-view-${widget.chapterId ?? "all"}';
    
    ui_web.platformViewRegistry.registerViewFactory(viewTypeId, (int viewId) {
      final iframe = html.IFrameElement()
        ..src = '1913-game-map/index.html?chapter=$chapterParam'
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%';
      return iframe;
    });
    
    return HtmlElementView(viewType: viewTypeId);
  }
}
