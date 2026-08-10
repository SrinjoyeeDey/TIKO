import 'dart:ui';
import 'package:flutter/material.dart';
import 'wooden_plank_button.dart';
import 'rope_painter.dart';
import '../screens/character_profile_screen.dart';
import '../screens/leaderboard_screen.dart';

class AnimatedRopeMenu extends StatefulWidget {
  final VoidCallback? onMenuItemSelected;

  const AnimatedRopeMenu({super.key, this.onMenuItemSelected});

  @override
  State<AnimatedRopeMenu> createState() => _AnimatedRopeMenuState();
}

class _AnimatedRopeMenuState extends State<AnimatedRopeMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _blurAnimation;
  late Animation<double> _swingAnimation;

  bool _isExpanded = false;

  final List<String> _menuItems = [
    'PROFILE',
    'HOME',
    'LEADERBOARD',
    'MORE GAME',
    'OPTIONS',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _blurAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );

    _swingAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.08), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.08, end: -0.05), weight: 30),
      TweenSequenceItem(tween: Tween(begin: -0.05, end: 0.02), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.02, end: 0.0), weight: 20),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _controller.forward(from: 0.0);
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final blurVal = _blurAnimation.value * 6.0;
        final darkOpacity = _blurAnimation.value * 0.5;

        return Stack(
          children: [
            // Dark Backdrop & Blur Overlay when expanding
            if (_controller.value > 0.01)
              GestureDetector(
                onTap: _toggleMenu,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: blurVal, sigmaY: blurVal),
                  child: Container(
                    color: Colors.black.withValues(alpha: darkOpacity),
                  ),
                ),
              ),

            // Top Action Buttons (BACK / FRW)
            if (_controller.value > 0.05)
              Positioned(
                top: 40,
                left: 16,
                right: 16,
                child: Opacity(
                  opacity: _blurAnimation.value,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // BACK Button
                      WoodenPlankButton(
                        text: 'BACK',
                        onTap: () {},
                        width: 90,
                        height: 38,
                        variant: WoodenPlankVariant.standard,
                      ),

                      // FRW Button
                      WoodenPlankButton(
                        text: 'FRW',
                        onTap: () {},
                        width: 90,
                        height: 38,
                        variant: WoodenPlankVariant.standard,
                      ),
                    ],
                  ),
                ),
              ),

            // Expanded Hanging Rope Wooden Menu
            if (_controller.value > 0.01)
              Positioned.fill(
                child: Transform.rotate(
                  angle: _swingAnimation.value,
                  origin: const Offset(0, -200),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 70),

                      // Main NIMO WORLD Wooden Header Sign
                      _buildStaggeredItem(
                        index: 0,
                        totalItems: 7,
                        child: WoodenPlankButton(
                          text: 'NIMO WORLD',
                          onTap: () {},
                          width: 250,
                          height: 60,
                          variant: WoodenPlankVariant.menuHeader,
                          hasLeafLeft: true,
                          hasLeafRight: true,
                        ),
                      ),

                      // Menu Items Stack connected with Ropes
                      ...List.generate(_menuItems.length, (index) {
                        final itemText = _menuItems[index];
                        final isMenuTrigger = itemText == 'MENU';

                        return Column(
                          children: [
                            // Connecting Rope segment
                            CustomPaint(
                              size: const Size(180, 20),
                              painter: RopePainter(
                                topPoints: const [Offset(30, 0), Offset(150, 0)],
                                bottomPoints: const [Offset(30, 20), Offset(150, 20)],
                                swingAngle: _swingAnimation.value,
                              ),
                            ),

                            // Plank Button
                            _buildStaggeredItem(
                              index: index + 1,
                              totalItems: 7,
                              child: WoodenPlankButton(
                                text: itemText,
                                onTap: () {
                                  if (isMenuTrigger) {
                                    _toggleMenu();
                                  } else if (itemText == 'PROFILE') {
                                    _toggleMenu();
                                    Navigator.of(context).push(
                                      PageRouteBuilder(
                                        pageBuilder: (context, animation, secondaryAnimation) =>
                                            const CharacterProfileScreen(),
                                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                          return FadeTransition(opacity: animation, child: child);
                                        },
                                        transitionDuration: const Duration(milliseconds: 350),
                                      ),
                                    );
                                  } else if (itemText == 'LEADERBOARD') {
                                    _toggleMenu();
                                    Navigator.of(context).push(
                                      PageRouteBuilder(
                                        pageBuilder: (context, animation, secondaryAnimation) =>
                                            const LeaderboardScreen(),
                                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                          return FadeTransition(opacity: animation, child: child);
                                        },
                                        transitionDuration: const Duration(milliseconds: 350),
                                      ),
                                    );
                                  } else {
                                    widget.onMenuItemSelected?.call();
                                  }
                                },
                                width: 230,
                                height: 46,
                                hasLeafRight: index % 2 == 0,
                                hasLeafLeft: index % 2 != 0,
                              ),
                            ),
                          ],
                        );
                      }),

                      // Connecting Rope for EXIT Plank
                      CustomPaint(
                        size: const Size(140, 16),
                        painter: RopePainter(
                          topPoints: const [Offset(30, 0), Offset(110, 0)],
                          bottomPoints: const [Offset(30, 16), Offset(110, 16)],
                          swingAngle: _swingAnimation.value,
                        ),
                      ),

                      // EXIT Plank Button
                      _buildStaggeredItem(
                        index: 6,
                        totalItems: 7,
                        child: WoodenPlankButton(
                          text: 'EXIT',
                          onTap: _toggleMenu,
                          width: 190,
                          height: 42,
                          variant: WoodenPlankVariant.exit,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Top-Right Wooden Hamburger Icon Trigger (Always Accessible!)
            if (!_isExpanded)
              Positioned(
                top: 16,
                right: 16,
                child: SafeArea(
                  child: _buildWoodenHamburgerIcon(),
                ),
              ),

          ],
        );
      },
    );
  }

  // Wooden Hamburger Icon Button
  Widget _buildWoodenHamburgerIcon() {
    return GestureDetector(
      onTap: _toggleMenu,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: const Color(0xFF4A321E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF8D5B2A), width: 2.0),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(
          Icons.menu_rounded,
          color: Color(0xFFFFF176),
          size: 28,
        ),
      ),
    );
  }

  Widget _buildStaggeredItem({
    required int index,
    required int totalItems,
    required Widget child,
  }) {
    final startInterval = (index / totalItems) * 0.4;
    final endInterval = (startInterval + 0.5).clamp(0.0, 1.0);

    final animation = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        startInterval,
        endInterval,
        curve: Curves.elasticOut,
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, childWidget) {
        final scale = animation.value;
        final offsetY = (1.0 - animation.value) * -40.0;

        return Transform.translate(
          offset: Offset(0, offsetY),
          child: Transform.scale(
            scale: scale.clamp(0.0, 1.1),
            child: childWidget,
          ),
        );
      },
      child: child,
    );
  }
}
