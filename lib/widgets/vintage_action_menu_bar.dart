import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Item data model for Vintage Emblem Menu Items
class VintageMenuItemData {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const VintageMenuItemData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
}

/// Vintage Action Menu Bar Widget
/// Displays a horizontal row of 5 geometric mandala emblem badges at the bottom of the map.
/// Includes pop-bubble hover animations, gold mandala line art, and a cute mascot bottom divider.
class VintageActionMenuBar extends StatelessWidget {
  final List<VintageMenuItemData> items;

  const VintageActionMenuBar({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Horizontal Row of 5 Bubble-Popping Emblem Badges
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 650;

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: items.map((item) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: isCompact ? 2.0 : 6.0),
                      child: _VintageHoverEmblem(item: item, isCompact: isCompact),
                    ),
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 14),

          // 2. Bottom Decorative Mascot Line Divider:  ────-─── ( 👻 ) ───────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 140,
                height: 1.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      const Color(0xFFFFD54F).withValues(alpha: 0.6),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Cute Mascot Icon
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFF3E2716),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFFD54F).withValues(alpha: 0.8),
                    width: 1.2,
                  ),
                  boxShadow: const [
                    BoxShadow(color: Colors.black45, blurRadius: 6),
                  ],
                ),
                child: const Text(
                  '👻',
                  style: TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 140,
                height: 1.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFFD54F).withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Individual Emblem Badge with Bubble Pop Animation on Hover
class _VintageHoverEmblem extends StatefulWidget {
  final VintageMenuItemData item;
  final bool isCompact;

  const _VintageHoverEmblem({
    required this.item,
    required this.isCompact,
  });

  @override
  State<_VintageHoverEmblem> createState() => _VintageHoverEmblemState();
}

class _VintageHoverEmblemState extends State<_VintageHoverEmblem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    // Playful elastic bubble-pop spring curve on hover
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onHover(bool hover) {
    setState(() {
      _isHovered = hover;
    });
    if (hover) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final double iconSize = widget.isCompact ? 44.0 : 54.0;

    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.item.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _scaleAnim,
          builder: (context, child) {
            final scale = 1.0 + (_scaleAnim.value * 0.18); // Pop up 18% on hover!

            return Transform.scale(
              scale: scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Circular Mandala Frame with Icon
                  Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isHovered
                          ? const Color(0xFF4E342E)
                          : const Color(0xFF2C190B).withValues(alpha: 0.85),
                      boxShadow: [
                        BoxShadow(
                          color: _isHovered
                              ? const Color(0xFFFFD54F).withValues(alpha: 0.55)
                              : Colors.black45,
                          blurRadius: _isHovered ? 14 : 6,
                          spreadRadius: _isHovered ? 2 : 0,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: CustomPaint(
                      painter: _MandalaFramePainter(isHovered: _isHovered),
                      child: Center(
                        child: Icon(
                          widget.item.icon,
                          size: widget.isCompact ? 20 : 24,
                          color: _isHovered
                              ? const Color(0xFFFFF176)
                              : const Color(0xFFFFD54F),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Title Text (e.g. EXPLORE)
                  Text(
                    widget.item.title.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: widget.isCompact ? 10 : 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: _isHovered
                          ? const Color(0xFFFFF176)
                          : const Color(0xFFFFE082),
                      shadows: const [
                        Shadow(color: Colors.black87, blurRadius: 4),
                      ],
                    ),
                  ),

                  const SizedBox(height: 2),

                  // Subtitle Text (e.g. VAST LANDS)
                  Text(
                    widget.item.subtitle.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: widget.isCompact ? 7.5 : 8.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                      color: _isHovered ? Colors.white : Colors.white70,
                      shadows: const [
                        Shadow(color: Colors.black87, blurRadius: 4),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Custom Painter drawing 12-point Geometric Star Mandala Ring around emblem icon
class _MandalaFramePainter extends CustomPainter {
  final bool isHovered;

  _MandalaFramePainter({required this.isHovered});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.width / 2 - 3;

    final outerPaint = Paint()
      ..color = isHovered
          ? const Color(0xFFFFD54F)
          : const Color(0xFFD4B886).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isHovered ? 1.8 : 1.2;

    final innerPaint = Paint()
      ..color = isHovered
          ? const Color(0xFFFFF176).withValues(alpha: 0.6)
          : const Color(0xFFB8860B).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // 1. Draw Inner Circle
    canvas.drawCircle(Offset(cx, cy), radius - 4, innerPaint);

    // 2. Draw 12-Point Geometric Star Frame
    const int points = 12;
    final path = Path();
    for (int i = 0; i < points * 2; i++) {
      final angle = (i * math.pi) / points;
      final r = (i % 2 == 0) ? radius : radius - 3.5;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, outerPaint);
  }

  @override
  bool shouldRepaint(covariant _MandalaFramePainter oldDelegate) {
    return oldDelegate.isHovered != isHovered;
  }
}
