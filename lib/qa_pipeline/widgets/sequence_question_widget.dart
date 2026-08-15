import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/sequence_question.dart';

/// Renders a sequence question with drag-and-drop reordering inside a 3D Vintage Speech Bubble Card
/// with high-contrast vintage gold styling.
class SequenceQuestionWidget extends StatefulWidget {
  final SequenceQuestion question;
  final int questionNumber;

  /// Called after the user submits and views feedback.
  /// [isCorrect] indicates whether the order was right.
  final ValueChanged<bool> onAnswered;

  /// Called synchronously the exact instant the sequence is evaluated upon submit.
  final ValueChanged<bool>? onAnswerEvaluated;

  const SequenceQuestionWidget({
    super.key,
    required this.question,
    required this.questionNumber,
    required this.onAnswered,
    this.onAnswerEvaluated,
  });

  @override
  State<SequenceQuestionWidget> createState() => _SequenceQuestionWidgetState();
}

class _SequenceQuestionWidgetState extends State<SequenceQuestionWidget> {
  late List<String> _currentOrder;
  bool _submitted = false;
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    _currentOrder = List.from(widget.question.items);
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
                // Instruction
                const Text(
                  'Drag items to arrange them in the correct order',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: Color(0xFFF5EAD4),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 16),

                // Reorderable list
                _buildReorderableList(),
                const SizedBox(height: 24),

                // Submit / Continue button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _submitted ? _onContinue : _onSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37), // Vintage Gold
                      foregroundColor: const Color(0xFF2E1C12),
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
                    child: Text(_submitted ? 'CONTINUE →' : 'SUBMIT ORDER'),
                  ),
                ),

                // Feedback after submission
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

  Widget _buildReorderableList() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Material(
        color: Colors.transparent,
        child: ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: _currentOrder.length,
          // ignore: deprecated_member_use
          onReorder: _submitted ? (oldIndex, newIndex) {} : _onReorder,
          proxyDecorator: (child, index, animation) {
            return ListenableBuilder(
              listenable: animation,
              builder: (context, child) {
                final scale = 1.0 + 0.04 * animation.value;
                return Transform.scale(
                  scale: scale,
                  child: child,
                );
              },
              child: child,
            );
          },
          itemBuilder: (context, index) {
            final item = _currentOrder[index];
            final isCorrectPosition = _submitted &&
                index < widget.question.correctOrder.length &&
                item == widget.question.correctOrder[index];
            final isWrongPosition = _submitted && !isCorrectPosition;

            Color borderColor = const Color(0xFFD4AF37);
            Color bgColor = const Color(0xEE2E1C12);

            if (_submitted) {
              if (isCorrectPosition) {
                borderColor = const Color(0xFFA5D6A7);
                bgColor = const Color(0xCC1B5E20);
              } else if (isWrongPosition) {
                borderColor = const Color(0xFFEF9A9A);
                bgColor = const Color(0xCCB71C1C);
              }
            }

            return Container(
              key: ValueKey(item),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor, width: 2.0),
                boxShadow: const [
                  BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 3)),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    // Number badge
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFD4AF37),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            color: Color(0xFF2E1C12),
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Item text
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          color: Colors.white,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                        ),
                      ),
                    ),

                    // Status icon or drag handle
                    if (_submitted && isCorrectPosition)
                      const Icon(Icons.check_circle, color: Colors.white, size: 24)
                    else if (_submitted && isWrongPosition)
                      const Icon(Icons.cancel, color: Colors.white, size: 24)
                    else
                      ReorderableDragStartListener(
                        index: index,
                        child: const Icon(
                          Icons.drag_handle_rounded,
                          color: Color(0xFFD4AF37),
                          size: 26,
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

  Widget _buildFeedback() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isCorrect
            ? const Color(0xDD1B5E20)
            : const Color(0xDDE65100),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isCorrect ? const Color(0xFFA5D6A7) : const Color(0xFFFFCC80),
          width: 1.8,
        ),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Row(
        children: [
          Icon(
            _isCorrect ? Icons.check_circle : Icons.info_outline,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _isCorrect
                  ? '✨ PERFECT ORDER! You remembered the sequence!'
                  : '💡 GOOD TRY! Keep practicing the order.',
              style: const TextStyle(
                fontFamily: 'Outfit',
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _currentOrder.removeAt(oldIndex);
      _currentOrder.insert(newIndex, item);
    });
  }

  void _onSubmit() {
    final correct = widget.question.isCorrect(_currentOrder);
    // Synchronous immediate event trigger for Panda companion
    widget.onAnswerEvaluated?.call(correct);
    setState(() {
      _submitted = true;
      _isCorrect = correct;
    });
  }

  void _onContinue() {
    widget.onAnswered(_isCorrect);
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
