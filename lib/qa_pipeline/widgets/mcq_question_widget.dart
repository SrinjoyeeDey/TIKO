import 'dart:math' as math;
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../models/mcq_question.dart';

/// Renders an MCQ question in a clean, transparent 3D Vintage Speech Bubble layout
/// with 3D Parallax Tilt, Confetti Celebration, Gentle Shake Feedback, and Bobbing Question Marks.
class McqQuestionWidget extends StatefulWidget {
  final McqQuestion question;
  final int questionNumber;
  final String phaseLabel;

  /// Called after the user submits and views feedback.
  /// [isCorrect] indicates whether the selected answer was right.
  final ValueChanged<bool> onAnswered;

  /// Called immediately on submission to trigger character animations without waiting for next question.
  final ValueChanged<bool>? onPandaReaction;

  const McqQuestionWidget({
    super.key,
    required this.question,
    required this.questionNumber,
    required this.phaseLabel,
    required this.onAnswered,
    this.onPandaReaction,
  });

  @override
  State<McqQuestionWidget> createState() => _McqQuestionWidgetState();
}

class _McqQuestionWidgetState extends State<McqQuestionWidget>
    with SingleTickerProviderStateMixin {
  String? _selectedKey;
  bool _submitted = false;

  ConfettiController? _confettiController;
  AnimationController? _shakeController;

  ConfettiController get confettiController {
    _confettiController ??= ConfettiController(
      duration: const Duration(seconds: 2),
    );
    return _confettiController!;
  }

  AnimationController get shakeController {
    _shakeController ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    return _shakeController!;
  }

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
  }

  @override
  void dispose() {
    _confettiController?.dispose();
    _shakeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final sortedKeys = q.options.keys.toList()..sort();

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              // CLEAN TRANSPARENT VINTAGE SPEECH BUBBLE CARD WITH 3D TILT
              _VintageSpeechBubbleCard(
                questionText: q.questionText,
                child: Column(
                  children: [
                    // Options Grid / Rows with Haptic Shake Feedback
                    AnimatedBuilder(
                      animation: shakeController,
                      builder: (context, child) {
                        final shakeVal = math.sin(shakeController.value * math.pi * 4) * 12.0;
                        return Transform.translate(
                          offset: Offset(shakeVal, 0),
                          child: child,
                        );
                      },
                      child: sortedKeys.length <= 2
                          ? Row(
                              children: sortedKeys.map((key) {
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6),
                                    child: _buildOptionCard(key, q.options[key]!),
                                  ),
                                );
                              }).toList(),
                            )
                          : Column(
                              children: [
                                // Top pair (A, B)
                                Row(
                                  children: sortedKeys.take(2).map((key) {
                                    return Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 6),
                                        child: _buildOptionCard(key, q.options[key]!),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 12),
                                // Bottom pair (C, D)
                                Row(
                                  children: sortedKeys.skip(2).map((key) {
                                    return Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 6),
                                        child: _buildOptionCard(key, q.options[key]!),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                    ),

                    const SizedBox(height: 24),

                    // Submit / Continue Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _canAct ? _onButtonPressed : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4AF37), // Vintage Gold
                          foregroundColor: const Color(0xFF2E1C12),
                          disabledBackgroundColor: Colors.white12,
                          disabledForegroundColor: Colors.white30,
                          elevation: 6,
                          shadowColor: Colors.black45,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: Color(0xFFFFF8E1), width: 1.5),
                          ),
                          textStyle: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        child: Text(_submitted ? 'CONTINUE →' : 'SUBMIT ANSWER'),
                      ),
                    ),

                    // Feedback Banner after submission
                    if (_submitted) ...[
                      const SizedBox(height: 18),
                      _buildFeedback(),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        // CONFETTI CELEBRATION OVERLAY
        ConfettiWidget(
          confettiController: confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          shouldLoop: false,
          colors: const [
            Color(0xFFFFD700),
            Color(0xFFFFB300),
            Color(0xFF4CAF50),
            Color(0xFF2196F3),
            Color(0xFFE91E63),
          ],
        ),
      ],
    );
  }

  Widget _buildOptionCard(String key, String text) {
    final bool isCorrect = key == widget.question.correctAnswerKey;
    final bool isSelected = key == _selectedKey;

    // Transparent vintage parchment card styling
    Color cardBg = const Color(0x401E100A);
    Color borderColor = const Color(0xFFD4AF37); // Vintage Gold
    Color badgeBg = const Color(0xFFFAF4EE);
    Color badgeTextColor = const Color(0xFF3E2716);

    if (_submitted) {
      if (isCorrect) {
        cardBg = const Color(0xCC1B5E20); // Semi-transparent Emerald Green
        borderColor = const Color(0xFFA5D6A7);
        badgeBg = const Color(0xFFA5D6A7);
        badgeTextColor = const Color(0xFF1B5E20);
      } else if (isSelected && !isCorrect) {
        cardBg = const Color(0xCCB71C1C); // Semi-transparent Crimson Red
        borderColor = const Color(0xFFEF9A9A);
        badgeBg = const Color(0xFFEF9A9A);
        badgeTextColor = const Color(0xFFB71C1C);
      }
    } else if (isSelected) {
      cardBg = const Color(0xEEFFB300); // Amber/Gold Active
      borderColor = const Color(0xFFFFF8E1);
      badgeBg = const Color(0xFF3E2716);
      badgeTextColor = const Color(0xFFFFD700);
    }

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        // Main Transparent Option Card Container
        InkWell(
          onTap: _submitted ? null : () => setState(() => _selectedKey = key),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(top: 14),
            padding: const EdgeInsets.fromLTRB(10, 22, 10, 16),
            height: 78,
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 2.0),
              boxShadow: [
                BoxShadow(
                  color: isSelected ? cardBg.withValues(alpha: 0.6) : Colors.black26,
                  blurRadius: isSelected ? 12 : 4,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                text.toUpperCase(),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.5,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.6,
                  shadows: [
                    Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(1, 1)),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Floating Letter Badge ("A", "B", "C", "D") Centered Right Over Top Border
        Positioned(
          top: 0,
          child: IgnorePointer(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor, width: 1.8),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: Text(
                key,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: badgeTextColor,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeedback() {
    final isCorrect = widget.question.isCorrect(_selectedKey!);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCorrect
            ? const Color(0xDD1B5E20)
            : const Color(0xDDB71C1C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCorrect ? const Color(0xFFA5D6A7) : const Color(0xFFEF9A9A),
          width: 1.8,
        ),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Row(
        children: [
          Icon(
            isCorrect ? Icons.check_circle : Icons.cancel,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isCorrect ? 'EXCELLENT! Correct Answer.' : 'INCORRECT. The correct answer is ${widget.question.correctAnswerKey}.',
              style: const TextStyle(
                fontFamily: 'Outfit',
                color: Colors.white,
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool get _canAct {
    if (!_submitted) return _selectedKey != null;
    return true;
  }

  void _onButtonPressed() {
    if (!_submitted) {
      final isCorrect = widget.question.isCorrect(_selectedKey!);
      setState(() => _submitted = true);

      widget.onPandaReaction?.call(isCorrect);

      if (isCorrect) {
        confettiController.play();
      } else {
        shakeController.forward(from: 0.0);
      }
    } else {
      widget.onAnswered(widget.question.isCorrect(_selectedKey!));
    }
  }
}

/// Clean Transparent Vintage Speech Bubble Card Container with 3D Mouse Parallax Tilt
class _VintageSpeechBubbleCard extends StatefulWidget {
  final String questionText;
  final Widget child;

  const _VintageSpeechBubbleCard({
    required this.questionText,
    required this.child,
  });

  @override
  State<_VintageSpeechBubbleCard> createState() => _VintageSpeechBubbleCardState();
}

class _VintageSpeechBubbleCardState extends State<_VintageSpeechBubbleCard> {
  double _tiltX = 0.0;
  double _tiltY = 0.0;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) {
        final RenderBox? box = context.findRenderObject() as RenderBox?;
        if (box != null && box.hasSize && box.size.width > 0 && box.size.height > 0) {
          final localPos = box.globalToLocal(event.position);
          final size = box.size;
          setState(() {
            _tiltX = ((localPos.dx / size.width) - 0.5) * 0.06;
            _tiltY = -((localPos.dy / size.height) - 0.5) * 0.06;
          });
        }
      },
      onExit: (_) {
        setState(() {
          _tiltX = 0.0;
          _tiltY = 0.0;
        });
      },
      child: Transform(
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001) // 3D Perspective
          ..rotateY(_tiltX)
          ..rotateX(_tiltY),
        alignment: Alignment.center,
        child: CustomPaint(
          painter: _SpeechBubblePainter(),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 36),
            margin: const EdgeInsets.only(bottom: 20, right: 10, top: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Stylized Giant White Question Marks Header (¿  ?  ?)
                const _VintageQuestionMarksHeader(),
                const SizedBox(height: 16),

                // Question Text
                Text(
                  widget.questionText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.35,
                    shadows: [
                      Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(1, 1)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Child Options / Controls
                widget.child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter for transparent vintage speech bubble with a gold outline
class _SpeechBubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height - 22);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(32));

    // Tail path at bottom right
    final tailPath = Path()
      ..moveTo(size.width * 0.74, size.height - 22)
      ..lineTo(size.width * 0.86, size.height)
      ..lineTo(size.width * 0.82, size.height - 22)
      ..close();

    final fullPath = Path.combine(
      PathOperation.union,
      Path()..addRRect(rrect),
      tailPath,
    );

    // Semi-transparent dark vintage sepia backdrop (lets 1913 map show through!)
    final fillPaint = Paint()
      ..color = const Color(0xB51E100A)
      ..style = PaintingStyle.fill;

    // Border stroke in bright vintage gold
    final strokePaint = Paint()
      ..color = const Color(0xFFD4AF37)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Shadow
    canvas.drawShadow(fullPath, Colors.black54, 10.0, true);
    canvas.drawPath(fullPath, fillPaint);
    canvas.drawPath(fullPath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Stylized Giant White Question Marks Header with smooth floating bobbing animation
class _VintageQuestionMarksHeader extends StatefulWidget {
  const _VintageQuestionMarksHeader();

  @override
  State<_VintageQuestionMarksHeader> createState() => _VintageQuestionMarksHeaderState();
}

class _VintageQuestionMarksHeaderState extends State<_VintageQuestionMarksHeader>
    with SingleTickerProviderStateMixin {
  AnimationController? _bobController;

  AnimationController get bobController {
    _bobController ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    return _bobController!;
  }

  @override
  void initState() {
    super.initState();
    _bobController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bobController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: bobController,
      builder: (context, child) {
        final floatOffset = math.sin(bobController.value * math.pi * 2) * 5.0;
        return Transform.translate(
          offset: Offset(0, floatOffset),
          child: child,
        );
      },
      child: SizedBox(
        height: 115,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Background crisp white radiating burst lines
            CustomPaint(
              size: const Size(280, 110),
              painter: _BurstRaysPainter(),
            ),

            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Left Inverted Question Mark (¿) — Pure White
                Transform.rotate(
                  angle: -0.18,
                  child: Stack(
                    children: [
                      Text(
                        '¿',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 66,
                          fontWeight: FontWeight.w900,
                          foreground: Paint()
                            ..style = PaintingStyle.stroke
                            ..strokeWidth = 4.5
                            ..color = Colors.white.withValues(alpha: 0.80),
                        ),
                      ),
                      const Text(
                        '¿',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 66,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          shadows: [
                            Shadow(color: Colors.black87, blurRadius: 8, offset: Offset(2, 3)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // 2. Giant Center Question Mark (?) — 100pt Pure White
                Transform.rotate(
                  angle: 0.05,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer White Offset Outline
                      Positioned(
                        left: 3,
                        top: 3,
                        child: Text(
                          '?',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 100,
                            fontWeight: FontWeight.w900,
                            foreground: Paint()
                              ..style = PaintingStyle.stroke
                              ..strokeWidth = 5.0
                              ..color = Colors.white.withValues(alpha: 0.90),
                          ),
                        ),
                      ),
                      // Inner Giant White Symbol
                      const Text(
                        '?',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 100,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          shadows: [
                            Shadow(color: Colors.black, blurRadius: 12, offset: Offset(3, 4)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // 3. Right Small Question Mark (?) — Pure White
                Transform.rotate(
                  angle: 0.22,
                  child: Stack(
                    children: [
                      Text(
                        '?',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 60,
                          fontWeight: FontWeight.w900,
                          foreground: Paint()
                            ..style = PaintingStyle.stroke
                            ..strokeWidth = 4.5
                            ..color = Colors.white.withValues(alpha: 0.80),
                        ),
                      ),
                      const Text(
                        '?',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 60,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          shadows: [
                            Shadow(color: Colors.black87, blurRadius: 8, offset: Offset(2, 3)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BurstRaysPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;
    final cy = size.height / 2;

    // Crisp white radial burst rays around the giant question marks
    canvas.drawLine(Offset(cx - 95, cy - 35), Offset(cx - 115, cy - 48), paint);
    canvas.drawLine(Offset(cx - 65, cy - 45), Offset(cx - 78, cy - 60), paint);
    canvas.drawLine(Offset(cx + 65, cy - 45), Offset(cx + 78, cy - 60), paint);
    canvas.drawLine(Offset(cx + 95, cy - 35), Offset(cx + 115, cy - 48), paint);
    canvas.drawLine(Offset(cx - 35, cy + 42), Offset(cx - 45, cy + 56), paint);
    canvas.drawLine(Offset(cx + 35, cy + 42), Offset(cx + 45, cy + 56), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
