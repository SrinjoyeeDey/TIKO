import 'package:flutter/material.dart';

enum ChapterStatus {
  locked,
  available,
  inProgress,
  completed,
}

class StoryChapter {
  final int id;
  final String title;
  final String subtitle;
  final String summary;
  final IconData icon;
  final String fullStoryText;
  final String historicalContext;
  final String keyTakeaway;
  ChapterStatus status;

  StoryChapter({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.summary,
    required this.icon,
    required this.fullStoryText,
    required this.historicalContext,
    required this.keyTakeaway,
    this.status = ChapterStatus.locked,
  });

  bool get isLocked => status == ChapterStatus.locked;
  bool get isAvailable => status == ChapterStatus.available;
  bool get isInProgress => status == ChapterStatus.inProgress;
  bool get isCompleted => status == ChapterStatus.completed;
}
