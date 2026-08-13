// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../widgets/wooden_back_button.dart';

/// Screen that loads and presents the interactive 1913 Game Map web application.
class GameMap1913Screen extends StatefulWidget {
  const GameMap1913Screen({super.key});

  @override
  State<GameMap1913Screen> createState() => _GameMap1913ScreenState();
}

class _GameMap1913ScreenState extends State<GameMap1913Screen> {
  static const String _viewTypeId = '1913-game-map-view';
  static bool _isViewRegistered = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb && !_isViewRegistered) {
      ui_web.platformViewRegistry.registerViewFactory(_viewTypeId, (int viewId) {
        final iframe = html.IFrameElement()
          ..src = '1913-game-map/index.html'
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%';
        return iframe;
      });
      _isViewRegistered = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0D0B), // Vintage dark parchment background
      body: Stack(
        children: [
          // 1. Embedded 1913 Game Map Webview / Iframe
          Positioned.fill(
            child: kIsWeb
                ? const HtmlElementView(viewType: _viewTypeId)
                : Container(
                    color: const Color(0xFF1B140E),
                    child: const Center(
                      child: Text(
                        '1913 World Map Loaded',
                        style: TextStyle(color: Colors.white, fontFamily: 'Outfit'),
                      ),
                    ),
                  ),
          ),

          // 2. Vintage Top Control Bar with Back Button
          Positioned(
            top: 20,
            left: 20,
            child: SafeArea(
              child: WoodenBackButton(
                size: 52,
                onTap: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
