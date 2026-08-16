import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/models/activity_result.dart';

/// Premium Result Screen for Teenagers (Age 15+) matching NIMO's aesthetic.
class CatchNimoResultScreen extends StatefulWidget {
  final ActivityResult result;

  const CatchNimoResultScreen({
    super.key,
    required this.result,
  });

  @override
  State<CatchNimoResultScreen> createState() => _CatchNimoResultScreenState();
}

class _CatchNimoResultScreenState extends State<CatchNimoResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _cardController;

  @override
  void initState() {
    super.initState();
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _cardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.result.session;
    final bestReactionSec = (session.bestReactionTimeMs / 1000.0).toStringAsFixed(2);
    final accuracyStr = '${session.accuracyPercentage.toStringAsFixed(0)}%';

    return Scaffold(
      body: Container(
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Title Header
                  Text(
                    'RUN COMPLETE',
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF14300D),
                      letterSpacing: 2.5,
                    ),
                  ),

                  if (widget.result.isPersonalBest) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Text(
                        '✨ NEW PERSONAL BEST',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF161B33),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Stat Cards Grid
                  Expanded(
                    child: FadeTransition(
                      opacity: _cardController,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                          CurvedAnimation(
                            parent: _cardController,
                            curve: Curves.easeOutBack,
                          ),
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              // XP Highlight Card
                              _buildStatCard(
                                icon: '⚡',
                                label: 'TOTAL XP',
                                value: '${session.totalXP} XP',
                                valueColor: const Color(0xFFFFD700),
                              ),
                              const SizedBox(height: 14),

                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      icon: '🎯',
                                      label: 'ACCURACY',
                                      value: accuracyStr,
                                      valueColor: const Color(0xFF00F2FE),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: _buildStatCard(
                                      icon: '⏱️',
                                      label: 'BEST TIME',
                                      value: '${bestReactionSec}s',
                                      valueColor: const Color(0xFF4FACFE),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      icon: '🔥',
                                      label: 'BEST COMBO',
                                      value: '${session.highestStreak}',
                                      valueColor: const Color(0xFFFF416C),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: _buildStatCard(
                                      icon: '📊',
                                      label: 'DIFFICULTY',
                                      value: 'LVL ${session.difficultyReached}',
                                      valueColor: const Color(0xFFA8EDEA),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 28),

                              // Encouraging Feedback Banner
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF14300D),
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(color: const Color(0xFF85D64B), width: 2.2),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x550F220A),
                                      offset: Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      widget.result.headlineFeedback,
                                      style: GoogleFonts.outfit(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        color: const Color(0xFF85D64B),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      widget.result.detailFeedback,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Continue Button (3D Tactile Monster Green)
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF85D64B),
                        foregroundColor: const Color(0xFF14300D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: const BorderSide(color: Colors.white, width: 2.0),
                        ),
                        elevation: 6,
                        shadowColor: const Color(0xFF4F8528),
                      ),
                      child: Text(
                        'CONTINUE →',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      );
    }

  Widget _buildStatCard({
    required String icon,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF14300D), // Monster dark green
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF85D64B), width: 2.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x550F220A),
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF85D64B),
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
