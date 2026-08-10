import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../data/west_bengal_stories_database.dart';
import '../models/interactive_story_models.dart';
import 'interactive_story_screen.dart';

/// 80s Showa Retro Worn Explorer Postcard Carousel Screen
/// Features:
/// - Increased spacing between cards (`viewportFraction: 0.46`)
/// - Significantly wider featured center card (295w x 355h)
/// - Dull black & white desaturated side cards -> Bright vibrant color center card
/// - Working carousel navigation arrows (< and >) and mouse/touch drag
/// - Worn, tea-stained 80s Showa vintage paper edges
class StateStoryCollectionScreen extends StatefulWidget {
  final String stateId;

  const StateStoryCollectionScreen({
    super.key,
    required this.stateId,
  });

  @override
  State<StateStoryCollectionScreen> createState() => _StateStoryCollectionScreenState();
}

class _StateStoryCollectionScreenState extends State<StateStoryCollectionScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late final StateStoriesCollection _collection;
  int _selectedStoryIndex = 1; // Default center featured story
  int? _animatingIndex;
  bool _isTransitioningToStory = false;

  // Interactive 3D Drag Tilt State
  double _tiltX = 0.0;
  double _tiltY = 0.0;

  // Grayscale Color Matrix for Dull Black & White Side Cards
  static const List<double> _grayscaleMatrix = [
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0,      0,      0,      1, 0,
  ];

  @override
  void initState() {
    super.initState();
    _collection = IndianStoriesDatabase.getCollectionForState(widget.stateId)!;
    _pageController = PageController(
      viewportFraction: 0.46, // Increased spacing between cards
      initialPage: _selectedStoryIndex.clamp(0, _collection.stories.length - 1),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Scrolls one story to the left (prev). Returns true if a scroll happened,
  /// false if already at the first story (used by press-&-hold repeat scrolling).
  bool _scrollPrev() {
    if (_selectedStoryIndex > 0) {
      final targetPage = _selectedStoryIndex - 1;
      setState(() => _selectedStoryIndex = targetPage);
      _pageController.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
      return true;
    }
    return false;
  }

  /// Scrolls one story to the right (next). Returns true if a scroll happened,
  /// false if already at the last story (used by press-&-hold repeat scrolling).
  bool _scrollNext() {
    if (_selectedStoryIndex < _collection.stories.length - 1) {
      final targetPage = _selectedStoryIndex + 1;
      setState(() => _selectedStoryIndex = targetPage);
      _pageController.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
      return true;
    }
    return false;
  }

  void _onCardTap(int index) async {
    if (_selectedStoryIndex != index) {
      setState(() => _selectedStoryIndex = index);
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
      return;
    }

    if (_isTransitioningToStory) return;

    setState(() {
      _animatingIndex = index;
      _isTransitioningToStory = true;
    });

    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    final selectedStory = _collection.stories[index];

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            InteractiveStoryScreen(story: selectedStory),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 450),
      ),
    ).then((_) {
      if (mounted) {
        setState(() {
          _animatingIndex = null;
          _isTransitioningToStory = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeStory = _collection.stories[_selectedStoryIndex.clamp(0, _collection.stories.length - 1)];

    return Scaffold(
      backgroundColor: const Color(0xFFC5AE79),
      body: Stack(
        children: [
          // 1. GENERATED WEST BENGAL HISTORY MAP BACKGROUND (Isolated in RepaintBoundary, Cache-Optimized)
          Positioned.fill(
            child: RepaintBoundary(
              child: Image.asset(
                'assets/images/story_selection_wb_bg.png',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                cacheWidth: 1280,
                errorBuilder: (ctx, err, stack) => Image.asset(
                  'assets/images/nimo_japanese_bg_clean.png',
                  fit: BoxFit.cover,
                  cacheWidth: 1280,
                ),
              ),
            ),
          ),

          // 2. Soft 80s Showa Darkened Sepia Vignette Overlay
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.95,
                    colors: [
                      Colors.transparent,
                      const Color(0xFF2E1C12).withValues(alpha: 0.25),
                      const Color(0xFF1E100A).withValues(alpha: 0.55),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Top-Left Back to Map Button
          Positioned(
            top: 14,
            left: 16,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF4EE),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF8B6914), width: 1.2),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                ),
                child: Row(
                  children: const [
                    Icon(Icons.arrow_back_ios_new_rounded, size: 13, color: Color(0xFF3E2A1E)),
                    SizedBox(width: 6),
                    Text(
                      'Map',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF3E2A1E),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Main Layout Content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 6),

                // Top 80s Showa Folded Ribbon Banner: "WHERE ARE U GOING?"
                _buildFoldedRibbonHeader(),

                const SizedBox(height: 12),

                // HORIZONTALLY SCROLLABLE CAROUSEL (Touch, Mouse, Trackpad & Working Arrow Buttons)
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Scrollable PageView Carousel
                      ScrollConfiguration(
                        behavior: _MouseAndTouchScrollBehavior(),
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: _collection.stories.length,
                          onPageChanged: (idx) => setState(() => _selectedStoryIndex = idx),
                          itemBuilder: (context, index) {
                            final story = _collection.stories[index];
                            final isAnimating = _animatingIndex == index;

                            return AnimatedBuilder(
                              animation: _pageController,
                              builder: (context, child) {
                                double dist = 0.0;
                                if (_pageController.hasClients && _pageController.page != null) {
                                  dist = _pageController.page! - index;
                                  dist = (1 - (dist.abs() * 0.25)).clamp(0.0, 1.0);
                                } else {
                                  dist = index == _selectedStoryIndex ? 1.0 : 0.70;
                                }

                                final isSelected = index == _selectedStoryIndex;
                                // Center card expands to scale 1.25x (wider & commanding)
                                final scale = isAnimating ? 1.28 : (0.78 + (dist * 0.22));

                                // 80s Worn Tilt Angles: Left -0.04 rad, Right +0.04 rad
                                double rotation = 0.0;
                                if (index < _selectedStoryIndex) rotation = -0.04;
                                if (index > _selectedStoryIndex) rotation = 0.04;

                                return Transform.scale(
                                  scale: scale,
                                  child: Transform.rotate(
                                    angle: rotation,
                                    child: _buildPostcardStampCard(story, index, isSelected, isAnimating),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),

                      // Left Carousel Arrow Button (Scroll Left - one on each side)
                      Positioned(
                        left: 12,
                        child: Opacity(
                          opacity: _selectedStoryIndex > 0 ? 1.0 : 0.35,
                          child: IgnorePointer(
                            ignoring: _selectedStoryIndex <= 0,
                            child: _CarouselArrowButton(
                              icon: Icons.chevron_left_rounded,
                              label: 'Previous story',
                              enabled: _selectedStoryIndex > 0,
                              onScroll: _scrollPrev,
                            ),
                          ),
                        ),
                      ),

                      // Right Carousel Arrow Button (Scroll Right - one on each side)
                      Positioned(
                        right: 12,
                        child: Opacity(
                          opacity: _selectedStoryIndex < _collection.stories.length - 1 ? 1.0 : 0.35,
                          child: IgnorePointer(
                            ignoring: _selectedStoryIndex >= _collection.stories.length - 1,
                            child: _CarouselArrowButton(
                              icon: Icons.chevron_right_rounded,
                              label: 'Next story',
                              enabled: _selectedStoryIndex < _collection.stories.length - 1,
                              onScroll: _scrollNext,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Bottom Dark Description Banner
                _buildBottomDescriptionBanner(activeStory),

                const SizedBox(height: 8),
              ],
            ),
          ),

          // Dimming Overlay when transitioning to story
          AnimatedOpacity(
            opacity: _isTransitioningToStory ? 0.6 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Container(color: Colors.black),
          ),
        ],
      ),
    );
  }

  // 80s Showa Folded Paper Ribbon Header Banner ("WHERE ARE U GOING?")
  Widget _buildFoldedRibbonHeader() {
    return CustomPaint(
      painter: _RibbonBannerPainter(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 8),
        child: const Text(
          'WHERE ARE U GOING?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.2,
            color: Color(0xFF3E2716),
          ),
        ),
      ),
    );
  }

  // 80s Showa Worn Postcard Stamp Card (Dull B&W Side Cards -> Bright Vibrant Color Center Card)
  Widget _buildPostcardStampCard(StoryData story, int index, bool isSelected, bool isAnimating) {
    // Card Container Layout (Center card is wider 295w x 355h vs side cards 210w x 275h)
    Widget cardContent = AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      width: isSelected ? 295 : 210, // Center card is wider & commanding!
      height: isSelected ? 355 : 275,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001) // 3D Perspective
        ..rotateY(_tiltX)
        ..rotateX(_tiltY),
      transformAlignment: Alignment.center,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? const Color(0xFFEF6C6C).withValues(alpha: isAnimating ? 0.55 : 0.40)
                : Colors.black.withValues(alpha: 0.35), // Dull monochrome paper shadow for side cards
            blurRadius: isSelected ? 28 : 10,
            offset: isSelected ? const Offset(0, 12) : const Offset(0, 4),
          ),
        ],
      ),
      child: ClipPath(
        clipper: _PostageStampClipper(toothRadius: 5.2, toothSpacing: 15.0),
        child: CustomPaint(
          painter: _WornPaperEdgePainter(), // Renders tea-stained 80s worn edge patina
          child: Container(
            color: isSelected ? const Color(0xFFFAF4EE) : const Color(0xFFE5DDD0), // Dull aged cream for side cards
            padding: const EdgeInsets.all(12),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. CLEAN 78% IMAGE PLACEHOLDER AREA
                    Expanded(
                      flex: 78,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFEFE6D5) : const Color(0xFFDCD2C4),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isSelected ? const Color(0xFFEF6C6C) : const Color(0xFFB5A692),
                              width: isSelected ? 2.2 : 1.0,
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.crop_original_rounded,
                                    size: isSelected ? 42 : 28,
                                    color: isSelected
                                        ? const Color(0xFFEF6C6C).withValues(alpha: 0.90)
                                        : const Color(0xFF6E6053).withValues(alpha: 0.60),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'STORY ARTWORK SPACE',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: isSelected ? 11.5 : 9.0,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.4,
                                      color: isSelected
                                          ? const Color(0xFFEF6C6C).withValues(alpha: 0.90)
                                          : const Color(0xFF6E6053).withValues(alpha: 0.65),
                                    ),
                                  ),
                                ],
                              ),

                              // Vintage 80s Showa Japan Watermark Accent (昭和80s)
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Opacity(
                                  opacity: isSelected ? 0.22 : 0.12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: isSelected ? const Color(0xFF3E2716) : const Color(0xFF555555),
                                        width: 1,
                                      ),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      '昭和80s · 旅',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        color: isSelected ? const Color(0xFF3E2716) : const Color(0xFF555555),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // 2. CLEAN BOTTOM TEXT AREA (Title & Subtitle)
                    Expanded(
                      flex: 22,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            story.subtitle,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: isSelected ? 14.5 : 11.5,
                              fontWeight: FontWeight.w900,
                              color: isSelected ? const Color(0xFF2E1C12) : const Color(0xFF554A40),
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            story.title,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: isSelected ? 12 : 9.5,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? const Color(0xFF6D5547) : const Color(0xFF776B60),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Metallic Silver Paperclip Attachment (Top-Left)
                Positioned(
                  top: -10,
                  left: 6,
                  child: SizedBox(
                    width: 28,
                    height: 48,
                    child: CustomPaint(painter: _PaperclipPainter()),
                  ),
                ),

                // Prominent Glowing Border Highlight for Center Active Card
                if (isSelected)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFFEF6C6C).withValues(alpha: 0.75),
                            width: 2.2,
                          ),
                          borderRadius: BorderRadius.circular(4),
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

    // Apply Dull Black & White Desaturation Filter to Side Cards
    if (!isSelected) {
      cardContent = ColorFiltered(
        colorFilter: const ColorFilter.matrix(_grayscaleMatrix),
        child: Opacity(
          opacity: 0.75, // Dull & desaturated side cards
          child: cardContent,
        ),
      );
    }

    return GestureDetector(
      onTap: () => _onCardTap(index),
      onPanUpdate: (details) {
        if (isSelected) {
          setState(() {
            _tiltX += details.delta.dx * 0.002;
            _tiltY -= details.delta.dy * 0.002;
          });
        }
      },
      onPanEnd: (_) {
        if (isSelected) {
          setState(() {
            _tiltX = 0.0;
            _tiltY = 0.0;
          });
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Center(child: cardContent),
    );
  }

  // Bottom Dark Description Banner
  Widget _buildBottomDescriptionBanner(StoryData activeStory) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2E1C12).withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD4AF37), width: 1.2),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Row(
        children: [
          Text(
            '${activeStory.subtitle.toUpperCase()} : ',
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Color(0xFFC6FF00),
              letterSpacing: 1.0,
            ),
          ),
          Expanded(
            child: Text(
              activeStory.taglineOrQuote,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.play_arrow_rounded, color: Color(0xFFFF9800), size: 18),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CAROUSEL ARROW BUTTON (Tap to scroll one story, press-&-hold to keep scrolling)
// ─────────────────────────────────────────────────────────────────────────────
class _CarouselArrowButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final bool Function() onScroll;

  const _CarouselArrowButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onScroll,
  });

  @override
  State<_CarouselArrowButton> createState() => _CarouselArrowButtonState();
}

