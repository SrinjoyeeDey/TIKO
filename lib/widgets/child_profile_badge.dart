import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/models/child_profile.dart';
import '../core/state/child_state.dart';
import '../qa_pipeline/database/child_repository.dart';

/// Compact, glowing game-styled profile badge placed in the upper-left corner of learning screens.
/// Displays the child's Name, Age, Standard/Grade, and calibrated Difficulty Level.
class ChildProfileBadge extends StatefulWidget {
  final String? childId;
  final bool compact;
  final VoidCallback? onTap;

  const ChildProfileBadge({
    super.key,
    this.childId,
    this.compact = false,
    this.onTap,
  });

  @override
  State<ChildProfileBadge> createState() => _ChildProfileBadgeState();
}

class _ChildProfileBadgeState extends State<ChildProfileBadge> {
  ChildProfile? _profile;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  @override
  void didUpdateWidget(covariant ChildProfileBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.childId != widget.childId) {
      _fetchProfile();
    }
  }

  Future<void> _fetchProfile() async {
    final cid = widget.childId ?? ChildState.instance.currentProfile.id;
    if (cid.isNotEmpty) {
      try {
        final profile = await ChildRepository.getChildById(cid);
        if (profile != null && mounted) {
          setState(() {
            _profile = ChildProfile(
              id: profile.id,
              name: profile.name,
              age: profile.age,
              className: profile.className,
              difficultyPercentage: profile.difficultyPercentage,
              difficultyLevel: profile.difficultyLevel,
              difficultyReasoning: profile.difficultyReasoning,
              parentId: profile.parentId,
            );
          });
          return;
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _profile = ChildState.instance.currentProfile;
      });
    }
  }

  Color _getDifficultyColor(int pct) {
    if (pct <= 35) return const Color(0xFF4CAF50); // Gentle Green
    if (pct <= 50) return const Color(0xFF00BCD4); // Balanced Cyan
    if (pct <= 65) return const Color(0xFFFF9800); // Curious Amber
    if (pct <= 80) return const Color(0xFFE91E63); // Challenger Pink/Red
    return const Color(0xFF9C27B0); // Champion Purple
  }

  void _showDifficultyDialog(BuildContext context, ChildProfile profile) {
    final diffPct = profile.difficultyPercentage ?? 50;
    final diffLevel = profile.difficultyLevel ?? 'Balanced Explorer';
    final reasoning = profile.difficultyReasoning ?? 'Pedagogically calibrated by Dr. Nimo.';
    final color = _getDifficultyColor(diffPct);

    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2C1E14), Color(0xFF19100A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFD4AF37), width: 2),
              boxShadow: const [
                BoxShadow(color: Colors.black54, blurRadius: 16, offset: Offset(0, 8)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withValues(alpha: 0.2),
                        border: Border.all(color: color, width: 2),
                      ),
                      child: Icon(Icons.psychology_rounded, color: color, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.name,
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFFFE082),
                            ),
                          ),
                          Text(
                            'Age ${profile.age ?? 5} • ${profile.className ?? "Standard"}',
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13,
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Quest Difficulty Level',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13,
                              color: Colors.white60,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: color, width: 1.2),
                            ),
                            child: Text(
                              '⚡ $diffPct% • $diffLevel',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: (diffPct.clamp(0, 100)) / 100.0,
                          minHeight: 8,
                          backgroundColor: Colors.white12,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B2718),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.auto_awesome, color: Color(0xFFFFD700), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          reasoning,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.5,
                            color: Color(0xFFFFF8E1),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: const Color(0xFF2C1E14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text(
                      'Got it! 🚀',
                      style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w900, fontSize: 14),
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

  @override
  Widget build(BuildContext context) {
    final profile = _profile ?? ChildState.instance.currentProfile;
    final name = profile.name.isNotEmpty ? profile.name : 'Learner';
    final age = profile.age ?? 5;
    final std = profile.className != null && profile.className!.isNotEmpty
        ? profile.className!
        : 'Class 1';
    final diffPct = profile.difficultyPercentage ?? 50;
    final diffLevel = profile.difficultyLevel ?? 'Balanced Explorer';
    final badgeColor = _getDifficultyColor(diffPct);

    return InkWell(
      onTap: widget.onTap ?? () => _showDifficultyDialog(context, profile),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xDD2A1B12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD4AF37), width: 1.2),
          boxShadow: const [
            BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Child Avatar Badge
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [badgeColor, badgeColor.withValues(alpha: 0.6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: const Color(0xFFFFF8E1), width: 1.2),
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'N',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Profile info
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFFE082),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: badgeColor.withValues(alpha: 0.8), width: 0.8),
                      ),
                      child: Text(
                        '⚡ $diffPct%',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          color: badgeColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  'Age $age • $std • $diffLevel',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 10,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
