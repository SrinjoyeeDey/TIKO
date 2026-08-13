import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:webview_windows/webview_windows.dart';
import 'state_story_collection_screen.dart';

Widget getPlatformGameMap1913View() {
  if (Platform.isWindows) {
    return const WindowsGameMapView();
  }
  return const Center(
    child: Text(
      'Map not supported on this platform',
      style: TextStyle(color: Colors.white, fontFamily: 'Outfit'),
    ),
  );
}

class WindowsGameMapView extends StatefulWidget {
  const WindowsGameMapView({super.key});

  @override
  State<WindowsGameMapView> createState() => _WindowsGameMapViewState();
}

class _WindowsGameMapViewState extends State<WindowsGameMapView> {
  WebviewController _controller = WebviewController();
  bool _isInitialized = false;
  bool _isWebViewVisible = true;

  @override
  void initState() {
    super.initState();
    _initWebview();
  }

  Future<void> _initWebview() async {
    try {
      await _controller.initialize();
      
      // Resolve local asset path for Windows
      String executablePath = Platform.resolvedExecutable;
      String executableDir = p.dirname(executablePath);
      String assetPath = p.join(executableDir, 'data', 'flutter_assets', 'assets', '1913-game-map', 'index.html');
      
      await _controller.loadUrl('file:///$assetPath');
      
      _controller.webMessage.listen((message) {
        debugPrint("WEBVIEW MESSAGE RECEIVED: $message");
        if (message == 'open_calcutta') {
          if (!mounted) return;
          debugPrint("Navigating to West Bengal story collection...");
          
          // Completely dispose and unmount webview to prevent Impeller from crashing 
          // when media_kit tries to composite a new DirectX texture!
          _controller.dispose();
          setState(() {
            _isWebViewVisible = false;
            _isInitialized = false;
          });
          
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Future.delayed(const Duration(milliseconds: 300), () {
              if (!mounted) return;
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const StateStoryCollectionScreen(stateId: 'west_bengal')),
              ).then((_) {
                if (mounted) {
                  // Reinitialize Webview entirely when returning
                  setState(() {
                    _controller = WebviewController();
                    _isWebViewVisible = true;
                  });
                  _initWebview();
                }
              });
            });
          });
        }
      });
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint("Webview Windows Init Error: $e");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    
    if (!_isWebViewVisible) {
      return const SizedBox.expand(
        child: DecoratedBox(
          decoration: BoxDecoration(color: Color(0xFFC5AE79)),
        ),
      );
    }
    
    return Webview(_controller);
  }
}
