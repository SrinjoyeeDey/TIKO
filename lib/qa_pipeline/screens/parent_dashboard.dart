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
import '../models/clinical_report_model.dart';
import '../services/clinical_report_service.dart';

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
  ClinicalReport? _clinicalReport;
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
    final clinical = await ClinicalReportService.generateReport(widget.childId);

    if (mounted) {
      setState(() {
        _profile = profile;
        _progressList = progress;
        _sectionStats = stats;
        _insights = insights;
        _chapters = chapters;
        _clinicalReport = clinical;
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
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: AppBar(
        title: Text(
          _profile?.name.isNotEmpty == true
              ? "${_profile!.name}'s Dashboard"
              : 'Parent Dashboard',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFF1B5E20),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF558B2F)),
            )
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFF1F8E9),
                    Color(0xFFDCEDC8),
                    Color(0xFFC5E1A5),
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
                  _buildAdaptiveInsights(),
                  const SizedBox(height: 16),
                  _buildClinicalReport(),
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
        color: Color(0xFF1B5E20).withValues(alpha: 0.06),
        border: Border.all(
          color: const Color(0xFF558B2F).withValues(alpha: 0.2),
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
              color: Color(0xFF33691E),
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
                colors: [Color(0xFF558B2F), Color(0xFF689F38)],
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
                  color: Color(0xFF1B5E20),
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
                  color: Color(0xFF1B5E20),
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
                  color: Color(0xFF558B2F),
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
                  color: const Color(0xFF558B2F),
                ),
              ),
              Text(
                ' / $_totalLevels',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF558B2F).withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Levels Completed',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: Color(0xFF558B2F),
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
                  const AlwaysStoppedAnimation<Color>(Color(0xFF558B2F)),
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
            style: GoogleFonts.outfit(fontSize: 15, color: Color(0xFF1B5E20)),
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
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        insight.reason,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: Color(0xFF558B2F),
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


  Widget _buildClinicalReport() {
    if (_clinicalReport == null) {
      return const SizedBox.shrink();
    }

    if (!_clinicalReport!.hasSufficientData) {
      return _buildCard(
        title: 'Post-Play Clinical & Parental Report',
        child: Text(
          'Not enough play data yet. Once your child starts playing stories and answering questions, we will generate detailed sensory, speech, cognitive, and behavioral insights here.',
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: const Color(0xFF558B2F),
            height: 1.4,
          ),
        ),
      );
    }

    final rpt = _clinicalReport!;
    final summary = rpt.sessionSummary;
    final sensory = rpt.sensoryAndAttention;
    final speech = rpt.speechAndCommunication;
    final cognitive = rpt.cognitiveAndMotorSkills;
    final behavior = rpt.behavioralObservations;
    final insights = rpt.actionableInsights;

    Color engagementColor = summary.overallEngagement == 'High'
        ? const Color(0xFF2E7D32)
        : (summary.overallEngagement == 'Moderate'
            ? const Color(0xFFEF6C00)
            : const Color(0xFFC62828));

    return _buildCard(
      title: 'Post-Play Clinical & Parental Report',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Session Summary Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF81C784).withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Session Overview',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1B5E20),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: engagementColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: engagementColor, width: 1),
                      ),
                      child: Text(
                        '${summary.overallEngagement} Engagement',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: engagementColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildSummaryMiniStat(Icons.timer_outlined, '${summary.durationMinutes} min', 'Play Duration'),
                    const SizedBox(width: 16),
                    _buildSummaryMiniStat(Icons.task_alt, '${summary.activitiesCompleted}', 'Completed Tasks'),
                    const SizedBox(width: 16),
                    _buildSummaryMiniStat(Icons.analytics_outlined, '${rpt.totalEventsAnalyzed}', 'Data Points'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Sensory & Attention (Vision & Concentration)
          _buildReportSectionHeader(
            title: 'Sensory & Concentration Focus (Vision)',
            icon: Icons.visibility,
            color: const Color(0xFF1976D2),
          ),
          const SizedBox(height: 8),
          _buildProgressBarRow(
            label: 'Visual Engagement Score',
            value: sensory.visualEngagementScore,
            color: const Color(0xFF1976D2),
          ),
          _buildProgressBarRow(
            label: 'Screen Gaze Alignment (Concentration)',
            value: sensory.screenGazeAlignment,
            color: const Color(0xFF0288D1),
          ),
          _buildProgressBarRow(
            label: 'Focus Stability Index',
            value: sensory.focusStability,
            color: const Color(0xFF00796B),
          ),
          _buildBulletItem('Distraction Events (Looked away > 5s): ${sensory.distractionEvents} time(s)'),
          if (sensory.sensoryPreferences.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: sensory.sensoryPreferences.map((pref) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF90CAF9)),
                    ),
                    child: Text(
                      pref,
                      style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF0D47A1), fontWeight: FontWeight.w500),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: 16),

          // 3. Speech & Communication (Acoustic & Lip Articulation)
          _buildReportSectionHeader(
            title: 'Speech & Communication (Lip Articulation)',
            icon: Icons.record_voice_over,
            color: const Color(0xFF7B1FA2),
          ),
          const SizedBox(height: 8),
          _buildProgressBarRow(
            label: 'Pronunciation Accuracy',
            value: speech.pronunciationAccuracy,
            color: const Color(0xFF7B1FA2),
          ),
          _buildProgressBarRow(
            label: 'Physical Lip & Mouth Articulation',
            value: speech.lipMovementActivePercent,
            color: const Color(0xFF8E24AA),
          ),
          _buildBulletItem('Total Vocalizations / Speech Attempts: ${speech.totalVocalizations}'),
          _buildBulletItem('Lip Movement Checkpoints Detected: ${speech.mouthMovementDetectedCount}'),
          _buildBulletItem('Average Processing Response Delay: ${speech.averageResponseDelaySeconds < 0 ? "N/A" : "${speech.averageResponseDelaySeconds}s"}'),
          if (speech.successfulWords.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Recognized Words: ',
                    style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF4A148C)),
                  ),
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      children: speech.successfulWords.map((word) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E5F5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFCE93D8)),
                          ),
                          child: Text(
                            word,
                            style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF4A148C), fontWeight: FontWeight.bold),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),

          // 4. Cognitive & Motor Skills
          _buildReportSectionHeader(
            title: 'Cognitive & Motor Developmental Milestones',
            icon: Icons.psychology,
            color: const Color(0xFFE65100),
          ),
          const SizedBox(height: 8),
          _buildProgressBarRow(label: 'Detail Recall & Memory', value: cognitive.memory, color: const Color(0xFFFB8C00)),
          _buildProgressBarRow(label: 'Story Sequencing & Logic', value: cognitive.sequencing, color: const Color(0xFF00ACC1)),
          _buildProgressBarRow(label: 'Fine Motor Control (Touch Accuracy)', value: cognitive.fineMotorControl, color: const Color(0xFF43A047)),
          if (cognitive.areasOfStruggle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Areas of Struggle: ',
                    style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFB71C1C)),
                  ),
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      children: cognitive.areasOfStruggle.map((area) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFEF9A9A)),
                          ),
                          child: Text(
                            area,
                            style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFFB71C1C), fontWeight: FontWeight.w600),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),

          // 5. Behavioral Observations
          _buildReportSectionHeader(
            title: 'Behavioral & Emotional Regulation',
            icon: Icons.mood,
            color: const Color(0xFF00897B),
          ),
          const SizedBox(height: 8),
          _buildBulletItem('Hints / Scaffolding Requested: ${behavior.hintsRequested} time(s)'),
          _buildBulletItem('Abandoned / Skipped Activities: ${behavior.abandonedActivities}'),
          _buildBulletItem('Frustration Indicators (Rapid taps/High pressure): ${behavior.frustrationIndicators}'),
          const SizedBox(height: 16),

          // 6. Actionable Insights
          _buildReportSectionHeader(
            title: 'Actionable Insights & Recommendations',
            icon: Icons.lightbulb_outline,
            color: const Color(0xFFF57F17),
          ),
          const SizedBox(height: 8),
          if (insights.forParents.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Text(
                '👨‍👩‍👧 For Parents (Home Support):',
                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF2E7D32)),
              ),
            ),
            ...insights.forParents.map((tip) => _buildBulletItem(tip, color: const Color(0xFF1B5E20))),
            const SizedBox(height: 8),
          ],
          if (insights.forDoctors.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Text(
                '🩺 For Clinicians & Therapists:',
                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0D47A1)),
              ),
            ),
            ...insights.forDoctors.map((tip) => _buildBulletItem(tip, color: const Color(0xFF0D47A1))),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryMiniStat(IconData icon, String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: const Color(0xFF2E7D32)),
            const SizedBox(width: 4),
            Text(
              value,
              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1B5E20)),
            ),
          ],
        ),
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF689F38)),
        ),
      ],
    );
  }

  Widget _buildReportSectionHeader({
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1B5E20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBarRow({
    required String label,
    required double value,
    required Color color,
  }) {
    final isPending = value < 0;
    final clamped = isPending ? 0.0 : (value / 100.0).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 6, right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF33691E), fontWeight: FontWeight.w500),
              ),
              Text(
                isPending ? 'Not attempted yet' : '${value.toStringAsFixed(1)}%',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: isPending ? FontWeight.normal : FontWeight.bold,
                  fontStyle: isPending ? FontStyle.italic : FontStyle.normal,
                  color: isPending ? Colors.grey : color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: clamped,
              backgroundColor: isPending ? Colors.grey.withValues(alpha: 0.15) : color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(isPending ? Colors.grey : color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletItem(String text, {Color color = const Color(0xFF33691E)}) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(fontSize: 12.5, color: color, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
