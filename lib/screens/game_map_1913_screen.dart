import 'package:flutter/material.dart';
import '../widgets/wooden_back_button.dart';
import 'game_map_1913_platform.dart';

/// Screen that loads and presents the interactive 1913 Game Map web application.
class GameMap1913Screen extends StatelessWidget {
  const GameMap1913Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0D0B), // Vintage dark parchment background
      body: Stack(
        children: [
          // 1. Embedded 1913 Game Map Webview / Iframe
          Positioned.fill(
            child: getGameMap1913View(),
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
