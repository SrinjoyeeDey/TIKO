import 'package:flutter/material.dart';

import '../models/sequence_question.dart';

/// Renders a sequence question with drag-and-drop reordering.
///
/// The child arranges events in the correct order by dragging items.
/// After submission, shows child-friendly feedback.
class SequenceQuestionWidget extends StatefulWidget {
  final SequenceQuestion question;
  final int questionNumber;

  /// Called after the user submits and views feedback.
  /// [isCorrect] indicates whether the order was right.
  final ValueChanged<bool> onAnswered;

  const SequenceQuestionWidget({
    super.key,
    required this.question,
    required this.questionNumber,
    required this.onAnswered,
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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Phase + number
          Text(
            'Sequence — Question ${widget.questionNumber}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),

          // Question text
          Text(
            widget.question.questionText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),

          // Instruction
          Text(
            'Drag items to arrange them in the correct order',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 20),

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
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: Text(_submitted ? 'Continue' : 'Submit'),
            ),
          ),

          // Feedback after submission
          if (_submitted) ...[
            const SizedBox(height: 20),
            _buildFeedback(),
          ],
        ],
      ),
    );
  }

  Widget _buildReorderableList() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Material(
        color: Colors.transparent,
        child: ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: _currentOrder.length,
          onReorder: _submitted ? (_, __) {} : _onReorder,
          proxyDecorator: (child, index, animation) {
            return ListenableBuilder(
              listenable: animation,
              builder: (context, child) {
                final scale = 1.0 + 0.03 * animation.value;
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

            Color borderColor = Colors.white24;
            Color? bgColor;

            if (_submitted) {
              if (isCorrectPosition) {
                borderColor = Colors.greenAccent;
                bgColor = Colors.greenAccent.withValues(alpha: 0.1);
              } else if (isWrongPosition) {
                borderColor = Colors.redAccent;
                bgColor = Colors.redAccent.withValues(alpha: 0.1);
              }
            }

            return Container(
              key: ValueKey(item),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: bgColor ?? Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: 1.5),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    // Number badge
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Item text
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          height: 1.3,
                        ),
                      ),
                    ),

                    // Status icon or drag handle
                    if (_submitted && isCorrectPosition)
                      const Icon(Icons.check_circle,
                          color: Colors.greenAccent, size: 22)
                    else if (_submitted && isWrongPosition)
                      const Icon(Icons.cancel,
                          color: Colors.redAccent, size: 22)
                    else
                      ReorderableDragStartListener(
                        index: index,
                        child: Icon(
                          Icons.drag_handle,
                          color: Colors.white.withValues(alpha: 0.4),
                          size: 24,
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
            ? Colors.greenAccent.withValues(alpha: 0.08)
            : Colors.orangeAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isCorrect
              ? Colors.greenAccent.withValues(alpha: 0.3)
              : Colors.orangeAccent.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isCorrect ? Icons.check_circle : Icons.info_outline,
            color: _isCorrect ? Colors.greenAccent : Colors.orangeAccent,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _isCorrect
                  ? '✨ Perfect order! You remembered the sequence!'
                  : '💡 Not quite right, but good try! Keep practicing!',
              style: TextStyle(
                color: _isCorrect ? Colors.greenAccent : Colors.orangeAccent,
                fontSize: 15,
                fontWeight: FontWeight.w500,
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
    setState(() {
      _submitted = true;
      _isCorrect = correct;
    });
  }

  void _onContinue() {
    widget.onAnswered(_isCorrect);
  }
}