class _CarouselArrowButtonState extends State<_CarouselArrowButton> {
  Timer? _holdTimer; // Delay before hold-repeat kicks in
  Timer? _repeatTimer; // Repeating scroll while held
  bool _hovered = false;
  bool _pressed = false;
  bool _repeatStarted = false;

  void _handleTapDown(TapDownDetails _) {
    if (!widget.enabled) return;
    setState(() => _pressed = true);
    _repeatStarted = false;

    // After a short hold, start continuously scrolling to the side.
    _holdTimer?.cancel();
    _holdTimer = Timer(const Duration(milliseconds: 400), () {
      if (!mounted || !widget.enabled) return;
      _repeatStarted = true;
      widget.onScroll();
      _repeatTimer?.cancel();
      // Slightly longer than the 350ms page animation so each step completes
      // smoothly before the next one begins.
      _repeatTimer = Timer.periodic(const Duration(milliseconds: 450), (_) {
        if (!mounted || !widget.enabled) return;
        // Stop repeating once we reach the end of the carousel.
        if (!widget.onScroll()) {
          _cancelTimers();
          if (mounted) setState(() => _pressed = false);
        }
      });
    });
  }

  void _handleTapUp(TapUpDetails _) {
    _cancelTimers();
    if (mounted) setState(() => _pressed = false);
    // Quick tap = single scroll to the side.
    if (widget.enabled && !_repeatStarted) {
      widget.onScroll();
    }
  }

