import 'package:flutter/material.dart';

import '../models/learning_content.dart';
import '../models/level_progress.dart';
import '../screens/video_player_screen.dart';

/// A card widget representing a single level in the level selection screen.
class LevelCard extends StatelessWidget {
  final String childId;
  final LearningLevel level;
  final LevelProgress? progress;
  final bool isLocked;
  final VoidCallback onCompleted;

  const LevelCard({
    super.key,
    required this.childId,
    required this.level,
    this.progress,
    this.isLocked = false,
    required this.onCompleted,
  });

  bool get _isCompleted => progress?.completed ?? false;
  int get _stars => progress?.stars ?? 0;
  bool get _isPlayable => level.isPlayable;

  @override
  Widget build(BuildContext context) {
    // If it's missing assets, we show it as unavailable (unless locked hides it anyway).
    final bool unavailable = !_isPlayable;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: (isLocked || unavailable)
              ? [
                  Colors.white.withValues(alpha: 0.05),
                  Colors.white.withValues(alpha: 0.02),
                ]
              : _isCompleted
                  ? [
                      const Color(0xFF4CAF50).withValues(alpha: 0.15),
                      const Color(0xFF4CAF50).withValues(alpha: 0.05),
                    ]
                  : [
                      const Color(0xFF6C63FF).withValues(alpha: 0.15),
                      const Color(0xFF6C63FF).withValues(alpha: 0.05),
                    ],
        ),
        border: Border.all(
          color: (isLocked || unavailable)
              ? Colors.white.withValues(alpha: 0.1)
              : _isCompleted
                  ? const Color(0xFF4CAF50).withValues(alpha: 0.3)
                  : const Color(0xFF6C63FF).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: (isLocked || unavailable)
              ? null
              : () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => VideoPlayerScreen(
                        childId: childId,
                        level: level,
                      ),
                    ),
                  );
                  // Refresh progress when returning
                  onCompleted();
                },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Icon / Badge
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: (isLocked || unavailable)
                        ? Colors.white.withValues(alpha: 0.05)
                        : _isCompleted
                            ? const Color(0xFF4CAF50).withValues(alpha: 0.2)
                            : const Color(0xFF6C63FF).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: (isLocked || unavailable)
                        ? Icon(
                            unavailable ? Icons.error_outline : Icons.lock_outline,
                            color: Colors.white.withValues(alpha: 0.3),
                            size: 20,
                          )
                        : _isCompleted
                            ? const Icon(
                                Icons.check,
                                color: Color(0xFF4CAF50),
                                size: 24,
                              )
                            : const Icon(
                                Icons.play_arrow_rounded,
                                color: Color(0xFF6C63FF),
                                size: 28,
                              ),
                  ),
                ),
                const SizedBox(width: 16),

                // Title and subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        level.levelName,
                        style: TextStyle(
                          color: (isLocked || unavailable)
                              ? Colors.white.withValues(alpha: 0.3)
                              : Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (_isCompleted)
                        _buildStarRow()
                      else
                        Text(
                          unavailable
                              ? 'Missing Assets'
                              : isLocked
                                  ? '🔒 Locked'
                                  : (level.questionsPath != null ? 'Video + Questions' : 'Video Only'),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
                
                // End Icon
                if (!isLocked && !unavailable && !_isCompleted)
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white54,
                    size: 16,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStarRow() {
    return Row(
      children: List.generate(3, (index) {
        return Icon(
          index < _stars ? Icons.star_rounded : Icons.star_outline_rounded,
          color: index < _stars
              ? const Color(0xFFFFD700) // Gold
              : Colors.white.withValues(alpha: 0.2),
          size: 18,
        );
      }),
    );
  }
}
