import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../screens/onboarding_screen.dart';
import '../widgets/stone_gate_waterfall_background.dart';
import '../widgets/wooden_back_button.dart';
import '../widgets/stone_begin_journey_button.dart';
import '../journey/screens/map_journey_intro_screen.dart';

/// Interactive Child Profile Selection Screen for prototype.
/// - NO NIMO hanging signboard (showNimoSign: false).
/// - Clean centered male child avatar (NO overlapping emojis).
/// - Animated floating cards & sparkle particles for delightful child interactivity.
class ChildProfileSelectionScreen extends StatefulWidget {
  final VoidCallback? onStartAdventure;

  const ChildProfileSelectionScreen({
    super.key,
    this.onStartAdventure,
  });

  @override
  State<ChildProfileSelectionScreen> createState() => _ChildProfileSelectionScreenState();
}

class _ChildProfileSelectionScreenState extends State<ChildProfileSelectionScreen>
    with TickerProviderStateMixin {
  int _selectedChildIndex = 0;

  late AnimationController _floatAnimationController;
  late AnimationController _pulseAnimationController;

  final List<Map<String, dynamic>> _profiles = [
    {
      'name': 'Tinna',
      'avatar': '👦',
      'level': 4,
      'streak': 5,
    },
  ];

  @override
  void initState() {
    super.initState();
    _floatAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatAnimationController.dispose();
    _pulseAnimationController.dispose();
    super.dispose();
  }

  void _startAdventure() {
    if (widget.onStartAdventure != null) {
      widget.onStartAdventure!();
      return;
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MapJourneyIntroScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  void _addNewChildDialog() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C1C0F),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFFFD54F), width: 1.5),
        ),
        title: const Text(
          'Add New Child Profile',
          style: TextStyle(
            fontFamily: 'Outfit',
            color: Color(0xFFFFD54F),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter Child\'s Name',
                hintStyle: const TextStyle(color: Colors.white54),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF8D6E63)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFFFD54F)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD54F),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                setState(() {
                  _profiles.add({
                    'name': nameController.text.trim(),
                    'avatar': '👦',
                    'level': 1,
                    'streak': 1,
                  });
                  _selectedChildIndex = _profiles.length - 1;
                });
                Navigator.of(context).pop();
              }
            },
            child: const Text('Add Profile', style: TextStyle(color: Color(0xFF2C1C0F), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StoneGateWaterfallBackground(
        showNimoSign: false, // NO NIMO signboard as requested!
        child: SafeArea(
          child: Stack(
            children: [
              // Top Left Back Button (Safe navigation)
              Positioned(
                top: 16,
                left: 16,
                child: WoodenBackButton(
                  onTap: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      Navigator.of(context).pushReplacement(
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) =>
                              const OnboardingScreen(),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                              FadeTransition(opacity: animation, child: child),
                          transitionDuration: const Duration(milliseconds: 350),
                        ),
                      );
                    }
                  },
                  size: 38,
                ),
              ),

              // Center Profile Selection Content
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 30), // Clean spacing without NIMO sign overlap

                      // Title Box: "Who are you?"
                      _buildTitleHeader(),

                      const SizedBox(height: 32),

                      // Interactive Floating Profiles Grid
                      AnimatedBuilder(
                        animation: _floatAnimationController,
                        builder: (context, child) {
                          return Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 24,
                            runSpacing: 24,
                            children: [
                              ...List.generate(_profiles.length, (index) {
                                final profile = _profiles[index];
                                final isSelected = _selectedChildIndex == index;
                                final floatY = math.sin((_floatAnimationController.value * math.pi * 2) + (index * 1.5)) * 4.0;

                                return Transform.translate(
                                  offset: Offset(0, floatY),
                                  child: _buildChildProfileCard(profile, isSelected, index),
                                );
                              }),

                              // + Add Child Button Card
                              _buildAddChildCard(),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 36),

                      // Start Adventure Button for Selected Child
                      if (_profiles.isNotEmpty)
                        StoneBeginJourneyButton(
                          onTap: _startAdventure,
                          width: 250,
                          height: 60,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── TITLE HEADER ──────────────────────────────────────────────────────────
  Widget _buildTitleHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2C1C0F).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFD54F), width: 2.0),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text(
            'Who are you?',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.8,
              color: Color(0xFFFFF176),
              shadows: [
                Shadow(color: Colors.black, offset: Offset(1, 2), blurRadius: 4),
              ],
            ),
          ),
          SizedBox(height: 3),
          Text(
            'Select your profile to continue your journey',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFFE8C98A),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── CHILD PROFILE CARD (CLEAN SINGLE AVATAR & SPARKLES) ────────────────────
  Widget _buildChildProfileCard(Map<String, dynamic> profile, bool isSelected, int index) {
    return GestureDetector(
      onTap: () => setState(() => _selectedChildIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 210,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFDF5).withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFB300) : const Color(0xFFD7CCC8),
            width: isSelected ? 3.2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFFFFB300).withValues(alpha: 0.45)
                  : Colors.black26,
              blurRadius: isSelected ? 18 : 8,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar Circle with Pulsing Glow & Sparkle Accents
            AnimatedBuilder(
              animation: _pulseAnimationController,
              builder: (context, child) {
                final pulseScale = isSelected
                    ? 1.0 + (_pulseAnimationController.value * 0.05)
                    : 1.0;

                return Transform.scale(
                  scale: pulseScale,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Sparkle Accents when selected
                      if (isSelected) ...[
                        const Positioned(
                          top: 0,
                          right: 0,
                          child: Text('✨', style: TextStyle(fontSize: 18)),
                        ),
                        const Positioned(
                          bottom: 2,
                          left: 0,
                          child: Text('🌟', style: TextStyle(fontSize: 16)),
                        ),
                      ],

                      // Clean Single Avatar Container (NO EMOJI OVERLAP!)
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFFECB3),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFFFB300) : Colors.white,
                            width: 3.5,
                          ),
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: const Color(0xFFFFB300).withValues(alpha: 0.6),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            profile['avatar'] ?? '👦',
                            style: const TextStyle(fontSize: 44), // Single clean male child avatar
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 14),

            // Profile Name
            Text(
              profile['name'],
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF3E2716),
              ),
            ),

            const SizedBox(height: 10),

            // Stats Pill Row (⭐ Level 4  •  🔥 5 day streak)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF5EBE0),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE0D0C0), width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('⭐', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        'Lvl ${profile['level']}',
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF3E2716),
                        ),
                      ),
                    ],
                  ),
                  Container(width: 1, height: 12, color: const Color(0xFFD7CCC8)),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        '${profile['streak']}d streak',
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFD84315),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── ADD CHILD BUTTON CARD ──────────────────────────────────────────────────
  Widget _buildAddChildCard() {
    return GestureDetector(
      onTap: _addNewChildDialog,
      child: Container(
        width: 160,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: const Color(0xFF8D6E63),
            width: 2.0,
          ),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.add_circle_outline_rounded, size: 40, color: Color(0xFF5D4037)),
            SizedBox(height: 8),
            Text(
              '+ Add Child',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF3E2716),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
