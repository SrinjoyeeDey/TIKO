import 'package:flutter/material.dart';

class SteampunkScrollTreasureNode extends StatefulWidget {
  final bool isUnlocked;
  final VoidCallback onTap;

  const SteampunkScrollTreasureNode({
    super.key,
    required this.isUnlocked,
    required this.onTap,
  });

  @override
  State<SteampunkScrollTreasureNode> createState() => _SteampunkScrollTreasureNodeState();
}

class _SteampunkScrollTreasureNodeState extends State<SteampunkScrollTreasureNode>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUnlocked = widget.isUnlocked;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedBuilder(
          animation: _glowController,
          builder: (context, child) {
            final pulse = _glowController.value;

            return AnimatedScale(
              scale: _isPressed ? 0.94 : (_isHovered ? 1.08 : (isUnlocked ? 1.06 : 1.0)),
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                // Make unlocked centerpiece BIGGER (240px wide vs 205px)
                width: isUnlocked ? 240 : 205,
                height: isUnlocked ? 210 : 185,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 1. Aged Parchment Scroll Container (Emerald Green & Gold when Unlocked!)
                    Container(
                      margin: const EdgeInsets.only(top: 24),
                      width: isUnlocked ? 230 : 195,
                      padding: EdgeInsets.fromLTRB(16, isUnlocked ? 32 : 28, 16, 16),
                      decoration: BoxDecoration(
                        gradient: isUnlocked
                            ? const LinearGradient(
                                colors: [
                                  Color(0xFFDCFCE7), // Radiant Emerald Parchment Light
                                  Color(0xFF86EFAC), // Emerald Gold Middle
                                  Color(0xFF22C55E), // Deep Emerald Base
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              )
                            : const LinearGradient(
                                colors: [
                                  Color(0xFFF9ECC9), // Parchment ivory top
                                  Color(0xFFEDE0B8), // Middle aged paper
                                  Color(0xFFDFCC9B), // Bottom vintage paper
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isUnlocked
                              ? const Color(0xFFFFF176) // Radiant Gold border
                              : (_isHovered ? const Color(0xFFFFD54F) : const Color(0xFF5D4037)),
                          width: isUnlocked ? 3.5 : (_isHovered ? 3.0 : 2.5),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (isUnlocked
                                    ? const Color(0xFF22C55E) // Emerald Radiant Glow
                                    : (_isHovered
                                        ? const Color(0xFFFFD54F)
                                        : const Color(0xFF8D5B2A)))
                                .withValues(alpha: isUnlocked ? 0.65 + pulse * 0.25 : 0.35 + pulse * 0.30),
                            blurRadius: isUnlocked ? 28 + pulse * 10 : (_isHovered ? 24 : 16 + pulse * 8),
                            spreadRadius: isUnlocked ? 4 : (_isHovered ? 3 : 2),
                          ),
                          const BoxShadow(
                            color: Colors.black54,
                            blurRadius: 12,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Burnt Paper Corner Vignette Shading
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _ParchmentTexturePainter(isUnlocked: isUnlocked),
                            ),
                          ),

                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(height: isUnlocked ? 12 : 10),
                              // Title: ULTIMATE CROWN UNLOCKED! vs MYSTERY CROWN
                              Text(
                                isUnlocked ? '★ ULTIMATE CROWN UNLOCKED! ★' : 'MYSTERY CROWN',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: isUnlocked ? 15 : 14,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Outfit',
                                  letterSpacing: 1.2,
                                  color: isUnlocked
                                      ? const Color(0xFF064E3B) // Dark Emerald Ink
                                      : const Color(0xFF2C1C0F), // Vintage dark ink
                                ),
                              ),

                              const SizedBox(height: 4),

                              // Subtitle
                              Text(
                                isUnlocked
                                    ? 'You achieved the Ultimate Mastery! Tap to claim reward!'
                                    : 'Are you ready to unlock your true self?',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: isUnlocked ? 11 : 10,
                                  fontWeight: FontWeight.bold,
                                  height: 1.3,
                                  color: isUnlocked ? const Color(0xFF14532D) : const Color(0xFF4A3423),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // 2. Heavy Iron / Golden Crown Lock Mechanism Securing the Top
                    Positioned(
                      top: 0,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Custom Lock Gear Painter
                          CustomPaint(
                            size: Size(isUnlocked ? 72 : 64, isUnlocked ? 72 : 64),
                            painter: _HeavyIronGearLockPainter(isUnlocked: isUnlocked),
                          ),

                          // Lock Badge Label (🔒 LOCKED / ★ ULTIMATE ★)
                          Positioned(
                            bottom: 0,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isUnlocked ? const Color(0xFF15803D) : const Color(0xFF2A1F18),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isUnlocked ? const Color(0xFFFFF176) : const Color(0xFFFFD54F),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isUnlocked ? Icons.stars_rounded : Icons.lock_rounded,
                                    size: 11,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    isUnlocked ? 'ULTIMATE' : 'LOCKED',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Aged Parchment Vintage Texture Painter
class _ParchmentTexturePainter extends CustomPainter {
  final bool isUnlocked;

  _ParchmentTexturePainter({required this.isUnlocked});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final burntPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          (isUnlocked ? const Color(0xFF15803D) : const Color(0xFF8D5B2A)).withValues(alpha: 0.15),
          (isUnlocked ? const Color(0xFF064E3B) : const Color(0xFF5D4037)).withValues(alpha: 0.30),
        ],
        stops: const [0.6, 0.85, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), burntPaint);
  }

  @override
  bool shouldRepaint(covariant _ParchmentTexturePainter oldDelegate) =>
      oldDelegate.isUnlocked != isUnlocked;
}

// Heavy Iron / Emerald Gold Lock Mechanism Painter
class _HeavyIronGearLockPainter extends CustomPainter {
  final bool isUnlocked;

  _HeavyIronGearLockPainter({required this.isUnlocked});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    // 1. Shackle Bar
    final shacklePaint = Paint()
      ..color = isUnlocked ? const Color(0xFFFFF176) : const Color(0xFF1E130B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0;

    final shacklePath = Path()
      ..moveTo(center.dx - 14, center.dy)
      ..lineTo(center.dx - 14, center.dy - 18)
      ..cubicTo(center.dx - 14, center.dy - 28, center.dx + 14, center.dy - 28, center.dx + 14, center.dy - 18)
      ..lineTo(center.dx + 14, center.dy);

    canvas.drawPath(shacklePath, shacklePaint);

    // 2. Lock Body
    final lockBodyGradient = Paint()
      ..shader = (isUnlocked
          ? const LinearGradient(
              colors: [Color(0xFF4ADE80), Color(0xFF22C55E), Color(0xFF15803D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : const LinearGradient(
              colors: [Color(0xFF5D483A), Color(0xFF3E2D23), Color(0xFF261910)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawCircle(center, 24, lockBodyGradient);

    final borderPaint = Paint()
      ..color = isUnlocked ? const Color(0xFFFFF176) : const Color(0xFF1E130B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawCircle(center, 24, borderPaint);

    // Inner Icon (Crown/Star for Unlocked, Keyhole for Locked)
    if (isUnlocked) {
      final starPaint = Paint()..color = const Color(0xFFFFF176);
      canvas.drawCircle(center, 8, starPaint);
    } else {
      final keyholePaint = Paint()..color = const Color(0xFF120A05);
      canvas.drawCircle(Offset(center.dx, center.dy - 2), 4, keyholePaint);
      canvas.drawRect(Rect.fromLTWH(center.dx - 2.5, center.dy - 2, 5, 8), keyholePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HeavyIronGearLockPainter oldDelegate) =>
      oldDelegate.isUnlocked != isUnlocked;
}
