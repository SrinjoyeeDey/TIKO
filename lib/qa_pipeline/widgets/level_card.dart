import 'package:flutter/material.dart';

import '../models/learning_content.dart';
import '../models/level_progress.dart';
import '../screens/video_player_screen.dart';
import '../services/content_discovery_service.dart';

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
    final bool unavailable = !_isPlayable;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: (isLocked || unavailable)
            ? const Color(0xFFE5DDD0).withValues(alpha: 0.5)
            : const Color(0xFFFAF4EE), // Bright parchment card
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isLocked || unavailable)
              ? const Color(0xFF8B6914).withValues(alpha: 0.3)
              : const Color(0xFF8B6914),
          width: 2,
        ),
        boxShadow: [
          if (!isLocked && !unavailable)
            const BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
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
                  onCompleted();
                },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Dynamic Level Image
                FutureBuilder<String?>(
                  future: ContentDiscoveryService.findLevelImage(level.chapterId, level.id),
                  builder: (context, snapshot) {
                    final imagePath = snapshot.data;
                    return Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5DDD0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFF8B6914).withValues(alpha: 0.5), 
                            width: 1.5),
                        image: imagePath != null
                            ? DecorationImage(
                                image: AssetImage(imagePath),
                                fit: BoxFit.cover,
                                colorFilter: (isLocked || unavailable)
                                    ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
                                    : null,
                              )
                            : null,
                      ),
                      child: imagePath == null
                          ? Center(
                              child: Icon(
                                (isLocked || unavailable)
                                    ? (unavailable ? Icons.error_outline : Icons.lock_outline)
                                    : Icons.play_arrow_rounded,
                                color: const Color(0xFF8B6914),
                                size: 28,
                              ),
                            )
                          : null,
                    );
                  },
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
                          fontFamily: 'Outfit',
                          color: (isLocked || unavailable)
                              ? const Color(0xFF2E1C12).withValues(alpha: 0.5)
                              : const Color(0xFF2E1C12),
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (_isCompleted)
                        _buildStarRow()
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3E2A1E).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            unavailable
                                ? 'MISSING TAPE'
                                : isLocked
                                    ? 'RESTRICTED'
                                    : (level.questionsPath != null ? 'TAPE + EXAM' : 'TAPE ONLY'),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              color: const Color(0xFF3E2A1E).withValues(alpha: (isLocked || unavailable) ? 0.5 : 1.0),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                // End Icon / Checkmark
                if (_isCompleted)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFFD4AF37),
                    size: 32,
                  )
                else if (!isLocked && !unavailable)
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Color(0xFF8B6914),
                    size: 20,
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
              ? const Color(0xFFD4AF37) // Gold
              : const Color(0xFF8B6914).withValues(alpha: 0.3),
          size: 20,
        );
      }),
    );
  }
}

