import 'package:flutter/material.dart';
import '../widgets/wooden_back_button.dart';
import 'game_map_1913_platform.dart';
import '../core/state/child_state.dart';
import '../core/models/child_profile.dart';
import 'sego_concept_screen.dart';

/// Screen that loads and presents the interactive 1913 Game Map web application
/// overlayed with live Child Profile HUD (Level, XP, Streak, Name).
class GameMap1913Screen extends StatelessWidget {
  final String? chapterId;

  const GameMap1913Screen({
    super.key,
    this.chapterId,
  });

  void _handleBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SegoConceptScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleBack(context);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0D0B), // Vintage dark parchment background
        body: Stack(
          children: [
            // 1. Embedded 1913 Game Map Webview / Iframe
            Positioned.fill(
              child: getGameMap1913View(chapterId: chapterId),
            ),

            // 2. Vintage Top Control Bar with Back Button & Child Profile HUD
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    WoodenBackButton(
                      size: 48,
                      onTap: () => _handleBack(context),
                    ),

                  // Real Child Profile HUD Display (Step 6)
                  ValueListenableBuilder<ChildProfile?>(
                    valueListenable: ChildState.instance.activeProfileNotifier,
                    builder: (context, profile, _) {
                      final name = profile?.name ?? 'Child';
                      final level = profile?.level ?? 1;
                      final xp = profile?.xp ?? 0;
                      final streak = profile?.streak ?? 1;

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E1C12).withValues(alpha: 0.90),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFFFD54F), width: 1.5),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black45,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Child Name
                            Text(
                              name,
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFFFF59D),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(width: 1, height: 14, color: const Color(0xFF8D7A6F)),
                            const SizedBox(width: 10),
                            // Level Pill
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('⭐', style: TextStyle(fontSize: 12)),
                                const SizedBox(width: 4),
                                Text(
                                  'Lvl $level',
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 10),
                            Container(width: 1, height: 14, color: const Color(0xFF8D7A6F)),
                            const SizedBox(width: 10),
                            // XP Pill
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('💎', style: TextStyle(fontSize: 12)),
                                const SizedBox(width: 4),
                                Text(
                                  '$xp XP',
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF80DEEA),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 10),
                            Container(width: 1, height: 14, color: const Color(0xFF8D7A6F)),
                            const SizedBox(width: 10),
                            // Streak Pill
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🔥', style: TextStyle(fontSize: 12)),
                                const SizedBox(width: 4),
                                Text(
                                  '${streak}d',
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFFF8A65),
                                  ),
                                ),
                              ],
                            ),
                            // Difficulty Pill
                            if (profile?.difficultyLevel != null && profile!.difficultyLevel!.isNotEmpty) ...[
                              const SizedBox(width: 10),
                              Container(width: 1, height: 14, color: const Color(0xFF8D7A6F)),
                              const SizedBox(width: 10),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('🛡️', style: TextStyle(fontSize: 12)),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${profile.difficultyLevel} (${profile.difficultyPercentage}%)',
                                    style: const TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFFFD54F),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ));
  }
}
