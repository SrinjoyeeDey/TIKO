// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'state_story_collection_screen.dart';

bool _isViewRegistered = false;

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
      if (data == 'open_calcutta' || data == '"open_calcutta"' || (data != null && data.contains('open_calcutta'))) {
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => StateStoryCollectionScreen(
              stateId: 'west_bengal',
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
    const String viewTypeId = '1913-game-map-view';
    if (!_isViewRegistered) {
      ui_web.platformViewRegistry.registerViewFactory(viewTypeId, (int viewId) {
        final iframe = html.IFrameElement()
          ..src = 'assets/assets/1913-game-map/index.html'
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%';
        return iframe;
      });
      _isViewRegistered = true;
    }
    return const HtmlElementView(viewType: viewTypeId);
  }
}
