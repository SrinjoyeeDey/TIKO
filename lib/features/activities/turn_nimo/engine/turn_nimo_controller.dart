import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/activity_attempt.dart';
import '../../core/models/activity_session.dart';
import '../../core/services/activity_persistence_service.dart';
import '../../core/services/adaptive_learning_service.dart';
import '../config/turn_nimo_difficulty.dart';
import '../models/power_card.dart';

enum TurnNimoPhase {
  nimoTurn,
  nimoRolling,
  playerTurn,
  playerRolling,
  turnComplete,
  sessionFinished,
}

class TurnNimoController extends ChangeNotifier {
  static const _uuid = Uuid();
  final math.Random _random = math.Random();

  final String sessionId = _uuid.v4();
  final String childId;
  final DateTime startedAt = DateTime.now();

  final AdaptiveLearningService adaptiveEngine;

  int _currentTurnCount = 1;
  int _currentLevel = 1;

  TurnNimoPhase _phase = TurnNimoPhase.nimoTurn;

  // Dice & Scores
  int _diceValue = 0; // 0 to 5 (maps to 1 to 6 points)
  int _nimoScore = 0;
  int _playerScore = 0;
  int _streak = 0;
  int _highestStreak = 0;

  // Tactical Power Cards
  PowerCardType? _activePlayerPowerCard;
  final Set<PowerCardType> _usedPowerCards = {};

  // Timers & Reaction measurement
  Timer? _autoRollTimer;
  Timer? _diceTickerTimer;
  final Stopwatch _turnStopwatch = Stopwatch();
  DateTime? _lastTapTime;

  // Stats & Banter
  int _currentXP = 300;
  String? _feedbackHeadline;
  String? _feedbackDetail;

  final List<ActivityAttempt> _attempts = [];

  static const List<String> _nimoBanterPrompts = [
    'Watch this roll! Can you beat a 6?',
    'Nice move, but I am taking the lead!',
    'Your turn! Show me what you\'ve got!',
    'Let\'s see if the dice favor us!',
  ];

  TurnNimoController({
    required this.childId,
    this.adaptiveEngine = const AdaptiveLearningService(),
  });

  // Getters
  int get currentTurnCount => _currentTurnCount;
  int get currentLevel => _currentLevel;
  TurnNimoDifficulty get currentConfig => TurnNimoDifficulty.getForLevel(_currentLevel);
  TurnNimoPhase get phase => _phase;
  int get diceValue => _diceValue;
  int get nimoScore => _nimoScore;
  int get playerScore => _playerScore;
  int get currentXP => _currentXP;
  int get streak => _streak;
  int get highestStreak => _highestStreak;
  PowerCardType? get activePlayerPowerCard => _activePlayerPowerCard;
  Set<PowerCardType> get usedPowerCards => Set.unmodifiable(_usedPowerCards);
  String? get feedbackHeadline => _feedbackHeadline;
  String? get feedbackDetail => _feedbackDetail;
  bool get isSessionFinished => _phase == TurnNimoPhase.sessionFinished;
  bool get isPlayerTurn => _phase == TurnNimoPhase.playerTurn;

  /// Starts the game and initializes NIMO's first turn
  void startGame() {
    _currentTurnCount = 1;
    _nimoScore = 0;
    _playerScore = 0;
    _usedPowerCards.clear();
    _activePlayerPowerCard = null;
    _startNimoTurn();
  }

  /// Activates a tactical power card for the current player turn
  void activatePowerCard(PowerCardType cardType) {
    if (_phase != TurnNimoPhase.playerTurn) return;
    if (_usedPowerCards.contains(cardType)) return;

    SystemSound.play(SystemSoundType.click);
    _activePlayerPowerCard = cardType;
    _usedPowerCards.add(cardType);

    if (cardType == PowerCardType.doubleRoll) {
      _feedbackHeadline = 'DOUBLE ROLL ACTIVATED ⚡';
      _feedbackDetail = 'Your next roll score will be doubled!';
    } else if (cardType == PowerCardType.shield) {
      _feedbackHeadline = 'SHIELD ACTIVATED 🛡️';
      _feedbackDetail = 'Protected against NIMO\'s high score!';
    } else if (cardType == PowerCardType.targetLock) {
      _feedbackHeadline = 'TARGET LOCK ACTIVATED 🎯';
      _feedbackDetail = 'Predicting a high roll for 3x XP!';
    }

    notifyListeners();
  }

  /// NIMO's turn: NIMO avatar waits briefly then auto-rolls
  void _startNimoTurn() {
    if (_currentTurnCount > currentConfig.totalTurnsPerSession) {
      _finishSession();
      return;
    }

    _phase = TurnNimoPhase.nimoTurn;
    _activePlayerPowerCard = null;

    final banter = _nimoBanterPrompts[_random.nextInt(_nimoBanterPrompts.length)];
    _feedbackHeadline = '🤖 NIMO\'S TURN';
    _feedbackDetail = banter;
    notifyListeners();

    _autoRollTimer?.cancel();
    _autoRollTimer = Timer(currentConfig.nimoAutoRollDelay, () {
      _rollDice(isNimo: true);
    });
  }

