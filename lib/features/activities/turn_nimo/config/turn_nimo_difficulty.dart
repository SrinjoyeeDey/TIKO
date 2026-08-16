import '../../core/models/difficulty_config.dart';

/// Difficulty Configuration for Turn NIMO social turn-taking activity.
class TurnNimoDifficulty extends DifficultyConfig {
  final Duration nimoAutoRollDelay;
  final int totalTurnsPerSession;

  const TurnNimoDifficulty({
    required super.level,
    required super.baseXP,
    required super.timeout,
    required this.nimoAutoRollDelay,
    required this.totalTurnsPerSession,
  });

  static const List<TurnNimoDifficulty> levels = [
    TurnNimoDifficulty(
      level: 1,
      baseXP: 30,
      timeout: Duration(seconds: 30),
      nimoAutoRollDelay: Duration(milliseconds: 1800),
      totalTurnsPerSession: 6,
    ),
    TurnNimoDifficulty(
      level: 2,
      baseXP: 40,
      timeout: Duration(seconds: 28),
      nimoAutoRollDelay: Duration(milliseconds: 1500),
      totalTurnsPerSession: 8,
    ),
    TurnNimoDifficulty(
      level: 3,
      baseXP: 55,
      timeout: Duration(seconds: 25),
      nimoAutoRollDelay: Duration(milliseconds: 1200),
      totalTurnsPerSession: 8,
    ),
    TurnNimoDifficulty(
      level: 4,
      baseXP: 70,
      timeout: Duration(seconds: 22),
      nimoAutoRollDelay: Duration(milliseconds: 1000),
      totalTurnsPerSession: 10,
    ),
    TurnNimoDifficulty(
      level: 5,
      baseXP: 90,
      timeout: Duration(seconds: 20),
      nimoAutoRollDelay: Duration(milliseconds: 800),
      totalTurnsPerSession: 10,
    ),
  ];

  static TurnNimoDifficulty getForLevel(int level) {
    if (level <= 1) return levels[0];
    if (level >= levels.length) return levels.last;
    return levels[level - 1];
  }
}
