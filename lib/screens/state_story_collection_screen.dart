import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/west_bengal_stories_database.dart';
import '../data/india_states_data.dart';
import '../models/interactive_story_models.dart';
import '../qa_pipeline/services/content_discovery_service.dart';
import '../qa_pipeline/database/progress_repository.dart';
import '../qa_pipeline/screens/video_player_screen.dart';
import '../qa_pipeline/screens/level_clear_screen.dart';
import '../qa_pipeline/models/learning_content.dart';
import '../core/state/child_state.dart';
import 'interactive_story_screen.dart';

/// 80s Showa Retro Worn Explorer Postcard Carousel Screen
/// Features:
/// - Increased spacing between cards (`viewportFraction: 0.46`)
/// - Significantly wider featured center card (295w x 355h)
/// - Dull black & white desaturated side cards -> Bright vibrant color center card
/// - Working carousel navigation arrows (< and >) and mouse/touch drag
/// - Worn, tea-stained 80s Showa vintage paper edges
class StateStoryCollectionScreen extends StatefulWidget {
  final String stateId;
  final String? chapterId;

  const StateStoryCollectionScreen({
    super.key,
    required this.stateId,
    this.chapterId,
  });

  @override
  State<StateStoryCollectionScreen> createState() => _StateStoryCollectionScreenState();
}

