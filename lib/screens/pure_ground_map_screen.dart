import 'package:flutter/material.dart';
import '../widgets/ground_india_map_widget.dart';
import '../widgets/vintage_action_menu_bar.dart';
import '../widgets/observing_eyes_widget.dart';

/// Pure 3D Ground Map Screen — "A LEGENDARY JOURNEY" Poster Page
/// Features:
/// 1. Title Header: "A LEGENDARY JOURNEY - AN INDIE ADVENTURE GAME" with diamond ornaments
/// 2. Surroundings: Ancient oak tree & signpost on left, fantasy castle on right horizon
/// 3. Map: 3D Ground India Map with vertical glowing light pillar beam on selected state
/// 4. Character: Young child hero facing away towards map on elevated stone blocks
/// 5. Scroll: Vertical scroll down reveals pitch black void with giant slowly blinking happy observing eyes!
class PureGroundMapScreen extends StatefulWidget {
  const PureGroundMapScreen({super.key});

  @override
  State<PureGroundMapScreen> createState() => _PureGroundMapScreenState();
}

class _PureGroundMapScreenState extends State<PureGroundMapScreen> {
  final double _pitchAngle = -0.75;
  final double _yawAngle = 0.0;
  final double _zoomLevel = 1.65;
  final Offset _panOffset = const Offset(10.0, 30.0);
  String? _selectedStateId = 'madhya_pradesh';

  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF4E6C8),
      body: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // =================================================================
            // SECTION 1: "A LEGENDARY JOURNEY" MAIN GAME POSTER PAGE
            // =================================================================
            SizedBox(
              width: screenSize.width,
              height: screenSize.height,
              child: Stack(
                children: [
                  // 1. Parchment Base Gradient Background
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFF4E6C8),
                        gradient: RadialGradient(
                          colors: [
                            Color(0xFFF7EED8),
                            Color(0xFFEADBBE),
                            Color(0xFFD4B886),
                          ],
                          stops: [0.35, 0.75, 1.0],
                          radius: 1.3,
                        ),
                      ),
                    ),
                  ),

                  // 2. Vintage Fantasy Environment Layer (Ancient Tree + Signpost on left, Castle on right)
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/legendary_bg.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const SizedBox(),
                    ),
                  ),

                  // 3. Center Piece: 3D Ground India Map (With vertical glowing light beam on selected state)
                  Positioned.fill(
                    child: GroundIndiaMapWidget(
                      selectedStateId: _selectedStateId,
                      onStateSelected: (id) {
                        setState(() {
                          _selectedStateId = id;
                        });
                      },
                      pitchAngle: _pitchAngle,
                      yawAngle: _yawAngle,
                      zoomLevel: _zoomLevel,
                      panOffset: _panOffset,
                      enableGestures: false,
                      showOuterBorder: false,
                    ),
                  ),

                  // 4. "A LEGENDARY JOURNEY" Title Header (Positioned on Extreme Right with ZERO box, perfectly blended into scene)
                  Positioned(
                    top: 140,
                    right: 48,
                    child: SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Top Line: ───♦─── A ───♦───
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 45,
                                height: 1.5,
                                color: const Color(0xFF2C190B).withValues(alpha: 0.8),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6),
                                child: Text('♦', style: TextStyle(color: Color(0xFF2C190B), fontSize: 10)),
                              ),
                              const Text(
                                'A',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF2C190B),
                                  letterSpacing: 4.0,
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6),
                                child: Text('♦', style: TextStyle(color: Color(0xFF2C190B), fontSize: 10)),
                              ),
                              Container(
                                width: 45,
                                height: 1.5,
                                color: const Color(0xFF2C190B).withValues(alpha: 0.8),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // "LEGENDARY" Header
                          const Text(
                            'LEGENDARY',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 50,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF2C190B),
                              height: 0.9,
                              letterSpacing: 6.0,
                              shadows: [
                                Shadow(color: Colors.white70, blurRadius: 4, offset: Offset(0, 1)),
                              ],
                            ),
                          ),

                          // "JOURNEY" Header
                          const Text(
                            'JOURNEY',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 52,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF2C190B),
                              height: 0.9,
                              letterSpacing: 7.0,
                              shadows: [
                                Shadow(color: Colors.white70, blurRadius: 4, offset: Offset(0, 1)),
                              ],
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Subtitle Line:  ───♦ AN INDIE ADVENTURE GAME ♦───
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 30,
                                height: 1.2,
                                color: const Color(0xFF2C190B).withValues(alpha: 0.7),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6),
                                child: Text('♦', style: TextStyle(color: Color(0xFF2C190B), fontSize: 8)),
                              ),
                              const Text(
                                ' AN INDIE ADVENTURE GAME ',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF2C190B),
                                  letterSpacing: 2.2,
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6),
                                child: Text('♦', style: TextStyle(color: Color(0xFF2C190B), fontSize: 8)),
                              ),
                              Container(
                                width: 30,
                                height: 1.2,
                                color: const Color(0xFF2C190B).withValues(alpha: 0.7),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 5. Back Navigation Arrow (Top-Left)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: SafeArea(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(22),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5D4037).withValues(alpha: 0.85),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFFFD54F),
                                width: 1.5,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black38,
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              color: Color(0xFFFFF176),
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 6. Floating Vintage Action Emblem Menu Bar (Placed at Bottom)
                  Positioned(
                    bottom: 8,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      child: VintageActionMenuBar(
                        items: [
                          VintageMenuItemData(
                            title: 'Explore',
                            subtitle: 'Vast Lands',
                            icon: Icons.explore_rounded,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Exploring India Lands...'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                          VintageMenuItemData(
                            title: 'Battle',
                            subtitle: 'Fierce Enemies',
                            icon: Icons.shield_rounded,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Entering Battle Mode...'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                          VintageMenuItemData(
                            title: 'Solve',
                            subtitle: 'Ancient Puzzles',
                            icon: Icons.extension_rounded,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Solving Ancient Puzzles...'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                          VintageMenuItemData(
                            title: 'Discover',
                            subtitle: 'Forgotten Stories',
                            icon: Icons.auto_stories_rounded,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Discovering Forgotten Stories...'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                          VintageMenuItemData(
                            title: 'Become',
                            subtitle: 'A Legend',
                            icon: Icons.favorite_rounded,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Becoming a Legend!'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // =================================================================
            // SECTION 2: OBSERVED REALM - GIANT SLOWLY BLINKING HAPPY EYES PAGE
            // =================================================================
            const ObservingEyesWidget(),
          ],
        ),
      ),
    );
  }
}
