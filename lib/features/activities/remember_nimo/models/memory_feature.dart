import 'package:flutter/material.dart';

/// Categories of character features to memorize & reconstruct.
enum FeatureCategory {
  hairstyle,
  eyes,
  expression,
  accessory,
  clothing,
}

extension FeatureCategoryExtension on FeatureCategory {
  String get displayName {
    switch (this) {
      case FeatureCategory.hairstyle: return 'HAIR';
      case FeatureCategory.eyes: return 'EYES';
      case FeatureCategory.expression: return 'EXPRESSION';
      case FeatureCategory.accessory: return 'ACCESSORY';
      case FeatureCategory.clothing: return 'CLOTHING';
    }
  }

  IconData get icon {
    switch (this) {
      case FeatureCategory.hairstyle: return Icons.face_retouching_natural;
      case FeatureCategory.eyes: return Icons.visibility_rounded;
      case FeatureCategory.expression: return Icons.mood_rounded;
      case FeatureCategory.accessory: return Icons.headphones_rounded;
      case FeatureCategory.clothing: return Icons.checkroom_rounded;
    }
  }
}

/// A specific option for a character feature category.
class MemoryFeatureOption {
  final String id;
  final FeatureCategory category;
  final String name;
  final IconData iconData;
  final Color color;

  const MemoryFeatureOption({
    required this.id,
    required this.category,
    required this.name,
    required this.iconData,
    required this.color,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemoryFeatureOption &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  // Pre-defined feature option pools
  static const List<MemoryFeatureOption> allHairstyles = [
    MemoryFeatureOption(id: 'hair_curly', category: FeatureCategory.hairstyle, name: 'Curly Afro', iconData: Icons.wb_cloudy_rounded, color: Color(0xFFFFBF27)),
    MemoryFeatureOption(id: 'hair_spiky', category: FeatureCategory.hairstyle, name: 'Spiky Crop', iconData: Icons.bolt_rounded, color: Color(0xFFFF3B63)),
    MemoryFeatureOption(id: 'hair_smooth', category: FeatureCategory.hairstyle, name: 'Smooth Bob', iconData: Icons.waves_rounded, color: Color(0xFFA855F7)),
    MemoryFeatureOption(id: 'hair_ponytail', category: FeatureCategory.hairstyle, name: 'Top Knot', iconData: Icons.filter_hdr_rounded, color: Color(0xFF4FACFE)),
  ];

  static const List<MemoryFeatureOption> allEyes = [
    MemoryFeatureOption(id: 'eyes_sparkle', category: FeatureCategory.eyes, name: 'Sparkle Big', iconData: Icons.auto_awesome_rounded, color: Color(0xFF00F2FE)),
    MemoryFeatureOption(id: 'eyes_shades', category: FeatureCategory.eyes, name: 'Cool Shades', iconData: Icons.dark_mode_rounded, color: Color(0xFF14300D)),
    MemoryFeatureOption(id: 'eyes_goggles', category: FeatureCategory.eyes, name: 'Cyber Goggles', iconData: Icons.vrpano_rounded, color: Color(0xFFFFD700)),
    MemoryFeatureOption(id: 'eyes_wink', category: FeatureCategory.eyes, name: 'Anime Wink', iconData: Icons.remove_red_eye_rounded, color: Color(0xFFFF3B63)),
  ];

  static const List<MemoryFeatureOption> allExpressions = [
    MemoryFeatureOption(id: 'exp_grin', category: FeatureCategory.expression, name: 'Big Grin', iconData: Icons.sentiment_very_satisfied_rounded, color: Color(0xFF85D64B)),
    MemoryFeatureOption(id: 'exp_smirk', category: FeatureCategory.expression, name: 'Cool Smirk', iconData: Icons.sentiment_satisfied_alt_rounded, color: Color(0xFFFFBF27)),
    MemoryFeatureOption(id: 'exp_open', category: FeatureCategory.expression, name: 'Surprised O', iconData: Icons.sentiment_neutral_rounded, color: Color(0xFF4FACFE)),
    MemoryFeatureOption(id: 'exp_playful', category: FeatureCategory.expression, name: 'Tongue Out', iconData: Icons.tag_faces_rounded, color: Color(0xFFFF3B63)),
  ];

  static const List<MemoryFeatureOption> allAccessories = [
    MemoryFeatureOption(id: 'acc_headphones', category: FeatureCategory.accessory, name: 'Pro Headset', iconData: Icons.headphones_rounded, color: Color(0xFFA855F7)),
    MemoryFeatureOption(id: 'acc_cap', category: FeatureCategory.accessory, name: 'Snapback Cap', iconData: Icons.sports_baseball_rounded, color: Color(0xFFFFBF27)),
    MemoryFeatureOption(id: 'acc_crown', category: FeatureCategory.accessory, name: 'Neon Crown', iconData: Icons.military_tech_rounded, color: Color(0xFFFFD700)),
    MemoryFeatureOption(id: 'acc_scarf', category: FeatureCategory.accessory, name: 'Bandana', iconData: Icons.dry_cleaning_rounded, color: Color(0xFFFF3B63)),
  ];

  static const List<MemoryFeatureOption> allClothing = [
    MemoryFeatureOption(id: 'cloth_jacket', category: FeatureCategory.clothing, name: 'Tech Jacket', iconData: Icons.checkroom_rounded, color: Color(0xFF00F2FE)),
    MemoryFeatureOption(id: 'cloth_hoodie', category: FeatureCategory.clothing, name: 'Urban Hoodie', iconData: Icons.dry_cleaning_rounded, color: Color(0xFF85D64B)),
    MemoryFeatureOption(id: 'cloth_vest', category: FeatureCategory.clothing, name: 'Armor Vest', iconData: Icons.shield_rounded, color: Color(0xFFFFBF27)),
    MemoryFeatureOption(id: 'cloth_tee', category: FeatureCategory.clothing, name: 'Graphic Tee', iconData: Icons.dry_rounded, color: Color(0xFFA855F7)),
  ];

  static List<MemoryFeatureOption> getOptionsForCategory(FeatureCategory cat) {
    switch (cat) {
      case FeatureCategory.hairstyle: return allHairstyles;
      case FeatureCategory.eyes: return allEyes;
      case FeatureCategory.expression: return allExpressions;
      case FeatureCategory.accessory: return allAccessories;
      case FeatureCategory.clothing: return allClothing;
    }
  }
}