class _StateStoryCollectionScreenState extends State<StateStoryCollectionScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late StateStoriesCollection _collection;
  int _selectedStoryIndex = 0;
  int? _animatingIndex;
  bool _isTransitioningToStory = false;

  List<LearningLevel> _levels = [];
  Map<String, bool> _completedLevels = {};
  int _highestUnlockedIndex = 0;

  // Interactive 3D Drag Tilt State
  double _tiltX = 0.0;
  double _tiltY = 0.0;

  // Grayscale Color Matrix for Dull Black & White Side Cards
  static const List<double> _grayscaleMatrix = [
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0,      0,      0,      1, 0,
  ];

  bool _isLoadingDynamic = false;

  @override
  void initState() {
    super.initState();
    debugPrint("StateStoryCollectionScreen: initState called for stateId: ${widget.stateId}, chapterId: ${widget.chapterId}");
    _collection = IndianStoriesDatabase.getCollectionForState(widget.stateId) ?? 
        StateStoriesCollection(stateId: widget.stateId, stateName: widget.stateId, tagline: '', atmosphericImage: 'assets/images/nimo_splash.png', stories: []);
    
    _isLoadingDynamic = true;
    _loadQAChaptersAsStories();

    _pageController = PageController(
      viewportFraction: 0.46, // Increased spacing between cards
      initialPage: 0,
    );
  }

  Future<void> _loadQAChaptersAsStories() async {
    final childId = ChildState.instance.currentProfile.id;
    final chapters = await ContentDiscoveryService.discoverContent();

    // 1. Resolve whether this specific state has a designated video learning chapter
    LearningChapter? resolvedChapter;
    if (widget.chapterId != null && widget.chapterId!.isNotEmpty) {
      resolvedChapter = chapters.where((c) => c.id.toLowerCase() == widget.chapterId!.toLowerCase()).firstOrNull;
    }

    if (resolvedChapter == null && chapters.isNotEmpty) {
      final sId = widget.stateId.toLowerCase();
      // Match strictly:
      // - Tamil Nadu -> Bharatnatayam
      // - West Bengal -> Netaji
      // - Direct chapter name/ID match
      resolvedChapter = chapters.where(
        (c) {
          final cId = c.id.toLowerCase();
          final cName = c.name.toLowerCase();
          if (cId == sId || cName == sId) return true;
          if (sId.contains('tamil') || sId == 'tn') {
            return cId.contains('bharat') || cId.contains('tamil') || cName.contains('bharat');
          }
          if (sId.contains('bengal') || sId.contains('calcutta') || sId.contains('kolkata') || sId == 'wb') {
            return cId.contains('netaji') || cId.contains('bengal');
          }
          return false; // Bharatnatyam is ONLY for Tamil Nadu!
        },
      ).firstOrNull;
    }

    // 2. If this state HAS an active video chapter (e.g. Tamil Nadu -> Bharatnatyam, West Bengal -> Netaji):
    if (resolvedChapter != null) {
      final chapter = resolvedChapter;
      _levels = chapter.levels;

      // Load progress from SQLite
      final allProgress = await ProgressRepository.getAllProgress(childId);
      final completedMap = <String, bool>{};
      for (final p in allProgress) {
        if (p.chapterId == chapter.id && p.completed) {
          completedMap[p.levelId] = true;
        }
      }

      // Sequential unlock calculation
      int highestUnlocked = 0;
      for (int i = 0; i < _levels.length; i++) {
        final lvl = _levels[i];
        if (completedMap[lvl.id] == true) {
          highestUnlocked = i + 1;
        } else {
          break;
        }
      }
      if (highestUnlocked >= _levels.length) {
        highestUnlocked = _levels.length - 1;
      }

      final List<StoryData> mappedStories = [];
      for (int i = 0; i < _levels.length; i++) {
        final lvl = _levels[i];
        final levelImg = await ContentDiscoveryService.findLevelImage(chapter.id, lvl.id)
            ?? await ContentDiscoveryService.findCoverImage(chapter.id)
            ?? 'assets/images/nimo_splash.png';

        mappedStories.add(
          StoryData(
            id: lvl.id,
            stateId: widget.stateId,
            title: chapter.name,
            subtitle: 'Episode ${i + 1}',
            taglineOrQuote: 'Episode ${i + 1} of ${chapter.name} adventure',
            imagePath: levelImg,
            scenes: [],
          ),
        );
      }

      if (mounted) {
        setState(() {
          _completedLevels = completedMap;
          _highestUnlockedIndex = highestUnlocked;
          _collection = StateStoriesCollection(
            stateId: widget.stateId,
            stateName: chapter.name,
            tagline: 'Explore ${chapter.name} Episodes',
            atmosphericImage: 'assets/images/nimo_splash.png',
            stories: mappedStories,
          );
          _isLoadingDynamic = false;
          _selectedStoryIndex = _selectedStoryIndex.clamp(0, mappedStories.isNotEmpty ? mappedStories.length - 1 : 0);
          _pageController = PageController(
            viewportFraction: 0.46,
            initialPage: _selectedStoryIndex,
          );
        });
      }
      return;
    }

    // 3. For OTHER states (Maharashtra, Rajasthan, Punjab, Karnataka, Kerala, Gujarat, etc.):
    // Load and display authentic Heritage & Culture stories for THAT specific state!
    _levels = [];
    final heritageCollection = _getOrCreateHeritageCollection(widget.stateId);

    if (mounted) {
      setState(() {
        _completedLevels = {};
        _highestUnlockedIndex = heritageCollection.stories.length; // All heritage cards unlocked
        _collection = heritageCollection;
        _isLoadingDynamic = false;
        _selectedStoryIndex = _selectedStoryIndex.clamp(0, heritageCollection.stories.isNotEmpty ? heritageCollection.stories.length - 1 : 0);
        _pageController = PageController(
          viewportFraction: 0.46,
          initialPage: _selectedStoryIndex,
        );
      });
    }
  }

  StateStoriesCollection _getOrCreateHeritageCollection(String stateId) {
    final sId = stateId.toLowerCase();
    final existing = IndianStoriesDatabase.getCollectionForState(sId);
    if (existing != null && existing.stateId.toLowerCase() == sId && existing.stories.isNotEmpty) {
      return existing;
    }

    final stateData = IndiaStatesDatabase.states[sId];
    final stateName = stateData?.name ?? _formatTitle(stateId);
    final capital = stateData?.capital ?? 'Historical Capital';
    final famous = stateData?.famousFor ?? 'UNESCO Monuments and Ancient Heritage';
    final fact = stateData?.fact ?? 'Rich heritage with ancient traditions and architecture.';
    final food = stateData?.food ?? 'Traditional culinary specialties';
    final lang = stateData?.language ?? 'Regional languages';

    return StateStoriesCollection(
      stateId: sId,
      stateName: stateName,
      tagline: 'Discover the Heritage, Monuments & Culture of $stateName',
      atmosphericImage: 'assets/images/nimo_japanese_bg_clean.png',
      stories: [
        StoryData(
          id: '${sId}_monuments',
          stateId: sId,
          title: '$stateName Heritage',
          subtitle: 'Monuments & History',
          taglineOrQuote: '“$famous”',
          imagePath: 'assets/images/story_selection_wb_bg.png',
          scenes: [
            StoryScene(
              id: 's1',
              narrativeText:
                  'Welcome to $stateName! Capital: $capital. Renowned across India for its landmark heritage: $famous.',
              imagePath: 'assets/images/story_selection_wb_bg.png',
              historicalFact: fact,
              choices: const [
                SceneChoice(label: 'Explore Culture & Traditions', nextSceneId: 's2'),
              ],
            ),
            StoryScene(
              id: 's2',
              narrativeText:
                  '$stateName has vibrant cultural traditions. Official Language: $lang. Famous Gastronomy: $food.',
              imagePath: 'assets/images/story_selection_wb_bg.png',
              historicalFact: 'Preserving over centuries of architectural and folk heritage.',
            ),
          ],
        ),
        StoryData(
          id: '${sId}_culture',
          stateId: sId,
          title: 'Living Traditions',
          subtitle: 'Arts, Language & Gastronomy',
          taglineOrQuote: '“Languages: $lang | Cuisine: $food”',
          imagePath: 'assets/images/nimo_japanese_bg_clean.png',
          scenes: [
            StoryScene(
              id: 's1',
              narrativeText:
                  'Discover the vibrant daily life, folk arts, and culinary delicacies of $stateName ($food).',
              imagePath: 'assets/images/nimo_japanese_bg_clean.png',
              historicalFact: fact,
            ),
          ],
        ),
      ],
    );
  }

  String _formatTitle(String raw) {
    return raw.split('_').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Scrolls one story to the left (prev). Returns true if a scroll happened,
  /// false if already at the first story (used by press-&-hold repeat scrolling).
  bool _scrollPrev() {
    if (_selectedStoryIndex > 0) {
      final targetPage = _selectedStoryIndex - 1;
      setState(() => _selectedStoryIndex = targetPage);
      _pageController.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
      return true;
    }
    return false;
  }

  /// Scrolls one story to the right (next). Returns true if a scroll happened,
  /// false if already at the last story (used by press-&-hold repeat scrolling).
  bool _scrollNext() {
    if (_selectedStoryIndex < _collection.stories.length - 1) {
      final targetPage = _selectedStoryIndex + 1;
      setState(() => _selectedStoryIndex = targetPage);
      _pageController.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
      return true;
    }
    return false;
  }

  void _onCardTap(int index) async {
    if (_selectedStoryIndex != index) {
      setState(() => _selectedStoryIndex = index);
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
      return;
    }

    if (_isTransitioningToStory) return;

    if (index > _highestUnlockedIndex) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🔒 Complete Episode $index first to unlock Episode ${index + 1}!'),
          backgroundColor: const Color(0xFF2E1C12),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _animatingIndex = index;
      _isTransitioningToStory = true;
    });

    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    final selectedStory = _collection.stories[index];

    // Trigger Session Engine -> POST /api/sessions
    await ChildState.instance.startNewSession(storyId: selectedStory.id);
    if (!mounted) return;

    final level = index < _levels.length ? _levels[index] : null;

    if (level != null && level.isPlayable) {
      // Play Video Quest Screen (e.g. Tamil Nadu Bharatanatyam or Netaji)
      final childId = ChildState.instance.currentProfile.id;
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => VideoPlayerScreen(
            childId: childId,
            level: level,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 450),
        ),
      ).then((_) {
        if (mounted) {
          setState(() {
            _animatingIndex = null;
            _isTransitioningToStory = false;
          });
          _loadQAChaptersAsStories();
        }
      });
    } else {
      // Open Interactive Heritage Story Screen
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => InteractiveStoryScreen(
            story: selectedStory,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 450),
        ),
      ).then((_) {
        if (mounted) {
          setState(() {
            _animatingIndex = null;
            _isTransitioningToStory = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_collection.stories.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFC5AE79),
        body: Center(
          child: _isLoadingDynamic 
              ? const CircularProgressIndicator(color: Color(0xFF8B4513))
              : const Text(
                  'No stories found for this state.',
                  style: TextStyle(fontFamily: 'Outfit', fontSize: 24, color: Color(0xFF5C3A21)),
                ),
        ),
      );
    }

    final activeStory = _collection.stories[_selectedStoryIndex.clamp(0, _collection.stories.length - 1)];

    return Scaffold(
      backgroundColor: const Color(0xFFC5AE79),
      body: Stack(
        children: [
          // 1. GENERATED WEST BENGAL HISTORY MAP BACKGROUND (Isolated in RepaintBoundary, Cache-Optimized)
          Positioned.fill(
            child: RepaintBoundary(
              child: Image.asset(
                'assets/images/story_selection_wb_bg.png',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (ctx, err, stack) => Image.asset(
                  'assets/images/nimo_japanese_bg_clean.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // 2. Soft 80s Showa Darkened Sepia Vignette Overlay
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.95,
                    colors: [
                      Colors.transparent,
                      const Color(0xFF2E1C12).withValues(alpha: 0.25),
                      const Color(0xFF1E100A).withValues(alpha: 0.55),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Top-Left Back to Map Button
          Positioned(
            top: 14,
            left: 16,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF4EE),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF8B6914), width: 1.2),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                ),
                child: Row(
                  children: const [
                    Icon(Icons.arrow_back_ios_new_rounded, size: 13, color: Color(0xFF3E2A1E)),
                    SizedBox(width: 6),
                    Text(
                      'Map',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF3E2A1E),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Top-Right Dev Rewards Button
          Positioned(
            top: 14,
            right: 16,
            child: InkWell(
              onTap: () async {
                final navigator = Navigator.of(context);
                final chapters = await ContentDiscoveryService.discoverContent();
                final chapter = chapters.firstOrNull;
                final level = chapter?.levels.firstOrNull ?? LearningLevel(
                  id: 'Netaji_0',
                  chapterId: 'netaji_subhas_chandra_bose',
                  chapterName: 'Netaji Subhas Chandra Bose',
                  levelName: 'Level 1',
                  videoPath: 'assets/Netaji/Netaji_0/video.mp4',
                  isPlayable: true,
                );
                if (!mounted) return;
                navigator.push(
                  MaterialPageRoute(
                    builder: (_) => LevelClearScreen(
                      childId: 'default_child',
                      level: level,
                      totalCorrect: 3,
                      totalQuestions: 3,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFF8E1), width: 1.2),
                  boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2))],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.emoji_events_rounded, size: 14, color: Color(0xFF2E1C12)),
                    SizedBox(width: 6),
                    Text(
                      'DEV: REWARDS',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2E1C12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Main Layout Content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 6),

                // Top 80s Showa Folded Ribbon Banner: "WHERE ARE U GOING?"
                _buildFoldedRibbonHeader(),

                const SizedBox(height: 12),

                // HORIZONTALLY SCROLLABLE CAROUSEL (Touch, Mouse, Trackpad & Working Arrow Buttons)
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Scrollable PageView Carousel
                      _isLoadingDynamic 
                        ? const CircularProgressIndicator(color: Color(0xFF8B6914))
                        : ScrollConfiguration(
                        behavior: _MouseAndTouchScrollBehavior(),
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: _collection.stories.length,
                          onPageChanged: (idx) => setState(() => _selectedStoryIndex = idx),
                          itemBuilder: (context, index) {
                            final story = _collection.stories[index];
                            final isAnimating = _animatingIndex == index;

                            return AnimatedBuilder(
                              animation: _pageController,
                              builder: (context, child) {
                                double dist = 0.0;
                                if (_pageController.hasClients && _pageController.page != null) {
                                  dist = _pageController.page! - index;
                                  dist = (1 - (dist.abs() * 0.25)).clamp(0.0, 1.0);
                                } else {
                                  dist = index == _selectedStoryIndex ? 1.0 : 0.70;
                                }

                                final isSelected = index == _selectedStoryIndex;
                                // Center card expands to scale 1.25x (wider & commanding)
                                final scale = isAnimating ? 1.28 : (0.78 + (dist * 0.22));

                                // 80s Worn Tilt Angles: Left -0.04 rad, Right +0.04 rad
                                double rotation = 0.0;
                                if (index < _selectedStoryIndex) rotation = -0.04;
                                if (index > _selectedStoryIndex) rotation = 0.04;

                                return Transform.scale(
                                  scale: scale,
                                  child: Transform.rotate(
                                    angle: rotation,
                                    child: InkWell(
                                      onTap: () => _onCardTap(index),
                                      child: _buildPostcardStampCard(story, index, isSelected, isAnimating),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),

                      // Left Carousel Arrow Button (Scroll Left - one on each side)
                      Positioned(
                        left: 12,
                        child: Opacity(
                          opacity: _selectedStoryIndex > 0 ? 1.0 : 0.35,
                          child: IgnorePointer(
                            ignoring: _selectedStoryIndex <= 0,
                            child: _CarouselArrowButton(
                              icon: Icons.chevron_left_rounded,
                              label: 'Previous story',
                              enabled: _selectedStoryIndex > 0,
                              onScroll: _scrollPrev,
                            ),
                          ),
                        ),
                      ),

                      // Right Carousel Arrow Button (Scroll Right - one on each side)
                      Positioned(
                        right: 12,
                        child: Opacity(
                          opacity: _selectedStoryIndex < _collection.stories.length - 1 ? 1.0 : 0.35,
                          child: IgnorePointer(
                            ignoring: _selectedStoryIndex >= _collection.stories.length - 1,
                            child: _CarouselArrowButton(
                              icon: Icons.chevron_right_rounded,
                              label: 'Next story',
                              enabled: _selectedStoryIndex < _collection.stories.length - 1,
                              onScroll: _scrollNext,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Bottom Dark Description Banner
                _buildBottomDescriptionBanner(activeStory),

                const SizedBox(height: 8),
              ],
            ),
          ),

          // A transparent overlay still receives taps unless it is excluded
          // from hit testing.
          IgnorePointer(
            ignoring: !_isTransitioningToStory,
            child: AnimatedOpacity(
              opacity: _isTransitioningToStory ? 0.6 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  // 80s Showa Folded Paper Ribbon Header Banner ("WHERE ARE U GOING?")
  Widget _buildFoldedRibbonHeader() {
    return CustomPaint(
      painter: _RibbonBannerPainter(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 8),
        child: const Text(
          'WHERE ARE U GOING?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.2,
            color: Color(0xFF3E2716),
          ),
        ),
      ),
    );
  }

  // 80s Showa Worn Postcard Stamp Card (Dull B&W Side Cards -> Bright Vibrant Color Center Card)
  Widget _buildPostcardStampCard(StoryData story, int index, bool isSelected, bool isAnimating) {
    final bool isLocked = index > _highestUnlockedIndex;
    final bool isCompleted = index < _levels.length && (_completedLevels[_levels[index].id] == true);

    // Card Container Layout (Center card is wider 295w x 355h vs side cards 210w x 275h)
    Widget cardContent = AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      width: isSelected ? 295 : 210, // Center card is wider & commanding!
      height: isSelected ? 355 : 275,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001) // 3D Perspective
        ..rotateY(_tiltX)
        ..rotateX(_tiltY),
      transformAlignment: Alignment.center,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? const Color(0xFFEF6C6C).withValues(alpha: isAnimating ? 0.55 : 0.40)
                : Colors.black.withValues(alpha: 0.35), // Dull monochrome paper shadow for side cards
            blurRadius: isSelected ? 28 : 10,
            offset: isSelected ? const Offset(0, 12) : const Offset(0, 4),
          ),
        ],
      ),
      child: ClipPath(
        clipper: _PostageStampClipper(toothRadius: 5.2, toothSpacing: 15.0),
        child: CustomPaint(
          painter: _WornPaperEdgePainter(), // Renders tea-stained 80s worn edge patina
          child: Container(
            color: isSelected ? const Color(0xFFFAF4EE) : const Color(0xFFE5DDD0), // Dull aged cream for side cards
            padding: const EdgeInsets.all(12),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. CLEAN 78% IMAGE PLACEHOLDER AREA
                    Expanded(
                      flex: 78,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFEFE6D5) : const Color(0xFFDCD2C4),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isSelected ? const Color(0xFFEF6C6C) : const Color(0xFFB5A692),
                              width: isSelected ? 2.2 : 1.0,
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Positioned.fill(
                                child: Padding(
                                  padding: EdgeInsets.all(story.imagePath.toLowerCase().contains('bharat') ? 6.0 : 0.0),
                                  child: Image.asset(
                                    story.imagePath,
                                    fit: story.imagePath.toLowerCase().contains('bharat') ? BoxFit.contain : BoxFit.cover,
                                    alignment: Alignment.center,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Center(
                                      child: Icon(
                                        Icons.broken_image_outlined,
                                        color: Color(0xFF6E6053),
                                        size: 36,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Lock Overlay for Locked Episodes
                              if (isLocked)
                                Positioned.fill(
                                  child: Container(
                                    color: Colors.black.withValues(alpha: 0.52),
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF2E1C12).withValues(alpha: 0.90),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: const Color(0xFFD4AF37), width: 1.2),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.lock_rounded, color: Color(0xFFD4AF37), size: 14),
                                            SizedBox(width: 4),
                                            Text(
                                              'LOCKED',
                                              style: TextStyle(
                                                fontFamily: 'Outfit',
                                                fontSize: 10,
                                                fontWeight: FontWeight.w900,
                                                color: Color(0xFFD4AF37),
                                                letterSpacing: 1.0,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                              // Completed Badge
                              if (isCompleted)
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2E7D32),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 1.5),
                                      boxShadow: const [
                                        BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 13,
                                    ),
                                  ),
                                ),

                              // Vintage 80s Showa Japan Watermark Accent (昭和80s)
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Opacity(
                                  opacity: isSelected ? 0.22 : 0.12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: isSelected ? const Color(0xFF3E2716) : const Color(0xFF555555),
                                        width: 1,
                                      ),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      '昭和80s · 旅',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        color: isSelected ? const Color(0xFF3E2716) : const Color(0xFF555555),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // 2. CLEAN BOTTOM TEXT AREA (Title & Subtitle)
                    Expanded(
                      flex: 22,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            story.subtitle,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: isSelected ? 14.5 : 11.5,
                              fontWeight: FontWeight.w900,
                              color: isSelected ? const Color(0xFF2E1C12) : const Color(0xFF554A40),
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isLocked ? 'Locked' : (isCompleted ? '${story.title} ✓' : story.title),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: isSelected ? 12 : 9.5,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? const Color(0xFF6D5547) : const Color(0xFF776B60),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Metallic Silver Paperclip Attachment (Top-Left)
                Positioned(
                  top: -10,
                  left: 6,
                  child: SizedBox(
                    width: 28,
                    height: 48,
                    child: CustomPaint(painter: _PaperclipPainter()),
                  ),
                ),

                // Prominent Glowing Border Highlight for Center Active Card
                if (isSelected)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFFEF6C6C).withValues(alpha: 0.75),
                            width: 2.2,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    // Apply Dull Black & White Desaturation Filter to Side Cards or Locked Cards
    if (!isSelected || isLocked) {
      cardContent = ColorFiltered(
        colorFilter: const ColorFilter.matrix(_grayscaleMatrix),
        child: Opacity(
          opacity: isLocked ? 0.70 : 0.75, // Dull & desaturated side or locked cards
          child: cardContent,
        ),
      );
    }

    return GestureDetector(
      onTap: () => _onCardTap(index),
      onPanUpdate: (details) {
        if (isSelected) {
          setState(() {
            _tiltX += details.delta.dx * 0.002;
            _tiltY -= details.delta.dy * 0.002;
          });
        }
      },
      onPanEnd: (_) {
        if (isSelected) {
          setState(() {
            _tiltX = 0.0;
            _tiltY = 0.0;
          });
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Center(child: cardContent),
    );
  }

  // Bottom Dark Description Banner
  Widget _buildBottomDescriptionBanner(StoryData activeStory) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2E1C12).withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD4AF37), width: 1.2),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Row(
        children: [
          Text(
            '${activeStory.subtitle.toUpperCase()} : ',
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Color(0xFFC6FF00),
              letterSpacing: 1.0,
            ),
          ),
          Expanded(
            child: Text(
              activeStory.taglineOrQuote,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.play_arrow_rounded, color: Color(0xFFFF9800), size: 18),
        ],
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// CAROUSEL ARROW BUTTON (Tap to scroll one story, press-&-hold to keep scrolling)
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _CarouselArrowButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final bool Function() onScroll;

  const _CarouselArrowButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onScroll,
  });

  @override
  State<_CarouselArrowButton> createState() => _CarouselArrowButtonState();
}

class _CarouselArrowButtonState extends State<_CarouselArrowButton> {
  Timer? _holdTimer; // Delay before hold-repeat kicks in
  Timer? _repeatTimer; // Repeating scroll while held
  bool _hovered = false;
  bool _pressed = false;
  bool _repeatStarted = false;

  void _handleTapDown(TapDownDetails _) {
    if (!widget.enabled) return;
    setState(() => _pressed = true);
    _repeatStarted = false;

    // After a short hold, start continuously scrolling to the side.
    _holdTimer?.cancel();
    _holdTimer = Timer(const Duration(milliseconds: 400), () {
      if (!mounted || !widget.enabled) return;
      _repeatStarted = true;
      widget.onScroll();
      _repeatTimer?.cancel();
      // Slightly longer than the 350ms page animation so each step completes
      // smoothly before the next one begins.
      _repeatTimer = Timer.periodic(const Duration(milliseconds: 450), (_) {
        if (!mounted || !widget.enabled) return;
        // Stop repeating once we reach the end of the carousel.
        if (!widget.onScroll()) {
          _cancelTimers();
          if (mounted) setState(() => _pressed = false);
        }
      });
    });
  }

  void _handleTapUp(TapUpDetails _) {
    _cancelTimers();
    if (mounted) setState(() => _pressed = false);
    // Quick tap = single scroll to the side.
    if (widget.enabled && !_repeatStarted) {
      widget.onScroll();
    }
  }

  void _handleTapCancel() {
    _cancelTimers();
    if (mounted) setState(() => _pressed = false);
  }

  void _cancelTimers() {
    _holdTimer?.cancel();
    _repeatTimer?.cancel();
    _holdTimer = null;
    _repeatTimer = null;
  }

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) {
        if (widget.enabled) setState(() => _hovered = true);
      },
      onExit: (_) {
        if (_hovered) setState(() => _hovered = false);
        _handleTapCancel();
      },
      child: Semantics(
        button: true,
        label: widget.label,
        enabled: widget.enabled,
        child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: AnimatedScale(
          scale: _pressed ? 0.88 : (_hovered ? 1.08 : 1.0),
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFAF4EE).withValues(alpha: 0.95),
              shape: BoxShape.circle,
              border: Border.all(
                color: _hovered ? const Color(0xFFEF6C6C) : const Color(0xFF8B6914),
                width: _hovered ? 2.2 : 1.6,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: _hovered ? 12 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Icon(widget.icon, color: const Color(0xFF3E2716), size: 30),
            ),
          ),
        ),
        ),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// MOUSE, TOUCH, TRACKPAD & STYLUS SCROLL BEHAVIOR
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _MouseAndTouchScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// 80s WORN TEA-STAINED PAPER EDGE PAINTER
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _WornPaperEdgePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Outer Tea-Stained Perforated Rim Shadow
    final edgeShadowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFC8B490).withValues(alpha: 0.45),
          const Color(0xFFB59F78).withValues(alpha: 0.20),
          const Color(0xFFD6C5A2).withValues(alpha: 0.45),
        ],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0;

    canvas.drawRect(Offset.zero & size, edgeShadowPaint);

    // Micro Aged Distress Crease Line
    final creasePaint = Paint()
      ..color = const Color(0xFF8B6914).withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawLine(const Offset(12, 18), Offset(size.width - 16, 24), creasePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// CUSTOM SCRAPED POSTAGE STAMP CLIPPER
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _PostageStampClipper extends CustomClipper<Path> {
  final double toothRadius;
  final double toothSpacing;

  _PostageStampClipper({this.toothRadius = 5.2, this.toothSpacing = 15.0});

  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);

    // Top edge
    double x = toothSpacing / 2;
    while (x < size.width) {
      path.lineTo(x - toothRadius, 0);
      path.arcToPoint(
        Offset(x + toothRadius, 0),
        radius: Radius.circular(toothRadius),
        clockwise: false,
      );
      x += toothSpacing;
    }
    path.lineTo(size.width, 0);

    // Right edge
    double y = toothSpacing / 2;
    while (y < size.height) {
      path.lineTo(size.width, y - toothRadius);
      path.arcToPoint(
        Offset(size.width, y + toothRadius),
        radius: Radius.circular(toothRadius),
        clockwise: false,
      );
      y += toothSpacing;
    }
    path.lineTo(size.width, size.height);

    // Bottom edge
    x = size.width - toothSpacing / 2;
    while (x > 0) {
      path.lineTo(x + toothRadius, size.height);
      path.arcToPoint(
        Offset(x - toothRadius, size.height),
        radius: Radius.circular(toothRadius),
        clockwise: false,
      );
      x -= toothSpacing;
    }
    path.lineTo(0, size.height);

    // Left edge
    y = size.height - toothSpacing / 2;
    while (y > 0) {
      path.lineTo(0, y + toothRadius);
      path.arcToPoint(
        Offset(0, y - toothRadius),
        radius: Radius.circular(toothRadius),
        clockwise: false,
      );
      y -= toothSpacing;
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// METALLIC SILVER PAPERCLIP PAINTER
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _PaperclipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD0D5DD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final shadowPaint = Paint()
      ..color = Colors.black38
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final path = Path();
    path.moveTo(10, 40);
    path.lineTo(10, 8);
    path.arcToPoint(const Offset(20, 8), radius: const Radius.circular(5));
    path.lineTo(20, 44);
    path.arcToPoint(const Offset(5, 44), radius: const Radius.circular(8));
    path.lineTo(5, 16);

    canvas.drawPath(path.shift(const Offset(1.5, 2)), shadowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// 3D FOLDED WHITE RIBBON BANNER PAINTER (Swallow-tail notched ends)
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _RibbonBannerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final fillPaint = Paint()
      ..color = const Color(0xFFFFFDF8)
      ..style = PaintingStyle.fill;

    final shadowFoldPaint = Paint()
      ..color = const Color(0xFFC5B697)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFFD8C7A5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    const tailW = 34.0;
    const foldH = 8.0;

    // Left Fold Triangle
    final leftFold = Path()
      ..moveTo(tailW, size.height)
      ..lineTo(tailW, size.height + foldH)
      ..lineTo(tailW - 12, size.height)
      ..close();
    canvas.drawPath(leftFold, shadowFoldPaint);

    // Right Fold Triangle
    final rightFold = Path()
      ..moveTo(size.width - tailW, size.height)
      ..lineTo(size.width - tailW, size.height + foldH)
      ..lineTo(size.width - tailW + 12, size.height)
      ..close();
    canvas.drawPath(rightFold, shadowFoldPaint);

    // Left Ribbon Tail with swallow-tail / notched end
    final leftTail = Path()
      ..moveTo(0, foldH)
      ..lineTo(tailW, 0)
      ..lineTo(tailW, size.height)
      ..lineTo(0, size.height + foldH)
      ..lineTo(10, (size.height + foldH) / 2)
      ..close();

    // Right Ribbon Tail with swallow-tail / notched end
    final rightTail = Path()
      ..moveTo(size.width, foldH)
      ..lineTo(size.width - tailW, 0)
      ..lineTo(size.width - tailW, size.height)
      ..lineTo(size.width, size.height + foldH)
      ..lineTo(size.width - 10, (size.height + foldH) / 2)
      ..close();

    canvas.drawPath(leftTail.shift(const Offset(0, 2)), shadowPaint);
    canvas.drawPath(rightTail.shift(const Offset(0, 2)), shadowPaint);

    canvas.drawPath(leftTail, fillPaint);
    canvas.drawPath(leftTail, borderPaint);

    canvas.drawPath(rightTail, fillPaint);
    canvas.drawPath(rightTail, borderPaint);

    // Center Main Banner
    final mainBanner = RRect.fromRectAndRadius(
      Rect.fromLTWH(tailW - 4, 0, size.width - 2 * (tailW - 4), size.height),
      const Radius.circular(2),
    );

    canvas.drawRRect(mainBanner.shift(const Offset(0, 3)), shadowPaint);
    canvas.drawRRect(mainBanner, fillPaint);
    canvas.drawRRect(mainBanner, borderPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
