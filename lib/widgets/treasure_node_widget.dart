import 'package:flutter/material.dart';

class TreasureNodeWidget extends StatefulWidget {
  final bool isUnlocked;
  final VoidCallback onTap;
  final double size;

  const TreasureNodeWidget({
    super.key,
    required this.isUnlocked,
    required this.onTap,
    this.size = 100.0,
  });

  @override
  State<TreasureNodeWidget> createState() => _TreasureNodeWidgetState();
}

class _TreasureNodeWidgetState extends State<TreasureNodeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  bool _isHovered = false;

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
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _glowController,
          builder: (context, child) {
            final pulse = _glowController.value;
            final isUnlocked = widget.isUnlocked;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Violet-Blue & Royal Blue Centerpiece Medallion Node
                AnimatedScale(
                  scale: _isHovered ? 1.08 : (isUnlocked ? 1.05 : 1.0),
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isUnlocked
                          ? const LinearGradient(
                              colors: [Color(0xFF0D9488), Color(0xFF0284C7), Color(0xFF1E1B4B)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : const LinearGradient(
                              colors: [Color(0xFF4F46E5), Color(0xFF1D4ED8), Color(0xFF0F172A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      border: Border.all(
                        color: isUnlocked ? const Color(0xFF38BDF8) : const Color(0xFF818CF8),
                        width: 3.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isUnlocked ? const Color(0xFF38BDF8) : const Color(0xFF6366F1))
                              .withValues(alpha: 0.35 + (pulse * 0.30)),
                          blurRadius: 20 + (pulse * 10),
                          spreadRadius: 3 + (pulse * 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Treasure Icon
                        Icon(
                          isUnlocked ? Icons.auto_awesome_rounded : Icons.lock_rounded,
                          size: 44,
                          color: isUnlocked ? const Color(0xFF38BDF8) : const Color(0xFFC7D2FE),
                        ),

                        // Lock / Unlock Badge
                        Positioned(
                          bottom: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isUnlocked ? const Color(0xFF0D9488) : const Color(0xFF1E1B4B),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF38BDF8), width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isUnlocked ? Icons.lock_open_rounded : Icons.lock_rounded,
                                  size: 10,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  isUnlocked ? 'UNLOCKED' : 'LOCKED',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
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
                ),

                const SizedBox(height: 10),

                // Empowering Accessible Text Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isUnlocked ? const Color(0xFF38BDF8) : const Color(0xFF6366F1),
                      width: 1.4,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        isUnlocked ? 'TRUE SELF UNLOCKED!' : 'MYSTERY CROWN',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          fontFamily: 'Outfit',
                          color: isUnlocked ? const Color(0xFF38BDF8) : const Color(0xFFA5B4FC),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isUnlocked
                            ? 'You unlocked your potential!'
                            : 'Are you ready to unlock your true self?',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: isUnlocked ? Colors.white : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
