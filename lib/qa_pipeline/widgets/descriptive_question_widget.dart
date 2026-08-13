import 'package:flutter/material.dart';

import '../models/descriptive_question.dart';
import '../services/keyword_matcher.dart';

/// Renders a descriptive question with a text field, Submit button,
/// and child-friendly feedback (no scores or diagnostics shown).
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

  const DescriptiveQuestionWidget({
    super.key,
    required this.question,
    required this.questionNumber,
    required this.onAnswered,
    this.onAnsweredDetailed,
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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Phase + number
          Text(
            'Descriptive — Question ${widget.questionNumber}',
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
          const SizedBox(height: 24),

          // Answer text field
          TextField(
            controller: _controller,
            enabled: !_submitted,
            onChanged: (_) => setState(() {}),
            maxLines: 5,
            minLines: 3,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Type your answer...',
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF6C63FF),
                  width: 1.5,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Submit / Continue
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

          // Child-friendly feedback
          if (_submitted) ...[
            const SizedBox(height: 20),
            _buildFeedback(),
          ],
        ],
      ),
    );
  }

  /// Child-friendly feedback — no scores, percentages, or diagnostics shown.
  Widget _buildFeedback() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _passed
            ? Colors.greenAccent.withValues(alpha: 0.08)
            : Colors.orangeAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _passed
              ? Colors.greenAccent.withValues(alpha: 0.3)
              : Colors.orangeAccent.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _passed ? Icons.check_circle : Icons.lightbulb_outline,
            color: _passed ? Colors.greenAccent : Colors.orangeAccent,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _passed
                  ? '✨ Nice work!\n\nYou included the important ideas.'
                  : '💡 Good try!\n\nLet\'s keep learning.',
              style: TextStyle(
                color: _passed ? Colors.greenAccent : Colors.orangeAccent,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 1.4,
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

      setState(() {
        _score = score;
        _passed = passed;
        _submitted = true;
      });
    } else {
      // Use the detailed callback if available, otherwise the simple one.
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
