import 'package:flutter/material.dart';
import 'auth_mode_selection_screen.dart';
import 'pure_ground_map_screen.dart';
import 'game_map_1913_screen.dart';
import 'sego_concept_screen.dart';
import '../widgets/animated_rope_menu.dart';
import '../widgets/wooden_next_button.dart';
import '../widgets/wooden_back_button.dart';
import '../widgets/wooden_plank_button.dart';
import '../widgets/japanese_kungfu_background.dart';
import '../widgets/animated_interactive_swing.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  double _currentPage = 0.0;

  final int _pageCount = 2;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      if (_pageController.hasClients && _pageController.page != null) {
        setState(() {
          _currentPage = _pageController.page!;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openMainMenu() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const GameMap1913Screen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  void _previousPage() {
    if (_pageController.hasClients && _currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextPage() {
    if (_pageController.hasClients && _currentPage < _pageCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _openMainMenu();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Multi-Page Onboarding PageView
          Positioned.fill(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index.toDouble();
                });
              },
              children: [
                // Page 1: Japanese Swing Page with iconic 3D Wooden NIMO Signboard!
                JapaneseKungFuBackground(
                  showNimoSign: true,
                  child: Stack(
                    children: const [
                      AnimatedInteractiveSwing(),
                    ],
                  ),
                ),

                // Page 2: Authentication & Mode Selection Page (Child Mode / Parent Mode)
                AuthModeSelectionScreen(
                  onBeginJourney: _openMainMenu,
                ),
              ],
            ),
          ),

          // 2. Page Indicators (Dots)
          Positioned(
            bottom: 105,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pageCount,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage.round() == index ? 26 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage.round() == index
                        ? const Color(0xFFFFD54F)
                        : Colors.white60,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 3. Interactive Animated Rope Wooden Menu Overlay
          Positioned.fill(
            child: AnimatedRopeMenu(
              onMenuItemSelected: _nextPage,
            ),
          ),

          // 4. Top-Left 3D Ground Map Wooden Shortcut Button on Landing Page
          Positioned(
            top: 16,
            left: 16,
            child: SafeArea(
              child: WoodenPlankButton(
                text: '3D MAP',
                width: 110,
                height: 44,
                variant: WoodenPlankVariant.standard,
                onTap: () {
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          const PureGroundMapScreen(),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                          FadeTransition(opacity: animation, child: child),
                      transitionDuration: const Duration(milliseconds: 400),
                    ),
                  );
                },
              ),
            ),
          ),

          // 5. Top-Right SEGO Concept Navigation Button on Landing Page
          Positioned(
            top: 16,
            right: 16,
            child: SafeArea(
              child: WoodenPlankButton(
                text: 'SEGO PAGE',
                width: 125,
                height: 44,
                variant: WoodenPlankVariant.golden,
                onTap: () {
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          const SegoConceptScreen(),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                          FadeTransition(opacity: animation, child: child),
                      transitionDuration: const Duration(milliseconds: 400),
                    ),
                  );
                },
              ),
            ),
          ),

          // 4. Wooden Back Arrow Button (Bottom-Left on Page 2)
          if (_currentPage > 0.1)
            Positioned(
              bottom: 30,
              left: 24,
              child: WoodenBackButton(
                size: 64,
                onTap: _previousPage,
              ),
            ),

          // 5. Wooden Next Arrow Button (Only on Page 1)
          if (_currentPage < 0.5)
            Positioned(
              bottom: 30,
              right: 24,
              child: WoodenNextButton(
                size: 64,
                onTap: _nextPage,
              ),
            ),
        ],
      ),
    );
  }
}