  void _handleTapCancel() {
    _cancelTimers();
    if (mounted) setState(() => _pressed = false);
  }

  void _cancelTimers() {
    _holdTimer?.cancel();
    _repeatTimer?.cancel();
    _holdTimer = null;
    _repeatTimer = null;
  }

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) {
        if (widget.enabled) setState(() => _hovered = true);
      },
      onExit: (_) {
        if (_hovered) setState(() => _hovered = false);
        _handleTapCancel();
      },
      child: Semantics(
        button: true,
        label: widget.label,
        enabled: widget.enabled,
        child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: AnimatedScale(
          scale: _pressed ? 0.88 : (_hovered ? 1.08 : 1.0),
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFAF4EE).withValues(alpha: 0.95),
              shape: BoxShape.circle,
              border: Border.all(
                color: _hovered ? const Color(0xFFEF6C6C) : const Color(0xFF8B6914),
                width: _hovered ? 2.2 : 1.6,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: _hovered ? 12 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Icon(widget.icon, color: const Color(0xFF3E2716), size: 30),
            ),
          ),
        ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MOUSE, TOUCH, TRACKPAD & STYLUS SCROLL BEHAVIOR
// ─────────────────────────────────────────────────────────────────────────────
class _MouseAndTouchScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// 80s WORN TEA-STAINED PAPER EDGE PAINTER
// ─────────────────────────────────────────────────────────────────────────────
class _WornPaperEdgePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Outer Tea-Stained Perforated Rim Shadow
    final edgeShadowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFC8B490).withValues(alpha: 0.45),
          const Color(0xFFB59F78).withValues(alpha: 0.20),
          const Color(0xFFD6C5A2).withValues(alpha: 0.45),
        ],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0;

    canvas.drawRect(Offset.zero & size, edgeShadowPaint);

    // Micro Aged Distress Crease Line
    final creasePaint = Paint()
      ..color = const Color(0xFF8B6914).withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawLine(const Offset(12, 18), Offset(size.width - 16, 24), creasePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM SCRAPED POSTAGE STAMP CLIPPER
// ─────────────────────────────────────────────────────────────────────────────
class _PostageStampClipper extends CustomClipper<Path> {
  final double toothRadius;
  final double toothSpacing;

  _PostageStampClipper({this.toothRadius = 5.2, this.toothSpacing = 15.0});

  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);

    // Top edge
    double x = toothSpacing / 2;
    while (x < size.width) {
      path.lineTo(x - toothRadius, 0);
      path.arcToPoint(
        Offset(x + toothRadius, 0),
        radius: Radius.circular(toothRadius),
        clockwise: false,
      );
      x += toothSpacing;
    }
    path.lineTo(size.width, 0);

    // Right edge
    double y = toothSpacing / 2;
    while (y < size.height) {
      path.lineTo(size.width, y - toothRadius);
      path.arcToPoint(
        Offset(size.width, y + toothRadius),
        radius: Radius.circular(toothRadius),
        clockwise: false,
      );
      y += toothSpacing;
    }
    path.lineTo(size.width, size.height);

    // Bottom edge
    x = size.width - toothSpacing / 2;
    while (x > 0) {
      path.lineTo(x + toothRadius, size.height);
      path.arcToPoint(
        Offset(x - toothRadius, size.height),
        radius: Radius.circular(toothRadius),
        clockwise: false,
      );
      x -= toothSpacing;
    }
    path.lineTo(0, size.height);

    // Left edge
    y = size.height - toothSpacing / 2;
    while (y > 0) {
      path.lineTo(0, y + toothRadius);
      path.arcToPoint(
        Offset(0, y - toothRadius),
        radius: Radius.circular(toothRadius),
        clockwise: false,
      );
      y -= toothSpacing;
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// METALLIC SILVER PAPERCLIP PAINTER
// ─────────────────────────────────────────────────────────────────────────────
class _PaperclipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD0D5DD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final shadowPaint = Paint()
      ..color = Colors.black38
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final path = Path();
    path.moveTo(10, 40);
    path.lineTo(10, 8);
    path.arcToPoint(const Offset(20, 8), radius: const Radius.circular(5));
    path.lineTo(20, 44);
    path.arcToPoint(const Offset(5, 44), radius: const Radius.circular(8));
    path.lineTo(5, 16);

    canvas.drawPath(path.shift(const Offset(1.5, 2)), shadowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// 3D FOLDED WHITE RIBBON BANNER PAINTER (Swallow-tail notched ends)
// ─────────────────────────────────────────────────────────────────────────────
class _RibbonBannerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final fillPaint = Paint()
      ..color = const Color(0xFFFFFDF8)
      ..style = PaintingStyle.fill;

    final shadowFoldPaint = Paint()
      ..color = const Color(0xFFC5B697)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFFD8C7A5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    const tailW = 34.0;
    const foldH = 8.0;

    // Left Fold Triangle
    final leftFold = Path()
      ..moveTo(tailW, size.height)
      ..lineTo(tailW, size.height + foldH)
      ..lineTo(tailW - 12, size.height)
      ..close();
    canvas.drawPath(leftFold, shadowFoldPaint);

    // Right Fold Triangle
    final rightFold = Path()
      ..moveTo(size.width - tailW, size.height)
      ..lineTo(size.width - tailW, size.height + foldH)
      ..lineTo(size.width - tailW + 12, size.height)
      ..close();
    canvas.drawPath(rightFold, shadowFoldPaint);

    // Left Ribbon Tail with swallow-tail / notched end
    final leftTail = Path()
      ..moveTo(0, foldH)
      ..lineTo(tailW, 0)
      ..lineTo(tailW, size.height)
      ..lineTo(0, size.height + foldH)
      ..lineTo(10, (size.height + foldH) / 2)
      ..close();

    // Right Ribbon Tail with swallow-tail / notched end
    final rightTail = Path()
      ..moveTo(size.width, foldH)
      ..lineTo(size.width - tailW, 0)
      ..lineTo(size.width - tailW, size.height)
      ..lineTo(size.width, size.height + foldH)
      ..lineTo(size.width - 10, (size.height + foldH) / 2)
      ..close();

    canvas.drawPath(leftTail.shift(const Offset(0, 2)), shadowPaint);
    canvas.drawPath(rightTail.shift(const Offset(0, 2)), shadowPaint);

    canvas.drawPath(leftTail, fillPaint);
    canvas.drawPath(leftTail, borderPaint);

    canvas.drawPath(rightTail, fillPaint);
    canvas.drawPath(rightTail, borderPaint);

    // Center Main Banner
    final mainBanner = RRect.fromRectAndRadius(
      Rect.fromLTWH(tailW - 4, 0, size.width - 2 * (tailW - 4), size.height),
      const Radius.circular(2),
    );

    canvas.drawRRect(mainBanner.shift(const Offset(0, 3)), shadowPaint);
    canvas.drawRRect(mainBanner, fillPaint);
    canvas.drawRRect(mainBanner, borderPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
