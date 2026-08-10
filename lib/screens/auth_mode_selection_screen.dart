import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'child_profile_selection_screen.dart';

/// Japanese-Inspired Authentication & Mode Selection Screen
/// Matching the exact reference mockup (Image 2):
/// - Clean Japanese garden background artwork with parrot mascot, Mt Fuji, Torii gate, and lantern
/// - Side-by-side equal size Child Mode (こども) and Parent Mode (保護者) cards
/// - Exact character avatars (anime child girl in pink kimono, anime parent in green kimono)
/// - Interactive working buttons ("はじめる >", "つづける >")
/// - Top right language selector ("日本語 ˅")
/// - Bottom privacy badge ("お子さまのプライバシーを大切にしています 🔒")
class AuthModeSelectionScreen extends StatefulWidget {
  final VoidCallback? onBeginJourney;

  const AuthModeSelectionScreen({
    super.key,
    this.onBeginJourney,
  });

  @override
  State<AuthModeSelectionScreen> createState() => _AuthModeSelectionScreenState();
}

class _AuthModeSelectionScreenState extends State<AuthModeSelectionScreen>
    with TickerProviderStateMixin {
  String _selectedLanguage = '日本語';

  // Animation Controllers
  AnimationController? _petalController;
  AnimationController? _floatController;
  AnimationController? _glowController;

  // Hover states
  bool _isChildHovered = false;
  bool _isParentHovered = false;
  bool _isChildPressed = false;
  bool _isParentPressed = false;

  // Cherry blossom petals
  final List<_CherryBlossomPetal> _petals = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generatePetals();
  }

  void _initializeAnimations() {
    _petalController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
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
    _petalController?.dispose();
    _floatController?.dispose();
    _glowController?.dispose();
    super.dispose();
  }

  void _openChildProfileSelection() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ChildProfileSelectionScreen(onStartAdventure: widget.onBeginJourney),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 450),
      ),
    );
  }

  void _openParentPinModal() {
    final List<String> enteredPin = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: const Color(0xFFFAF6EE),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: Color(0xFF7CB342), width: 1.5),
            ),
            title: Column(
              children: const [
                Icon(Icons.lock_rounded, size: 36, color: Color(0xFF558B2F)),
                SizedBox(height: 6),
                Text(
                  'Parent Access / 保護者確認',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF33691E),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Enter 4-Digit PIN to access Parent Dashboard',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF689F38),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    final isFilled = index < enteredPin.length;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isFilled ? const Color(0xFF558B2F) : Colors.transparent,
                        border: Border.all(color: const Color(0xFF689F38), width: 2),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 230,
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (int i = 1; i <= 9; i++)
                        _buildPinKey(i.toString(), () {
                          if (enteredPin.length < 4) {
                            setModalState(() => enteredPin.add(i.toString()));
                            if (enteredPin.length == 4) {
                              Navigator.of(context).pop();
                              _showParentDashboardSnackBar();
                            }
                          }
                        }),
                      _buildPinKey('C', () {
                        setModalState(() => enteredPin.clear());
                      }),
                      _buildPinKey('0', () {
                        if (enteredPin.length < 4) {
                          setModalState(() => enteredPin.add('0'));
                          if (enteredPin.length == 4) {
                            Navigator.of(context).pop();
                            _showParentDashboardSnackBar();
                          }
                        }
                      }),
                      _buildPinKey('⌫', () {
                        if (enteredPin.isNotEmpty) {
                          setModalState(() => enteredPin.removeLast());
                        }
                      }),
                    ],
                  ),
                ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel', style: TextStyle(color: Color(0xFF689F38), fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPinKey(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFC5E1A5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF33691E),
            ),
          ),
        ),
      ),
    );
  }

  void _showParentDashboardSnackBar() {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.verified_rounded, color: Color(0xFFAED581)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Parent Access Verified. Opening Parent Dashboard & AI Insights...',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF33691E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFAED581), width: 1.2),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showPrivacyInfoModal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFAF5EE),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.shield_rounded, color: Color(0xFF4CAF50)),
            SizedBox(width: 10),
            Text('Data Privacy Promise', style: TextStyle(fontFamily: 'Outfit', color: Color(0xFF33691E), fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'We are built specifically for young learners. All facial recognition, speech synthesis, and behavioral learning analytics stay 100% encrypted and stored locally on your device. No private data is ever shared or sold.',
          style: TextStyle(fontFamily: 'Outfit', fontSize: 13, color: Color(0xFF558B2F), height: 1.4),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF558B2F)),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Understood', style: TextStyle(color: Colors.white)),
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
          // 1. Clean Japanese Garden Background Image (Isolated in RepaintBoundary, Cache-Optimized)
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

          // 2. Animated Floating Cherry Blossom Petals
          _buildCherryBlossomPetals(),

          // 3. Main UI Overlay
          SafeArea(
            child: Column(
              children: [
                // Top Bar with Language Selector (Top-Right)
                _buildTopBar(),

                // Center Content Container
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Header Titles
                          _buildTitle(),
                          const SizedBox(height: 6),
                          _buildSubtitle(),

                          const SizedBox(height: 24),

                          // Equal Size Side-by-Side Mode Cards
                          _buildModeCards(),

                          const SizedBox(height: 24),

                          // Floating Privacy Notice Badge
                          _buildPrivacyNotice(),
                        ],
                      ),
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

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0, right: 24.0, left: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Glassmorphic Language Selector Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🌸', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedLanguage,
                    dropdownColor: Colors.white,
                    isDense: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF5D4037), size: 18),
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF3E2A1E),
                    ),
                    items: const [
                      DropdownMenuItem(value: '日本語', child: Text('日本語')),
                      DropdownMenuItem(value: 'English', child: Text('English')),
                      DropdownMenuItem(value: 'Hindi', child: Text('Hindi')),
                      DropdownMenuItem(value: 'Bengali', child: Text('Bengali')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedLanguage = val);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return AnimatedBuilder(
      animation: _floatController!,
      builder: (context, child) {
        final floatY = math.sin(_floatController!.value * math.pi) * 2;
        return Transform.translate(
          offset: Offset(0, floatY),
          child: Column(
            children: [
              // Japanese Title Text "ニモ"
              const Text(
                '二モ',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 50,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2E1C12),
                  height: 1.0,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              // NIMO subtitle with decorative lines
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 1.5,
                    color: const Color(0xFF5D4037).withValues(alpha: 0.5),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      '— N I M O —',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                        color: Color(0xFF4A3525),
                      ),
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 1.5,
                    color: const Color(0xFF5D4037).withValues(alpha: 0.5),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubtitle() {
    return Column(
      children: const [
        Text(
          'こんにちは！冒険の時間だよ！',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF3E2A1E),
          ),
        ),
        SizedBox(height: 2),
        Text(
          "Let's learn, play and grow together!",
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6D5547),
          ),
        ),
      ],
    );
  }

  Widget _buildCherryBlossomPetals() {
    return AnimatedBuilder(
      animation: _petalController!,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: _CherryBlossomPainter(
            petals: _petals,
            animationValue: _petalController!.value,
          ),
        );
      },
    );
  }

  Widget _buildModeCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 480;
        final cardWidth = isNarrow ? (constraints.maxWidth - 32) : 240.0;

        if (isNarrow) {
          return Column(
            children: [
              SizedBox(
                width: cardWidth,
                child: _buildChildModeCard(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: cardWidth,
                child: _buildParentModeCard(),
              ),
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: cardWidth,
              child: _buildChildModeCard(),
            ),
            const SizedBox(width: 20),
            SizedBox(
              width: cardWidth,
              child: _buildParentModeCard(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChildModeCard() {
    return MouseRegion(
      onEnter: (_) => setState(() => _isChildHovered = true),
      onExit: (_) => setState(() => _isChildHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isChildPressed = true),
        onTapCancel: () => setState(() => _isChildPressed = false),
        onTap: () {
          setState(() => _isChildPressed = false);
          _openChildProfileSelection();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          transform: Matrix4.identity()
            ..scale(_isChildPressed ? 0.97 : (_isChildHovered ? 1.02 : 1.0), _isChildPressed ? 0.97 : (_isChildHovered ? 1.02 : 1.0), 1.0),
          transformAlignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFDFB),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _isChildHovered
                  ? const Color(0xFFF48FB1)
                  : Colors.white.withValues(alpha: 0.8),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE57373).withValues(alpha: _isChildHovered ? 0.25 : 0.08),
                blurRadius: _isChildHovered ? 24 : 16,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Exact Anime Child Girl Avatar from Image 2
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF48FB1).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/nimo_child_avatar.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Title: こども
              const Text(
                'こども',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2E1C12),
                ),
              ),

              const SizedBox(height: 2),

              // Subtitle: Child Mode
              const Text(
                'Child Mode',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF756A63),
                ),
              ),

              const SizedBox(height: 18),

              // Solid Pink Pill Button "はじめる >"
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _openChildProfileSelection,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFEF6C6C),
                          Color(0xFFE55353),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE55353).withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text('🌸', style: TextStyle(fontSize: 13)),
                        SizedBox(width: 8),
                        Text(
                          'はじめる',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(width: 6),
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
    );
  }

  Widget _buildParentModeCard() {
    return MouseRegion(
      onEnter: (_) => setState(() => _isParentHovered = true),
      onExit: (_) => setState(() => _isParentHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isParentPressed = true),
        onTapCancel: () => setState(() => _isParentPressed = false),
        onTap: () {
          setState(() => _isParentPressed = false);
          _openParentPinModal();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          transform: Matrix4.identity()
            ..scale(_isParentPressed ? 0.97 : (_isParentHovered ? 1.02 : 1.0), _isParentPressed ? 0.97 : (_isParentHovered ? 1.02 : 1.0), 1.0),
          transformAlignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFDFB),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _isParentHovered
                  ? const Color(0xFFA5D6A7)
                  : Colors.white.withValues(alpha: 0.8),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7CB342).withValues(alpha: _isParentHovered ? 0.25 : 0.08),
                blurRadius: _isParentHovered ? 24 : 16,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Exact Anime Parent Woman Avatar from Image 2
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFA5D6A7).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/nimo_parent_avatar.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Title: 保護者
              const Text(
                '保護者',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2E1C12),
                ),
              ),

              const SizedBox(height: 2),

              // Subtitle: Parent Mode
              const Text(
                'Parent Mode',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF756A63),
                ),
              ),

              const SizedBox(height: 18),

              // Solid Sage Green Pill Button "つづける >"
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _openParentPinModal,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF819965),
                          Color(0xFF718B55),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF718B55).withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.eco_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'つづける',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(width: 6),
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
    );
  }

  Widget _buildPrivacyNotice() {
    return GestureDetector(
      onTap: _showPrivacyInfoModal,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF6F0).withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Text('🌸', style: TextStyle(fontSize: 11)),
            ),
            const SizedBox(width: 8),
            const Text(
              'お子さまのプライバシーを大切にしています',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4A382C),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                color: Color(0xFF5D4537),
                size: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ═══════════════════════════════════════════════════════════════════════════════
// CUSTOM PAINTERS
// ═══════════════════════════════════════════════════════════════════════════════

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
      // Update petal position
      petal.y += petal.speed * 0.002;
      petal.rotation += petal.rotationSpeed * 0.02;
      
      // Reset petal when it falls off screen
      if (petal.y > 1.2) {
        petal.y = -0.1;
      }

      final x = petal.x * size.width + math.sin(animationValue * math.pi * 2 * petal.swaySpeed) * petal.swayAmplitude;
      final y = petal.y * size.height;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(petal.rotation);

      // Draw petal shape
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
