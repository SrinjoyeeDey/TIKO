import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import '../models/image_matching_question.dart';
import '../services/content_discovery_service.dart';

class ImageMatchingWidget extends StatefulWidget {
  final ImageMatchingQuestion question;
  final String chapterId;
  final String levelId;
  final Function(int correctMatches, int totalMatches) onCompleted;

  const ImageMatchingWidget({
    super.key,
    required this.question,
    required this.chapterId,
    required this.levelId,
    required this.onCompleted,
  });

  @override
  State<ImageMatchingWidget> createState() => _ImageMatchingWidgetState();
}

class _ImageMatchingWidgetState extends State<ImageMatchingWidget> {
  late List<MatchingDescription> _shuffledDescriptions;
  final Map<String, String> _currentMatches = {};
  bool _isSubmitted = false;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _shuffledDescriptions = List.from(widget.question.descriptions)..shuffle();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _checkAnswers() {
    if (_isSubmitted) return;
    
    setState(() {
      _isSubmitted = true;
    });

    int correct = 0;
    for (final img in widget.question.images) {
      final selectedDescId = _currentMatches[img.id];
      final correctDescId = widget.question.correctMatches[img.id];
      if (selectedDescId != null && selectedDescId == correctDescId) {
        correct++;
      }
    }

    if (correct == widget.question.images.length) {
      _confettiController.play();
    }
  }

  void _continue() {
    int correct = 0;
    for (final img in widget.question.images) {
      if (_currentMatches[img.id] == widget.question.correctMatches[img.id]) {
        correct++;
      }
    }
    widget.onCompleted(correct, widget.question.images.length);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '🧩 Match the Pictures!',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  // Images Column
                  Expanded(
                    child: ListView.builder(
                      itemCount: widget.question.images.length,
                      itemBuilder: (context, index) {
                        final img = widget.question.images[index];
                        final matchedDescId = _currentMatches[img.id];
                        final matchedDesc = matchedDescId != null 
                            ? widget.question.descriptions.firstWhere((d) => d.id == matchedDescId)
                            : null;

                        return DragTarget<String>(
                          onAcceptWithDetails: (details) {
                            if (_isSubmitted) return;
                            setState(() {
                              _currentMatches[img.id] = details.data;
                            });
                          },
                          builder: (context, candidateData, rejectedData) {
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: candidateData.isNotEmpty
                                    ? Colors.white.withValues(alpha: 0.2)
                                    : Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: candidateData.isNotEmpty 
                                      ? const Color(0xFF6C63FF) 
                                      : Colors.white24,
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: FutureBuilder<String?>(
                                      future: ContentDiscoveryService.findImageAsset(widget.chapterId, widget.levelId, img.file),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return const SizedBox(
                                            width: 100,
                                            height: 100,
                                            child: Center(child: CircularProgressIndicator()),
                                          );
                                        }
                                        final actualPath = snapshot.data;
                                        if (actualPath == null) {
                                          return Container(
                                            width: 100,
                                            height: 100,
                                            color: Colors.white12,
                                            child: const Icon(Icons.broken_image, color: Colors.white54),
                                          );
                                        }
                                        return Image.asset(
                                          actualPath,
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              width: 100,
                                              height: 100,
                                              color: Colors.white12,
                                              child: const Icon(Icons.broken_image, color: Colors.white54),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: matchedDesc != null
                                        ? InkWell(
                                            onTap: _isSubmitted ? null : () {
                                              // Allow unmatching by tapping
                                              setState(() {
                                                _currentMatches.remove(img.id);
                                              });
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: const Color(0xFF6C63FF).withValues(alpha: 0.5)),
                                              ),
                                              child: Text(
                                                matchedDesc.text,
                                                style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                                              ),
                                            ),
                                          )
                                        : Text(
                                            'Drag a description here',
                                            style: GoogleFonts.outfit(
                                              color: Colors.white54,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                  ),
                                  if (_isSubmitted && matchedDesc != null)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: Icon(
                                        matchedDescId == widget.question.correctMatches[img.id]
                                            ? Icons.check_circle
                                            : Icons.cancel,
                                        color: matchedDescId == widget.question.correctMatches[img.id]
                                            ? Colors.greenAccent
                                            : Colors.redAccent,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  
                  const VerticalDivider(color: Colors.white24, thickness: 1),

                  // Descriptions Column
                  Expanded(
                    child: ListView.builder(
                      itemCount: _shuffledDescriptions.length,
                      itemBuilder: (context, index) {
                        final desc = _shuffledDescriptions[index];
                        final isMatched = _currentMatches.containsValue(desc.id);

                        if (isMatched) {
                          return const SizedBox.shrink(); // Hide if already matched
                        }

                        return Draggable<String>(
                          data: desc.id,
                          feedback: Material(
                            color: Colors.transparent,
                            child: Container(
                              width: 300,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6C63FF),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  )
                                ],
                              ),
                              child: Text(
                                desc.text,
                                style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                              ),
                            ),
                          ),
                          childWhenDragging: Opacity(
                            opacity: 0.3,
                            child: _buildDescriptionCard(desc),
                          ),
                          child: _buildDescriptionCard(desc),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            // Check / Continue Button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: _isSubmitted
                  ? Column(
                      children: [
                        Text(
                          _currentMatches.length == widget.question.images.length &&
                                  _currentMatches.entries.every((e) => e.value == widget.question.correctMatches[e.key])
                              ? '🎉 Amazing! You matched them all!'
                              : '✨ Nice try! Let\'s keep learning!',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _continue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: Text(
                            'Continue',
                            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ],
                    )
                  : ElevatedButton(
                      onPressed: _currentMatches.length == widget.question.images.length ? _checkAnswers : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        disabledBackgroundColor: Colors.white12,
                      ),
                      child: Text(
                        'CHECK',
                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
            ),
          ],
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionCard(MatchingDescription desc) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        desc.text,
        style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
      ),
    );
  }
}
