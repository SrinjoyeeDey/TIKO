// ignore_for_file: avoid_web_libraries_in_flutter
import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

bool _isViewRegistered = false;

Widget getPlatformGameMap1913View() {
  const String viewTypeId = '1913-game-map-view';
  if (!_isViewRegistered) {
    ui_web.platformViewRegistry.registerViewFactory(viewTypeId, (int viewId) {
      final iframe = html.IFrameElement()
        ..src = '1913-game-map/index.html'
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%';
      return iframe;
    });
    _isViewRegistered = true;
  }
  return const HtmlElementView(viewType: viewTypeId);
}
