import 'package:flutter/material.dart';
import '../models/story_chapter.dart';

class ChapterNodeWidget extends StatefulWidget {
  final StoryChapter chapter;
  final VoidCallback onTap;
  final double size;

  const ChapterNodeWidget({
    super.key,
    required this.onTap,
    required this.chapter,
    this.size = 76.0,
  });

  @override
  State<ChapterNodeWidget> createState() => _ChapterNodeWidgetState();
}

class _ChapterNodeWidgetState extends State<ChapterNodeWidget> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final chapter = widget.chapter;
    final isLocked = chapter.isLocked;
    final isCompleted = chapter.isCompleted;
    final isAvailable = chapter.isAvailable;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.90 : (_isHovered && !isLocked ? 1.08 : 1.0),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutBack,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Circular Royal Blue / Muted Cyan Node
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isCompleted
                      ? const LinearGradient(
                          colors: [Color(0xFF0D9488), Color(0xFF0F766E), Color(0xFF042F2E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : (isAvailable
                          ? const LinearGradient(
                              colors: [Color(0xFF1D4ED8), Color(0xFF1E40AF), Color(0xFF0F172A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : const LinearGradient(
                              colors: [Color(0xFF1E1B4B), Color(0xFF0F172A), Color(0xFF070A12)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )),
                  border: Border.all(
                    color: isCompleted
                        ? const Color(0xFF2DD4BF)
                        : (isAvailable ? const Color(0xFF38BDF8) : const Color(0xFF475569)),
                    width: isAvailable || isCompleted ? 3.0 : 2.0,
                  ),
                  boxShadow: [
                    if (isAvailable || isCompleted)
                      BoxShadow(
                        color: (isCompleted ? const Color(0xFF2DD4BF) : const Color(0xFF38BDF8))
                            .withValues(alpha: 0.45),
                        blurRadius: 14,
                        spreadRadius: 2,
                      )
                    else
                      const BoxShadow(
                        color: Colors.black45,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Node Icon / Lock
                    Icon(
                      isLocked ? Icons.lock_rounded : chapter.icon,
                      size: isLocked ? 28 : 34,
                      color: isCompleted
                          ? const Color(0xFF99F6E4)
                          : (isAvailable ? const Color(0xFFE0F2FE) : const Color(0xFF64748B)),
                    ),

                    // Top-Right Status Badge (Checkmark for completed, CH # for available)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? const Color(0xFF0D9488)
                              : (isAvailable ? const Color(0xFF0284C7) : const Color(0xFF334155)),
                          border: Border.all(color: const Color(0xFF38BDF8), width: 1.5),
                        ),
                        child: isCompleted
                            ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
                            : Text(
                                '${chapter.id}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // Short Chapter Title Label Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isLocked
                      ? const Color(0xFF0F172A).withValues(alpha: 0.90)
                      : const Color(0xFF1E293B).withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCompleted
                        ? const Color(0xFF2DD4BF).withValues(alpha: 0.8)
                        : (isAvailable
                            ? const Color(0xFF38BDF8).withValues(alpha: 0.8)
                            : const Color(0xFF334155)),
                    width: 1.2,
                  ),
                ),
                child: Text(
                  chapter.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Outfit',
                    color: isLocked
                        ? const Color(0xFF64748B)
                        : (isCompleted ? const Color(0xFF99F6E4) : const Color(0xFFE0F2FE)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
