import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/memory_feature.dart';

/// Interactive Category Selector & Option Cards for Remember NIMO reconstruction.
class FeatureSelectorWidget extends StatefulWidget {
  final List<FeatureCategory> activeCategories;
  final Map<FeatureCategory, List<MemoryFeatureOption>> optionsPerCategory;
  final Map<FeatureCategory, MemoryFeatureOption> playerSelections;
  final Function(FeatureCategory, MemoryFeatureOption) onOptionSelected;

  const FeatureSelectorWidget({
    super.key,
    required this.activeCategories,
    required this.optionsPerCategory,
    required this.playerSelections,
    required this.onOptionSelected,
  });

  @override
  State<FeatureSelectorWidget> createState() => _FeatureSelectorWidgetState();
}

class _FeatureSelectorWidgetState extends State<FeatureSelectorWidget> {
  late FeatureCategory _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.activeCategories.first;
  }

  @override
  void didUpdateWidget(covariant FeatureSelectorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.activeCategories.contains(_selectedCategory)) {
      _selectedCategory = widget.activeCategories.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentOptions = widget.optionsPerCategory[_selectedCategory] ?? [];
    final currentSelection = widget.playerSelections[_selectedCategory];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Category Tab Bar
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: widget.activeCategories.map((cat) {
              final isSelected = cat == _selectedCategory;
              final isChosen = widget.playerSelections.containsKey(cat);

              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF14300D)
                        : (isChosen ? const Color(0xFF85D64B).withValues(alpha: 0.25) : const Color(0xFFFFFBF0)),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF85D64B) : const Color(0xFFE2D6B5),
                      width: isSelected ? 2.0 : 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        cat.icon,
                        size: 16,
                        color: isSelected ? const Color(0xFF85D64B) : const Color(0xFF14300D),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        cat.displayName,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: isSelected ? Colors.white : const Color(0xFF14300D),
                          letterSpacing: 1.0,
                        ),
                      ),
                      if (isChosen) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF85D64B)),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 14),

        // 2. Option Cards Grid
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: currentOptions.map((option) {
            final isSelected = currentSelection?.id == option.id;

            return GestureDetector(
              onTap: () => widget.onOptionSelected(_selectedCategory, option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 105,
                height: 100,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF85D64B) : const Color(0xFFFFFBF0),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Colors.white : const Color(0xFFE2D6B5),
                    width: isSelected ? 2.5 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected ? const Color(0xFF4F8528) : const Color(0x200F220A),
                      offset: Offset(0, isSelected ? 4 : 2),
                      blurRadius: isSelected ? 6 : 4,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: option.color.withValues(alpha: isSelected ? 0.9 : 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        option.iconData,
                        size: 26,
                        color: isSelected ? Colors.white : option.color,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      option.name,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: isSelected ? const Color(0xFF14300D) : const Color(0xFF3A2200),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
