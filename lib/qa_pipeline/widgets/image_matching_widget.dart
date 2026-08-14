import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../models/image_matching_question.dart';
import '../services/content_discovery_service.dart';

/// High-contrast 3D Vintage Image Matching Widget with Perfectly Aligned Side-by-Side Rows
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
    final int rowCount = widget.question.images.length;

    return Stack(
      children: [
        Column(
          children: [
            // Title Header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Text(
                '🧩 MATCH THE PICTURES!',
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFFFD700), // Bright Vintage Gold
                  letterSpacing: 1.5,
                  shadows: [
                    Shadow(color: Colors.black, blurRadius: 8, offset: Offset(2, 3)),
                  ],
                ),
              ),
            ),

            // Perfectly Aligned Side-by-Side Matching Rows
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                itemCount: rowCount,
                itemBuilder: (context, index) {
                  final img = widget.question.images[index];
                  final desc = index < _shuffledDescriptions.length ? _shuffledDescriptions[index] : null;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Left Column: Image Target Card (Row index)
                          Expanded(
                            flex: 5,
                            child: _buildImageTargetCard(img),
                          ),

                          const SizedBox(width: 14),

                          // Right Column: Description Card (Row index - Side by Side Alignment!)
                          Expanded(
                            flex: 5,
                            child: desc != null
                                ? _buildDescriptionDraggableCard(desc)
                                : const SizedBox(),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Check / Continue Button with High-Contrast Feedback Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: _isSubmitted
                  ? Column(
                      children: [
                        // High-Contrast Feedback Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _currentMatches.length == widget.question.images.length &&
                                    _currentMatches.entries.every((e) => e.value == widget.question.correctMatches[e.key])
                                ? const Color(0xDD1B5E20)
                                : const Color(0xDDE65100),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFFFFF8E1),
                              width: 1.8,
                            ),
                            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 4))],
                          ),
                          child: Text(
                            _currentMatches.length == widget.question.images.length &&
                                    _currentMatches.entries.every((e) => e.value == widget.question.correctMatches[e.key])
                                ? 'AMAZING! You matched them all correctly!'
                                : 'NICE TRY! Let\'s keep learning together.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _continue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD4AF37),
                              foregroundColor: const Color(0xFF2E1C12),
                              elevation: 6,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              textStyle: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                            child: const Text('CONTINUE →'),
                          ),
                        ),
                      ],
                    )
                  : SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _currentMatches.length == widget.question.images.length ? _checkAnswers : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4AF37),
                          foregroundColor: const Color(0xFF2E1C12),
                          disabledBackgroundColor: Colors.white12,
                          disabledForegroundColor: Colors.white30,
                          elevation: 6,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          textStyle: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        child: const Text('CHECK ANSWERS'),
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
            colors: const [Color(0xFFFFD700), Color(0xFFFFB300), Color(0xFF4CAF50), Color(0xFF2196F3)],
          ),
        ),
      ],
    );
  }

  Widget _buildImageTargetCard(MatchingImage img) {
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
        final isHovering = candidateData.isNotEmpty;
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isHovering ? const Color(0xEEFFB300) : const Color(0xEE2E1C12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHovering ? Colors.white : const Color(0xFFD4AF37),
              width: 2.2,
            ),
            boxShadow: const [
              BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 4)),
            ],
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
                        width: 78,
                        height: 78,
                        child: Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37))),
                      );
                    }
                    final actualPath = snapshot.data;
                    if (actualPath == null) {
                      return Container(
                        width: 78,
                        height: 78,
                        color: Colors.black38,
                        child: const Icon(Icons.broken_image, color: Colors.white54),
                      );
                    }
                    return Image.asset(
                      actualPath,
                      width: 78,
                      height: 78,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 78,
                          height: 78,
                          color: Colors.black38,
                          child: const Icon(Icons.broken_image, color: Colors.white54),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: matchedDesc != null
                    ? InkWell(
                        onTap: _isSubmitted ? null : () {
                          setState(() {
                            _currentMatches.remove(img.id);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B70A6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFFF8E1), width: 1.5),
                          ),
                          child: Text(
                            matchedDesc.text,
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      )
                    : const Text(
                        'Drag description here',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: Color(0xFFF5EAD4),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
              ),
              if (_isSubmitted && matchedDesc != null)
                Padding(
                  padding: const EdgeInsets.only(left: 6.0),
                  child: Icon(
                    matchedDescId == widget.question.correctMatches[img.id]
                        ? Icons.check_circle
                        : Icons.cancel,
                    color: matchedDescId == widget.question.correctMatches[img.id]
                        ? const Color(0xFFA5D6A7)
                        : const Color(0xFFEF9A9A),
                    size: 26,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDescriptionDraggableCard(MatchingDescription desc) {
    final isMatched = _currentMatches.containsValue(desc.id);

    if (isMatched) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0x332E1C12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x55D4AF37), width: 1.5),
        ),
        child: const Center(
          child: Text(
            '✓ MATCHED',
            style: TextStyle(
              fontFamily: 'Outfit',
              color: Color(0xFFD4AF37),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );
    }

    return Draggable<String>(
      data: desc.id,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: 260,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFD4AF37),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 10,
                offset: Offset(0, 5),
              )
            ],
          ),
          child: Text(
            desc.text,
            style: const TextStyle(
              fontFamily: 'Outfit',
              color: Color(0xFF2E1C12),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildDescriptionCard(desc),
      ),
      child: _buildDescriptionCard(desc),
    );
  }

  Widget _buildDescriptionCard(MatchingDescription desc) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xEE2E1C12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4AF37), width: 1.8),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Center(
        child: Text(
          desc.text,
          style: const TextStyle(
            fontFamily: 'Outfit',
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            height: 1.3,
          ),
        ),
      ),
    );
  }
}
