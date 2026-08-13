import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/india_states_data.dart';
import '../data/india_map_data.dart';
import '../widgets/wooden_back_button.dart';

import 'story_map_screen.dart';
import 'onboarding_screen.dart';
import 'state_story_collection_screen.dart';
import 'horizontal_ground_map_screen.dart';
import '../journey/widgets/proceed_button.dart';
import '../services/app_asset_preloader.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EXPLORE INDIA SCREEN (Red Pin & Ultra-Smooth Leisurely Animations)
// ─────────────────────────────────────────────────────────────────────────────
class ExploreIndiaScreen extends StatefulWidget {
  final bool isIntroJourney;
  final String? initialStateId;

  const ExploreIndiaScreen({
    super.key,
    this.isIntroJourney = false,
    this.initialStateId,
  });

  @override
  State<ExploreIndiaScreen> createState() => _ExploreIndiaScreenState();
}

class _ExploreIndiaScreenState extends State<ExploreIndiaScreen>
    with TickerProviderStateMixin {
  String? _selectedStateId;
  String? _previousSelectedStateId;
  String? _hoveredStateId;

  // Ultra-Smooth Card Slide/Fade animation (600ms leisurely ease)
  late final AnimationController _cardAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  late final Animation<double> _cardFade =
      CurvedAnimation(parent: _cardAnim, curve: Curves.easeInOutCubic);
  late final Animation<Offset> _cardSlide =
      Tween<Offset>(begin: const Offset(0.10, 0), end: Offset.zero)
          .animate(CurvedAnimation(parent: _cardAnim, curve: Curves.easeInOutCubic));
  late final Animation<double> _cardScale = Tween<double>(begin: 0.95, end: 1.0)
      .animate(CurvedAnimation(parent: _cardAnim, curve: Curves.easeInOutCubic));

  // Smooth State Color Interpolation animation (500ms smooth morph)
  late final AnimationController _colorAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  late final Animation<double> _colorProgress =
      CurvedAnimation(parent: _colorAnim, curve: Curves.easeInOut);

  // Pin bounce animation (800ms gentle spring drop)
  late final AnimationController _pinAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );
  late final Animation<double> _pinBounce = Tween<double>(begin: -22, end: 0)
      .animate(CurvedAnimation(parent: _pinAnim, curve: Curves.bounceOut));

  // Continuous Soft Red Pulse Wave under Pin (1800ms pulse)
  late final AnimationController _pulseAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
  late final Animation<double> _pulseScale = Tween<double>(begin: 0.5, end: 2.0)
      .animate(CurvedAnimation(parent: _pulseAnim, curve: Curves.easeOut));
  late final Animation<double> _pulseOpacity = Tween<double>(begin: 0.8, end: 0.0)
      .animate(CurvedAnimation(parent: _pulseAnim, curve: Curves.easeOut));

  @override
  void initState() {
    super.initState();
    _pulseAnim.repeat();
    // STEP 3 & 14: Always reset selection to clean neutral state on entry
    _selectedStateId = null;
    _previousSelectedStateId = null;
    _hoveredStateId = null;
  }

  @override
  void dispose() {
    _cardAnim.dispose();
    _colorAnim.dispose();
    _pinAnim.dispose();
    _pulseAnim.dispose();
    super.dispose();
  }

  void _proceedToStoryMap() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const StoryMapScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  void _openStateStories(String stateId) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            StateStoryCollectionScreen(stateId: stateId),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _safePop() {
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
  }

  void _selectState(String stateId) {
    if (_selectedStateId == stateId) return;

    // Instantly trigger parallel staged asset precaching for selected state stories
    AppAssetPreloader.precacheStateAssets(context, stateId);

    setState(() {
      _previousSelectedStateId = _selectedStateId;
      _selectedStateId = stateId;
    });

    _cardAnim.forward(from: 0.0);
    _colorAnim.forward(from: 0.0);
    _pinAnim.forward(from: 0.0);
  }

  void _clearSelection() {
    _colorAnim.reverse();
    _cardAnim.reverse().then((_) {
      if (mounted) {
        setState(() {
          _previousSelectedStateId = null;
          _selectedStateId = null;
        });
      }
    });
  }

  void _navigatePrev() {
    final target = _selectedStateId == null
        ? IndiaStatesDatabase.stateOrder.last
        : IndiaStatesDatabase.getPreviousStateId(_selectedStateId!) ??
            IndiaStatesDatabase.stateOrder.last;
    _selectState(target);
  }

  void _navigateNext() {
    final target = _selectedStateId == null
        ? IndiaStatesDatabase.stateOrder.first
        : IndiaStatesDatabase.getNextStateId(_selectedStateId!) ??
            IndiaStatesDatabase.stateOrder.first;
    _selectState(target);
  }

  void _playStateAudio(IndiaStateData data) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.volume_up_rounded, color: Color(0xFFFFD54F)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${data.name}. Capital: ${data.capital}. Language: ${data.language}.',
                style: const TextStyle(fontWeight: FontWeight.w600),
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

  @override
  Widget build(BuildContext context) {
    final selectedData = _selectedStateId != null
        ? IndiaStatesDatabase.getState(_selectedStateId!)
        : null;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFCEBE9C), Color(0xFFBCAA84), Color(0xFFA89770)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      child: LayoutBuilder(builder: (ctx, constraints) {
                        return _buildMainLayout(constraints, selectedData);
                      }),
                    ),
                  ),
                  _buildBottomBar(),
                ],
              ),
            ),
          ),

          // Intro Journey Floating PROCEED Button Overlay
          if (widget.isIntroJourney)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: ProceedButton(
                  label: 'PROCEED  →',
                  onTap: _proceedToStoryMap,
                  isVisible: true,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── HEADER (Compact Wood Header) ──────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 6, 10, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF3D2716),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFB8860B), width: 1.8),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          WoodenBackButton(size: 36, onTap: _safePop),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'EXPLORE INDIA',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.5,
                    color: Color(0xFFFFF176),
                    shadows: [
                      Shadow(
                          color: Colors.black54,
                          offset: Offset(1, 2),
                          blurRadius: 3),
                    ],
                  ),
                ),
                Text(
                  'Tap any state to learn more',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFE8C98A),
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
          _PressableIconButton(
            onTap: () {
              Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      HorizontalGroundMapScreen(initialStateId: _selectedStateId),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                      FadeTransition(opacity: animation, child: child),
                  transitionDuration: const Duration(milliseconds: 500),
                ),
              );
            },
            icon: Icons.view_in_ar_rounded,
            active: true,
            size: 36,
            iconSize: 18,
          ),
          const SizedBox(width: 6),
          _PressableIconButton(
            onTap: () {
              if (_selectedStateId != null) {
                final d = IndiaStatesDatabase.getState(_selectedStateId!);
                if (d != null) _playStateAudio(d);
              }
            },
            icon: Icons.volume_up_rounded,
            active: _selectedStateId != null,
            size: 36,
            iconSize: 18,
          ),
        ],
      ),
    );
  }

  // ── MAIN LAYOUT (Map ALWAYS 100% full size, Compact Card in Bay of Bengal)
  Widget _buildMainLayout(BoxConstraints c, IndiaStateData? data) {
    final isWide = c.maxWidth >= 700;

    return Stack(
      children: [
        // 1. Map Container (100% Full Canvas Size, Isolated in RepaintBoundary)
        Positioned.fill(
          child: RepaintBoundary(
            child: _buildMapArea(),
          ),
        ),

        // 2. Floating Info Card positioned at bottom-right (Bay of Bengal ocean space)
        if (data != null)
          Positioned(
            bottom: 10,
            right: 10,
            width: isWide
                ? math.min(290, c.maxWidth * 0.34)
                : math.min(270, c.maxWidth - 20),
            child: _buildStateInfoCard(data, c.maxHeight - 20),
          ),
      ],
    );
  }

  // ── MAP AREA ───────────────────────────────────────────────────────────────
  Widget _buildMapArea() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFF8B6914).withValues(alpha: 0.6), width: 1.8),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 10, offset: Offset(0, 5)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            // Interactive Map Widget (Always 100% Full Canvas Size)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _pinBounce,
                  _colorProgress,
                  _pulseAnim,
                ]),
                builder: (context, _) {
                  return _IndiaMapWidget(
                    selectedStateId: _selectedStateId,
                    previousSelectedStateId: _previousSelectedStateId,
                    hoveredStateId: _hoveredStateId,
                    colorProgress: _colorProgress.value,
                    pinBounce: _pinBounce.value,
                    pulseScale: _pulseScale.value,
                    pulseOpacity: _pulseOpacity.value,
                    onStateHover: (id) {
                      if (_hoveredStateId != id) {
                        setState(() => _hoveredStateId = id);
                      }
                    },
                    onStateSelected: (id) {
                      if (id != null) _selectState(id);
                    },
                  );
                },
              ),
            ),

            // Antique Compass in upper right
            Positioned(
              top: 10,
              right: 10,
              child: SizedBox(
                width: 52,
                height: 52,
                child: CustomPaint(painter: _CompassPainter()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── STATE INFO CARD (Smooth 600ms Ease Slide) ─────────────────────────────
  Widget _buildStateInfoCard(IndiaStateData data, double maxAllowedHeight) {
    return FadeTransition(
      opacity: _cardFade,
      child: SlideTransition(
        position: _cardSlide,
        child: ScaleTransition(
          scale: _cardScale,
          child: Container(
            constraints: BoxConstraints(maxHeight: maxAllowedHeight),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F4E8), // Warm parchment cream
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF8B6914), width: 1.4),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black38,
                    blurRadius: 12,
                    offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Bar (Tight padding, NO extra whitespace)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE2D5B4), width: 1.0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: FittedBox(
                            key: ValueKey(data.id),
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              data.name,
                              maxLines: 1,
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF3E2716),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _PressableIconButton(
                        onTap: () => _playStateAudio(data),
                        icon: Icons.volume_up_rounded,
                        active: true,
                        size: 28,
                        iconSize: 15,
                        bgColor: const Color(0xFF3D2716),
                        iconColor: const Color(0xFFFFD54F),
                      ),
                      const SizedBox(width: 4),
                      _PressableIconButton(
                        onTap: _clearSelection,
                        icon: Icons.close_rounded,
                        active: true,
                        size: 28,
                        iconSize: 15,
                        bgColor: const Color(0xFF3D2716),
                        iconColor: const Color(0xFFD7CCC8),
                      ),
                    ],
                  ),
                ),

                // Card Content Body
                Flexible(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: SingleChildScrollView(
                      key: ValueKey(data.id),
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildLandmarkIllustration(data),
                          const SizedBox(height: 6),
                          _buildInfoTile(
                            icon: Icons.location_city_rounded,
                            label: 'Capital',
                            value: data.capital,
                            onAudio: () => _playStateAudio(data),
                          ),
                          const SizedBox(height: 4),
                          _buildInfoTile(
                            icon: Icons.chat_bubble_outline_rounded,
                            label: 'Language',
                            value: data.language,
                            onAudio: () => _playStateAudio(data),
                          ),
                          const SizedBox(height: 4),
                          _buildInfoTile(
                            icon: Icons.star_rounded,
                            label: 'Famous For',
                            value: data.famousFor,
                            onAudio: () => _playStateAudio(data),
                          ),
                          const SizedBox(height: 4),
                          _buildInfoTile(
                            icon: Icons.restaurant_rounded,
                            label: 'Food',
                            value: data.food,
                            onAudio: () => _playStateAudio(data),
                          ),
                          const SizedBox(height: 4),
                          _buildDidYouKnowTile(data.fact),
                          const SizedBox(height: 10),

                          // Step 4: Thematic "LET'S EXPLORE" Discovery Button
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _openStateStories(data.id),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFEF6C6C),
                                      Color(0xFFE55353),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFE55353).withValues(alpha: 0.4),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Text('🌸', style: TextStyle(fontSize: 13)),
                                    SizedBox(width: 6),
                                    Text(
                                      "LET'S EXPLORE",
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: Colors.white,
                                      size: 18,
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLandmarkIllustration(IndiaStateData data) {
    return Container(
      width: double.infinity,
      height: 65,
      decoration: BoxDecoration(
        color: const Color(0xFFEFE5CC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD6C4A0), width: 1.0),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(double.infinity, 65),
            painter: _IllustrationBgPainter(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(data.illustrationIcon,
                  size: 26, color: const Color(0xFF5D3A1A)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  data.illustrationDesc,
                  textAlign: TextAlign.left,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5D3A1A),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onAudio,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1E8D2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2D5B4), width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF3D2716),
            ),
            child: Icon(icon, size: 12, color: const Color(0xFFFFD54F)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 8.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8B6914),
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2C1C0F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDidYouKnowTile(String fact) {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: const Color(0xFFF1E8D2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2D5B4), width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF3D2716),
            ),
            child: const Icon(Icons.lightbulb_rounded,
                size: 12, color: Color(0xFFFFD54F)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Did You Know?',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF8B6914),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  fact,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2C1C0F),
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── BOTTOM BAR (Compact Height) ───────────────────────────────────────────
  Widget _buildBottomBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 4, 10, 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF3D2716),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFB8860B), width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          _PressableNavButton(
            icon: Icons.chevron_left_rounded,
            label: 'Previous State',
            onTap: _navigatePrev,
            iconLeft: true,
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.touch_app_rounded,
                    size: 14, color: Color(0xFFE8C98A)),
                SizedBox(width: 6),
                Text(
                  'Tap a state to explore',
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
          ),
          _PressableNavButton(
            icon: Icons.chevron_right_rounded,
            label: 'Next State',
            onTap: _navigateNext,
            iconLeft: false,
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// PRESSABLE BUTTON WIDGETS WITH MICRO-SCALE FEEDBACK
// ═════════════════════════════════════════════════════════════════════════════
class _PressableIconButton extends StatefulWidget {
  final VoidCallback onTap;
  final IconData icon;
  final bool active;
  final double size;
  final double iconSize;
  final Color? bgColor;
  final Color? iconColor;

  const _PressableIconButton({
    required this.onTap,
    required this.icon,
    this.active = true,
    this.size = 36,
    this.iconSize = 18,
    this.bgColor,
    this.iconColor,
  });

  @override
  State<_PressableIconButton> createState() => _PressableIconButtonState();
}

class _PressableIconButtonState extends State<_PressableIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.bgColor ?? const Color(0xFF5D3A1A),
            border: Border.all(color: const Color(0xFFB8860B), width: 1.2),
          ),
          child: Icon(
            widget.icon,
            size: widget.iconSize,
            color: widget.iconColor ??
                (widget.active
                    ? const Color(0xFFFFD54F)
                    : const Color(0xFF8D6E53)),
          ),
        ),
      ),
    );
  }
}

