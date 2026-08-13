import 'package:flutter/material.dart';

/// Animated star display for the level-clear celebration.
///
/// Stars appear one by one with a scale-and-fade animation.
class LevelClearAnimation extends StatefulWidget {
  final int starCount;

  const LevelClearAnimation({super.key, required this.starCount});

  @override
  State<LevelClearAnimation> createState() => _LevelClearAnimationState();
}

class _LevelClearAnimationState extends State<LevelClearAnimation>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _scaleAnimations;
  late final List<Animation<double>> _opacityAnimations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (index) {
      return AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      );
    });

    _scaleAnimations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.elasticOut),
      );
    }).toList();

    _opacityAnimations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
        ),
      );
    }).toList();

    // Stagger the star animations.
    _animateStars();
  }

  Future<void> _animateStars() async {
    for (int i = 0; i < widget.starCount && i < 3; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        _controllers[i].forward();
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isEarned = index < widget.starCount;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: ListenableBuilder(
            listenable: _controllers[index],
            builder: (context, child) {
              return Transform.scale(
                scale: isEarned ? _scaleAnimations[index].value : 1.0,
                child: Opacity(
                  opacity: isEarned
                      ? _opacityAnimations[index].value
                      : 0.3,
                  child: child,
                ),
              );
            },
            child: Icon(
              isEarned ? Icons.star_rounded : Icons.star_border_rounded,
              size: 56,
              color: isEarned
                  ? const Color(0xFFFFD700)
                  : Colors.white.withValues(alpha: 0.3),
            ),
          ),
        );
      }),
    );
  }
}
