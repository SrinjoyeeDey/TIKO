import 'package:flutter/material.dart';

enum PowerCardType {
  doubleRoll,
  shield,
  targetLock,
}

/// Tactical Action Power Card for Turn NIMO.
class PowerCard {
  final PowerCardType type;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const PowerCard({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  static const doubleRoll = PowerCard(
    type: PowerCardType.doubleRoll,
    title: 'Double Roll ⚡',
    subtitle: 'Roll 2 dice!',
    icon: Icons.flash_on_rounded,
    color: Color(0xFFFFBF27),
  );

  static const shield = PowerCard(
    type: PowerCardType.shield,
    title: 'Shield 🛡️',
    subtitle: 'Block NIMO\'s points',
    icon: Icons.shield_rounded,
    color: Color(0xFF45B7D1),
  );

  static const targetLock = PowerCard(
    type: PowerCardType.targetLock,
    title: 'Target Lock 🎯',
    subtitle: 'Predict roll for 3x XP',
    icon: Icons.track_changes_rounded,
    color: Color(0xFFFF3B63),
  );

  static const List<PowerCard> defaultHand = [
    doubleRoll,
    shield,
    targetLock,
  ];
}
