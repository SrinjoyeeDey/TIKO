import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../qa_pipeline/database/child_repository.dart';
import '../screens/onboarding_screen.dart';
import 'game_map_1913_screen.dart';
import '../widgets/smoke_bomb_transition.dart';

/// Japanese-Inspired Child Profile Selection Screen ("Who are you?")
/// Features:
/// - Clean Japanese garden background artwork matching AuthModeSelectionScreen
/// - Animated floating cherry blossom petals particle layer
/// - Off-white elegant profile cards with avatar, level & streak stats
/// - Start Journey vibrant pill button
/// - Add Child Profile modal & card
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
  late AnimationController _petalController;

  final List<_CherryBlossomPetal> _petals = [];

  final List<Map<String, dynamic>> _profiles = [
    {
      'name': 'Tinna',
      'avatar': 'assets/images/nimo_child_avatar.png',
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

    _petalController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    _generatePetals();
  }

  void _generatePetals() {
    final random = math.Random();
    for (int i = 0; i < 20; i++) {
      _petals.add(_CherryBlossomPetal(
        x: random.nextDouble(),
        y: random.nextDouble() * -0.3,
        size: 8 + random.nextDouble() * 10,
        speed: 0.2 + random.nextDouble() * 0.3,
        rotation: random.nextDouble() * math.pi * 2,
        rotationSpeed: 0.5 + random.nextDouble() * 1.0,
        swayAmplitude: 15 + random.nextDouble() * 25,
        swaySpeed: 0.4 + random.nextDouble() * 0.4,
        opacity: 0.4 + random.nextDouble() * 0.4,
        hue: random.nextDouble() * 30,
      ));
    }
  }

  @override
  void dispose() {
    _floatAnimationController.dispose();
    _pulseAnimationController.dispose();
    _petalController.dispose();
    super.dispose();
  }

  Future<void> _startAdventure() async {
    final name = _profiles[_selectedChildIndex]['name'] as String;
    // Keep the analytics/parent dashboard profile in sync with the profile
    // selected in the main experience.
    final existingProfile = await ChildRepository.getChildByName(name);
    if (existingProfile == null) {
      await ChildRepository.createChild(name: name);
    }

    if (!mounted) return;
    if (widget.onStartAdventure != null) {
      widget.onStartAdventure!();
      return;
    }

    Navigator.of(context).pushReplacement(
      SmokeBombPageRoute(
        page: const GameMap1913Screen(),
        originOffset: Offset(
          MediaQuery.of(context).size.width / 2,
          MediaQuery.of(context).size.height * 0.75,
        ),
        buttonColor: const Color(0xFFEF6C6C),
        vintageMapColor: const Color(0xFFF4E8C1),
      ),
    );
  }

  void _addNewChildDialog() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFAF6EE),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFF48FB1), width: 1.5),
        ),
        title: Column(
          children: const [
            Text('🌸', style: TextStyle(fontSize: 28)),
            SizedBox(height: 6),
            Text(
              'Add New Child Profile',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2E1C12),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Color(0xFF2E1C12), fontFamily: 'Outfit'),
              decoration: InputDecoration(
                hintText: 'Enter Child\'s Name',
                hintStyle: const TextStyle(color: Color(0xFF8D7A6F)),
                fillColor: Colors.white,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE0D0C0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFEF6C6C), width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF8D7A6F), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF6C6C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                setState(() {
                  _profiles.add({
                    'name': nameController.text.trim(),
                    'avatar': 'assets/images/nimo_child_avatar.png',
                    'level': 1,
                    'streak': 1,
                  });
                  _selectedChildIndex = _profiles.length - 1;
                });
                Navigator.of(context).pop();
              }
            },
            child: const Text('Add Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF4ED),
      body: Stack(
        children: [
          // 1. Japanese Garden Background Image (Isolated in RepaintBoundary, Cache-Optimized)
          Positioned.fill(
            child: RepaintBoundary(
              child: Image.asset(
                'assets/images/nimo_japanese_bg_clean.png',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                cacheWidth: 1280,
              ),
            ),
          ),

          // 2. Animated Cherry Blossom Petals
          AnimatedBuilder(
            animation: _petalController,
            builder: (context, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: _CherryBlossomPainter(
                  petals: _petals,
                  animationValue: _petalController.value,
                ),
              );
            },
          ),

          // 3. Main Interface
          SafeArea(
            child: Stack(
              children: [
                // Top Left Back Button (Pill style)
                Positioned(
                  top: 12,
                  left: 20,
                  child: InkWell(
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
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFF3E2A1E)),
                          SizedBox(width: 6),
                          Text(
                            'Back',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF3E2A1E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Center Content Container
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),

                        // Title Header: "Who are you?"
                        _buildTitleHeader(),

                        const SizedBox(height: 28),

                        // Interactive Profiles Grid
                        AnimatedBuilder(
                          animation: _floatAnimationController,
                          builder: (context, child) {
                            return Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 20,
                              runSpacing: 20,
                              children: [
                                ...List.generate(_profiles.length, (index) {
                                  final profile = _profiles[index];
                                  final isSelected = _selectedChildIndex == index;
                                  final floatY = math.sin((_floatAnimationController.value * math.pi * 2) + (index * 1.5)) * 3.0;

                                  return Transform.translate(
                                    offset: Offset(0, floatY),
                                    child: _buildChildProfileCard(profile, isSelected, index),
                                  );
                                }),

                                // + Add Child Card
                                _buildAddChildCard(),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 32),

                        // Start Adventure Button
                        if (_profiles.isNotEmpty)
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _startAdventure,
                              borderRadius: BorderRadius.circular(28),
                              child: Container(
                                constraints: const BoxConstraints(minWidth: 260, maxWidth: 300),
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFEF6C6C),
                                      Color(0xFFE55353),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(28),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFE55353).withValues(alpha: 0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Text('🌸', style: TextStyle(fontSize: 15)),
                                    SizedBox(width: 6),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        'はじめる  Enter Your Journey',
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Header Title
  Widget _buildTitleHeader() {
    return Column(
      children: [
        const Text(
          '誰ですか？',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF3E2A1E),
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Who are you?',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 34,
            fontWeight: FontWeight.w900,
            color: Color(0xFF2E1C12),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 24, height: 1.5, color: const Color(0xFF5D4037).withValues(alpha: 0.5)),
            const Flexible(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'Select your profile to continue your journey',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6D5547),
                  ),
                ),
              ),
            ),
            Container(width: 24, height: 1.5, color: const Color(0xFF5D4037).withValues(alpha: 0.5)),
          ],
        ),
      ],
    );
  }

  // Profile Card
  Widget _buildChildProfileCard(Map<String, dynamic> profile, bool isSelected, int index) {
    return GestureDetector(
      onTap: () => setState(() => _selectedChildIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 200,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFDFB),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? const Color(0xFFEF6C6C) : Colors.white.withValues(alpha: 0.8),
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFFEF6C6C).withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.06),
              blurRadius: isSelected ? 20 : 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar Circle
            AnimatedBuilder(
              animation: _pulseAnimationController,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isSelected) ...[
                      const Positioned(
                        top: 0,
                        right: 0,
                        child: Text('✨', style: TextStyle(fontSize: 16)),
                      ),
                      const Positioned(
                        bottom: 0,
                        left: 0,
                        child: Text('🌸', style: TextStyle(fontSize: 14)),
                      ),
                    ],

                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF48FB1).withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: profile['avatar'] != null && profile['avatar'].toString().contains('/')
                            ? Image.asset(
                                profile['avatar'],
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: const Color(0xFFFCE4EC),
                                child: Center(
                                  child: Text(profile['avatar'] ?? '👦', style: const TextStyle(fontSize: 44)),
                                ),
                              ),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 12),

            // Name
            Text(
              profile['name'],
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2E1C12),
              ),
            ),

            const SizedBox(height: 8),

            // Stats Pill Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF2EA),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE8DCD0), width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('⭐', style: TextStyle(fontSize: 11)),
                      const SizedBox(width: 4),
                      Text(
                        'Lvl ${profile['level']}',
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF3E2A1E),
                        ),
                      ),
                    ],
                  ),
                  Container(width: 1, height: 12, color: const Color(0xFFD8C4B4)),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 11)),
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

  // Add Child Card
  Widget _buildAddChildCard() {
    return GestureDetector(
      onTap: _addNewChildDialog,
      child: Container(
        width: 160,
        height: 220,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFEF6C6C).withValues(alpha: 0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.add_circle_outline_rounded, size: 42, color: Color(0xFFEF6C6C)),
            SizedBox(height: 8),
            Text(
              '+ Add Profile',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF3E2A1E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Particle Painter
class _CherryBlossomPetal {
  final double x;
  double y;
  final double size;
  final double speed;
  double rotation;
  final double rotationSpeed;
  final double swayAmplitude;
  final double swaySpeed;
  final double opacity;
  final double hue;

  _CherryBlossomPetal({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.rotation,
    required this.rotationSpeed,
    required this.swayAmplitude,
    required this.swaySpeed,
    required this.opacity,
    required this.hue,
  });
}

class _CherryBlossomPainter extends CustomPainter {
  final List<_CherryBlossomPetal> petals;
  final double animationValue;

  _CherryBlossomPainter({
    required this.petals,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final petal in petals) {
      petal.y += petal.speed * 0.002;
      petal.rotation += petal.rotationSpeed * 0.02;

      if (petal.y > 1.2) {
        petal.y = -0.1;
      }

      final x = petal.x * size.width + math.sin(animationValue * math.pi * 2 * petal.swaySpeed) * petal.swayAmplitude;
      final y = petal.y * size.height;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(petal.rotation);

      final paint = Paint()
        ..color = Color.lerp(
          const Color(0xFFF8BBD0),
          const Color(0xFFEC407A),
          petal.hue / 30,
        )!.withValues(alpha: petal.opacity)
        ..style = PaintingStyle.fill;

      final path = Path();
      path.moveTo(0, -petal.size / 2);
      path.cubicTo(
        petal.size / 2, -petal.size / 4,
        petal.size / 2, petal.size / 4,
        0, petal.size / 2,
      );
      path.cubicTo(
        -petal.size / 2, petal.size / 4,
        -petal.size / 2, -petal.size / 4,
        0, -petal.size / 2,
      );

      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _CherryBlossomPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

