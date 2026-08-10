import 'package:flutter/material.dart';
import '../widgets/wooden_back_button.dart';
import 'onboarding_screen.dart';

/// Data model representing a single explorer entry on the Leaderboard.
class LeaderboardEntry {
  final String id;
  final int rank;
  final String name;
  final String title;
  int points;
  int destinations;
  final String avatarUrl;

  LeaderboardEntry({
    required this.id,
    required this.rank,
    required this.name,
    required this.title,
    required this.points,
    required this.destinations,
    required this.avatarUrl,
  });
}

/// Dynamic Leaderboard Screen matching Reference Image.
/// Includes dynamic points increase/decrease logic, empty Badges placeholder column,
/// and menu integration.
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String _selectedCategory = 'GLOBAL'; // GLOBAL, INDIA, FRIENDS, SCHOOL
  String _selectedTimeframe = 'THIS WEEK'; // THIS WEEK, ALL TIME

  late List<LeaderboardEntry> _explorers;

  @override
  void initState() {
    super.initState();
    _initExplorerData();
  }

  void _initExplorerData() {
    _explorers = [
      LeaderboardEntry(
        id: '1',
        rank: 1,
        name: 'HIKARU',
        title: 'WARRIOR OF THE RISING SUN',
        points: 25680,
        destinations: 37,
        avatarUrl: 'assets/images/nimo_splash.png',
      ),
      LeaderboardEntry(
        id: '2',
        rank: 2,
        name: 'AKEMI',
        title: 'PATH OF KNOWLEDGE',
        points: 21430,
        destinations: 29,
        avatarUrl: 'assets/images/nimo_splash.png',
      ),
      LeaderboardEntry(
        id: '3',
        rank: 3,
        name: 'RYOTA',
        title: 'SEEKER OF TRUTH',
        points: 18920,
        destinations: 24,
        avatarUrl: 'assets/images/nimo_splash.png',
      ),
      LeaderboardEntry(
        id: '4',
        rank: 4,
        name: 'KAZUYA',
        title: 'WANDERER',
        points: 15670,
        destinations: 20,
        avatarUrl: 'assets/images/nimo_splash.png',
      ),
      LeaderboardEntry(
        id: '5',
        rank: 5,
        name: 'MEI',
        title: 'CURIOUS MIND',
        points: 13450,
        destinations: 18,
        avatarUrl: 'assets/images/nimo_splash.png',
      ),
      LeaderboardEntry(
        id: '6',
        rank: 6,
        name: 'HARUTO',
        title: 'DISCOVERER',
        points: 11230,
        destinations: 16,
        avatarUrl: 'assets/images/nimo_splash.png',
      ),
      LeaderboardEntry(
        id: '7',
        rank: 7,
        name: 'YUNA',
        title: 'DREAM CHASER',
        points: 9870,
        destinations: 13,
        avatarUrl: 'assets/images/nimo_splash.png',
      ),
      LeaderboardEntry(
        id: '8',
        rank: 8,
        name: 'TAICHI',
        title: 'PATHFINDER',
        points: 8410,
        destinations: 11,
        avatarUrl: 'assets/images/nimo_splash.png',
      ),
    ];
  }

  /// Dynamic Logic: Increase points for an explorer and auto-re-sort leaderboard
  void increasePoints(String explorerId, int delta) {
    setState(() {
      final item = _explorers.firstWhere((e) => e.id == explorerId);
      item.points += delta;
      _resortLeaderboard();
    });
  }

  /// Dynamic Logic: Decrease points for an explorer and auto-re-sort leaderboard
  void decreasePoints(String explorerId, int delta) {
    setState(() {
      final item = _explorers.firstWhere((e) => e.id == explorerId);
      item.points = (item.points - delta).clamp(0, 999999);
      _resortLeaderboard();
    });
  }

  void _resortLeaderboard() {
    _explorers.sort((a, b) => b.points.compareTo(a.points));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Japanese Midnight Atmosphere Background
          Positioned.fill(
            child: Image.asset(
              'assets/images/japanese_garden_bg.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E140E), Color(0xFF100B07), Color(0xFF070402)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),

          // Dark Vignette & Sakura Atmosphere Overlay
          Positioned.fill(
            child: Container(
              color: const Color(0xFF0E0906).withValues(alpha: 0.65),
            ),
          ),

          // 2. Main Content Layout
          SafeArea(
            child: Column(
              children: [
                _buildTopNavigationHeader(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Filter Sidebar (GLOBAL, INDIA, FRIENDS, SCHOOL)
                        _buildFilterSidebar(),
                        const SizedBox(width: 16),

                        // Main Scroll Table (LEADERBOARD PARCHMENT)
                        Expanded(
                          child: _buildLeaderboardParchmentScroll(),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Footer Motto Plank
                _buildBottomMottoPlank(),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 1. TOP HEADER ────────────────────────────────────────────────────────
  Widget _buildTopNavigationHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          WoodenBackButton(
            onTap: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                Navigator.of(context).pushReplacement(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const OnboardingScreen(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                        FadeTransition(opacity: animation, child: child),
                    transitionDuration: const Duration(milliseconds: 350),
                  ),
                );
              }
            },
            size: 38,
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  '❀  LEADERBOARD  ❀',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3.5,
                    color: Color(0xFFF5D061),
                    shadows: [
                      Shadow(color: Colors.black, offset: Offset(1, 2), blurRadius: 4),
                    ],
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'THE BEST EXPLORERS. THE BRAVEST JOURNEYS.',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.0,
                    color: Color(0xFFD4B886),
                  ),
                ),
              ],
            ),
          ),

          // Timeframe Dropdown (THIS WEEK / ALL TIME)
          _buildTimeframeDropdown(),
        ],
      ),
    );
  }

  Widget _buildTimeframeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF261910).withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFC5A059), width: 1.2),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedTimeframe,
          dropdownColor: const Color(0xFF261910),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFF5D061), size: 18),
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: Color(0xFFF5D061),
          ),
          items: const [
            DropdownMenuItem(value: 'THIS WEEK', child: Text('THIS WEEK')),
            DropdownMenuItem(value: 'ALL TIME', child: Text('ALL TIME')),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _selectedTimeframe = val);
          },
        ),
      ),
    );
  }

  // ── 2. LEFT SIDEBAR FILTERS ────────────────────────────────────────────────
  Widget _buildFilterSidebar() {
    return SizedBox(
      width: 150,
      child: Column(
        children: [
          _buildFilterCategoryItem('GLOBAL', Icons.public_rounded),
          const SizedBox(height: 8),
          _buildFilterCategoryItem('INDIA', Icons.location_on_rounded),
          const SizedBox(height: 8),
          _buildFilterCategoryItem('FRIENDS', Icons.group_rounded),
          const SizedBox(height: 8),
          _buildFilterCategoryItem('SCHOOL', Icons.school_rounded),
          const Spacer(),

          // Decorative Quote Card Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E140E).withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF8B6914).withValues(alpha: 0.6), width: 1),
            ),
            child: const Text(
              'THE JOURNEY OF\nA THOUSAND MILES\nBEGINS WITH\nA SINGLE STEP.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFFC4AD82),
                letterSpacing: 1.2,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterCategoryItem(String title, IconData icon) {
    final isSelected = _selectedCategory == title;

    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF3E2A1A)
              : const Color(0xFF1A120B).withValues(alpha: 0.80),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFD54F) : const Color(0xFF5D4037),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFFD54F).withValues(alpha: 0.3),
                    blurRadius: 6,
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? const Color(0xFFFFD54F) : const Color(0xFF9E8262)),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                letterSpacing: 1.5,
                color: isSelected ? const Color(0xFFFFF176) : const Color(0xFF9E8262),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 3. MAIN PARCHMENT SCROLL TABLE ────────────────────────────────────────
  Widget _buildLeaderboardParchmentScroll() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3DFB7), // Parchment texture background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF5D4037), width: 3),
        boxShadow: const [
          BoxShadow(color: Colors.black87, blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: Column(
          children: [
            // Table Header Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFF3E2A1A),
                border: Border(bottom: BorderSide(color: Color(0xFFFFD54F), width: 1.5)),
              ),
              child: Row(
                children: const [
                  SizedBox(width: 50, child: Text('RANK', style: _headerStyle)),
                  Expanded(flex: 3, child: Text('EXPLORER', style: _headerStyle)),
                  Expanded(flex: 2, child: Text('JOURNEY POINTS', textAlign: TextAlign.center, style: _headerStyle)),
                  Expanded(flex: 2, child: Text('DESTINATIONS', textAlign: TextAlign.center, style: _headerStyle)),
                  Expanded(flex: 2, child: Text('BADGES', textAlign: TextAlign.center, style: _headerStyle)),
                ],
              ),
            ),

            // Scrollable Explorer List Rows
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: _explorers.length,
                separatorBuilder: (context, index) => const Divider(
                  color: Color(0xFFD4C29E),
                  height: 1,
                  indent: 12,
                  endIndent: 12,
                ),
                itemBuilder: (context, index) {
                  final explorer = _explorers[index];
                  final isTopThree = index < 3;

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: isTopThree
                        ? const Color(0xFFFAF0DD).withValues(alpha: 0.6)
                        : Colors.transparent,
                    child: Row(
                      children: [
                        // Rank Badge Icon
                        SizedBox(
                          width: 50,
                          child: _buildRankBadge(index + 1),
                        ),

                        // Explorer Avatar & Info (Name + Title)
                        Expanded(
                          flex: 3,
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: const Color(0xFF3E2A1A),
                                child: Text(
                                  explorer.name[0],
                                  style: const TextStyle(color: Color(0xFFFFF176), fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      explorer.name,
                                      style: const TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.2,
                                        color: Color(0xFF2C1C0F),
                                      ),
                                    ),
                                    Text(
                                      explorer.title,
                                      style: const TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.8,
                                        color: Color(0xFF7A5C38),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Journey Points (Dynamic Value)
                        Expanded(
                          flex: 2,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _formatPoints(explorer.points),
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF3E2A1A),
                                ),
                              ),
                              const SizedBox(width: 3),
                              const Icon(Icons.star_rounded, size: 14, color: Color(0xFFD4A843)),
                            ],
                          ),
                        ),

                        // Destinations Count
                        Expanded(
                          flex: 2,
                          child: Text(
                            '${explorer.destinations}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF3E2A1A),
                            ),
                          ),
                        ),

                        // BADGES Column (Empty Placeholder as requested!)
                        const Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 28,
                            child: Center(
                              // Left clean and empty for future badge design
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    if (rank == 1) {
      return Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [Color(0xFFFFF176), Color(0xFFFFB300), Color(0xFF8B6914)],
          ),
          boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 4)],
        ),
        child: const Center(
          child: Text('1', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF2C1C0F), fontSize: 13)),
        ),
      );
    } else if (rank == 2) {
      return Container(
        width: 26,
        height: 26,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [Color(0xFFE0E0E0), Color(0xFF9E9E9E), Color(0xFF424242)],
          ),
        ),
        child: const Center(
          child: Text('2', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 12)),
        ),
      );
    } else if (rank == 3) {
      return Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [Color(0xFFFFB74D), Color(0xFFA1887F), Color(0xFF4E342E)],
          ),
        ),
        child: const Center(
          child: Text('3', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 11)),
        ),
      );
    }

    return Text(
      '$rank',
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontFamily: 'Outfit',
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: Color(0xFF5D4037),
      ),
    );
  }

  // ── 4. BOTTOM MOTTO PLANK ─────────────────────────────────────────────────
  Widget _buildBottomMottoPlank() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF261910),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC5A059), width: 1.2),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.workspace_premium_rounded, size: 16, color: Color(0xFFF5D061)),
          SizedBox(width: 8),
          Text(
            'KEEP EXPLORING. KEEP LEARNING. KEEP GROWING.',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.0,
              color: Color(0xFFF5D061),
            ),
          ),
        ],
      ),
    );
  }

  static const TextStyle _headerStyle = TextStyle(
    fontFamily: 'Outfit',
    fontSize: 10,
    fontWeight: FontWeight.w900,
    letterSpacing: 1.5,
    color: Color(0xFFFFF176),
  );

  String _formatPoints(int points) {
    return points.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}