class _PressableNavButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool iconLeft;

  const _PressableNavButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.iconLeft,
  });

  @override
  State<_PressableNavButton> createState() => _PressableNavButtonState();
}

class _PressableNavButtonState extends State<_PressableNavButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF5D3A1A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFB8860B), width: 1.2),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.iconLeft)
                Icon(widget.icon, size: 16, color: const Color(0xFFFFD54F)),
              Text(
                widget.label,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFFD54F),
                ),
              ),
              if (!widget.iconLeft)
                Icon(widget.icon, size: 16, color: const Color(0xFFFFD54F)),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// INTERACTIVE INDIA MAP WIDGET
// ═════════════════════════════════════════════════════════════════════════════
class _IndiaMapWidget extends StatelessWidget {
  final String? selectedStateId;
  final String? previousSelectedStateId;
  final String? hoveredStateId;
  final double colorProgress;
  final double pinBounce;
  final double pulseScale;
  final double pulseOpacity;
  final ValueChanged<String?> onStateHover;
  final ValueChanged<String?> onStateSelected;

  const _IndiaMapWidget({
    required this.selectedStateId,
    required this.previousSelectedStateId,
    required this.hoveredStateId,
    required this.colorProgress,
    required this.pinBounce,
    required this.pulseScale,
    required this.pulseOpacity,
    required this.onStateHover,
    required this.onStateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      return MouseRegion(
        onHover: (event) {
          String? hit;
          for (final st in IndiaMapData.states) {
            if (st.containsPoint(event.localPosition, size)) {
              hit = st.id;
              break;
            }
          }
          onStateHover(hit);
        },
        onExit: (_) => onStateHover(null),
        child: GestureDetector(
          onTapUp: (details) {
            String? hit;
            for (final st in IndiaMapData.states) {
              if (st.containsPoint(details.localPosition, size)) {
                hit = st.id;
                break;
              }
            }
            onStateSelected(hit);
          },
          child: CustomPaint(
            size: size,
            painter: _IndiaMapPainter(
              states: IndiaMapData.states,
              selectedStateId: selectedStateId,
              previousSelectedStateId: previousSelectedStateId,
              hoveredStateId: hoveredStateId,
              colorProgress: colorProgress,
              pinBounce: pinBounce,
              pulseScale: pulseScale,
              pulseOpacity: pulseOpacity,
            ),
          ),
        ),
      );
    });
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// INDIA MAP PAINTER — Crimson Red Location Pin & Smooth Curves
// ═════════════════════════════════════════════════════════════════════════════
class _IndiaMapPainter extends CustomPainter {
  final List<IndiaStatePath> states;
  final String? selectedStateId;
  final String? previousSelectedStateId;
  final String? hoveredStateId;
  final double colorProgress;
  final double pinBounce;
  final double pulseScale;
  final double pulseOpacity;

