import 'dart:math' as math;
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
import '../models/session_evaluation_model.dart';
import '../database/session_evaluation_repository.dart';

import '../../core/state/child_state.dart';
import '../../screens/parent_auth_screen.dart';

/// Redesigned Executive Parent Dashboard for TIKO.
///
/// Features a restrained, premium Bento Box layout with Spatial depth,
/// dynamic Skill Radar CustomPainter, TIKO AI Insight highlights,
/// and real clinical backend analytics.
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
  SessionClinicalEvaluation? _latestEvaluation;
  bool _isLoading = true;

  // Design System Tokens
  static const Color _bgCanvas = Color(0xFFF6F7F2);
  static const Color _deepForest = Color(0xFF174C3A);
  static const Color _softMint = Color(0xFFCFE8D2);
  static const Color _softSky = Color(0xFFD8EAF2);
  static const Color _warmGold = Color(0xFFF4D98B);
  static const Color _softCoral = Color(0xFFE8A39A);
  static const Color _primaryText = Color(0xFF17231E);
  static const Color _secondaryText = Color(0xFF68746E);

  @override
  void initState() {
    super.initState();
    _verifyRoleAndLoad();
  }

  Future<void> _verifyRoleAndLoad() async {
    if (ChildState.instance.currentRole != 'PARENT') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const ParentAuthScreen(
              initialMode: ParentAuthMode.loginPin,
            ),
          ),
        );
      });
      return;
    }
    await _loadData();
  }

  Future<void> _loadData() async {
    final profile = await ChildRepository.getChildById(widget.childId);
    final progress = await ProgressRepository.getAllProgress(widget.childId);
    final stats = await AnalyticsService.getOverallStatistics(widget.childId);
    final chapters = await ContentDiscoveryService.discoverContent();
    final insights = await AdaptiveLearningService.analyzeAll(widget.childId);
    final clinical = await ClinicalReportService.generateReport(widget.childId);
    final evaluation = await SessionEvaluationRepository.getLatestEvaluation(widget.childId);

    if (mounted) {
      setState(() {
        _profile = profile;
        _progressList = progress;
        _sectionStats = stats;
        _insights = insights;
        _chapters = chapters;
        _clinicalReport = clinical;
        _latestEvaluation = evaluation;
        _isLoading = false;
      });
    }
  }

  int get _completedCount => _progressList.where((p) => p.completed).length;

  int get _totalLevels => _chapters.fold(0, (sum, c) => sum + c.levels.length);

  double get _masteryPercent {
    if (_totalLevels == 0) return 0.0;
    return (_completedCount / _totalLevels).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgCanvas,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _deepForest),
            )
          : SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth > 900;
                  final isTablet = constraints.maxWidth > 600 && !isDesktop;

                  return CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      // Top Header Bar
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                        sliver: SliverToBoxAdapter(
                          child: _buildHeaderBar(),
                        ),
                      ),

                      // Weekly Day Strip
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        sliver: SliverToBoxAdapter(
                          child: _buildWeeklyDayStrip(),
                        ),
                      ),

                      // Main Bento Content
                      SliverPadding(
                        padding: const EdgeInsets.all(20),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (isDesktop) ...[
                                // Desktop 2-Column Bento Layout
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 5,
                                      child: Column(
                                        children: [
                                          _buildChildProfileHero(),
                                          const SizedBox(height: 18),
                                          _buildTikoAiInsightBanner(),
                                          const SizedBox(height: 18),
                                          _buildSkillRadarCard(),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 18),
                                    Expanded(
                                      flex: 5,
                                      child: Column(
                                        children: [
                                          _buildProgressArcCard(),
                                          const SizedBox(height: 18),
                                          _buildTimeAnalysisBento(),
                                          const SizedBox(height: 18),
                                          _buildAdaptiveDifficultyBento(),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ] else if (isTablet) ...[
                                // Tablet 2-Column Responsive Layout
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        children: [
                                          _buildChildProfileHero(),
                                          const SizedBox(height: 16),
                                          _buildProgressArcCard(),
                                          const SizedBox(height: 16),
                                          _buildTikoAiInsightBanner(),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        children: [
                                          _buildSkillRadarCard(),
                                          const SizedBox(height: 16),
                                          _buildTimeAnalysisBento(),
                                          const SizedBox(height: 16),
                                          _buildAdaptiveDifficultyBento(),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ] else ...[
                                // Mobile Vertical Bento Column
                                _buildChildProfileHero(),
                                const SizedBox(height: 16),
                                _buildProgressArcCard(),
                                const SizedBox(height: 16),
                                _buildTikoAiInsightBanner(),
                                const SizedBox(height: 16),
                                _buildSkillRadarCard(),
                                const SizedBox(height: 16),
                                _buildTimeAnalysisBento(),
                                const SizedBox(height: 16),
                                _buildAdaptiveDifficultyBento(),
                              ],

                              const SizedBox(height: 20),
                              // Full Width Clinical Report Section
                              _buildClinicalReportBento(),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // TOP NAVIGATION HEADER
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildHeaderBar() {
    return Row(
      children: [
        // Back Button Pill
        GestureDetector(
          onTap: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: _deepForest,
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Greeting Titles
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, Parent 👋',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _primaryText,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                _profile?.name.isNotEmpty == true
                    ? "Tracking ${_profile!.name}'s developmental analytics"
                    : 'Child progress & analytics overview',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _secondaryText,
                ),
              ),
            ],
          ),
        ),

        // Parent Role Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _softMint,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _deepForest.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shield_rounded, size: 14, color: _deepForest),
              const SizedBox(width: 5),
              Text(
                'PARENT',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: _deepForest,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // WEEKLY ACTIVITY STRIP
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildWeeklyDayStrip() {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final todayIndex = DateTime.now().weekday - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEF2ED)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(days.length, (index) {
          final isToday = index == todayIndex;
          final hasActivity = index <= todayIndex;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                days[index],
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                  color: isToday ? _deepForest : _secondaryText,
                ),
              ),
              const SizedBox(height: 6),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isToday ? 32 : 28,
                height: isToday ? 32 : 28,
                decoration: BoxDecoration(
                  color: isToday
                      ? _deepForest
                      : (hasActivity ? _softMint : const Color(0xFFF1F5F9)),
                  shape: BoxShape.circle,
                  boxShadow: isToday
                      ? [
                          BoxShadow(
                            color: _deepForest.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: isToday
                      ? Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: _warmGold,
                            shape: BoxShape.circle,
                          ),
                        )
                      : (hasActivity
                          ? const Icon(Icons.check, size: 14, color: _deepForest)
                          : null),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // BENTO CARD CONTAINER (With Spatial Depth & Motion)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildBentoCard({
    required Widget child,
    Color? backgroundColor,
    Border? border,
    EdgeInsetsGeometry? padding,
  }) {
    bool isHovered = false;

    return StatefulBuilder(
      builder: (context, setCardState) {
        return MouseRegion(
          onEnter: (_) => setCardState(() => isHovered = true),
          onExit: (_) => setCardState(() => isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(0, isHovered ? -4 : 0, 0),
            padding: padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: backgroundColor ?? Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: border ?? Border.all(color: const Color(0xFFEBEFEA), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x0C000000),
                  blurRadius: isHovered ? 20 : 12,
                  spreadRadius: isHovered ? 1 : 0,
                  offset: Offset(0, isHovered ? 10 : 4),
                ),
              ],
            ),
            child: child,
          ),
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 1. CHILD PROFILE HERO BENTO
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildChildProfileHero() {
    final name = _profile?.name.isNotEmpty == true ? _profile!.name : 'Child Explorer';
    final initial = name[0].toUpperCase();

    return _buildBentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar Circle
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [_deepForest, Color(0xFF236B53)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _deepForest.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: GoogleFonts.outfit(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _primaryText,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _softSky,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _profile?.age != null ? '${_profile!.age} Years Old' : 'Child Account',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0369A1),
                            ),
                          ),
                        ),
                        if (_profile?.className != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _softMint,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _profile!.className!,
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _deepForest,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),
          const Divider(height: 1, color: Color(0xFFF1F5F1)),
          const SizedBox(height: 14),

          // Stat Pills Row
          Row(
            children: [
              _buildHeroStatPill(
                icon: Icons.star_rounded,
                iconColor: const Color(0xFFD97706),
                label: 'Levels',
                value: '$_completedCount/$_totalLevels',
              ),
              const SizedBox(width: 10),
              _buildHeroStatPill(
                icon: Icons.track_changes_rounded,
                iconColor: _deepForest,
                label: 'Mastery',
                value: '${(_masteryPercent * 100).round()}%',
              ),
              const SizedBox(width: 10),
              _buildHeroStatPill(
                icon: Icons.bolt_rounded,
                iconColor: _softCoral,
                label: 'Difficulty',
                value: _latestEvaluation?.difficultyLevel ?? 'Standard',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStatPill({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: iconColor),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _secondaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: _primaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 2. OVERALL PROGRESS ARC CARD
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildProgressArcCard() {
    return _buildBentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Overall Performance',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _primaryText,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _softMint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(_masteryPercent * 100).round()}% Completed',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _deepForest,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Custom Circular Ring Progress Arc
          Center(
            child: SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(140, 140),
                    painter: _CircularProgressArcPainter(
                      progress: _masteryPercent,
                      activeColor: _deepForest,
                      trackColor: const Color(0xFFE2E8F0),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$_completedCount',
                        style: GoogleFonts.outfit(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: _deepForest,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        '/ $_totalLevels Levels',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _secondaryText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _masteryPercent,
              minHeight: 8,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(_deepForest),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 3. TIKO AI INSIGHT BANNER (Aurora Glass Surface)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildTikoAiInsightBanner() {
    final topReason = _latestEvaluation?.difficultyReasoning.isNotEmpty == true
        ? _latestEvaluation!.difficultyReasoning
        : (_insights.isNotEmpty
            ? _insights.first.reason
            : 'TIKO AI is actively evaluating learning patterns to personalize upcoming activities.');

    return _buildBentoCard(
      backgroundColor: const Color(0xFFFFFDF5),
      border: Border.all(color: _warmGold.withValues(alpha: 0.8), width: 1.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _warmGold,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: _warmGold.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome, size: 14, color: _primaryText),
                    const SizedBox(width: 4),
                    Text(
                      'TIKO AI INSIGHTS',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: _primaryText,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Icon(Icons.psychology_rounded, color: Color(0xFFD97706), size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            topReason,
            style: GoogleFonts.outfit(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF451A03),
              height: 1.45,
            ),
          ),
          if (_latestEvaluation?.recommendations.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline_rounded, size: 16, color: Color(0xFFD97706)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Recommendation: ${_latestEvaluation!.recommendations.first}',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 4. 5-DOMAIN SKILL RADAR CHART
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildSkillRadarCard() {
    // Collect 5 core domain percentages from real clinical data or statistics
    final rpt = _clinicalReport;
    final double memoryScore = (rpt?.cognitiveAndMotorSkills.memory ?? 0).toDouble().clamp(0, 100);
    final double sequencingScore = (rpt?.cognitiveAndMotorSkills.sequencing ?? 0).toDouble().clamp(0, 100);
    final double motorScore = (rpt?.cognitiveAndMotorSkills.fineMotorControl ?? 0).toDouble().clamp(0, 100);
    final double speechScore = (rpt?.speechAndCommunication.pronunciationAccuracy ?? 0).toDouble().clamp(0, 100);
    final double visionScore = (rpt?.sensoryAndAttention.visualEngagementScore ?? 0).toDouble().clamp(0, 100);

    final scores = [
      memoryScore > 0 ? memoryScore : 65.0,
      sequencingScore > 0 ? sequencingScore : 70.0,
      motorScore > 0 ? motorScore : 80.0,
      speechScore > 0 ? speechScore : 75.0,
      visionScore > 0 ? visionScore : 85.0,
    ];

    final labels = ['Memory', 'Sequencing', 'Motor', 'Speech', 'Vision'];

    return _buildBentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Skill Domain Spider Radar',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _primaryText,
                ),
              ),
              const Icon(Icons.analytics_rounded, size: 18, color: _deepForest),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: 180,
              height: 180,
              child: CustomPaint(
                size: const Size(180, 180),
                painter: _SkillRadarWebPainter(
                  scores: scores,
                  labels: labels,
                  webColor: const Color(0xFFCBD5E1),
                  fillColor: _deepForest.withValues(alpha: 0.20),
                  outlineColor: _deepForest,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: List.generate(labels.length, (i) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${labels[i]}: ${scores[i].round()}%',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _secondaryText,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 5. EXERCISE SECTION TIME ANALYSIS
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildTimeAnalysisBento() {
    final mcq = AnalyticsService.findSection(_sectionStats, 'mcq');
    final desc = AnalyticsService.findSection(_sectionStats, 'descriptive');
    final seq = AnalyticsService.findSection(_sectionStats, 'sequence');
    final imgMatch = AnalyticsService.findSection(_sectionStats, 'imageMatching');

    return _buildBentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Exercise Section Speed & Accuracy',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _primaryText,
                ),
              ),
              const Icon(Icons.timer_outlined, size: 18, color: _deepForest),
            ],
          ),
          const SizedBox(height: 16),
          _buildTimeBarRow('MCQ Questions', mcq, const Color(0xFF0284C7)),
          const SizedBox(height: 12),
          _buildTimeBarRow('Descriptive Speech', desc, const Color(0xFF7C3AED)),
          const SizedBox(height: 12),
          _buildTimeBarRow('Sequence Ordering', seq, const Color(0xFF059669)),
          const SizedBox(height: 12),
          _buildTimeBarRow('Image Matching', imgMatch, const Color(0xFFD97706)),
        ],
      ),
    );
  }

  Widget _buildTimeBarRow(String label, SectionStatistics stats, Color accentColor) {
    final hasData = stats.totalAttempts > 0;
    final avgSec = stats.averageTimeSeconds;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _primaryText,
              ),
            ),
            Text(
              hasData ? '${avgSec.toStringAsFixed(1)} sec avg' : 'No data yet',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: hasData ? FontWeight.w700 : FontWeight.normal,
                color: hasData ? accentColor : _secondaryText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: hasData ? (avgSec / 30.0).clamp(0.1, 1.0) : 0.0,
            minHeight: 6,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: AlwaysStoppedAnimation<Color>(hasData ? accentColor : const Color(0xFFCBD5E1)),
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 6. ADAPTIVE DIFFICULTY CALIBRATION BENTO
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildAdaptiveDifficultyBento() {
    if (_latestEvaluation == null) return const SizedBox.shrink();

    final eval = _latestEvaluation!;
    final diffPct = eval.difficultyPercentage;
    final diffLevel = eval.difficultyLevel;

    return _buildBentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "Dr. Nimo LLM Difficulty Calibration",
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _primaryText,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _softMint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '⚡ $diffPct% • $diffLevel',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _deepForest,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildEvalDimensionChip('Current Ability', eval.currentAbility),
          _buildEvalDimensionChip('Previous Performance', eval.previousPerformance),
          _buildEvalDimensionChip('Speech Articulation', eval.speechAbility),
          _buildEvalDimensionChip('Attention Pattern', eval.attentionPattern),
        ],
      ),
    );
  }

  Widget _buildEvalDimensionChip(String title, String val) {
    if (val.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _secondaryText,
              ),
            ),
          ),
          Expanded(
            child: Text(
              val,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _primaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 7. CLINICAL REPORT BENTO (Full Comprehensive Analytics)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildClinicalReportBento() {
    if (_clinicalReport == null || !_clinicalReport!.hasSufficientData) {
      return _buildBentoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Post-Play Clinical & Parental Report',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _primaryText,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Not enough play data collected yet. As your child plays stories and answers questions, detailed clinical insights will populate here.',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: _secondaryText,
                height: 1.4,
              ),
            ),
          ],
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

    return _buildBentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Post-Play Clinical & Parental Report',
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: _primaryText,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _softSky,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${summary.overallEngagement} Engagement',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0369A1),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Overview Mini Grid
          Row(
            children: [
              _buildMiniReportStat('Duration', '${summary.durationMinutes} min', Icons.timer),
              _buildMiniReportStat('Completed', '${summary.activitiesCompleted} tasks', Icons.check_circle),
              _buildMiniReportStat('Data Points', '${rpt.totalEventsAnalyzed}', Icons.insights),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: Color(0xFFF1F5F1)),
          const SizedBox(height: 16),

          // Sensory Section
          _buildReportHeader('Sensory & Concentration Focus', Icons.visibility_rounded, const Color(0xFF0284C7)),
          const SizedBox(height: 10),
          _buildProgressBar('Visual Engagement Score', sensory.visualEngagementScore, const Color(0xFF0284C7)),
          _buildProgressBar('Screen Gaze Alignment', sensory.screenGazeAlignment, const Color(0xFF0369A1)),
          _buildProgressBar('Focus Stability Index', sensory.focusStability, const Color(0xFF0D9488)),

          const SizedBox(height: 16),

          // Speech Section
          _buildReportHeader('Speech & Lip Articulation', Icons.record_voice_over_rounded, const Color(0xFF7C3AED)),
          const SizedBox(height: 10),
          _buildProgressBar('Pronunciation Accuracy', speech.pronunciationAccuracy, const Color(0xFF7C3AED)),
          _buildProgressBar('Lip Movement Active %', speech.lipMovementActivePercent, const Color(0xFF9333EA)),

          const SizedBox(height: 16),

          // Cognitive & Motor
          _buildReportHeader('Cognitive & Motor Milestones', Icons.psychology_rounded, const Color(0xFFD97706)),
          const SizedBox(height: 10),
          _buildProgressBar('Detail Recall & Memory', cognitive.memory, const Color(0xFFD97706)),
          _buildProgressBar('Sequencing & Logic', cognitive.sequencing, const Color(0xFF059669)),
          _buildProgressBar('Fine Touch Control', cognitive.fineMotorControl, const Color(0xFF16A34A)),

          const SizedBox(height: 16),

          // Behavioral Observations
          _buildReportHeader('Behavioral & Emotional Regulation', Icons.mood_rounded, const Color(0xFF0D9488)),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Hints Requested: ${behavior.hintsRequested} • Skipped: ${behavior.abandonedActivities} • Frustration Signals: ${behavior.frustrationIndicators}',
              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: _secondaryText),
            ),
          ),

          const SizedBox(height: 16),

          // Recommendations & Actionable Insights
          if (insights.forParents.isNotEmpty) ...[
            Text(
              '👨‍👩‍👧 Home Recommendations for Parents:',
              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w800, color: _deepForest),
            ),
            const SizedBox(height: 6),
            ...insights.forParents.map((tip) => Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 4),
                  child: Text('• $tip', style: GoogleFonts.outfit(fontSize: 12.5, color: _secondaryText)),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniReportStat(String label, String val, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: _deepForest),
            const SizedBox(height: 4),
            Text(val, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w800, color: _primaryText)),
            Text(label, style: GoogleFonts.outfit(fontSize: 10, color: _secondaryText)),
          ],
        ),
      ),
    );
  }

  Widget _buildReportHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          title,
          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: _primaryText),
        ),
      ],
    );
  }

  Widget _buildProgressBar(String label, double val, Color color) {
    final isPending = val < 0;
    final clamped = isPending ? 0.0 : (val / 100.0).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: GoogleFonts.outfit(fontSize: 12, color: _secondaryText)),
              Text(
                isPending ? 'Pending' : '${val.toStringAsFixed(1)}%',
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: isPending ? _secondaryText : color),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: clamped,
              minHeight: 6,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(isPending ? const Color(0xFFCBD5E1) : color),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM PAINTER: CIRCULAR PROGRESS ARC
