
import '../services/analytics_service.dart';
import '../models/section_statistics.dart';

/// Configuration for adaptive learning thresholds.
///
/// These values can be tuned without changing the detection logic.
class AdaptiveLearningConfig {
  /// Minimum number of total attempts before any adaptation decision.
  static const int minimumAttempts = 5;

  /// If average time exceeds this, the section may be flagged.
  static const int maxAverageTimeSeconds = 30;

  /// If accuracy is below this, the section may be flagged.
  static const double minimumAccuracy = 0.60;

  /// Number of sessions before a skipped section is re-evaluated.
  static const int reEvaluateAfterSessions = 3;
}

/// Represents the adaptive learning status for a single section.
class AdaptiveInsight {
  final String sectionType;
  final AdaptiveStatus status;
  final String reason;
  final double accuracy;
  final double averageTime;
  final int totalAttempts;

  const AdaptiveInsight({
    required this.sectionType,
    required this.status,
    required this.reason,
    required this.accuracy,
    required this.averageTime,
    required this.totalAttempts,
  });
}

/// The adaptive status for a section.
enum AdaptiveStatus {
  /// Performing well — no changes needed.
  onTrack,

  /// Needs support — may be temporarily reduced.
  needsSupport,

  /// Insufficient data to make a determination.
  insufficientData,
}

/// Service that analyzes historical performance data and provides
/// adaptive learning recommendations.
///
/// Rules:
/// - Never adapts from a single question.
/// - Requires [AdaptiveLearningConfig.minimumAttempts] historical attempts.
/// - Considers both time and accuracy.
/// - Never permanently removes a learning area.
class AdaptiveLearningService {
  /// The question section types to analyze.
  static const List<String> _sectionTypes = ['mcq', 'descriptive', 'sequence', 'imageMatching'];

  /// Analyzes all sections and returns insights for each.
  static Future<List<AdaptiveInsight>> analyzeAll(String childId) async {
    final stats =
        await AnalyticsService.getOverallStatistics(childId);

    return _sectionTypes.map((type) {
      final section = stats.firstWhere(
        (s) => s.sectionType == type,
        orElse: () => SectionStatistics(
          sectionType: type,
          totalAttempts: 0,
          correctAttempts: 0,
          totalTimeSeconds: 0,
        ),
      );

      return _analyzeSection(section);
    }).toList();
  }

  /// Returns a list of section types that should be included in the
  /// next question session (i.e., sections NOT flagged as needsSupport).
  ///
  /// If a section needs support, it may be temporarily skipped.
  /// However, sections are never permanently removed.
  static Future<List<String>> getActiveSections(String childId) async {
    final insights = await analyzeAll(childId);

    final active = <String>[];
    for (final insight in insights) {
      if (insight.status != AdaptiveStatus.needsSupport) {
        active.add(insight.sectionType);
      }
    }

    // Safety: never remove ALL sections. If everything needs support,
    // include everything.
    if (active.isEmpty) {
      return List.from(_sectionTypes);
    }

    return active;
  }

  /// Analyzes a single section's statistics.
  static AdaptiveInsight _analyzeSection(SectionStatistics section) {
    // Not enough data.
    if (section.totalAttempts < AdaptiveLearningConfig.minimumAttempts) {
      return AdaptiveInsight(
        sectionType: section.sectionType,
        status: AdaptiveStatus.insufficientData,
        reason: 'Not enough attempts yet '
            '(${section.totalAttempts}/${AdaptiveLearningConfig.minimumAttempts}).',
        accuracy: section.accuracy,
        averageTime: section.averageTimeSeconds,
        totalAttempts: section.totalAttempts,
      );
    }

    // Check both conditions: low accuracy AND high time.
    final bool lowAccuracy =
        section.accuracy < AdaptiveLearningConfig.minimumAccuracy;
    final bool highTime = section.averageTimeSeconds >
        AdaptiveLearningConfig.maxAverageTimeSeconds;

    if (lowAccuracy && highTime) {
      return AdaptiveInsight(
        sectionType: section.sectionType,
        status: AdaptiveStatus.needsSupport,
        reason:
            'High average solving time (${section.averageTimeSeconds.toStringAsFixed(1)}s) '
            'combined with low accuracy (${section.accuracyPercent}%). '
            'This section has been temporarily reduced.',
        accuracy: section.accuracy,
        averageTime: section.averageTimeSeconds,
        totalAttempts: section.totalAttempts,
      );
    }

    return AdaptiveInsight(
      sectionType: section.sectionType,
      status: AdaptiveStatus.onTrack,
      reason: 'Performing well — '
          'accuracy ${section.accuracyPercent}%, '
          'avg time ${section.averageTimeSeconds.toStringAsFixed(1)}s.',
      accuracy: section.accuracy,
      averageTime: section.averageTimeSeconds,
      totalAttempts: section.totalAttempts,
    );
  }

  /// Returns a human-readable label for a section type.
  static String sectionLabel(String type) {
    switch (type) {
      case 'mcq':
        return 'Multiple Choice';
      case 'descriptive':
        return 'Descriptive';
      case 'sequence':
        return 'Sequence';
      case 'imageMatching':
        return 'Image Matching';
      default:
        return type;
    }
  }
}
