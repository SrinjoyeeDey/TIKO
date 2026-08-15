import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/descriptive_question.dart';
import '../services/keyword_matcher.dart';

/// Renders a descriptive question inside a high-contrast 3D Vintage Speech Bubble Card
/// with crisp white text, dark parchment input field, and vintage gold action button.
class DescriptiveQuestionWidget extends StatefulWidget {
  final DescriptiveQuestion question;
  final int questionNumber;

  /// Called after the user views the feedback.
  /// [passed] is true if the score met the threshold.
  final ValueChanged<bool> onAnswered;

  /// Optional detailed callback with similarity score and user answer
  /// for database persistence. If provided, this is called instead of [onAnswered].
  final void Function(bool isCorrect, double score, String userAnswer)?
      onAnsweredDetailed;

  /// Called synchronously the exact instant the answer is evaluated upon submit.
  final ValueChanged<bool>? onAnswerEvaluated;

  const DescriptiveQuestionWidget({
    super.key,
    required this.question,
    required this.questionNumber,
    required this.onAnswered,
    this.onAnsweredDetailed,
    this.onAnswerEvaluated,
  });

  @override
  State<DescriptiveQuestionWidget> createState() =>
      _DescriptiveQuestionWidgetState();
}

class _DescriptiveQuestionWidgetState extends State<DescriptiveQuestionWidget> {
  final _controller = TextEditingController();
  bool _submitted = false;
  double _score = 0.0;
  bool _passed = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          // CLEAN TRANSPARENT VINTAGE SPEECH BUBBLE CARD WITH 3D TILT
          _VintageSpeechBubbleCard(
            questionText: widget.question.questionText,
            child: Column(
              children: [
                // High-Contrast Dark Parchment Answer Text Field
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xEE2E1C12), // High Contrast Dark Sepia Canvas
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFD4AF37), width: 2.0),
                    boxShadow: const [
                      BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 4)),
                    ],
                  ),
                  child: TextField(
                    controller: _controller,
                    enabled: !_submitted,
                    onChanged: (_) => setState(() {}),
                    maxLines: 4,
                    minLines: 3,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.all(16),
                      hintText: 'Type your answer here...',
                      hintStyle: TextStyle(
                        fontFamily: 'Outfit',
                        color: Color(0xFFD5C4A1), // High Contrast Warm Cream
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Vintage Gold Action Button
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
    );
  }

  Widget _buildFeedback() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _passed
            ? const Color(0xDD1B5E20)
            : const Color(0xDDE65100),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _passed ? const Color(0xFFA5D6A7) : const Color(0xFFFFCC80),
          width: 1.8,
        ),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Row(
        children: [
          Icon(
            _passed ? Icons.check_circle : Icons.lightbulb_outline,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _passed
                  ? '✨ EXCELLENT! You included the key concepts.'
                  : '💡 GOOD TRY! Keep exploring and learning.',
              style: const TextStyle(
                fontFamily: 'Outfit',
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool get _canAct {
    if (!_submitted) return _controller.text.trim().isNotEmpty;
    return true;
  }

  void _onButtonPressed() {
    if (!_submitted) {
      final score = KeywordMatcher.calculateScore(
        _controller.text,
        widget.question.keyConcepts,
      );
      final passed = KeywordMatcher.meetsThreshold(
        score,
        widget.question.similarityThreshold,
      );

      // Synchronous immediate event trigger for Panda companion
      widget.onAnswerEvaluated?.call(passed);

      setState(() {
        _score = score;
        _passed = passed;
        _submitted = true;
      });
    } else {
      if (widget.onAnsweredDetailed != null) {
        widget.onAnsweredDetailed!(
          _passed,
          _score,
          _controller.text.trim(),
        );
      } else {
        widget.onAnswered(_passed);
      }
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

    // Semi-transparent dark vintage sepia backdrop
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
