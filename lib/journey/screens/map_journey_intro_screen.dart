import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/journey_destination.dart';
import '../models/journey_stage.dart';
import '../widgets/map_particle_layer.dart';
import '../widgets/unfolding_map.dart';
import '../widgets/historical_world_map_widget.dart';
import '../widgets/journey_title.dart';
import '../widgets/proceed_button.dart';
import '../../widgets/wooden_back_button.dart';
import '../../screens/onboarding_screen.dart';
import '../services/map_audio_service.dart';
import '../../screens/explore_india_screen.dart';

/// Single World Map Cinematic Intro Screen.
/// Flow: ONBOARDING -> 3D UNFOLDING -> ONE WORLD MAP (Japan origin) -> INDIA ILLUMINATES -> ENTER INDIA -> EXISTING INDIA MAP (ExploreIndiaScreen).
class MapJourneyIntroScreen extends StatefulWidget {
  final JourneyDestination destination;

  const MapJourneyIntroScreen({
    super.key,
    this.destination = JourneyDestination.japanToIndia,
  });

  @override
  State<MapJourneyIntroScreen> createState() => _MapJourneyIntroScreenState();
}

class _MapJourneyIntroScreenState extends State<MapJourneyIntroScreen>
    with TickerProviderStateMixin {
  JourneyStage _currentStage = JourneyStage.unfolding;

  late AnimationController _unfoldController;
  late AnimationController _zoomToIndiaController;

  bool _reducedMotion = false;
  bool _isMuted = false;
  bool _isTransitioningOut = false;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _startIntroSequence();
  }

  void _initControllers() {
    _unfoldController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    _zoomToIndiaController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  void _startIntroSequence() async {
    MapAudioService().playPaperUnfold();

    if (_reducedMotion) {
      _unfoldController.value = 1.0;
      _advanceToStage(JourneyStage.worldMapRevealed);
      return;
    }

    await _unfoldController.forward();
    _advanceToStage(JourneyStage.worldMapRevealed);

    // Auto-illuminate India immediately after unfolding completes
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted && _currentStage == JourneyStage.worldMapRevealed) {
      _advanceToStage(JourneyStage.indiaIlluminated);
    }
  }

  void _advanceToStage(JourneyStage nextStage) {
    if (!mounted) return;

    setState(() {
      _currentStage = nextStage;
    });

    if (nextStage == JourneyStage.enteringIndia) {
      _transitionToExistingIndiaMap();
    }
  }

  void _transitionToExistingIndiaMap() {
    if (_isTransitioningOut) return;
    _isTransitioningOut = true;

    MapAudioService().playDestinationReveal();

    // Start camera zoom into India instantly
    _zoomToIndiaController.forward(from: 0.0);

    if (!mounted) return;

    // Launch page transition immediately in parallel — zero delay, snappy 60 FPS motion!
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const ExploreIndiaScreen(
          isIntroJourney: true,
          initialStateId: 'west_bengal',
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final fadeAnim = CurvedAnimation(parent: animation, curve: Curves.easeInOut);
          final scaleAnim = Tween<double>(begin: 0.50, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          );

          return FadeTransition(
            opacity: fadeAnim,
            child: ScaleTransition(
              scale: scaleAnim,
              alignment: Alignment.center,
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 700),
      ),
    );
  }

  @override
  void dispose() {
    _unfoldController.dispose();
    _zoomToIndiaController.dispose();
    super.dispose();
  }

  void _toggleReducedMotion() {
    setState(() {
      _reducedMotion = !_reducedMotion;
      if (_reducedMotion) {
        _unfoldController.value = 1.0;
        if (_currentStage == JourneyStage.unfolding) {
          _currentStage = JourneyStage.indiaIlluminated;
        }
      }
    });
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      MapAudioService().toggleMute();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D111A), // Deep indigo
      body: Stack(
        children: [
          // 1. Midnight Atmosphere Background & Mt. Fuji Horizon Silhouette
          Positioned.fill(
            child: CustomPaint(
              painter: _JapaneseIndigoBackgroundPainter(),
              child: const SizedBox.expand(),
            ),
          ),

          // 2. Floating Sakura, Sumi Ink & Dust Particles
          Positioned.fill(
            child: MapParticleLayer(
              reducedMotion: _reducedMotion,
            ),
          ),

          // 3. Central 3D Paper Unfolding Container & SINGLE World Map Visual
          Positioned.fill(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    _unfoldController,
                    _zoomToIndiaController,
                  ]),
                  builder: (context, child) {
                    final unfoldVal = _reducedMotion ? 1.0 : _unfoldController.value;
                    final rollVal = math.min(1.0, unfoldVal * 2.0);
                    final triUnfoldVal = (unfoldVal > 0.4) ? (unfoldVal - 0.4) / 0.6 : 0.0;
                    final settleVal = (unfoldVal > 0.85) ? (unfoldVal - 0.85) / 0.15 : 0.0;

                    final rawZoom = _zoomToIndiaController.value;
                    final curveZoom = Curves.easeInOutCubic.transform(rawZoom);

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final screenW = constraints.maxWidth;
                        final screenH = constraints.maxHeight;

                        // Deep camera scale (1.0 -> 4.2x) directly into the Indian Subcontinent
                        final cameraScale = 1.0 + curveZoom * 3.2;

                        // Centering vector: target India coordinates on parchment
                        final cameraOffsetX = -curveZoom * (screenW * 0.14 * cameraScale);
                        final cameraOffsetY = -curveZoom * (screenH * 0.04 * cameraScale);

                        return Transform.translate(
                          offset: Offset(cameraOffsetX, cameraOffsetY),
                          child: Transform.scale(
                            scale: cameraScale,
                            alignment: Alignment.center,
                            child: UnfoldingMap(
                              rollProgress: rollVal,
                              unfoldProgress: triUnfoldVal,
                              settleProgress: settleVal,
                              child: GestureDetector(
                                onTap: () {
                                  if (_currentStage == JourneyStage.indiaIlluminated) {
                                    _advanceToStage(JourneyStage.enteringIndia);
                                  }
                                },
                                child: HistoricalWorldMapWidget(
                                  opacity: 1.0,
                                  indiaHighlightProgress: (_currentStage == JourneyStage.indiaIlluminated ||
                                          _currentStage == JourneyStage.enteringIndia)
                                      ? 1.0
                                      : 0.0,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),

          // 4. Golden Light Beam Portal Effect ("go inside that light and comeout as India map")
          if (_currentStage == JourneyStage.enteringIndia)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _zoomToIndiaController,
                builder: (context, child) {
                  final zoom = _zoomToIndiaController.value;
                  final lightIntensity = (zoom < 0.75) 
                      ? Curves.easeIn.transform(zoom / 0.75)
                      : (1.0 - (zoom - 0.75) / 0.25);

                  return IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFFFF176).withValues(alpha: math.min(1.0, lightIntensity * 1.3)),
                            const Color(0xFFFFD54F).withValues(alpha: math.min(0.95, lightIntensity * 1.0)),
                            const Color(0xFF00E5FF).withValues(alpha: math.min(0.8, lightIntensity * 0.7)),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.45, 0.80, 1.0],
                          center: Alignment.center,
                          radius: 0.1 + zoom * 2.2,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          // 5. Header Banners
          _buildStageHeaderTitle(),

          // 6. Contextual Action Button (ENTER INDIA →)
          if (_currentStage == JourneyStage.indiaIlluminated)
            Positioned(
              bottom: 36,
              left: 0,
              right: 0,
              child: Center(
                child: ProceedButton(
                  label: 'ENTER INDIA  →',
                  onTap: () => _advanceToStage(JourneyStage.enteringIndia),
                  isVisible: true,
                ),
              ),
            ),

          // 6. Top Controls Bar
          // 6. Top Left Back Button (Safe navigation)
          Positioned(
            top: 40,
            left: 20,
            child: WoodenBackButton(
              size: 38,
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
            ),
          ),

          // 7. Top Right Utility Controls (Reduced Motion, Mute, Skip)
          Positioned(
            top: 40,
            right: 20,
            child: Row(
              children: [
                _ControlIconButton(
                  icon: _reducedMotion ? Icons.accessible_forward_rounded : Icons.accessibility_new_rounded,
                  isActive: _reducedMotion,
                  tooltip: 'Toggle Reduced Motion',
                  onTap: _toggleReducedMotion,
                ),
                const SizedBox(width: 10),
                _ControlIconButton(
                  icon: _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  isActive: _isMuted,
                  tooltip: 'Mute Audio',
                  onTap: _toggleMute,
                ),
                const SizedBox(width: 10),
                if (_currentStage != JourneyStage.enteringIndia)
                  _ControlIconButton(
                    icon: Icons.fast_forward_rounded,
                    isActive: false,
                    tooltip: 'Enter India directly',
                    onTap: () => _advanceToStage(JourneyStage.enteringIndia),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStageHeaderTitle() {
    return Positioned(
      top: 75,
      left: 0,
      right: 0,
      child: JourneyTitle(
        destination: widget.destination,
        opacity: 1.0,
        slideOffset: 0.0,
        showDestinationText: false,
      ),
    );
  }
}

/// Custom Background Painter for Deep Midnight Indigo atmosphere & Mt. Fuji silhouette
class _JapaneseIndigoBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final bgGradient = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFF1B263B),
          Color(0xFF101726),
          Color(0xFF070B12),
        ],
        stops: [0.0, 0.55, 1.0],
        center: Alignment.center,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgGradient);

    // Distant Mount Fuji Silhouette
    final fujiPath = Path()
      ..moveTo(0, h)
      ..lineTo(w * 0.15, h * 0.88)
      ..lineTo(w * 0.35, h * 0.82)
      ..quadraticBezierTo(w * 0.48, h * 0.74, w * 0.50, h * 0.74)
      ..quadraticBezierTo(w * 0.52, h * 0.74, w * 0.65, h * 0.82)
      ..lineTo(w * 0.85, h * 0.88)
      ..lineTo(w, h)
      ..close();

    canvas.drawPath(
      fujiPath,
      Paint()
        ..color = const Color(0xFF141D2D).withValues(alpha: 0.7)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ControlIconButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final String tooltip;
  final VoidCallback onTap;

  const _ControlIconButton({
    required this.icon,
    required this.isActive,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFFFFD54F).withValues(alpha: 0.85)
                : const Color(0xFF0D111A).withValues(alpha: 0.75),
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? const Color(0xFFFFD54F) : Colors.white60,
              width: 1.4,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 20,
            color: isActive ? const Color(0xFF2C1C0F) : Colors.white,
          ),
        ),
      ),
    );
  }
}
