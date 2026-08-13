import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/india_states_data.dart';
import '../widgets/ground_india_map_widget.dart';
import '../widgets/wooden_back_button.dart';

/// Interactive 3D Horizontal Ground Map Page with Adaptive Responsive Layout (Phone vs Laptop).
class HorizontalGroundMapScreen extends StatefulWidget {
  final String? initialStateId;

  const HorizontalGroundMapScreen({
    super.key,
    this.initialStateId,
  });

  @override
  State<HorizontalGroundMapScreen> createState() => _HorizontalGroundMapScreenState();
}

class _HorizontalGroundMapScreenState extends State<HorizontalGroundMapScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedStateId;
  String? _hoveredStateId;

  // 3D View Parameters
  double _pitchAngle = 0.95; // ~54 degrees horizontal ground perspective
  double _yawAngle = 0.0;
  double _zoomLevel = 1.0;
  Offset _panOffset = Offset.zero;

  // Cinematic Auto-Tilt Animation
  bool _isAutoTilting = false;
  late AnimationController _autoTiltController;

  @override
  void initState() {
    super.initState();
    _selectedStateId = widget.initialStateId;

    _autoTiltController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..addListener(() {
        if (_isAutoTilting) {
          setState(() {
            _yawAngle = math.sin(_autoTiltController.value * 2 * math.pi) * 0.15;
            _pitchAngle = 0.85 + math.cos(_autoTiltController.value * 2 * math.pi) * 0.12;
          });
        }
      });
  }

  @override
  void dispose() {
    _autoTiltController.dispose();
    super.dispose();
  }

  void _toggleAutoTilt() {
    setState(() {
      _isAutoTilting = !_isAutoTilting;
      if (_isAutoTilting) {
        _autoTiltController.repeat();
      } else {
        _autoTiltController.stop();
      }
    });
  }

  void _setGroundView() {
    setState(() {
      _isAutoTilting = false;
      _autoTiltController.stop();
      _pitchAngle = 0.95;
      _yawAngle = 0.0;
      _zoomLevel = 1.0;
      _panOffset = Offset.zero;
    });
  }

  void _setTopDownView() {
    setState(() {
      _isAutoTilting = false;
      _autoTiltController.stop();
      _pitchAngle = 0.0;
      _yawAngle = 0.0;
      _zoomLevel = 1.0;
      _panOffset = Offset.zero;
    });
  }

  void _resetCamera() {
    setState(() {
      _isAutoTilting = false;
      _autoTiltController.stop();
      _pitchAngle = 0.95;
      _yawAngle = 0.0;
      _zoomLevel = 1.0;
      _panOffset = Offset.zero;
      _selectedStateId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final stateData = _selectedStateId != null
        ? IndiaStatesDatabase.getState(_selectedStateId!)
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFF2C1E14),
      body: Stack(
        children: [
          // 1. Full-Screen Edge-to-Edge 3D Vintage Ground Map Canvas
          Positioned.fill(
            child: GroundIndiaMapWidget(
              selectedStateId: _selectedStateId,
              onStateSelected: (id) => setState(() => _selectedStateId = id),
              onStateHovered: (id) => setState(() => _hoveredStateId = id),
              pitchAngle: _pitchAngle,
              yawAngle: _yawAngle,
              zoomLevel: _zoomLevel,
              panOffset: _panOffset,
              onPanUpdate: (offset) => setState(() => _panOffset = offset),
              onZoomUpdate: (zoom) => setState(() => _zoomLevel = zoom),
            ),
          ),

          // 2. Floating Vintage UI Controls & Header Overlay
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWidescreenLaptop = constraints.maxWidth > 840;

                return Column(
                  children: [
                    // Top Floating Vintage Control Header
                    _buildHeader(),

                    // Main Viewport with Floating Inspector Card
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Align(
                          alignment: isWidescreenLaptop ? Alignment.centerLeft : Alignment.bottomCenter,
                          child: SizedBox(
                            width: isWidescreenLaptop ? 340 : double.infinity,
                            child: _buildInspectorCard(stateData),
                          ),
                        ),
                      ),
                    ),

                    // Bottom Floating Controls Toolbar
                    _buildControlsBar(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── HEADER ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final hoveredData = _hoveredStateId != null
        ? IndiaStatesDatabase.getState(_hoveredStateId!)
        : null;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF3D2716).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFB8860B), width: 1.8),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          WoodenBackButton(
            size: 38,
            onTap: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'VINTAGE GROUND MAP',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.8,
                    color: Color(0xFFFFF176),
                  ),
                ),
                Text(
                  hoveredData != null
                      ? 'Hovering: ${hoveredData.name}'
                      : 'Full-screen 3D ground map • Tilt & tap states',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    color: Colors.amber.shade200,
                  ),
                ),
              ],
            ),
          ),

          // Preset View Mode Buttons
          _buildPresetButton('3D Ground', Icons.view_in_ar_rounded, _pitchAngle > 0.3 && !_isAutoTilting, _setGroundView),
          const SizedBox(width: 6),
          _buildPresetButton('2D Flat', Icons.map_rounded, _pitchAngle < 0.2 && !_isAutoTilting, _setTopDownView),
          const SizedBox(width: 6),
          _buildPresetButton('Auto-Orbit', Icons.sync_rounded, _isAutoTilting, _toggleAutoTilt),
        ],
      ),
    );
  }

  Widget _buildPresetButton(String label, IconData icon, bool isActive, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFB8860B) : const Color(0xFF5D4037),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive ? const Color(0xFFFFD54F) : const Color(0xFF8D6E63),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: isActive ? Colors.white : const Color(0xFFFFD54F)),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.white : const Color(0xFFFFF176),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── STATE INSPECTOR CARD ──────────────────────────────────────────────────
  Widget _buildInspectorCard(IndiaStateData? data) {
    if (data == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF3D2716).withValues(alpha: 0.90),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFB8860B), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.touch_app_rounded, size: 36, color: Color(0xFFFFD54F)),
            SizedBox(height: 10),
            Text(
              'SELECT A STATE',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFF176),
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Tap any state on the 3D map board to view its capital, language, and cultural facts.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF3D2716),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFD54F), width: 2.0),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF5D4037),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFD54F), width: 1.2),
                ),
                child: Icon(data.illustrationIcon, color: const Color(0xFFFFD54F), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.name.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFFF176),
                      ),
                    ),
                    Text(
                      'Capital: ${data.capital}',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _selectedStateId = null),
                icon: const Icon(Icons.close_rounded, color: Colors.white54),
              ),
            ],
          ),
          const Divider(color: Color(0xFF8D6E63), height: 18),
          _buildInfoRow(Icons.record_voice_over_rounded, 'Language', data.language),
          const SizedBox(height: 6),
          _buildInfoRow(Icons.star_rounded, 'Famous For', data.famousFor),
          const SizedBox(height: 6),
          _buildInfoRow(Icons.restaurant_rounded, 'Famous Food', data.food),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF2C190B),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFB8860B).withValues(alpha: 0.5)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_rounded, color: Color(0xFFFFD54F), size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    data.fact,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.5,
                      height: 1.3,
                      color: Color(0xFFFFF8E1),
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

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFFFFD54F)),
        const SizedBox(width: 6),
        Text(
          '$title: ',
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFFE082),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ── BOTTOM TOOLBAR & TILT SLIDER ──────────────────────────────────────────
  Widget _buildControlsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF1E140C),
      child: Row(
        children: [
          const Icon(Icons.rotate_right_rounded, color: Color(0xFFFFD54F), size: 20),
          const SizedBox(width: 8),
          const Text(
            'GROUND TILT',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFD54F),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: const Color(0xFFFFD54F),
                inactiveTrackColor: const Color(0xFF5D4037),
                thumbColor: const Color(0xFFFFF176),
                overlayColor: const Color(0xFFFFD54F).withValues(alpha: 0.2),
                trackHeight: 3.5,
              ),
              child: Slider(
                value: _pitchAngle,
                min: 0.0,  // Top-down 2D
                max: 1.25, // Extreme 3D horizontal tilt
                onChanged: (val) {
                  setState(() {
                    _isAutoTilting = false;
                    _autoTiltController.stop();
                    _pitchAngle = val;
                  });
                },
              ),
            ),
          ),
          TextButton.icon(
            onPressed: _resetCamera,
            icon: const Icon(Icons.refresh_rounded, size: 16, color: Colors.amber),
            label: const Text(
              'RESET',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
