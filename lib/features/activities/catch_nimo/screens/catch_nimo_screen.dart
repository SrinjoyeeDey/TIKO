import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/state/child_state.dart';
import '../../core/models/activity_result.dart';
import '../engine/catch_nimo_controller.dart';
import '../widgets/distractor_target.dart';
import '../widgets/game_hud.dart';
import '../widgets/nimo_character.dart';
import '../widgets/particle_burst.dart';
import 'catch_nimo_result_screen.dart';

/// Main Playable Catch NIMO Screen with NIMO's Monster Theme.
class CatchNimoScreen extends StatefulWidget {
  const CatchNimoScreen({super.key});

  @override
  State<CatchNimoScreen> createState() => _CatchNimoScreenState();
}

class _CatchNimoScreenState extends State<CatchNimoScreen> {
  late CatchNimoController _controller;
  bool _hasStartedRound = false;
  bool _showIntroBanner = true;

  Offset? _lastCatchPosition;
  String _lastCatchScoreText = '+25 XP';

  @override
  void initState() {
    super.initState();
    final childId = ChildState.instance.currentProfile.id;
    _controller = CatchNimoController(childId: childId);
    _controller.addListener(_onControllerStateChanged);

    Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _showIntroBanner = false);
      }
    });
  }

  void _onControllerStateChanged() {
    if (!mounted) return;

    if (_controller.isCaught && _lastCatchPosition == null) {
      final config = _controller.currentConfig;
      setState(() {
        _lastCatchPosition = _controller.nimoPosition;
        _lastCatchScoreText = '+${config.baseXP.toInt()} XP';
      });
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) setState(() => _lastCatchPosition = null);
      });
    }

    if (_controller.isSessionFinished) {
      final session = _controller.buildCompletedSession();
      final result = ActivityResult.fromSession(session);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => CatchNimoResultScreen(result: result),
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
          final screenSize = Size(
            constraints.maxWidth > 0 ? constraints.maxWidth : 360.0,
            constraints.maxHeight > 0 ? constraints.maxHeight : 640.0,
          );

          if (!_hasStartedRound) {
            _hasStartedRound = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _controller.startRound(screenSize);
              }
            });
          }

          return ListenableBuilder(
            listenable: _controller,
            builder: (context, child) {
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
                child: Stack(
                  children: [
                    // Organic Soft White Belly Oval Accent
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.center,
                        child: Container(
                          width: screenSize.width * 0.92,
                          height: screenSize.height * 0.78,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(160),
                            border: Border.all(
                              color: const Color(0xFFE8DFC8).withValues(alpha: 0.5),
                              width: 2.0,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Play Area: Distractors + NIMO Target
                    if (!_controller.isSessionFinished) ...[
                      // Distractors
                      ..._controller.distractorPositions.map(
                        (pos) => Positioned(
                          left: pos.dx,
                          top: pos.dy,
                          child: DistractorTarget(
                            size: 75.0,
                            onTap: _controller.onDistractorTapped,
                          ),
                        ),
                      ),

                      // NIMO Character Target
                      Positioned(
                        left: _controller.nimoPosition.dx,
                        top: _controller.nimoPosition.dy,
                        child: NimoCharacter(
                          size: _controller.currentConfig.targetSize,
                          isCaught: _controller.isCaught,
                          onTap: () => _controller.onNimoTapped(screenSize),
                        ),
                      ),

                      // Particle Burst
                      if (_lastCatchPosition != null)
                        ParticleBurst(
                          position: _lastCatchPosition!,
                          text: _lastCatchScoreText,
                        ),

                      // Status Banner
                      if (_controller.statusNotification != null)
                        Positioned(
                          top: screenSize.height * 0.42,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFBF0),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF85D64B), width: 2.2),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x350F220A),
                                    offset: Offset(0, 4),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Text(
                                _controller.statusNotification!,
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF14300D),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],

                    // HUD Header
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: GameHud(
                          currentRound: _controller.currentRound,
                          totalRounds: _controller.totalRounds,
                          currentLevel: _controller.currentLevel,
                          comboCount: _controller.comboCount,
                          currentXP: _controller.currentXP,
                          onBackPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),

                    // Intro Ready Banner
                    if (_showIntroBanner)
                      Positioned(
                        top: 100,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBF0),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF85D64B), width: 2.0),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x250F220A),
                                  offset: Offset(0, 3),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Text(
                              'TAP NIMO TO CATCH! ⚡',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF14300D),
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
