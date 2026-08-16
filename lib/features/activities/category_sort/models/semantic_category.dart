import 'package:flutter/material.dart';

/// Semantic Category definition for FFC categorization.
class SemanticCategory {
  final String key;
  final String displayName;
  final IconData icon;
  final String emoji;
  final Color color;
  final Color darkBevelColor;

  const SemanticCategory({
    required this.key,
    required this.displayName,
    required this.icon,
    required this.emoji,
    required this.color,
    required this.darkBevelColor,
  });

  static const food = SemanticCategory(
    key: 'Food',
    displayName: 'Food',
    icon: Icons.restaurant_rounded,
    emoji: '🍎',
    color: Color(0xFFFF6B6B),
    darkBevelColor: Color(0xFFD32F2F),
  );

  static const animals = SemanticCategory(
    key: 'Animals',
    displayName: 'Animals',
    icon: Icons.pets_rounded,
    emoji: '🐾',
    color: Color(0xFF4ECDC4),
    darkBevelColor: Color(0xFF00897B),
  );

  static const clothing = SemanticCategory(
    key: 'Clothing',
    displayName: 'Clothing',
    icon: Icons.checkroom_rounded,
    emoji: '👕',
    color: Color(0xFFDDA0DD),
    darkBevelColor: Color(0xFF8E24AA),
  );

  static const places = SemanticCategory(
    key: 'Places',
    displayName: 'Places',
    icon: Icons.location_city_rounded,
    emoji: '🏠',
    color: Color(0xFF45B7D1),
    darkBevelColor: Color(0xFF0288D1),
  );

  static const List<SemanticCategory> allCategories = [
    food,
    animals,
    clothing,
    places,
  ];

  static SemanticCategory getByKey(String key) {
    return allCategories.firstWhere(
      (c) => c.key.toLowerCase() == key.toLowerCase(),
      orElse: () => food,
    );
  }
}