  _IndiaMapPainter({
    required this.states,
    required this.selectedStateId,
    required this.previousSelectedStateId,
    required this.hoveredStateId,
    required this.colorProgress,
    required this.pinBounce,
    required this.pulseScale,
    required this.pulseOpacity,
  });

  static const List<Color> _palette = [
    Color(0xFFD8C9A5), Color(0xFFC9C7A5), Color(0xFFBFC5A8),
    Color(0xFFD0CBAD), Color(0xFFC8BEA0), Color(0xFFD1C9AB),
    Color(0xFFCDC4A4), Color(0xFFD0C8AA), Color(0xFFCEC2A2),
    Color(0xFFD4CAA8), Color(0xFFCABF9E), Color(0xFFD2C5A6),
    Color(0xFFD6CEA8), Color(0xFFCBC1A1), Color(0xFFD0C6A4),
  ];

  Color _stateBase(int idx) => _palette[idx % _palette.length];

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Parchment background
    _drawParchmentBackground(canvas, size);

    // 2. Ocean water
    _drawOcean(canvas, size);

    // 3. Himalayan mountains
    _drawMountains(canvas, size);

    // 4. State fills
    for (int i = 0; i < states.length; i++) {
      final st = states[i];
      final path = st.buildPath(size);
      final isSelected = st.id == selectedStateId;
      final wasSelected = st.id == previousSelectedStateId && !isSelected;
      final isHovered = st.id == hoveredStateId && !isSelected;

      final baseColor = _stateBase(i);
      final hoverColor = const Color(0xFFE0D2A8);
      final goldColor = const Color(0xFFD4A843);

      Color fillColor = baseColor;
      if (isSelected) {
        fillColor = Color.lerp(baseColor, goldColor, colorProgress)!;
      } else if (wasSelected) {
        fillColor = Color.lerp(goldColor, baseColor, colorProgress)!;
      } else if (isHovered) {
        fillColor = hoverColor;
      }

      if (isSelected) {
        canvas.drawPath(
          path.shift(const Offset(3, 4)),
          Paint()
            ..color = const Color(0xFF8B6914).withValues(alpha: 0.40 * colorProgress)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
      }

      canvas.drawPath(path, Paint()..color = fillColor);

      if (!isSelected) {
        canvas.drawPath(
          path,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.14)
            ..style = PaintingStyle.fill,
        );
      }

      final borderColor = isSelected
          ? Color.lerp(const Color(0xFF7B5B2A), const Color(0xFFB8860B), colorProgress)!
          : const Color(0xFF7B5B2A).withValues(alpha: 0.65);

      canvas.drawPath(
        path,
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected ? (1.0 + 1.2 * colorProgress) : 0.85
          ..strokeJoin = StrokeJoin.round,
      );

      if (isHovered) {
        canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0xFF8B6914).withValues(alpha: 0.70)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6,
        );
      }
    }

    // 5. State labels
    for (int i = 0; i < states.length; i++) {
      final st = states[i];
      _drawLabel(canvas, size, st, st.id == selectedStateId);
    }

    // 6. VIBRANT RED Location Pin & Red Pulse Wave
    if (selectedStateId != null) {
      final selSt = states.firstWhere(
        (s) => s.id == selectedStateId,
        orElse: () => states[0],
      );
      final px = selSt.labelPos.dx * size.width;
      final py = selSt.labelPos.dy * size.height - 24 + pinBounce;
      _drawRedPulseAndPin(canvas, Offset(px, py));
    }
  }

  void _drawParchmentBackground(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          colors: const [Color(0xFFC8B88A), Color(0xFFBBAA7C), Color(0xFFB0A070)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Offset.zero & size),
    );

    final rng = math.Random(1337);
    for (int i = 0; i < 50; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = rng.nextDouble() * 24 + 8;
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()
          ..color = const Color(0xFF8B6914).withValues(alpha: 0.04)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.85,
          colors: [
            Colors.transparent,
            const Color(0xFF5D3A1A).withValues(alpha: 0.18),
          ],
        ).createShader(Offset.zero & size),
    );
  }

  void _drawOcean(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, w * 0.06, h),
      Paint()
        ..color = const Color(0xFFB8C4BE).withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    canvas.drawRect(
      Rect.fromLTWH(w * 0.70, 0, w * 0.30, h),
      Paint()
        ..color = const Color(0xFFB0BCBA).withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.72, w, h * 0.28),
      Paint()
        ..color = const Color(0xFFB4C2BE).withValues(alpha: 0.30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );
  }

  void _drawMountains(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final mtPaint = Paint()
      ..color = const Color(0xFF8E9AAA).withValues(alpha: 0.28)
      ..style = PaintingStyle.fill;

    final far = Path();
    far.moveTo(w * 0.05, h * 0.22);
    far.lineTo(w * 0.10, h * 0.08);
    far.lineTo(w * 0.16, h * 0.15);
    far.lineTo(w * 0.22, h * 0.04);
    far.lineTo(w * 0.28, h * 0.12);
    far.lineTo(w * 0.35, h * 0.03);
    far.lineTo(w * 0.42, h * 0.10);
    far.lineTo(w * 0.50, h * 0.05);
    far.lineTo(w * 0.58, h * 0.12);
    far.lineTo(w * 0.66, h * 0.06);
    far.lineTo(w * 0.75, h * 0.14);
    far.lineTo(w * 0.82, h * 0.07);
    far.lineTo(w * 0.90, h * 0.15);
    far.lineTo(w, h * 0.18);
    far.lineTo(w, 0);
    far.lineTo(0, 0);
    far.close();
    canvas.drawPath(far, mtPaint);

    final near = Path();
    near.moveTo(w * 0.05, h * 0.20);
    near.lineTo(w * 0.12, h * 0.11);
    near.lineTo(w * 0.20, h * 0.17);
    near.lineTo(w * 0.28, h * 0.08);
    near.lineTo(w * 0.35, h * 0.15);
    near.lineTo(w * 0.44, h * 0.09);
    near.lineTo(w * 0.52, h * 0.16);
    near.lineTo(w * 0.60, h * 0.10);
    near.lineTo(w * 0.68, h * 0.18);
    near.lineTo(w * 0.78, h * 0.12);
    near.lineTo(w * 0.88, h * 0.19);
    near.lineTo(w, h * 0.23);
    near.lineTo(w, 0);
    near.lineTo(0, 0);
    near.close();
    canvas.drawPath(
      near,
      Paint()
        ..color = const Color(0xFF7E8C9A).withValues(alpha: 0.22)
        ..style = PaintingStyle.fill,
    );

    _drawSnowCap(canvas, w * 0.10, h * 0.08, w * 0.04, h * 0.04);
    _drawSnowCap(canvas, w * 0.22, h * 0.04, w * 0.04, h * 0.04);
    _drawSnowCap(canvas, w * 0.35, h * 0.03, w * 0.04, h * 0.03);
    _drawSnowCap(canvas, w * 0.50, h * 0.05, w * 0.03, h * 0.03);
    _drawSnowCap(canvas, w * 0.66, h * 0.06, w * 0.04, h * 0.04);
    _drawSnowCap(canvas, w * 0.82, h * 0.07, w * 0.04, h * 0.04);
  }

  void _drawSnowCap(
      Canvas canvas, double cx, double peakY, double hw, double hh) {
    final p = Path()
      ..moveTo(cx - hw * 0.4, peakY + hh * 0.6)
      ..lineTo(cx, peakY)
      ..lineTo(cx + hw * 0.4, peakY + hh * 0.6)
      ..close();
    canvas.drawPath(
      p,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.40)
        ..style = PaintingStyle.fill,
    );
  }

  void _drawLabel(
      Canvas canvas, Size size, IndiaStatePath st, bool isSelected) {
    final data = IndiaStatesDatabase.states[st.id];
    if (data == null) return;

    final bounds = st.buildPath(size).getBounds();
    if (bounds.width < 16 || bounds.height < 12) return;

    final name = _shortName(data.name);
    final pos =
        Offset(st.labelPos.dx * size.width, st.labelPos.dy * size.height);
    final fontSize = isSelected
        ? 9.5
        : bounds.width < 30
            ? 7.0
            : 8.2;

    final tp = TextPainter(
      text: TextSpan(
        text: name,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: fontSize,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          color: isSelected
              ? const Color(0xFF2C1C0F)
              : const Color(0xFF3E2716).withValues(alpha: 0.90),
          shadows: const [
            Shadow(
                color: Color(0x88FFEFCA), offset: Offset(0, 1), blurRadius: 2)
          ],
          height: 1.15,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: bounds.width + 22);

    tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
  }

  String _shortName(String name) {
    const Map<String, String> abbrev = {
      'Andhra Pradesh': 'Andhra\nPradesh',
      'Arunachal Pradesh': 'Arunachal\nPradesh',
      'Himachal Pradesh': 'Himachal\nPradesh',
      'Jammu & Kashmir': 'Jammu &\nKashmir',
      'Madhya Pradesh': 'Madhya\nPradesh',
      'Uttar Pradesh': 'Uttar\nPradesh',
      'West Bengal': 'West\nBengal',
      'Tamil Nadu': 'Tamil\nNadu',
    };
    return abbrev[name] ?? name;
  }

  // ── VIBRANT RED LOCATION PIN & PULSE WAVE ──────────────────────────────────
  void _drawRedPulseAndPin(Canvas canvas, Offset pos) {
    const pinW = 15.0;
    const pinH = 22.0;
    const r = pinW / 2;
    final groundPos = pos + const Offset(0, pinH + 2);

    // 1. Expanding Red Pulse Wave
    canvas.drawOval(
      Rect.fromCenter(
          center: groundPos,
          width: 16 * pulseScale,
          height: 7 * pulseScale),
      Paint()
        ..color = const Color(0xFFFF5252).withValues(alpha: pulseOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );

    // 2. Ground Shadow
    canvas.drawOval(
      Rect.fromCenter(center: groundPos, width: 14, height: 4.5),
      Paint()..color = Colors.black.withValues(alpha: 0.32),
    );

    // 3. Vibrant Crimson Red Pin Body
    final pinPath = Path()
      ..moveTo(pos.dx, pos.dy + pinH)
      ..arcTo(
          Rect.fromCenter(
              center: pos + const Offset(0, r), width: pinW, height: pinW),
          math.pi / 2 + 0.4,
          2 * math.pi - 0.8,
          false)
      ..close();

    // Red Gradient Fill
    canvas.drawPath(
      pinPath,
      Paint()
        ..shader = LinearGradient(
          colors: const [
            Color(0xFFFF5252), // Bright Red Top
            Color(0xFFD32F2F), // Crimson Red Middle
            Color(0xFF8E0000), // Dark Red Bottom
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(
            Rect.fromCenter(center: pos, width: pinW, height: pinH)),
    );

    // Pin Outline
    canvas.drawPath(
      pinPath,
      Paint()
        ..color = const Color(0xFF5D0000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );

    // Inner White Center Dot
    canvas.drawCircle(
      pos + const Offset(0, r - 1),
      3.8,
      Paint()..color = Colors.white,
    );

    // Inner Center Dot Border
    canvas.drawCircle(
      pos + const Offset(0, r - 1),
      3.8,
      Paint()
        ..color = const Color(0xFF8E0000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  @override
  bool shouldRepaint(covariant _IndiaMapPainter old) => true;
}

// ═════════════════════════════════════════════════════════════════════════════
// COMPASS PAINTER
// ═════════════════════════════════════════════════════════════════════════════
class _CompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(cx, cy) - 2;

    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..shader = RadialGradient(
          colors: const [Color(0xFFE8D5A0), Color(0xFFB8860B)],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r)),
    );
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..color = const Color(0xFF6B4226)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );

    canvas.drawCircle(
      Offset(cx, cy),
      r * 0.66,
      Paint()..color = const Color(0xFFF5EDD8),
    );
    canvas.drawCircle(
      Offset(cx, cy),
      r * 0.66,
      Paint()
        ..color = const Color(0xFF8B6914).withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final inner = r * 0.72;
      final outer = r * 0.84;
      canvas.drawLine(
        Offset(cx + inner * math.cos(angle), cy + inner * math.sin(angle)),
        Offset(cx + outer * math.cos(angle), cy + outer * math.sin(angle)),
        Paint()..color = const Color(0xFF8B6914)..strokeWidth = 1.0,
      );
    }

    _label(canvas, 'N', cx, cy - r * 0.84, 8.5, const Color(0xFF8B1C1C));
    _label(canvas, 'S', cx, cy + r * 0.84, 7.5, const Color(0xFF3D2716));
    _label(canvas, 'E', cx + r * 0.84, cy, 7.5, const Color(0xFF3D2716));
    _label(canvas, 'W', cx - r * 0.84, cy, 7.5, const Color(0xFF3D2716));

    final northArrow = Path()
      ..moveTo(cx, cy - r * 0.58)
      ..lineTo(cx - 4, cy)
      ..lineTo(cx + 4, cy)
      ..close();
    canvas.drawPath(northArrow, Paint()..color = const Color(0xFF8B1C1C));

    final southArrow = Path()
      ..moveTo(cx, cy + r * 0.58)
      ..lineTo(cx - 4, cy)
      ..lineTo(cx + 4, cy)
      ..close();
    canvas.drawPath(
        southArrow, Paint()..color = const Color(0xFF8B6914).withValues(alpha: 0.8));

    canvas.drawCircle(Offset(cx, cy), 3.0, Paint()..color = const Color(0xFF3D2716));
  }

  void _label(Canvas canvas, String text, double x, double y, double fs,
      Color color) {
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: fs,
              fontWeight: FontWeight.w900,
              color: color)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _IllustrationBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFEAD8B8), Color(0xFFD6C4A0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Offset.zero & size),
    );
    final linePaint = Paint()
      ..color = const Color(0xFF8B6914).withValues(alpha: 0.12)
      ..strokeWidth = 0.8;
    for (double y = 0; y < size.height; y += 7) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
