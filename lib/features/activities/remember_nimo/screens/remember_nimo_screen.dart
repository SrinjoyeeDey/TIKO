import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/state/child_state.dart';
import '../engine/remember_nimo_controller.dart';

import '../widgets/customizable_nimo_character.dart';
import '../widgets/feature_selector_widget.dart';
import 'remember_nimo_result_screen.dart';

/// Main Playable Remember NIMO Screen with preview timer, curtain transition & reconstruction.
class RememberNimoScreen extends StatefulWidget {
  const RememberNimoScreen({super.key});

  @override
  State<RememberNimoScreen> createState() => _RememberNimoScreenState();
}

class _RememberNimoScreenState extends State<RememberNimoScreen> {
  late RememberNimoController _controller;
  bool _hasStartedRound = false;

  @override
  void initState() {
    super.initState();
    final childId = ChildState.instance.currentProfile.id;
    _controller = RememberNimoController(childId: childId);
    _controller.addListener(_onControllerStateChanged);
  }

  void _onControllerStateChanged() {
    if (!mounted) return;

    if (_controller.isSessionFinished) {
      final session = _controller.buildCompletedSession();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => RememberNimoResultScreen(session: session),
        ),
      );
      return;
    }

    setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerStateChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (!_hasStartedRound) {
            _hasStartedRound = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _controller.startRound();
              }
            });
          }

          return ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              final challenge = _controller.currentChallenge;
              final phase = _controller.phase;
              final config = _controller.currentConfig;

              return Container(
                width: double.infinity,
                height: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFFFDF8), // Soft Cream Top
                      Color(0xFFF7F0DF), // Warm Ivory
                      Color(0xFFEFE4CC), // Cream Parchment Bottom
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // 1. HUD Header Bar
                        _buildHudHeader(),

                        const SizedBox(height: 10),

                        // 2. Preview Timer Progress Bar
                        if (phase == RememberNimoPhase.previewing)
                          _buildPreviewTimerBar(),

                        const SizedBox(height: 16),

                        // 3. Central NIMO Presentation Canvas with Curtain Transition
                        Expanded(
                          child: Center(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 350),
                              child: phase == RememberNimoPhase.previewing && challenge != null
                                  ? Column(
                                      key: const ValueKey('preview'),
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'MEMORIZE NIMO! 🧠',
                                          style: GoogleFonts.outfit(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                            color: const Color(0xFF14300D),
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        CustomizableNimoCharacter(
                                          size: 200,
                                          features: challenge.targetFeatures,
                                        ),
                                      ],
                                    )
                                  : phase == RememberNimoPhase.hiding
                                      ? Container(
                                          key: const ValueKey('hiding'),
                                          width: 200,
                                          height: 200,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF14300D).withValues(alpha: 0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Center(
                                            child: Icon(
                                              Icons.lock_clock_rounded,
                                              size: 64,
                                              color: Color(0xFF85D64B),
                                            ),
                                          ),
                                        )
                                      : Column(
                                          key: const ValueKey('reconstructing'),
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'RECONSTRUCT NIMO ✨',
                                              style: GoogleFonts.outfit(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w900,
                                                color: const Color(0xFF14300D),
                                                letterSpacing: 1.2,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            CustomizableNimoCharacter(
                                              size: 160,
                                              features: _controller.playerSelections,
                                            ),
                                          ],
                                        ),
                            ),
                          ),
                        ),

                        // 4. Reconstruction Feature Options Grid
                        if (phase == RememberNimoPhase.reconstructing && challenge != null) ...[
                          FeatureSelectorWidget(
                            activeCategories: config.activeCategories,
                            optionsPerCategory: challenge.optionsPerCategory,
                            playerSelections: _controller.playerSelections,
                            onOptionSelected: _controller.selectOption,
                          ),
                          const SizedBox(height: 14),

                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _controller.playerSelections.length == config.activeCategories.length
                                  ? _controller.submitReconstruction
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF85D64B),
                                foregroundColor: const Color(0xFF14300D),
                                disabledBackgroundColor: const Color(0xFFD6E4C8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  side: const BorderSide(color: Colors.white, width: 2),
                                ),
                                elevation: 6,
                              ),
                              child: Text(
                                'SUBMIT MATCH ✓',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],

                        // 5. Round Feedback Banner
                        if (phase == RememberNimoPhase.roundComplete)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBF0),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF85D64B), width: 2.2),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x300F220A),
                                  offset: Offset(0, 4),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  _controller.feedbackHeadline ?? 'Nice attempt!',
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF85D64B),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _controller.feedbackDetail ?? '',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF14300D),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHudHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF85D64B), width: 2.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x250F220A),
            offset: Offset(0, 4),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF85D64B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 14),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'MEMORY RUN',
                    style: GoogleFonts.outfit(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF4F8528),
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    'ROUND ${_controller.currentRound} / ${_controller.totalRounds}',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF14300D),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFBF27),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE89B00), width: 1.5),
                ),
                child: Text(
                  'LVL ${_controller.currentLevel}',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF3A2200),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFA855F7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF7C23D4), width: 1.5),
                ),
                child: Row(
                  children: [
                    const Text('⚡', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 3),
                    Text(
                      '${_controller.currentXP}',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewTimerBar() {
    final totalMs = _controller.currentConfig.previewDuration.inMilliseconds;
    final progress = (_controller.previewRemainingMs / totalMs).clamp(0.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'MEMORIZE THIS NIMO!',
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF14300D),
              ),
            ),
            Text(
              '${(_controller.previewRemainingMs / 1000.0).toStringAsFixed(1)}s',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF85D64B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: const Color(0xFFE2D6B5),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF85D64B)),
          ),
        ),
      ],
    );
  }
}
