import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/activity_attempt.dart';
import '../../core/models/activity_session.dart';
import '../../core/services/activity_persistence_service.dart';
import '../../core/services/adaptive_learning_service.dart';
import '../config/echo_nimo_difficulty.dart';
import '../models/echo_sequence.dart';
import '../models/echo_symbol.dart';

enum EchoNimoPhase {
  generating,
  playback,
  playerTurn,
  evaluating,
  roundComplete,
  sessionFinished,
}

class EchoNimoController extends ChangeNotifier {
  static const _uuid = Uuid();

  final String sessionId = _uuid.v4();
  final String childId;
  final DateTime startedAt = DateTime.now();

  final AdaptiveLearningService adaptiveEngine;

  int _currentRound = 1;
  final int totalRounds = 8;
  int _currentLevel = 1;

  EchoNimoPhase _phase = EchoNimoPhase.generating;
  List<EchoSymbol> _targetSequence = [];
  final List<EchoSymbol> _playerSequence = [];

  EchoSymbol? _activePlaybackSymbol;
  int _playbackStepIndex = 0;

  Timer? _playbackTimer;
  final Stopwatch _reactionStopwatch = Stopwatch();
  DateTime? _lastTapTime;

  // Stats & Metrics
  int _currentXP = 320;
  int _streak = 0;
  int _highestStreak = 0;
  int _longestSequenceReproduced = 0;

  EchoEvaluation? _lastEvaluation;
  String? _feedbackHeadline;
  String? _feedbackDetail;

  final List<ActivityAttempt> _attempts = [];

  EchoNimoController({
    required this.childId,
    this.adaptiveEngine = const AdaptiveLearningService(),
  });

  // Getters
  int get currentRound => _currentRound;
  int get currentLevel => _currentLevel;
  EchoNimoDifficulty get currentConfig => EchoNimoDifficulty.getForLevel(_currentLevel);
  EchoNimoPhase get phase => _phase;
  List<EchoSymbol> get targetSequence => List.unmodifiable(_targetSequence);
  List<EchoSymbol> get playerSequence => List.unmodifiable(_playerSequence);
  EchoSymbol? get activePlaybackSymbol => _activePlaybackSymbol;
  int get playbackStepIndex => _playbackStepIndex;
  int get currentXP => _currentXP;
  int get streak => _streak;
  int get highestStreak => _highestStreak;
  int get longestSequenceReproduced => _longestSequenceReproduced;
  EchoEvaluation? get lastEvaluation => _lastEvaluation;
  String? get feedbackHeadline => _feedbackHeadline;
  String? get feedbackDetail => _feedbackDetail;
  bool get isSessionFinished => _phase == EchoNimoPhase.sessionFinished;

