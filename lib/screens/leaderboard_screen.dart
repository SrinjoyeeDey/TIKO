import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../widgets/wooden_back_button.dart';
import 'onboarding_screen.dart';

/// Explorer model for the Leaderboard
class LeaderboardEntry {
  final String id;
  final int rank;
  final String name;
  final String avatarUrl;
  final int points;
  final int rankChange; // positive for UP (▲), negative for DOWN (▼)
  final bool isCurrentUser;

  LeaderboardEntry({
    required this.id,
    required this.rank,
    required this.name,
    required this.avatarUrl,
    required this.points,
    this.rankChange = 1,
    this.isCurrentUser = false,
  });
}

/// Leaderboard Screen matching the exact color palette & gradient from "Select Your Age":
/// - Background: Soft Pale Mint/Teal to Sunny Golden Yellow Gradient (`0xFFE4F3E6` -> `0xFFFAF7D4` -> `0xFFFFF197`)
/// - Wavy Vertical Contour Lines background painter (`_WavyBackgroundLinesPainter`)
/// - Golden Amber Card styling (`0xFFF5A800` / `0xFFFFB300` / `0xFFFFA000`)
/// - Off-white cream row cards (`0xFFFFFDF8`) with dark sepia text (`0xFF2C1A0F`)
/// - Duolingo Ruby League Header, Top 3 Podium with Crowns 👑, and Floating Pinned User Rank Card
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with TickerProviderStateMixin {
  bool _showTrophyCelebration = false;

  late AnimationController _crownFloatController;
  late AnimationController _trophyPulseController;

  late List<LeaderboardEntry> _entries;
  late LeaderboardEntry _currentUserEntry;

  @override
  void initState() {
    super.initState();
    _crownFloatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _trophyPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _initLeaderboardData();
  }

  void _initLeaderboardData() {
    _entries = [
      LeaderboardEntry(
        id: '1',
        rank: 1,
        name: 'Gary',
        avatarUrl: 'assets/images/nimo_child_avatar.png',
        points: 2051,
        rankChange: 3,
      ),
      LeaderboardEntry(
        id: '2',
        rank: 2,
        name: 'Tinapopo',
        avatarUrl: 'assets/images/nimo_splash.png',
        points: 1356,
        rankChange: -1,
      ),
      LeaderboardEntry(
        id: '3',
        rank: 3,
        name: 'SSY',
        avatarUrl: 'assets/images/nimo_child_avatar.png',
        points: 1067,
        rankChange: 2,
      ),
      LeaderboardEntry(
        id: '4',
        rank: 4,
        name: 'Joey Lui',
        avatarUrl: 'assets/images/nimo_splash.png',
        points: 1012,
        rankChange: 1,
      ),
      LeaderboardEntry(
        id: '5',
        rank: 5,
        name: 'Yukishino',
        avatarUrl: 'assets/images/nimo_child_avatar.png',
        points: 999,
        rankChange: -2,
      ),
      LeaderboardEntry(
        id: '6',
        rank: 6,
        name: 'Rururubi',
        avatarUrl: 'assets/images/nimo_splash.png',
        points: 988,
        rankChange: -1,
      ),
      LeaderboardEntry(
        id: '7',
        rank: 7,
        name: 'JK',
        avatarUrl: 'assets/images/nimo_child_avatar.png',
        points: 788,
        rankChange: 4,
      ),
      LeaderboardEntry(
        id: '8',
        rank: 8,
        name: 'Hugokyf',
        avatarUrl: 'assets/images/nimo_splash.png',
        points: 667,
        rankChange: -3,
      ),
      LeaderboardEntry(
        id: '9',
        rank: 9,
        name: 'Boris Ng',
        avatarUrl: 'assets/images/nimo_child_avatar.png',
        points: 556,
        rankChange: 1,
      ),
      LeaderboardEntry(
        id: '10',
        rank: 10,
        name: 'tth',
        avatarUrl: 'assets/images/nimo_splash.png',
        points: 456,
        rankChange: -1,
      ),
    ];

    _currentUserEntry = LeaderboardEntry(
      id: 'curr',
      rank: 24,
      name: 'Tinna (You)',
      avatarUrl: 'assets/images/nimo_child_avatar.png',
      points: 221,
      rankChange: 5,
      isCurrentUser: true,
    );
  }

  @override
  void dispose() {
    _crownFloatController.dispose();
    _trophyPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Exact Background Gradient from "Select Your Age" Image
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFE4F3E6), // Soft Pale Mint Green (Top Left)
                    Color(0xFFFAF7D4), // Creamy Pastel Transition
                    Color(0xFFFFF197), // Warm Sunny Yellow (Bottom Right)
                  ],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),

          // 2. Soft Wavy Contour Lines (Matching Right Side of Age Screen)
          Positioned.fill(
            child: CustomPaint(
              painter: _WavyBackgroundLinesPainter(),
            ),
          ),

          // 3. Subtle Japanese Garden Asset Watermark
          Positioned.fill(
            child: Opacity(
              opacity: 0.08,
              child: Image.asset(
                'assets/images/nimo_japanese_bg_clean.png',
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => const SizedBox(),
              ),
            ),
          ),

          // 4. Main Content
          SafeArea(
            child: _showTrophyCelebration
                ? _buildTrophyCelebrationView()
                : _buildMainLeaderboardView(),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── 1. MAIN LEADERBOARD VIEW ──────────────────────────────────────────────
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildMainLeaderboardView() {
    return Stack(
      children: [
        Column(
          children: [
            // Top Navigation & Title Bar
            _buildTopAppBar(),

            const SizedBox(height: 8),

            // Main Scrollable Area (League Header + Podium + Ranked List)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 90),
                child: Column(
                  children: [
                    // Golden Amber League Card (Matching Age Selection Card Color!)
                    _buildGoldenLeagueHeaderBanner(),

                    const SizedBox(height: 18),

                    // Top 3 Podium (1st, 2nd, 3rd Place Circles with Crowns 👑)
                    _buildTop3Podium(),

                    const SizedBox(height: 20),

                    // Ranked Explorer List Rows (Rank 4 to 10)
                    _buildRankedListRows(),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Sticky Pinned Bottom Card: "Your current rank"
        Positioned(
          left: 16,
          right: 16,
          bottom: 12,
          child: _buildPinnedUserRankCard(),
        ),
      ],
    );
  }

  // ── TOP NAVIGATION APP BAR ────────────────────────────────────────────────
  Widget _buildTopAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          WoodenBackButton(
            onTap: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                );
              }
            },
            size: 38,
          ),

          // Title with Sun Accent Icon
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text('☀️', style: TextStyle(fontSize: 20)),
              SizedBox(width: 6),
              Text(
                'Leaderboard',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2C1A0F), // Dark Sepia Brown
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),

          // Trophy View Toggle Button
          InkWell(
            onTap: () => setState(() => _showTrophyCelebration = true),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9E6),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFF5A800), width: 1.8),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF5A800).withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                color: Color(0xFFE67E22),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── GOLDEN AMBER LEAGUE BANNER (Matching Age Selection Card!) ─────────────
  Widget _buildGoldenLeagueHeaderBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF5A800), // Age Card Golden Yellow
            Color(0xFFFFB300),
            Color(0xFFFFA000),
          ],
        ),
        borderRadius: BorderRadius.circular(28), // Curved corners like Age Card
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF5A800).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // League Shields (Gold, Blue, Ruby Red, Silver)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLeagueShield(Icons.shield, Colors.white70, size: 26),
              const SizedBox(width: 8),
              _buildLeagueShield(Icons.shield, const Color(0xFF64B5F6), size: 26),
              const SizedBox(width: 8),
              // Active Ruby League Shield (Enlarged White/Gold)
              _buildLeagueShield(Icons.shield, const Color(0xFFE53935), size: 36, isActive: true),
              const SizedBox(width: 8),
              _buildLeagueShield(Icons.shield, const Color(0xFFE0E0E0), size: 26),
              const SizedBox(width: 8),
              _buildLeagueShield(Icons.shield, Colors.white60, size: 26),
            ],
          ),

          const SizedBox(height: 10),

          // Title & Subtitle (White Text on Golden Card)
          const Text(
            'Ruby League',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.5,
              shadows: [
                Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
              ],
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Top 7 advance to the next league',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFFF9E6),
            ),
          ),

          const SizedBox(height: 16),

          // Side-by-side Stats Cards (Off-white Cream Pills)
          Row(
            children: [
              // Today Stat Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFDF8), // Cream Off-White
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'TODAY',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF8D7362),
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.arrow_drop_up_rounded, color: Color(0xFF4CAF50), size: 22),
                            Text(
                              '25 places',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF4CAF50),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Time Left Stat Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFDF8), // Cream Off-White
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'TIME LEFT',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF8D7362),
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.access_time_filled_rounded, color: Color(0xFFE67E22), size: 16),
                            SizedBox(width: 4),
                            Text(
                              '5 days',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFE67E22),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeagueShield(IconData icon, Color color, {double size = 26, bool isActive = false}) {
    return Container(
      padding: EdgeInsets.all(isActive ? 6 : 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.white.withValues(alpha: 0.25) : Colors.transparent,
        shape: BoxShape.circle,
        border: isActive ? Border.all(color: Colors.white, width: 2) : null,
      ),
      child: Icon(icon, size: size, color: isActive ? Colors.white : color),
    );
  }

  // ── TOP 3 PODIUM CARDS ───────────────────────────────────────────────────
  Widget _buildTop3Podium() {
    if (_entries.length < 3) return const SizedBox();

    final first = _entries[0];
    final second = _entries[1];
    final third = _entries[2];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // 2nd Place (Left)
            _buildPodiumMemberCard(second, rank: 2, avatarSize: 72),

            const SizedBox(width: 14),

            // 1st Place (Center - Tallest)
            _buildPodiumMemberCard(first, rank: 1, avatarSize: 88, isCenterFirst: true),

            const SizedBox(width: 14),

            // 3rd Place (Right)
            _buildPodiumMemberCard(third, rank: 3, avatarSize: 68),
          ],
        ),
      ),
    );
  }

  Widget _buildPodiumMemberCard(
    LeaderboardEntry entry, {
    required int rank,
    required double avatarSize,
    bool isCenterFirst = false,
  }) {
    final Color badgeColor = rank == 1
        ? const Color(0xFFF5A800)
        : (rank == 2 ? const Color(0xFF78909C) : const Color(0xFFA1887F));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Floating Crown Above Head
        AnimatedBuilder(
          animation: _crownFloatController,
          builder: (context, child) {
            final dy = math.sin(_crownFloatController.value * math.pi * 2) * (isCenterFirst ? 4 : 2);
            return Transform.translate(
              offset: Offset(0, dy),
              child: Text(
                '👑',
                style: TextStyle(fontSize: isCenterFirst ? 28 : 22),
              ),
            );
          },
        ),

        const SizedBox(height: 2),

        // Circular Avatar with Rank Number Badge Overlay
        Stack(
          alignment: Alignment.center,
          children: [
            // Outer Glowing Border Ring
            Container(
              width: avatarSize + 8,
              height: avatarSize + 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: badgeColor, width: isCenterFirst ? 3.5 : 2.5),
                boxShadow: [
                  BoxShadow(
                    color: badgeColor.withValues(alpha: 0.4),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),

            // Vector Initial Avatar (No Image Picture)
            _buildCleanInitialAvatar(entry.name, avatarSize),

            // Circular Rank Badge Pill at Bottom Center
            Positioned(
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                child: Text(
                  '$rank',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Explorer Name
        Text(
          entry.name,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: isCenterFirst ? 16 : 14,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF2C1A0F),
          ),
        ),

        const SizedBox(height: 2),

        // Points & Rank Change Delta (▲/▼)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${entry.points}',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: isCenterFirst ? 14 : 12.5,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF8D7362),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              entry.rankChange >= 0 ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
              color: entry.rankChange >= 0 ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
              size: 18,
            ),
          ],
        ),
      ],
    );
  }

  // ── RANKED EXPLORER LIST ROWS (Ranks 4 to 10) ────────────────────────────
  Widget _buildRankedListRows() {
    final listEntries = _entries.where((e) => e.rank > 3).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: listEntries.map((entry) {
          final bool isGreenHighlight = entry.rank == 4 || entry.isCurrentUser;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isGreenHighlight
                  ? const Color(0xFFDCEDC8) // Duolingo Rank 1 highlight green tint
                  : const Color(0xFFFFFDF8), // Cream Off-White Row
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isGreenHighlight ? const Color(0xFF81C784) : const Color(0xFFFFF3C4),
                width: 1.2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                // Rank Number & Delta (▲ / ▼)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${entry.rank}',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: isGreenHighlight ? const Color(0xFF2E7D32) : const Color(0xFF2C1A0F),
                      ),
                    ),
                    Icon(
                      entry.rankChange >= 0 ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
                      color: entry.rankChange >= 0 ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
                      size: 16,
                    ),
                  ],
                ),

                const SizedBox(width: 14),

                // Vector Initial Avatar (No Image Picture)
                _buildCleanInitialAvatar(entry.name, 40),

                const SizedBox(width: 14),

                // Explorer Name
                Expanded(
                  child: Text(
                    entry.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isGreenHighlight ? const Color(0xFF1B5E20) : const Color(0xFF2C1A0F),
                    ),
                  ),
                ),

                // Points Text (e.g. 1012 points)
                Text(
                  '${entry.points} points',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isGreenHighlight ? const Color(0xFF2E7D32) : const Color(0xFF8D7362),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── PINNED USER RANK BOTTOM CARD (Golden Amber) ──────────────────────────
  Widget _buildPinnedUserRankCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFF5A800),
            Color(0xFFFFB300),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 1.8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF5A800).withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank Badge with Delta
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${_currentUserEntry.rank}',
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const Icon(Icons.arrow_drop_up_rounded, color: Colors.white, size: 16),
            ],
          ),

          const SizedBox(width: 14),

          // Text: "Your current rank"
          const Expanded(
            child: Text(
              'Your current rank',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),

          // Points: "221 points"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDF8),
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
              ],
            ),
            child: Text(
              '${_currentUserEntry.points} points',
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2C1A0F),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── 2. TROPHY CELEBRATION VIEW ────────────────────────────────────────────
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildTrophyCelebrationView() {
    return Column(
      children: [
        // Top Bar Back Button to Leaderboard
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: WoodenBackButton(
              onTap: () => setState(() => _showTrophyCelebration = false),
              size: 38,
            ),
          ),
        ),

        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Folded Yellow Ribbon Banner: "Congratuation!!"
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5A800),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
                      ],
                    ),
                    child: const Text(
                      'Congratuation!!',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Giant 3D Golden Star Trophy 🏆
                  AnimatedBuilder(
                    animation: _trophyPulseController,
                    builder: (context, child) {
                      final scale = 1.0 + 0.04 * math.sin(_trophyPulseController.value * math.pi * 2);
                      return Transform.scale(
                        scale: scale,
                        child: child,
                      );
                    },
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFFF5A800),
                            blurRadius: 36,
                            spreadRadius: 6,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.emoji_events_rounded,
                          size: 140,
                          color: Color(0xFFFFB300),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Your Current Rank Card (11 | Your current rank | 440 points)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFDF8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFF5A800), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          '11',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF2C1A0F),
                          ),
                        ),
                        const Icon(Icons.arrow_drop_up_rounded, color: Color(0xFF4CAF50), size: 16),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Your current rank',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2C1A0F),
                            ),
                          ),
                        ),
                        const Text(
                          '440 points',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF8D7362),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Golden Amber Pill Button: "Continue game"
                  SizedBox(
                    width: 240,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() => _showTrophyCelebration = false);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF5A800), // Golden Amber Button
                        foregroundColor: Colors.white,
                        elevation: 8,
                        shadowColor: const Color(0xFFF5A800).withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                      child: const Text(
                        'Continue game',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildCleanInitialAvatar(String name, double size) {
    final List<Color> bgColors = [
      const Color(0xFFF5A800), // Golden Amber
      const Color(0xFF4CAF50), // Fresh Green
      const Color(0xFF42A5F5), // Soft Sky Blue
      const Color(0xFFAB47BC), // Lavender Purple
      const Color(0xFFEF5350), // Coral Red
      const Color(0xFF26A69A), // Teal
    ];

    final colorIndex = name.isNotEmpty ? name.codeUnitAt(0) % bgColors.length : 0;
    final bgColor = bgColors[colorIndex];

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            bgColor,
            bgColor.withValues(alpha: 0.82),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: size * 0.44,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            shadows: const [
              Shadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 1.5)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter for the soft vertical wavy background lines matching the "Select Your Age" screen
class _WavyBackgroundLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    for (int i = 0; i < 6; i++) {
      final path = Path();
      final startX = size.width * (0.55 + i * 0.08);
      path.moveTo(startX, 0);
      path.cubicTo(
        startX + 35,
        size.height * 0.3,
        startX - 35,
        size.height * 0.7,
        startX + 25,
        size.height,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
