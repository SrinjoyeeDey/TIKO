import 'package:flutter/material.dart';

import '../database/progress_repository.dart';
import '../models/learning_content.dart';
import '../models/level_progress.dart';
import '../widgets/level_card.dart';

/// Displays a scrollable list of levels for a specific chapter.
/// Completed levels show stars and a checkmark.
/// Sequential unlocking applies within the chapter.
class LevelSelectionScreen extends StatefulWidget {
  final String childId;
  final LearningChapter chapter;

  const LevelSelectionScreen({
    super.key,
    required this.childId,
    required this.chapter,
  });

  @override
  State<LevelSelectionScreen> createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen> {
  Map<String, LevelProgress> _progressMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final allProgress = await ProgressRepository.getAllProgress(widget.childId);
    final map = <String, LevelProgress>{};
    for (final p in allProgress) {
      if (p.chapterId == widget.chapter.id) {
        map[p.levelId] = p;
      }
    }
    if (mounted) {
      setState(() {
        _progressMap = map;
        _isLoading = false;
      });
    }
  }

  /// Returns the highest index of the level the child can access in this chapter.
  /// Level 0 is always accessible. Each subsequent level requires the
  /// previous one to be completed.
  int get _highestAccessibleLevelIndex {
    for (int i = 0; i < widget.chapter.levels.length; i++) {
      final level = widget.chapter.levels[i];
      final progress = _progressMap[level.id];
      if (progress == null || !progress.completed) {
        return i; // This is the current level to play.
      }
    }
    return widget.chapter.levels.length - 1; // All completed.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0C29),
      appBar: AppBar(
        title: Text(widget.chapter.name),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F0C29),
              Color(0xFF302B63),
              Color(0xFF24243E),
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
                )
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  itemCount: widget.chapter.levels.length,
                  itemBuilder: (context, index) {
                    final level = widget.chapter.levels[index];
                    final progress = _progressMap[level.id];
                    final isLocked = index > _highestAccessibleLevelIndex;

                    return LevelCard(
                      childId: widget.childId,
                      level: level,
                      progress: progress,
                      isLocked: isLocked,
                      onCompleted: _loadProgress,
                    );
                  },
                ),
        ),
      ),
    );
  }
}