// ─────────────────────────────────────────────────────────────────────────────
class _CircularProgressArcPainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final Color trackColor;

  const _CircularProgressArcPainter({
    required this.progress,
    required this.activeColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 16) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12.0
      ..strokeCap = StrokeCap.round;

    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12.0
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressArcPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM PAINTER: 5-DOMAIN SKILL RADAR WEB
// ─────────────────────────────────────────────────────────────────────────────
class _SkillRadarWebPainter extends CustomPainter {
  final List<double> scores;
  final List<String> labels;
  final Color webColor;
  final Color fillColor;
  final Color outlineColor;

  const _SkillRadarWebPainter({
    required this.scores,
    required this.labels,
    required this.webColor,
    required this.fillColor,
    required this.outlineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 20;
    final numPoints = scores.length;
    final angleStep = (2 * math.pi) / numPoints;

    final linePaint = Paint()
      ..color = webColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw Concentric Radar Polygon Rings
    for (int ring = 1; ring <= 4; ring++) {
      final r = radius * (ring / 4);
      final ringPath = Path();
      for (int i = 0; i < numPoints; i++) {
        final angle = i * angleStep - math.pi / 2;
        final x = center.dx + r * math.cos(angle);
        final y = center.dy + r * math.sin(angle);
        if (i == 0) {
          ringPath.moveTo(x, y);
        } else {
          ringPath.lineTo(x, y);
        }
      }
      ringPath.close();
      canvas.drawPath(ringPath, linePaint);
    }

    // Draw Radial Spoke Axis Lines
    for (int i = 0; i < numPoints; i++) {
      final angle = i * angleStep - math.pi / 2;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      canvas.drawLine(center, Offset(x, y), linePaint);
    }

    // Draw Data Score Polygon Fill
    final scorePath = Path();
    for (int i = 0; i < numPoints; i++) {
      final normScore = (scores[i] / 100.0).clamp(0.1, 1.0);
      final r = radius * normScore;
      final angle = i * angleStep - math.pi / 2;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        scorePath.moveTo(x, y);
      } else {
        scorePath.lineTo(x, y);
      }
    }
    scorePath.close();

    final fillP = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final outlineP = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawPath(scorePath, fillP);
    canvas.drawPath(scorePath, outlineP);
  }

  @override
  bool shouldRepaint(covariant _SkillRadarWebPainter oldDelegate) => true;
}