  /// Starts next round sequence
  void startRound() {
    if (_currentRound > totalRounds) {
      _finishSession();
      return;
    }

    _playbackTimer?.cancel();
    _reactionStopwatch.reset();

    final config = currentConfig;
    _targetSequence = EchoSequence.generate(
      pool: config.activeSymbols,
      length: config.sequenceLength,
    );
    _playerSequence.clear();
    _activePlaybackSymbol = null;
    _playbackStepIndex = 0;

    _phase = EchoNimoPhase.playback;
    notifyListeners();

    // Start sequential playback after short 500ms prep pause
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_phase == EchoNimoPhase.playback) {
        _playNextStep();
      }
    });
  }

  /// Sequential step playback
  void _playNextStep() {
    final config = currentConfig;
    if (_playbackStepIndex >= _targetSequence.length) {
      // Playback finished -> Switch to Player Turn
      _activePlaybackSymbol = null;
      _phase = EchoNimoPhase.playerTurn;
      _reactionStopwatch.reset();
      _reactionStopwatch.start();
      notifyListeners();
      return;
    }

    final symbol = _targetSequence[_playbackStepIndex];
    _activePlaybackSymbol = symbol;
    SystemSound.play(SystemSoundType.click);
    notifyListeners();

    // Hold highlight for 70% of interval duration, then clear highlight briefly
    final activeDuration = Duration(milliseconds: (config.playbackInterval.inMilliseconds * 0.75).round());
    final gapDuration = Duration(milliseconds: (config.playbackInterval.inMilliseconds * 0.25).round());

    _playbackTimer = Timer(activeDuration, () {
      _activePlaybackSymbol = null;
      notifyListeners();

      _playbackTimer = Timer(gapDuration, () {
        _playbackStepIndex++;
        _playNextStep();
      });
    });
  }

  /// Handles player tap on an Echo pad with rapid double-tap debiasing
  void onSymbolTapped(EchoSymbol symbol) {
    if (_phase != EchoNimoPhase.playerTurn) return;

    // Rapid double-tap guard (150ms)
    final now = DateTime.now();
    if (_lastTapTime != null && now.difference(_lastTapTime!).inMilliseconds < 150) {
      return;
    }
    _lastTapTime = now;

    SystemSound.play(SystemSoundType.click);
    _playerSequence.add(symbol);
    notifyListeners();

    // Check if player completed full sequence length
    if (_playerSequence.length >= _targetSequence.length) {
      _evaluateRound();
    }
  }

  /// Evaluates completed sequence reproduction
  void _evaluateRound() {
    _reactionStopwatch.stop();
    _phase = EchoNimoPhase.evaluating;

    final evaluation = EchoSequence.evaluate(
      target: _targetSequence,
      player: _playerSequence,
    );
    _lastEvaluation = evaluation;

    if (evaluation.isExactMatch) {
      _streak++;
      if (_streak > _highestStreak) _highestStreak = _streak;
      if (evaluation.totalTargetSteps > _longestSequenceReproduced) {
        _longestSequenceReproduced = evaluation.totalTargetSteps;
      }
      _feedbackHeadline = 'Perfect echo!';
      _feedbackDetail = 'You reproduced the entire ${_targetSequence.length}-step sequence!';
    } else if (evaluation.positionalAccuracy >= 0.5) {
      _streak = 0;
      _feedbackHeadline = 'Almost!';
      _feedbackDetail = 'You remembered ${evaluation.correctPositions} of ${evaluation.totalTargetSteps} steps.';
    } else {
      _streak = 0;
      _feedbackHeadline = 'Keep listening!';
      _feedbackDetail = 'Let\'s try another sequence.';
    }

    // XP calculation
    final config = currentConfig;
    final reactionMs = _reactionStopwatch.elapsedMilliseconds;
    final baseXP = (config.baseXP * evaluation.positionalAccuracy).toInt();
    final streakBonus = _streak * 5;
    final earnedXP = baseXP + streakBonus;
    _currentXP += earnedXP;

    // Record attempt
    _attempts.add(ActivityAttempt(
      attemptId: _uuid.v4(),
      sessionId: sessionId,
      roundNumber: _currentRound,
      timestamp: DateTime.now(),
      responseTime: DateTime.now(),
      reactionTimeMs: reactionMs,
      isCorrect: evaluation.isExactMatch,
      isMissed: false,
      isIncorrectTarget: !evaluation.isExactMatch,
      score: earnedXP,
      difficultyLevel: _currentLevel,
    ));

    _evaluateAdaptiveEngine();
    _phase = EchoNimoPhase.roundComplete;
    notifyListeners();

    // Advance to next round after 1.8s feedback display
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (_phase == EchoNimoPhase.roundComplete) {
        _currentRound++;
        startRound();
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
    _playbackTimer?.cancel();
    _reactionStopwatch.stop();
    _phase = EchoNimoPhase.sessionFinished;

    final session = buildCompletedSession();
    ActivityPersistenceService.saveSession(session);
    notifyListeners();
  }

  ActivitySession buildCompletedSession() {
    final validReactionTimes = _attempts.map((a) => a.reactionTimeMs).toList();
    final avgReaction = validReactionTimes.isNotEmpty
        ? validReactionTimes.reduce((a, b) => a + b) / validReactionTimes.length
        : 0.0;
    final bestReaction = validReactionTimes.isNotEmpty
        ? validReactionTimes.reduce((a, b) => a < b ? a : b)
        : 0;

    final correctRounds = _attempts.where((a) => a.isCorrect).length;

    return ActivitySession(
      sessionId: sessionId,
      activityId: 'echo_nimo',
      childId: childId,
      startedAt: startedAt,
      completedAt: DateTime.now(),
      totalRounds: totalRounds,
      successfulRounds: correctRounds,
      missedRounds: totalRounds - correctRounds,
      incorrectTaps: 0,
      averageReactionTimeMs: avgReaction,
      bestReactionTimeMs: bestReaction,
      highestStreak: _highestStreak,
      difficultyReached: _currentLevel,
      totalXP: _currentXP,
      attempts: _attempts,
    );
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _reactionStopwatch.stop();
    super.dispose();
  }
}
