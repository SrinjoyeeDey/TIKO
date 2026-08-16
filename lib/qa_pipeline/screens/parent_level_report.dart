import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../database/progress_repository.dart';
import '../models/learning_content.dart';
import '../models/level_progress.dart';
import '../models/question_attempt.dart';
import '../models/section_statistics.dart';
import '../services/analytics_service.dart';

/// Detailed per-level report for the parent section.
///
/// Shows per-section accuracy, timing, and per-question breakdown.
class ParentLevelReport extends StatefulWidget {
  final String childId;
  final LearningLevel level;

  const ParentLevelReport({
    super.key,
    required this.childId,
    required this.level,
  });

  @override
  State<ParentLevelReport> createState() => _ParentLevelReportState();
}

class _ParentLevelReportState extends State<ParentLevelReport> {
  LevelProgress? _progress;
  List<SectionStatistics> _sectionStats = [];
  List<QuestionAttempt> _attempts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final progress = await ProgressRepository.getLevelProgress(
      widget.childId,
      widget.level.chapterId,
      widget.level.id,
    );
    final stats = await AnalyticsService.getLevelStatistics(
      widget.childId,
      widget.level.chapterId,
      widget.level.id,
    );
    final attempts = await AnalyticsService.getLevelAttempts(
      widget.childId,
      widget.level.chapterId,
      widget.level.id,
    );

    if (mounted) {
      setState(() {
        _progress = progress;
        _sectionStats = stats;
        _attempts = attempts;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0C29),
      appBar: AppBar(
        title: Text(
          '${widget.level.levelName} Report',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
            )
          : Container(
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
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildStarRating(),
                  const SizedBox(height: 16),
                  _buildSectionSummary(),
                  const SizedBox(height: 16),
                  _buildQuestionBreakdown(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(
          color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildStarRating() {
    final stars = _progress?.stars ?? 0;

    return _buildCard(
      title: 'Level Rating',
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                i < stars ? Icons.star_rounded : Icons.star_border_rounded,
                color: i < stars
                    ? const Color(0xFFFFD700)
                    : Colors.white.withValues(alpha: 0.2),
                size: 40,
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSectionSummary() {
    final mcq = AnalyticsService.findSection(_sectionStats, 'mcq');
    final desc = AnalyticsService.findSection(_sectionStats, 'descriptive');
    final speech = AnalyticsService.findSection(_sectionStats, 'speech');
    final seq = AnalyticsService.findSection(_sectionStats, 'sequence');
    final imgMatch = AnalyticsService.findSection(_sectionStats, 'imageMatching');

    return _buildCard(
      title: 'Section Summary',
      child: Column(
        children: [
          _buildSectionRow('MCQ', mcq, Icons.quiz),
          const Divider(color: Colors.white12, height: 24),
          _buildSectionRow('Descriptive', desc, Icons.edit_note),
          const Divider(color: Colors.white12, height: 24),
          _buildSectionRow('Speech Pronunciation', speech, Icons.record_voice_over),
          const Divider(color: Colors.white12, height: 24),
          _buildSectionRow('Sequence', seq, Icons.format_list_numbered),
          const Divider(color: Colors.white12, height: 24),
          _buildSectionRow('Image Matching', imgMatch, Icons.image_search),
        ],
      ),
    );
  }

  Widget _buildSectionRow(
    String label,
    SectionStatistics stats,
    IconData icon,
  ) {
    if (stats.totalAttempts == 0) {
      return Row(
        children: [
          Icon(icon, color: const Color(0xFF6C63FF), size: 22),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.outfit(fontSize: 15, color: Colors.white),
          ),
          const Spacer(),
          Text(
            'No data',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF6C63FF), size: 22),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildStatChip(
              '${stats.correctAttempts}/${stats.totalAttempts}',
              'Correct',
              Colors.greenAccent,
            ),
            const SizedBox(width: 12),
            _buildStatChip(
              '${stats.accuracyPercent}%',
              'Accuracy',
              stats.accuracy >= 0.6 ? Colors.greenAccent : Colors.orangeAccent,
            ),
            const SizedBox(width: 12),
            _buildStatChip(
              '${stats.averageTimeSeconds.toStringAsFixed(1)}s',
              'Avg Time',
              Colors.cyanAccent,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatChip(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: color.withValues(alpha: 0.08),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionBreakdown() {
    if (_attempts.isEmpty) {
      return _buildCard(
        title: 'Question Breakdown',
        child: Text(
          'No question data available.',
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
      );
    }

    return _buildCard(
      title: 'Question Breakdown',
      child: Column(
        children: _attempts.map((attempt) {
          final typeLabel = _typeLabel(attempt.questionType);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white.withValues(alpha: 0.04),
              ),
              child: Row(
                children: [
                  // Correct/incorrect indicator
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: attempt.isCorrect
                          ? Colors.greenAccent.withValues(alpha: 0.15)
                          : Colors.redAccent.withValues(alpha: 0.15),
                    ),
                    child: Icon(
                      attempt.isCorrect ? Icons.check : Icons.close,
                      color: attempt.isCorrect
                          ? Colors.greenAccent
                          : Colors.redAccent,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Question info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Q${attempt.questionId} — $typeLabel',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        if (attempt.similarityScore != null)
                          Text(
                            'Similarity: ${(attempt.similarityScore! * 100).round()}%',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Time taken
                  Text(
                    '${attempt.timeTakenSeconds}s',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'mcq':
        return 'MCQ';
      case 'descriptive':
        return 'Descriptive';
      case 'sequence':
        return 'Sequence';
      default:
        return type;
    }
  }
}
