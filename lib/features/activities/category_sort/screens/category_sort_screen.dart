import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/state/child_state.dart';
import '../engine/category_sort_controller.dart';
import '../widgets/category_bin_widget.dart';
import '../widgets/item_prompt_card.dart';
import 'category_sort_result_screen.dart';

/// Main Playable Category Sort Screen for FFC Categorization.
class CategorySortScreen extends StatefulWidget {
  const CategorySortScreen({super.key});

  @override
  State<CategorySortScreen> createState() => _CategorySortScreenState();
}

class _CategorySortScreenState extends State<CategorySortScreen> {
  late CategorySortController _controller;
  bool _hasStartedRound = false;

  @override
  void initState() {
    super.initState();
    final childId = ChildState.instance.currentProfile.id;
    _controller = CategorySortController(childId: childId);
    _controller.addListener(_onControllerStateChanged);
  }

  void _onControllerStateChanged() {
    if (!mounted) return;

    if (_controller.isSessionFinished) {
      final session = _controller.buildCompletedSession();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => CategorySortResultScreen(session: session),
        ),
      );
      return;
    }

    setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerStateChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (!_hasStartedRound) {
            _hasStartedRound = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _controller.startRound();
              }
            });
          }

          return ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              final phase = _controller.phase;
              final activeCategories = _controller.activeCategories;

              return Container(
                width: double.infinity,
                height: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFFFDF8), // Soft Cream Top
                      Color(0xFFF7F0DF), // Warm Ivory
                      Color(0xFFEFE4CC), // Cream Parchment Bottom
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // 1. HUD Header Bar
                        _buildHudHeader(),

                        const SizedBox(height: 16),

                        // 2. Item Prompt Display Card
                        ItemPromptCard(item: _controller.currentItem),

                        const SizedBox(height: 20),

                        // 3. Category Target Grid
                        Expanded(
                          child: Center(
                            child: GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 2,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 1.25,
                              children: activeCategories.map((category) {
                                final isSelected = _controller.tappedCategoryKey == category.key;
                                final isCorrect = isSelected ? _controller.isCurrentTapCorrect : null;
                                final isInteractive = phase == CategorySortPhase.interacting;

                                return CategoryBinWidget(
                                  category: category,
                                  isInteractive: isInteractive,
                                  isSelected: isSelected,
                                  isCorrect: isCorrect,
                                  onTap: () => _controller.onCategoryTapped(category),
                                );
                              }).toList(),
                            ),
                          ),
                        ),

                        // 4. Round Complete Feedback Banner
                        if (phase == CategorySortPhase.roundComplete)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBF0),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF85D64B), width: 2.2),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x300F220A),
                                  offset: Offset(0, 4),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  _controller.feedbackHeadline ?? 'Great sorting!',
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF85D64B),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _controller.feedbackDetail ?? '',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF14300D),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHudHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF85D64B), width: 2.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x250F220A),
            offset: Offset(0, 4),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF85D64B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 14),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'CATEGORY SORT',
                    style: GoogleFonts.outfit(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF4F8528),
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    'ROUND ${_controller.currentRound} / ${_controller.totalRounds}',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF14300D),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFBF27),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE89B00), width: 1.5),
                ),
                child: Text(
                  'LVL ${_controller.currentLevel}',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF3A2200),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFA855F7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF7C23D4), width: 1.5),
                ),
                child: Row(
                  children: [
                    const Text('⚡', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 3),
                    Text(
                      '${_controller.currentXP}',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
