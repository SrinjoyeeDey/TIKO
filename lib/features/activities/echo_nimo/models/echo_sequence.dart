import 'dart:math' as math;
import 'echo_symbol.dart';

/// Positional Evaluation Result of player sequence reproduction.
class EchoEvaluation {
  final bool isExactMatch;
  final int totalTargetSteps;
  final int totalPlayerSteps;
  final int correctPositions;
  final int incorrectPositions;
  final double positionalAccuracy;

  const EchoEvaluation({
    required this.isExactMatch,
    required this.totalTargetSteps,
    required this.totalPlayerSteps,
    required this.correctPositions,
    required this.incorrectPositions,
    required this.positionalAccuracy,
  });
}

/// Helper class for generating and evaluating sequence step matches.
class EchoSequence {
  /// Randomly generates a sequence of given length from active symbol pool.
  static List<EchoSymbol> generate({
    required List<EchoSymbol> pool,
    required int length,
  }) {
    final random = math.Random();
    final sequence = <EchoSymbol>[];
    for (int i = 0; i < length; i++) {
      final symbol = pool[random.nextInt(pool.length)];
      sequence.add(symbol);
    }
    return List.unmodifiable(sequence);
  }

  /// Evaluates player sequence step-by-step against target sequence.
  static EchoEvaluation evaluate({
    required List<EchoSymbol> target,
    required List<EchoSymbol> player,
  }) {
    int correctCount = 0;
    final minLength = math.min(target.length, player.length);

    for (int i = 0; i < minLength; i++) {
      if (target[i] == player[i]) {
        correctCount++;
      }
    }

    final isExact = target.length == player.length && correctCount == target.length;
    final accuracy = target.isNotEmpty ? (correctCount / target.length) : 0.0;

    return EchoEvaluation(
      isExactMatch: isExact,
      totalTargetSteps: target.length,
      totalPlayerSteps: player.length,
      correctPositions: correctCount,
      incorrectPositions: target.length - correctCount,
      positionalAccuracy: accuracy,
    );
  }
}
