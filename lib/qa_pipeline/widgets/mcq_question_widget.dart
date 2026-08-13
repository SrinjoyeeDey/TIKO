import 'package:flutter/material.dart';

import '../models/mcq_question.dart';

/// Renders a single MCQ question with radio-button options and a Submit button.
///
/// After submission, shows correct/incorrect feedback with the correct answer
/// highlighted, then calls [onAnswered].
class McqQuestionWidget extends StatefulWidget {
  final McqQuestion question;
  final int questionNumber;
  final String phaseLabel;

  /// Called after the user submits and views feedback.
  /// [isCorrect] indicates whether the selected answer was right.
  final ValueChanged<bool> onAnswered;

  const McqQuestionWidget({
    super.key,
    required this.question,
    required this.questionNumber,
    required this.phaseLabel,
    required this.onAnswered,
  });

  @override
  State<McqQuestionWidget> createState() => _McqQuestionWidgetState();
}

class _McqQuestionWidgetState extends State<McqQuestionWidget> {
  String? _selectedKey;
  bool _submitted = false;

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final sortedKeys = q.options.keys.toList()..sort();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Phase + question number
          Text(
            '${widget.phaseLabel} — Question ${widget.questionNumber}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),

          // Question text
          Text(
            q.questionText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          // Options
          ...sortedKeys.map((key) => _buildOption(key, q.options[key]!)),

          const SizedBox(height: 24),

          // Submit / Continue button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _canAct ? _onButtonPressed : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.white12,
                disabledForegroundColor: Colors.white30,
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

  Widget _buildOption(String key, String text) {
    final bool isCorrect = key == widget.question.correctAnswerKey;
    final bool isSelected = key == _selectedKey;

    Color borderColor = Colors.white24;
    Color? bgColor;

    if (_submitted) {
      if (isCorrect) {
        borderColor = Colors.greenAccent;
        bgColor = Colors.greenAccent.withValues(alpha: 0.1);
      } else if (isSelected && !isCorrect) {
        borderColor = Colors.redAccent;
        bgColor = Colors.redAccent.withValues(alpha: 0.1);
      }
    } else if (isSelected) {
      borderColor = const Color(0xFF6C63FF);
      bgColor = const Color(0xFF6C63FF).withValues(alpha: 0.1);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _submitted ? null : () => setState(() => _selectedKey = key),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: Row(
              children: [
                // Radio indicator
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF6C63FF)
                          : Colors.white38,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF6C63FF),
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 14),

                // Key label
                Text(
                  '$key.',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),

                // Option text
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.3,
                    ),
                  ),
                ),

                // Correct / incorrect icon after submission
                if (_submitted && isCorrect)
                  const Icon(Icons.check_circle, color: Colors.greenAccent, size: 22),
                if (_submitted && isSelected && !isCorrect)
                  const Icon(Icons.cancel, color: Colors.redAccent, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedback() {
    final isCorrect = widget.question.isCorrect(_selectedKey!);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCorrect
            ? Colors.greenAccent.withValues(alpha: 0.08)
            : Colors.redAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCorrect
              ? Colors.greenAccent.withValues(alpha: 0.3)
              : Colors.redAccent.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isCorrect ? Icons.check_circle : Icons.cancel,
            color: isCorrect ? Colors.greenAccent : Colors.redAccent,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isCorrect ? 'Correct!' : 'Incorrect. The correct answer is ${widget.question.correctAnswerKey}.',
              style: TextStyle(
                color: isCorrect ? Colors.greenAccent : Colors.redAccent,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool get _canAct {
    if (!_submitted) return _selectedKey != null;
    return true; // Continue is always enabled after submission
  }

  void _onButtonPressed() {
    if (!_submitted) {
      setState(() => _submitted = true);
    } else {
      widget.onAnswered(widget.question.isCorrect(_selectedKey!));
    }
  }
}
