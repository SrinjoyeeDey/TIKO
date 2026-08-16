import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/state/child_state.dart';
import '../engine/turn_nimo_controller.dart';
import '../widgets/power_card_bar_widget.dart';
import '../widgets/tactile_dice_widget.dart';
import '../widgets/turn_indicator_banner.dart';
import 'turn_nimo_result_screen.dart';

/// Main Playable Turn NIMO Screen with Tactical Power Cards & NIMO Banter.
class TurnNimoScreen extends StatefulWidget {
  const TurnNimoScreen({super.key});

  @override
  State<TurnNimoScreen> createState() => _TurnNimoScreenState();
}

class _TurnNimoScreenState extends State<TurnNimoScreen> {
  late TurnNimoController _controller;
  bool _hasStartedGame = false;

  @override
  void initState() {
    super.initState();
    final childId = ChildState.instance.currentProfile.id;
    _controller = TurnNimoController(childId: childId);
    _controller.addListener(_onControllerStateChanged);
  }

  void _onControllerStateChanged() {
    if (!mounted) return;

    if (_controller.isSessionFinished) {
      final session = _controller.buildCompletedSession();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => TurnNimoResultScreen(session: session),
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
          if (!_hasStartedGame) {
            _hasStartedGame = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _controller.startGame();
              }
            });
          }

          return ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              final phase = _controller.phase;
              final config = _controller.currentConfig;
              final isRolling = phase == TurnNimoPhase.nimoRolling || phase == TurnNimoPhase.playerRolling;

              return Container(
                width: double.infinity,
                height: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFFFDF8),
                      Color(0xFFF7F0DF),
                      Color(0xFFEFE4CC),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // 1. HUD Header Bar
                        _buildHudHeader(config.totalTurnsPerSession),

                        const SizedBox(height: 12),

                        // 2. Dual Scoreboard Card
                        _buildScoreboardCard(),

                        const SizedBox(height: 14),

                        // 3. Turn Indicator Status Banner
                        TurnIndicatorBanner(phase: phase),

                        const SizedBox(height: 14),

                        // 4. Tactical Power Cards Hand
                        PowerCardBarWidget(
                          isPlayerTurn: phase == TurnNimoPhase.playerTurn,
                          activeCardType: _controller.activePlayerPowerCard,
                          usedCards: _controller.usedPowerCards,
                          onCardTap: _controller.activatePowerCard,
                        ),

                        const SizedBox(height: 16),

                        // 5. Center 3D Dice Display
                        Expanded(
                          child: Center(
                            child: TactileDiceWidget(
                              diceValue: _controller.diceValue,
                              isRolling: isRolling,
                              isInteractive: phase == TurnNimoPhase.playerTurn,
                              onRollTap: _controller.onPlayerRollTapped,
                            ),
                          ),
                        ),

                        // 6. Round Feedback Banner
                        if (_controller.feedbackHeadline != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                                  _controller.feedbackHeadline!,
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF85D64B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _controller.feedbackDetail ?? '',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
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

  Widget _buildScoreboardCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF0),
        borderRadius: BorderRadius.circular(24),
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
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // NIMO Score
          Column(
            children: [
              Text(
                '🤖 NIMO',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFA855F7),
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${_controller.nimoScore}',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF14300D),
                ),
              ),
            ],
          ),
          Container(height: 28, width: 2, color: const Color(0xFFE2D6B5)),
          // Player Score
          Column(
            children: [
              Text(
                '🧒 YOU',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF4F8528),
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${_controller.playerScore}',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF85D64B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHudHeader(int totalTurns) {
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
                    'TURN NIMO',
                    style: GoogleFonts.outfit(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF4F8528),
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    'TURN ${_controller.currentTurnCount} / $totalTurns',
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
}
