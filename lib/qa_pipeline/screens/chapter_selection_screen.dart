import 'package:flutter/material.dart';

import '../../widgets/wooden_back_button.dart';
import '../../widgets/game_textured_text.dart';
import '../models/learning_content.dart';
import '../services/content_discovery_service.dart';
import 'video_player_screen.dart';

class ChapterSelectionScreen extends StatefulWidget {
  final String childId;

  const ChapterSelectionScreen({super.key, required this.childId});

  @override
  State<ChapterSelectionScreen> createState() => _ChapterSelectionScreenState();
}

class _ChapterSelectionScreenState extends State<ChapterSelectionScreen> {
  List<LearningChapter> _chapters = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChapters();
  }

  Future<void> _loadChapters() async {
    final chapters = await ContentDiscoveryService.discoverContent();
    if (mounted) {
      setState(() {
        _chapters = chapters;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC5AE79), // Vintage Parchment
      body: Stack(
        children: [
          // Background Map / Texture
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: Image.asset(
                'assets/maps/historical_world_map_parchment.png',
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => const SizedBox(),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Custom Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      WoodenBackButton(
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const Expanded(
                        child: Center(
                          child: GameTexturedText(
                            text: 'TOPICS',
                            fontSize: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content List
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Color(0xFF8B6914)),
                        )
                      : _chapters.isEmpty
                          ? const Center(
                              child: Text(
                                'No records found.\nPlease insert tapes.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  color: Color(0xFF3E2A1E), 
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              itemCount: _chapters.length,
                              itemBuilder: (context, index) {
                                final chapter = _chapters[index];
                                return _buildChapterCard(chapter);
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterCard(LearningChapter chapter) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF4EE), // Bright parchment card
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF8B6914),
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            if (chapter.levels.isNotEmpty) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => VideoPlayerScreen(
                    childId: widget.childId,
                    level: chapter.levels.first,
                  ),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Dynamic COVER_IMG Image
                FutureBuilder<String?>(
                  future: ContentDiscoveryService.findCoverImage(chapter.id),
                  builder: (context, snapshot) {
                    final imagePath = snapshot.data;
                    debugPrint('CoverImage for ${chapter.id}: $imagePath (state: ${snapshot.connectionState}, error: ${snapshot.error})');
                    return Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5DDD0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF8B6914), width: 1.5),
                        image: imagePath != null
                            ? DecorationImage(
                                image: AssetImage(imagePath),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: imagePath == null
                          ? const Center(
                              child: Icon(
                                Icons.photo_library_rounded,
                                color: Color(0xFF8B6914),
                                size: 32,
                              ),
                            )
                          : null,
                    );
                  },
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chapter.name,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          color: Color(0xFF2E1C12),
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3E2A1E),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${chapter.levels.length} TAPES',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            color: Color(0xFFD4AF37),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Color(0xFF8B6914),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

