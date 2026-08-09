import 'package:flutter/material.dart';
import '../models/story_chapter.dart';
import '../widgets/wooden_back_button.dart';
import '../widgets/game_textured_text.dart';

class ChapterDetailScreen extends StatelessWidget {
  final StoryChapter chapter;

  const ChapterDetailScreen({
    super.key,
    required this.chapter,
  });

  void _safePop(BuildContext context, [bool? result]) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(6.0),
          child: WoodenBackButton(
            size: 40,
            onTap: () => _safePop(context, false),
          ),
        ),
        title: GameTexturedText(
          text: 'Chapter ${chapter.id}: ${chapter.title}',
          fontSize: 16,
          letterSpacing: 1.5,
          strokeWidth: 4.0,
          gradientColors: const [
            Color(0xFFE0F2FE),
            Color(0xFF38BDF8),
            Color(0xFF0284C7),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chapter Banner Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1D4ED8), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF38BDF8), width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF0F172A),
                      ),
                      child: Icon(chapter.icon, size: 40, color: const Color(0xFF38BDF8)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CHAPTER ${chapter.id}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                              color: Color(0xFF38BDF8),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            chapter.title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'Outfit',
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            chapter.subtitle,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Full Story Text Section
              const Text(
                'THE STORY',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  color: Color(0xFF38BDF8),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Text(
                  chapter.fullStoryText,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: Color(0xFFE2E8F0),
                    fontFamily: 'Outfit',
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Historical Context Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF132338),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.5)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.menu_book_rounded, color: Color(0xFF38BDF8), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'HISTORICAL INSIGHT',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF38BDF8),
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            chapter.historicalContext,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: Color(0xFFCBD5E1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Key Takeaway Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF14B8A6).withValues(alpha: 0.6)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_rounded, color: Color(0xFF2DD4BF), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        chapter.keyTakeaway,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF99F6E4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // Complete Chapter Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
                  ),
                  icon: const Icon(Icons.check_circle_rounded, size: 26, color: Color(0xFF38BDF8)),
                  label: Text(
                    chapter.isCompleted ? 'CHAPTER ALREADY COMPLETED' : 'COMPLETE CHAPTER',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  onPressed: () => _safePop(context, true),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
