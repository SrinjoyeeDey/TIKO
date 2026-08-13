import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../database/child_repository.dart';
import '../database/progress_repository.dart';
import '../models/child_profile.dart';
import '../models/learning_content.dart';
import '../services/content_discovery_service.dart';
import '../models/level_progress.dart';
import '../models/section_statistics.dart';
import '../services/adaptive_learning_service.dart';
import '../services/analytics_service.dart';
import 'parent_level_report.dart';

/// Parent dashboard showing the child's overall learning analytics.
///
/// Displays profile info, progress, section accuracy, time analysis,
/// and adaptive learning insights.
class ParentDashboard extends StatefulWidget {
  final String childId;

  const ParentDashboard({super.key, required this.childId});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  ChildProfile? _profile;
  List<LevelProgress> _progressList = [];
  List<SectionStatistics> _sectionStats = [];
  List<AdaptiveInsight> _insights = [];
  List<LearningChapter> _chapters = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final profile = await ChildRepository.getChildById(widget.childId);
    final progress = await ProgressRepository.getAllProgress(widget.childId);
    final stats = await AnalyticsService.getOverallStatistics(widget.childId);
    final chapters = await ContentDiscoveryService.discoverContent();
    final insights = await AdaptiveLearningService.analyzeAll(widget.childId);

    if (mounted) {
      setState(() {
        _profile = profile;
        _progressList = progress;
        _sectionStats = stats;
        _insights = insights;
        _chapters = chapters;
        _isLoading = false;
      });
    }
  }

  int get _completedCount =>
      _progressList.where((p) => p.completed).length;

  int get _totalLevels => _chapters.fold(0, (sum, c) => sum + c.levels.length);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0C29),
      appBar: AppBar(
        title: Text(
          _profile?.name.isNotEmpty == true
              ? "${_profile!.name}'s Dashboard"
              : 'Parent Dashboard',
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
                  _buildProfileCard(),
                  const SizedBox(height: 16),
                  _buildProgressOverview(),
                  const SizedBox(height: 16),
                  _buildTimeAnalysis(),
                  const SizedBox(height: 16),
                  _buildLevelReports(),
                  const SizedBox(height: 16),
                  _buildAdaptiveInsights(),
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

  Widget _buildProfileCard() {
    return _buildCard(
      title: 'Child Profile',
      child: Row(
        children: [
          // Avatar
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF3F3D99)],
              ),
            ),
            child: Center(
              child: Text(
                _profile?.name.isNotEmpty == true
                    ? _profile!.name[0].toUpperCase()
                    : '?',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _profile?.name ?? 'Unknown',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                [
                  if (_profile?.age != null) '${_profile!.age} years',
                  if (_profile?.className != null) _profile!.className!,
                ].join(' • '),
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressOverview() {
    return _buildCard(
      title: 'Overall Performance',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$_completedCount',
                style: GoogleFonts.outfit(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF6C63FF),
                ),
              ),
              Text(
                ' / $_totalLevels',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Levels Completed',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _totalLevels > 0 ? _completedCount / _totalLevels : 0,
              minHeight: 8,
              backgroundColor: Colors.white12,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildTimeAnalysis() {
    final mcq = AnalyticsService.findSection(_sectionStats, 'mcq');
    final desc = AnalyticsService.findSection(_sectionStats, 'descriptive');
    final seq = AnalyticsService.findSection(_sectionStats, 'sequence');
    final imgMatch = AnalyticsService.findSection(_sectionStats, 'imageMatching');

    return _buildCard(
      title: 'Study Time',
      child: Column(
        children: [
          _buildTimeRow('MCQ', mcq),
          const SizedBox(height: 10),
          _buildTimeRow('Descriptive', desc),
          const SizedBox(height: 10),
          _buildTimeRow('Sequence', seq),
          const SizedBox(height: 10),
          _buildTimeRow('Image Matching', imgMatch),
        ],
      ),
    );
  }

  Widget _buildTimeRow(String label, SectionStatistics stats) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.outfit(fontSize: 15, color: Colors.white),
          ),
        ),
        Text(
          stats.totalAttempts > 0
              ? '${stats.averageTimeSeconds.toStringAsFixed(1)} sec'
              : '—',
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: stats.totalAttempts > 0
                ? Colors.white
                : Colors.white.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }

  Widget _buildLevelReports() {
    final levels = _chapters
        .expand((chapter) => chapter.levels)
        .toList(growable: false);

    return _buildCard(
      title: 'Level Reports',
      child: levels.isEmpty
          ? Text(
              'No levels are available yet.',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            )
          : Column(
              children: levels.map((level) {
                final progress = _progressList
                    .where((item) =>
                        item.chapterId == level.chapterId &&
                        item.levelId == level.id)
                    .firstOrNull;
                final isComplete = progress?.completed ?? false;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ParentLevelReport(
                              childId: widget.childId,
                              level: level,
                            ),
                          ),
                        );
                      },
                      child: Ink(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white.withValues(alpha: 0.04),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isComplete
                                  ? Icons.check_circle_rounded
                                  : Icons.description_outlined,
                              color: isComplete
                                  ? Colors.greenAccent
                                  : const Color(0xFF9D97FF),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                level.levelName,
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            if (isComplete)
                              Row(
                                children: List.generate(
                                  3,
                                  (index) => Icon(
                                    index < (progress?.stars ?? 0)
                                        ? Icons.star_rounded
                                        : Icons.star_border_rounded,
                                    color: const Color(0xFFFFD700),
                                    size: 17,
                                  ),
                                ),
                              )
                            else
                              Text(
                                'View',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.white.withValues(alpha: 0.45),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildAdaptiveInsights() {
    return _buildCard(
      title: 'Concentration Report',
      child: Column(
        children: _insights.map((insight) {
          IconData icon;
          Color statusColor;

          switch (insight.status) {
            case AdaptiveStatus.onTrack:
              icon = Icons.check_circle;
              statusColor = Colors.greenAccent;
              break;
            case AdaptiveStatus.needsSupport:
              icon = Icons.warning_rounded;
              statusColor = Colors.orangeAccent;
              break;
            case AdaptiveStatus.insufficientData:
              icon = Icons.info_outline;
              statusColor = Colors.white.withValues(alpha: 0.4);
              break;
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: statusColor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AdaptiveLearningService.sectionLabel(
                            insight.sectionType),
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        insight.reason,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.5),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

}
