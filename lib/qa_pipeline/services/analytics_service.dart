
import '../database/question_attempt_repository.dart';
import '../models/section_statistics.dart';
import '../models/question_attempt.dart';

class AnalyticsService {
  /// Aggregates all progress and attempts to build SectionStatistics.
  static Future<List<SectionStatistics>> getOverallStatistics(String childId) async {
    final attempts = await QuestionAttemptRepository.getAllAttempts(childId);

    final Map<String, SectionStatistics> stats = {
      'mcq': SectionStatistics(
          title: 'Multiple Choice', sectionKey: 'mcq', sectionType: 'mcq'),
      'descriptive': SectionStatistics(
          title: 'Descriptive & Keyword',
          sectionKey: 'descriptive',
          sectionType: 'descriptive'),
      'speech': SectionStatistics(
          title: 'Speech Recognition',
          sectionKey: 'speech',
          sectionType: 'speech'),
      'sequence': SectionStatistics(
          title: 'Sequencing', sectionKey: 'sequence', sectionType: 'sequence'),
      'imageMatching': SectionStatistics(
          title: 'Image Matching', sectionKey: 'imageMatching', sectionType: 'imageMatching'),
      'drag': SectionStatistics(
          title: 'Drag & Drop', sectionKey: 'drag', sectionType: 'drag'),
    };

    for (final attempt in attempts) {
      if (stats.containsKey(attempt.questionType)) {
        stats[attempt.questionType]!.addAttempt(attempt.isCorrect, attempt.timeTakenSeconds);
      }
    }

    return stats.values.toList();
  }

  /// Helper to find a section by key, or return a default empty SectionStatistics.
  static SectionStatistics findSection(
      List<SectionStatistics> stats, String sectionKey) {
    return stats.firstWhere(
      (s) => s.sectionKey == sectionKey,
      orElse: () => SectionStatistics(
          title: sectionKey, sectionKey: sectionKey, sectionType: sectionKey),
    );
  }

  /// Calculates accuracy for a specific level.
  static Future<double> getLevelAccuracy(
    String childId,
    String chapterId,
    String levelId,
  ) async {
    final attempts =
        await QuestionAttemptRepository.getAttemptsForLevel(childId, chapterId, levelId);
    if (attempts.isEmpty) return 0.0;

    final correctCount = attempts.where((a) => a.isCorrect).length;
    return correctCount / attempts.length;
  }

  /// Gets the average time per question across the entire platform.
  static Future<double> getAverageTimePerQuestion(String childId) async {
    final attempts = await QuestionAttemptRepository.getAllAttempts(childId);
    if (attempts.isEmpty) return 0.0;

    final totalSeconds = attempts.fold(0, (sum, a) => sum + a.timeTakenSeconds);
    return totalSeconds / attempts.length;
  }

  /// Aggregates all progress and attempts to build SectionStatistics for a specific level.
  static Future<List<SectionStatistics>> getLevelStatistics(
      String childId, String chapterId, String levelId) async {
    final attempts =
        await QuestionAttemptRepository.getAttemptsForLevel(childId, chapterId, levelId);

    final Map<String, SectionStatistics> stats = {
      'mcq': SectionStatistics(
          title: 'Multiple Choice', sectionKey: 'mcq', sectionType: 'mcq'),
      'descriptive': SectionStatistics(
          title: 'Descriptive & Keyword',
          sectionKey: 'descriptive',
          sectionType: 'descriptive'),
      'sequence': SectionStatistics(
          title: 'Sequencing', sectionKey: 'sequence', sectionType: 'sequence'),
      'imageMatching': SectionStatistics(
          title: 'Image Matching', sectionKey: 'imageMatching', sectionType: 'imageMatching'),
      'drag': SectionStatistics(
          title: 'Drag & Drop', sectionKey: 'drag', sectionType: 'drag'),
    };

    for (final attempt in attempts) {
      if (stats.containsKey(attempt.questionType)) {
        stats[attempt.questionType]!
            .addAttempt(attempt.isCorrect, attempt.timeTakenSeconds);
      }
    }

    return stats.values.toList();
  }

  /// Gets all question attempts for a specific level.
  static Future<List<QuestionAttempt>> getLevelAttempts(
      String childId, String chapterId, String levelId) async {
    return await QuestionAttemptRepository.getAttemptsForLevel(
        childId, chapterId, levelId);
  }
}
