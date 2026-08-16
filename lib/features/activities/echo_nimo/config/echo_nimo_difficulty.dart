import '../../core/models/difficulty_config.dart';
import '../models/echo_symbol.dart';

/// Difficulty Configurations for Echo NIMO.
class EchoNimoDifficulty extends DifficultyConfig {
  final int sequenceLength;
  final Duration playbackInterval;
  final List<EchoSymbol> activeSymbols;

  const EchoNimoDifficulty({
    required super.level,
    required super.baseXP,
    required super.timeout,
    required this.sequenceLength,
    required this.playbackInterval,
    required this.activeSymbols,
  });

  static const List<EchoNimoDifficulty> levels = [
    EchoNimoDifficulty(
      level: 1,
      baseXP: 30,
      timeout: Duration(seconds: 25),
      sequenceLength: 3,
      playbackInterval: Duration(milliseconds: 700),
      activeSymbols: [
        EchoSymbol.cyan,
        EchoSymbol.purple,
        EchoSymbol.yellow,
      ],
    ),
    EchoNimoDifficulty(
      level: 2,
      baseXP: 40,
      timeout: Duration(seconds: 22),
      sequenceLength: 4,
      playbackInterval: Duration(milliseconds: 600),
      activeSymbols: [
        EchoSymbol.cyan,
        EchoSymbol.purple,
        EchoSymbol.yellow,
        EchoSymbol.green,
      ],
    ),
    EchoNimoDifficulty(
      level: 3,
      baseXP: 50,
      timeout: Duration(seconds: 20),
      sequenceLength: 5,
      playbackInterval: Duration(milliseconds: 500),
      activeSymbols: [
        EchoSymbol.cyan,
        EchoSymbol.purple,
        EchoSymbol.yellow,
        EchoSymbol.green,
      ],
    ),
    EchoNimoDifficulty(
      level: 4,
      baseXP: 65,
      timeout: Duration(seconds: 18),
      sequenceLength: 6,
      playbackInterval: Duration(milliseconds: 420),
      activeSymbols: [
        EchoSymbol.cyan,
        EchoSymbol.purple,
        EchoSymbol.yellow,
        EchoSymbol.green,
        EchoSymbol.coral,
      ],
    ),
    EchoNimoDifficulty(
      level: 5,
      baseXP: 80,
      timeout: Duration(seconds: 15),
      sequenceLength: 7,
      playbackInterval: Duration(milliseconds: 350),
      activeSymbols: [
        EchoSymbol.cyan,
        EchoSymbol.purple,
        EchoSymbol.yellow,
        EchoSymbol.green,
        EchoSymbol.coral,
      ],
    ),
  ];

  static EchoNimoDifficulty getForLevel(int level) {
    if (level <= 1) return levels[0];
    if (level >= levels.length) return levels.last;
    return levels[level - 1];
  }
}
