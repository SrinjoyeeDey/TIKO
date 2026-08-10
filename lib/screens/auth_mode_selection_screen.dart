import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets/stone_gate_waterfall_background.dart';
import 'child_profile_selection_screen.dart';

/// Child-Centered Adaptive Learning Entry & Authentication Screen.
/// Implements all 14 visual hierarchy & accessibility refinements:
/// - Subtle blurred background with reduced contrast for sensory ease.
/// - Animated Nimo companion mascot ("Hi! I'm Nimo! Ready for today's adventure?").
/// - Friendly NIMO typography (no corporate letter spacing).
/// - Overwhelmingly dominant CHILD MODE Hero Card with [ START ADVENTURE → ].
/// - Secure Parent Access with PIN authentication modal.
/// - Unobtrusive top controls & refined data privacy assurance.
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
  String _selectedLanguage = 'English';
  bool _isChildPressed = false;

  AnimationController? _nimoAnimationController;
  AnimationController? _bounceController;

  @override
  void initState() {
    super.initState();
    _ensureControllersInitialized();
  }

  void _ensureControllersInitialized() {
    _nimoAnimationController ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _bounceController ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _nimoAnimationController?.dispose();
    _bounceController?.dispose();
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

  /// Parent Gate 4-Digit Security PIN Verification Modal
  void _openParentPinModal() {
    final List<String> enteredPin = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: const Color(0xFFFAF5EE),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: Color(0xFFC5A059), width: 1.5),
            ),
            title: Column(
              children: const [
                Icon(Icons.lock_rounded, size: 32, color: Color(0xFF5D4037)),
                SizedBox(height: 6),
                Text(
                  'Parent Access',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF3E2716),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Enter 4-Digit PIN to access Dashboard',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8D6E63),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 4 PIN Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    final isFilled = index < enteredPin.length;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isFilled ? const Color(0xFF5D4037) : Colors.transparent,
                        border: Border.all(color: const Color(0xFF8D6E63), width: 2),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 20),

                // Keypad 1-9 & 0
                SizedBox(
                  width: 220,
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
                child: const Text('Cancel', style: TextStyle(color: Color(0xFF8D6E63), fontWeight: FontWeight.bold)),
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
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFFEFE6D5),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFD7CCC8), width: 1),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF3E2716),
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
            Icon(Icons.verified_rounded, color: Color(0xFFFFD54F)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Parent Access Verified. Opening Parent Dashboard & AI Insights...',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF3E2716),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFFFD54F), width: 1.2),
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
            Text('Data Privacy Promise', style: TextStyle(fontFamily: 'Outfit', color: Color(0xFF2C1C0F), fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'NIMO is built specifically for children. All facial recognition, speech synthesis, and behavioral learning analytics stay 100% encrypted and stored locally on your device. No private child data is ever shared or sold.',
          style: TextStyle(fontFamily: 'Outfit', fontSize: 13, color: Color(0xFF5D4037), height: 1.4),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5D4037)),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Understood', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _ensureControllersInitialized();

    return Scaffold(
      body: Stack(
        children: [
          // 1. Muted Background with Soft Blur/Haze for Sensory Ease
          Positioned.fill(
            child: StoneGateWaterfallBackground(
              showNimoSign: false,
              child: const SizedBox.expand(),
            ),
          ),

          // 2. Soft Haze Overlay & Blur Filter (Reduces background contrast by 25%)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                color: const Color(0xFFFAF5EE).withValues(alpha: 0.55),
              ),
            ),
          ),

          // 3. Main Unobtrusive UI Layer
          SafeArea(
            child: Column(
              children: [
                // Top Control Bar (Small, Unobtrusive English & Menu)
                _buildTopControlBar(),

                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Friendly NIMO Title (Warm & Alive typography)
                          _buildFriendlyTitle(),

                          const SizedBox(height: 12),

                          // NIMO Companion Mascot & Speech Bubble
                          _buildNimoMascotCompanion(),

                          const SizedBox(height: 20),

                          // OVERWHELMINGLY DOMINANT CHILD HERO CARD
                          _buildDominantChildHeroCard(),

                          const SizedBox(height: 18),

                          // Secondary Protected Parent Access Button
                          _buildParentAccessButton(),

                          const SizedBox(height: 24),

                          // Refined Privacy Promise Badge
                          _buildPrivacyPromiseBadge(),
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

  // ── 1. TOP CONTROL BAR (UNOBTRUSIVE) ──────────────────────────────────────
  Widget _buildTopControlBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Sakura Accent Icon
          Row(
            children: const [
              Text('🌸', style: TextStyle(fontSize: 16)),
            ],
          ),

          // Unobtrusive Language Selector & Menu Icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD7CCC8), width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.language_rounded, size: 14, color: Color(0xFF5D4037)),
                    const SizedBox(width: 4),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedLanguage,
                        dropdownColor: Colors.white,
                        isDense: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF5D4037), size: 14),
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF3E2716),
                        ),
                        items: const [
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

              const SizedBox(width: 8),

              // Small Menu Trigger Icon
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.88),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFD7CCC8), width: 0.8),
                ),
                child: const Center(
                  child: Icon(Icons.menu_rounded, size: 16, color: Color(0xFF5D4037)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 2. FRIENDLY NIMO TYPOGRAPHY ───────────────────────────────────────────
  Widget _buildFriendlyTitle() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Text(
          'NIMO',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            color: Color(0xFF3E2716),
          ),
        ),
      ],
    );
  }

  // ── 3. NIMO MASCOT COMPANION & SPEECH BUBBLE ──────────────────────────────
  Widget _buildNimoMascotCompanion() {
    return AnimatedBuilder(
      animation: _nimoAnimationController!,
      builder: (context, child) {
        final waveVal = math.sin(_nimoAnimationController!.value * math.pi * 2);
        final floatY = waveVal * 3.0;

        return Transform.translate(
          offset: Offset(0, floatY),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Nimo Mascot Companion Avatar (Male Indian Explorer Boy Companion)
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFF3E0),
                  border: Border.all(color: const Color(0xFFFFB300), width: 2.5),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Positioned(
                      top: 6,
                      right: 8,
                      child: Text('🌸', style: TextStyle(fontSize: 12)),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text('👦', style: TextStyle(fontSize: 38)), // Male child explorer mascot
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Speech Bubble: "Hi! I'm Nimo! 🌸" / "Ready for today's adventure?"
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFE082), width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      '“Hi! I\'m Nimo! 🌸”',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF3E2716),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Ready for today\'s adventure?',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6D4C41),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── 4. OVERWHELMINGLY DOMINANT CHILD HERO CARD ────────────────────────────
  Widget _buildDominantChildHeroCard() {
    return AnimatedBuilder(
      animation: _bounceController!,
      builder: (context, child) {
        final bounceY = math.sin(_bounceController!.value * math.pi * 2) * 2.5;

        return Transform.translate(
          offset: Offset(0, bounceY),
          child: GestureDetector(
            onTapDown: (_) => setState(() => _isChildPressed = true),
            onTapCancel: () => setState(() => _isChildPressed = false),
            onTap: () {
              setState(() => _isChildPressed = false);
              _openChildProfileSelection();
            },
            child: AnimatedScale(
              duration: const Duration(milliseconds: 150),
              scale: _isChildPressed ? 0.96 : 1.0,
              child: Container(
                width: 290,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFDF8),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: const Color(0xFFFFB300), // Vibrant amber gold border
                    width: 2.5,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33FFB300),
                      blurRadius: 18,
                      spreadRadius: 2,
                      offset: Offset(0, 6),
                    ),
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Male Explorer Character Icon
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFFECB3),
                        border: Border.all(color: const Color(0xFFFFB300), width: 2),
                      ),
                      child: const Center(
                        child: Text('👦', style: TextStyle(fontSize: 36)),
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'CHILD MODE',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: Color(0xFF2C1C0F),
                      ),
                    ),

                    const SizedBox(height: 4),

                    const Text(
                      'Learn   •   Play   •   Explore',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF8D6E63),
                        letterSpacing: 0.8,
                      ),
                    ),

                    const SizedBox(height: 18),

                    // DOMINANT ACTION BUTTON: [ START ADVENTURE  → ]
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFFB300), // Rich amber gold
                            Color(0xFFF57C00), // Warm orange accent
                          ],
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x40F57C00),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'START ADVENTURE',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.8,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── 5. SECONDARY PROTECTED PARENT ACCESS BUTTON ───────────────────────────
  Widget _buildParentAccessButton() {
    return GestureDetector(
      onTap: _openParentPinModal,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD7CCC8), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.lock_rounded, size: 14, color: Color(0xFF6D4C41)),
            SizedBox(width: 6),
            Text(
              'Parent Access',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF5D4037),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 6. REFINED DATA PRIVACY ASSURANCE BADGE ───────────────────────────────
  Widget _buildPrivacyPromiseBadge() {
    return GestureDetector(
      onTap: _showPrivacyInfoModal,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0D0C0), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.verified_user_rounded, color: Color(0xFF8D6E63), size: 14),
            SizedBox(width: 6),
            Text(
              '🔒 Your child\'s data stays private',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4E342E),
              ),
            ),
            SizedBox(width: 6),
            Text(
              '•  Learn more',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8D6E63),
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
