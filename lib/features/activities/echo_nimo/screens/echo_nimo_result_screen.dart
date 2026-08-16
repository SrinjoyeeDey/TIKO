import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/state/child_state.dart';
import '../../core/models/activity_session.dart';

/// Result Screen for Echo NIMO.
class EchoNimoResultScreen extends StatefulWidget {
  final ActivitySession session;

  const EchoNimoResultScreen({
    super.key,
    required this.session,
  });

  @override
  State<EchoNimoResultScreen> createState() => _EchoNimoResultScreenState();
}

class _EchoNimoResultScreenState extends State<EchoNimoResultScreen> {
  @override
  void initState() {
    super.initState();
    // Sync profile XP
    ChildState.instance.addXp(widget.session.totalXP);
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final accuracyStr = '${session.accuracyPercentage.toStringAsFixed(0)}%';
    final avgReactionSec = (session.averageReactionTimeMs / 1000.0).toStringAsFixed(2);

    return Scaffold(
      body: Container(
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                const SizedBox(height: 16),

                // Title
                Text(
                  'ECHO RUN COMPLETE',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF14300D),
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your sequential memory echo is razor sharp.',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4F8528),
                  ),
                ),

                const SizedBox(height: 24),

                // XP Banner Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBF0),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF85D64B), width: 2.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x300F220A),
                        offset: Offset(0, 6),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('⚡', style: TextStyle(fontSize: 32)),
                      const SizedBox(width: 10),
                      Text(
                        '+${session.totalXP} XP',
                        style: GoogleFonts.outfit(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF14300D),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Stats Grid
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 1.35,
                    children: [
                      _buildStatCard(
                        icon: '🎯',
                        label: 'ACCURACY',
                        value: accuracyStr,
                        valueColor: const Color(0xFF85D64B),
                      ),
                      _buildStatCard(
                        icon: '⚡',
                        label: 'AVG TIME',
                        value: '${avgReactionSec}s',
                        valueColor: const Color(0xFFFFBF27),
                      ),
                      _buildStatCard(
                        icon: '🔥',
                        label: 'BEST STREAK',
                        value: '${session.highestStreak}',
                        valueColor: const Color(0xFFFF3B63),
                      ),
                      _buildStatCard(
                        icon: '🏆',
                        label: 'MAX LEVEL',
                        value: 'LVL ${session.difficultyReached}',
                        valueColor: const Color(0xFFA855F7),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Continue Button
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF85D64B),
                      foregroundColor: const Color(0xFF14300D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: Colors.white, width: 2),
                      ),
                      elevation: 6,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF85D64B), width: 2.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x250F220A),
            offset: Offset(0, 4),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF4F8528),
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