  /// Player's turn: Prompt player to tap 3D dice button
  void _startPlayerTurn() {
    if (_currentTurnCount > currentConfig.totalTurnsPerSession) {
      _finishSession();
      return;
    }

    _phase = TurnNimoPhase.playerTurn;
    _turnStopwatch.reset();
    _turnStopwatch.start();
    _feedbackHeadline = 'YOUR TURN! 🧒';
    _feedbackDetail = 'Select a Power Card or tap the dice to roll 🎲';
    notifyListeners();
  }

  /// Called when player taps the dice button
  void onPlayerRollTapped() {
    if (_phase != TurnNimoPhase.playerTurn) return;

    final now = DateTime.now();
    if (_lastTapTime != null && now.difference(_lastTapTime!).inMilliseconds < 150) {
      return;
    }
    _lastTapTime = now;

    SystemSound.play(SystemSoundType.click);
    _turnStopwatch.stop();
    _rollDice(isNimo: false);
  }

  /// Executes animated dice rolling sequence (10 ticks)
  void _rollDice({required bool isNimo}) {
    _phase = isNimo ? TurnNimoPhase.nimoRolling : TurnNimoPhase.playerRolling;
    notifyListeners();

    int tick = 0;
    _diceTickerTimer?.cancel();
    _diceTickerTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _diceValue = _random.nextInt(6);
      tick++;
      notifyListeners();

      if (tick >= 10) {
        timer.cancel();
        _finalizeRoll(isNimo: isNimo);
      }
    });
  }

  /// Finalizes roll value and calculates points with power card effects
  void _finalizeRoll({required bool isNimo}) {
    final finalRollValue = _random.nextInt(6);
    _diceValue = finalRollValue;
    int points = finalRollValue + 1;

    _phase = TurnNimoPhase.turnComplete;

    if (isNimo) {
      _nimoScore += points;
      _feedbackHeadline = 'NIMO ROLLED $points! 🎲';
      _feedbackDetail = 'NIMO scored $points points. Now it\'s your turn!';
    } else {
      // Check Power Card Multipliers
      if (_activePlayerPowerCard == PowerCardType.doubleRoll) {
        points *= 2;
      }

      _playerScore += points;
      _streak++;
      if (_streak > _highestStreak) _highestStreak = _streak;

      final config = currentConfig;
      int earnedXP = (config.baseXP + points * 2).toInt();

      if (_activePlayerPowerCard == PowerCardType.targetLock) {
        earnedXP *= 3;
      }

      _currentXP += earnedXP;

      _attempts.add(ActivityAttempt(
        attemptId: _uuid.v4(),
        sessionId: sessionId,
        roundNumber: _currentTurnCount,
        timestamp: DateTime.now(),
        responseTime: DateTime.now(),
        reactionTimeMs: _turnStopwatch.elapsedMilliseconds,
        isCorrect: true,
        isMissed: false,
        isIncorrectTarget: false,
        score: points,
        difficultyLevel: _currentLevel,
      ));

      _feedbackHeadline = 'YOU ROLLED $points! 🎉';
      _feedbackDetail = 'You scored $points points! Total: $_playerScore';
      _evaluateAdaptiveEngine();
    }

    notifyListeners();

    Future.delayed(const Duration(milliseconds: 1600), () {
      _currentTurnCount++;
      if (isNimo) {
        _startPlayerTurn();
      } else {
        _startNimoTurn();
      }
    });
  }

  void _evaluateAdaptiveEngine() {
    final decision = adaptiveEngine.evaluatePerformance(
      attempts: _attempts,
      currentDifficulty: _currentLevel,
    );

    if (decision.levelChanged) {
      _currentLevel = decision.nextDifficulty;
    }
  }

  void _finishSession() {
    _autoRollTimer?.cancel();
    _diceTickerTimer?.cancel();
    _turnStopwatch.stop();
    _phase = TurnNimoPhase.sessionFinished;

    final session = buildCompletedSession();
    ActivityPersistenceService.saveSession(session);
    notifyListeners();
  }

  ActivitySession buildCompletedSession() {
    final validReactionTimes = _attempts.map((a) => a.reactionTimeMs).toList();
    final avgReaction = validReactionTimes.isNotEmpty
        ? validReactionTimes.reduce((a, b) => a + b) / validReactionTimes.length
        : 0.0;

    return ActivitySession(
      sessionId: sessionId,
      activityId: 'turn_nimo',
      childId: childId,
      startedAt: startedAt,
      completedAt: DateTime.now(),
      totalRounds: currentConfig.totalTurnsPerSession,
      successfulRounds: _attempts.length,
      missedRounds: 0,
      incorrectTaps: 0,
      averageReactionTimeMs: avgReaction,
      bestReactionTimeMs: validReactionTimes.isNotEmpty ? validReactionTimes.reduce((a, b) => a < b ? a : b) : 0,
      highestStreak: _highestStreak,
      difficultyReached: _currentLevel,
      totalXP: _currentXP,
      attempts: _attempts,
    );
  }

  @override
  void dispose() {
    _autoRollTimer?.cancel();
    _diceTickerTimer?.cancel();
    _turnStopwatch.stop();
    super.dispose();
  }
}
