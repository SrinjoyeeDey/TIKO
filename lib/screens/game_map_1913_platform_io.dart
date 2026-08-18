import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:webview_windows/webview_windows.dart';
import 'state_story_collection_screen.dart';

Widget getPlatformGameMap1913View({String? chapterId}) {
  if (Platform.isWindows) {
    return WindowsGameMapView(chapterId: chapterId);
  }
  return const Center(
    child: Text(
      'Map not supported on this platform',
      style: TextStyle(color: Colors.white, fontFamily: 'Outfit'),
    ),
  );
}

class WindowsGameMapView extends StatefulWidget {
  final String? chapterId;
  const WindowsGameMapView({super.key, this.chapterId});

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
      String assetPath = p.join(executableDir, 'data', 'flutter_assets', 'assets', '1913-game-map', 'assets', 'index.html');
      
      if (!File(assetPath).existsSync()) {
        final currentDir = Directory.current.path;
        final candidates = [
          p.join(currentDir, 'assets', '1913-game-map', 'assets', 'index.html'),
          p.join(currentDir, 'web', '1913-game-map', 'index.html'),
          p.join(currentDir, 'assets', '1913-game-map', 'index.html'),
          p.join(executableDir, 'data', 'flutter_assets', 'assets', '1913-game-map', 'index.html'),
        ];
        for (final cand in candidates) {
          if (File(cand).existsSync()) {
            assetPath = cand;
            break;
          }
        }
      }
      
      final fileUri = Uri.file(p.canonicalize(assetPath)).toString();
      debugPrint("WEBVIEW LOADING URL: $fileUri");
      await _controller.loadUrl(fileUri);
      
      _controller.webMessage.listen((message) {
        debugPrint("WEBVIEW MESSAGE RECEIVED: $message");
        final msgStr = message.toString();
        
        String targetStateId = 'west_bengal';
        bool shouldOpen = false;

        try {
          final decoded = jsonDecode(msgStr);
          if (decoded is Map && (decoded['action'] == 'open_state' || decoded.containsKey('stateId'))) {
            targetStateId = decoded['stateId']?.toString() ?? 'west_bengal';
            shouldOpen = true;
          }
        } catch (_) {
          if (msgStr.startsWith('open_state_')) {
            targetStateId = msgStr.replaceFirst('open_state_', '');
            shouldOpen = true;
          } else if (msgStr == 'open_calcutta' || msgStr == '"open_calcutta"') {
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
          debugPrint("Navigating to state story collection for $targetStateId...");
          
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
                MaterialPageRoute(
                  builder: (_) => StateStoryCollectionScreen(
                    stateId: targetStateId,
                    chapterId: widget.chapterId,
                  ),
                ),
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
