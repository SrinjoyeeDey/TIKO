import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../config/difficulty_config.dart';
import '../models/activity_attempt.dart';
import '../models/activity_session.dart';
import '../services/activity_analytics_service.dart';

/// Controller handling 12-round game loop, adaptive difficulty (Levels 1-6),
/// stopwatch reaction timing, distractors, and analytics logging.
class CatchNimoController extends ChangeNotifier {
  static const _uuid = Uuid();
  final math.Random _random = math.Random();

  final String sessionId = _uuid.v4();
  final DateTime startedAt = DateTime.now();

  int _currentRound = 1;
  final int totalRounds = 12;
  int _currentLevel = 1;

  Offset _nimoPosition = const Offset(150, 300);
  final List<Offset> _distractorPositions = [];

  int _currentXP = 240;
  int _comboCount = 0;
  int _highestCombo = 0;
  int _catchCount = 0;
  int _missCount = 0;
  int _incorrectTaps = 0;

  bool _isCaught = false;
  bool _isEscaped = false;
  bool _isSessionFinished = false;

  String? _statusNotification;

  // Stopwatch for millisecond precision reaction time
  final Stopwatch _reactionStopwatch = Stopwatch();
  DateTime? _spawnTime;

  // Round Timeout Timer
  Timer? _roundTimer;

  // Recorded attempts for therapist analytics
  final List<ActivityAttempt> _attempts = [];

  // Getters
  int get currentRound => _currentRound;
  int get currentLevel => _currentLevel;
  DifficultyConfig get currentConfig => DifficultyConfig.getForLevel(_currentLevel);
  Offset get nimoPosition => _nimoPosition;
  List<Offset> get distractorPositions => _distractorPositions;
  int get currentXP => _currentXP;
  int get comboCount => _comboCount;
  int get highestCombo => _highestCombo;
  int get catchCount => _catchCount;
  int get missCount => _missCount;
  bool get isCaught => _isCaught;
  bool get isEscaped => _isEscaped;
  bool get isSessionFinished => _isSessionFinished;
  String? get statusNotification => _statusNotification;

  /// Spawns next round target and distractors within safe boundaries.
  void startRound(Size screenSize) {
    if (_currentRound > totalRounds) {
      _finishSession();
      return;
    }

    _roundTimer?.cancel();
    _isCaught = false;
    _isEscaped = false;
    _statusNotification = null;

    final config = currentConfig;
    final targetSize = config.targetSize;

    final topPadding = 110.0;
    final bottomPadding = 80.0;
    final sidePadding = 30.0;

    final minX = sidePadding;
    final maxX = math.max(minX, screenSize.width - targetSize - sidePadding);
    final minY = topPadding;
    final maxY = math.max(minY, screenSize.height - targetSize - bottomPadding);

    // Dynamic position logic
    if (config.level == 1) {
      // Level 1: Fixed center position
      _nimoPosition = Offset((screenSize.width - targetSize) / 2, (screenSize.height - targetSize) / 2);
    } else {
      // Level 2+: Random safe position
      final newX = minX + _random.nextDouble() * (maxX - minX);
      final newY = minY + _random.nextDouble() * (maxY - minY);
      _nimoPosition = Offset(newX, newY);
    }

    // Spawn Distractors if specified in config (Levels 5 & 6)
    _distractorPositions.clear();
    for (int i = 0; i < config.distractorsCount; i++) {
      double dx, dy;
      do {
        dx = minX + _random.nextDouble() * (maxX - minX);
        dy = minY + _random.nextDouble() * (maxY - minY);
      } while ((Offset(dx, dy) - _nimoPosition).distance < 110.0);
      _distractorPositions.add(Offset(dx, dy));
    }

    _spawnTime = DateTime.now();
    _reactionStopwatch.reset();
    _reactionStopwatch.start();

    // Start Round Timeout Timer
    _roundTimer = Timer(config.timeout, () => _handleRoundTimeout(screenSize));

    notifyListeners();
  }

  /// Handles NIMO tap: calculates reaction time, awards XP, adaptively evaluates difficulty.
  void onNimoTapped(Size screenSize) {
    if (_isCaught || _isEscaped || _isSessionFinished) return;

    _reactionStopwatch.stop();
    _roundTimer?.cancel();

    _isCaught = true;
    _catchCount++;
    _comboCount++;
    if (_comboCount > _highestCombo) _highestCombo = _comboCount;

    final reactionMs = _reactionStopwatch.elapsedMilliseconds;
    final tappedTime = DateTime.now();

    // Calculate XP reward
    final speedBonus = math.max(0, (1500 - reactionMs) ~/ 50);
    final comboBonus = _comboCount * 3;
    final earnedXP = (currentConfig.baseXP + speedBonus + comboBonus).toInt();
    _currentXP += earnedXP;

    // Log attempt silently
    _attempts.add(ActivityAttempt(
      attemptId: _uuid.v4(),
      sessionId: sessionId,
      roundNumber: _currentRound,
      targetSpawnTime: _spawnTime ?? tappedTime,
      targetTappedTime: tappedTime,
      reactionTimeMs: reactionMs,
      correct: true,
      missed: false,
      incorrectTarget: false,
      difficultyLevel: _currentLevel,
    ));

    _evaluateAdaptiveDifficulty();
    notifyListeners();

    // Advance to next round after short feedback delay
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!_isSessionFinished) {
        _currentRound++;
        startRound(screenSize);
      }
    });
  }

  /// Handles Distractor tap: logs incorrect target, shows gentle "Almost." notification.
  void onDistractorTapped() {
    if (_isCaught || _isEscaped || _isSessionFinished) return;

    _incorrectTaps++;
    _comboCount = 0; // Gentle streak reset
    _statusNotification = 'Almost.';
    notifyListeners();

    // Clear notification after 1 second
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (_statusNotification == 'Almost.') {
        _statusNotification = null;
        notifyListeners();
      }
    });
  }

  /// Handles round timeout: NIMO escapes, streak resets softly.
  void _handleRoundTimeout(Size screenSize) {
    if (_isCaught || _isEscaped || _isSessionFinished) return;

    _reactionStopwatch.stop();
    _isEscaped = true;
    _missCount++;
    _comboCount = 0; // Soft streak reset
    _statusNotification = 'NIMO escaped!';

    _attempts.add(ActivityAttempt(
      attemptId: _uuid.v4(),
      sessionId: sessionId,
      roundNumber: _currentRound,
      targetSpawnTime: _spawnTime ?? DateTime.now(),
      targetTappedTime: null,
      reactionTimeMs: currentConfig.timeout.inMilliseconds,
      correct: false,
      missed: true,
      incorrectTarget: false,
      difficultyLevel: _currentLevel,
    ));

    _evaluateAdaptiveDifficulty();
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!_isSessionFinished) {
        _currentRound++;
        startRound(screenSize);
      }
    });
  }

  /// Evaluates recent sliding window of 3 attempts to adjust difficulty adaptively.
  void _evaluateAdaptiveDifficulty() {
    if (_attempts.length < 3) return;

    final recent = _attempts.sublist(_attempts.length - 3);
    final correctCount = recent.where((a) => a.correct).length;
    final avgReaction = recent.fold(0, (sum, a) => sum + a.reactionTimeMs) / recent.length;

    if (correctCount == 3 && avgReaction < 1200) {
      if (_currentLevel < 6) {
        _currentLevel++;
        debugPrint('AdaptiveDifficulty: Promoted to Level $_currentLevel');
      }
    } else if (correctCount <= 1) {
      if (_currentLevel > 1) {
        _currentLevel--;
        debugPrint('AdaptiveDifficulty: Demoted to Level $_currentLevel');
      }
    }
  }

  /// Concludes the session and builds ActivitySession metrics.
  void _finishSession() {
    _roundTimer?.cancel();
    _reactionStopwatch.stop();
    _isSessionFinished = true;

    final validReactionTimes = _attempts.where((a) => a.correct).map((a) => a.reactionTimeMs).toList();
    final avgReaction = validReactionTimes.isNotEmpty
        ? validReactionTimes.reduce((a, b) => a + b) / validReactionTimes.length
        : 0.0;
    final bestReaction = validReactionTimes.isNotEmpty
        ? validReactionTimes.reduce(math.min)
        : 0;

    final session = ActivitySession(
      sessionId: sessionId,
      activityId: 'catch_nimo',
      startedAt: startedAt,
      completedAt: DateTime.now(),
      totalRounds: totalRounds,
      successfulRounds: _catchCount,
      missedRounds: _missCount,
      incorrectTaps: _incorrectTaps,
      averageReactionTimeMs: avgReaction,
      bestReactionTimeMs: bestReaction,
      highestCombo: _highestCombo,
      difficultyReached: _currentLevel,
      totalXP: _currentXP,
      attempts: _attempts,
    );

    ActivityAnalyticsService.logSession(session);
    notifyListeners();
  }

  /// Generates completed session summary object for result screen.
  ActivitySession buildCompletedSession() {
    final validReactionTimes = _attempts.where((a) => a.correct).map((a) => a.reactionTimeMs).toList();
    final avgReaction = validReactionTimes.isNotEmpty
        ? validReactionTimes.reduce((a, b) => a + b) / validReactionTimes.length
        : 0.0;
    final bestReaction = validReactionTimes.isNotEmpty
        ? validReactionTimes.reduce(math.min)
        : 0;

    return ActivitySession(
      sessionId: sessionId,
      activityId: 'catch_nimo',
      startedAt: startedAt,
      completedAt: DateTime.now(),
      totalRounds: totalRounds,
      successfulRounds: _catchCount,
      missedRounds: _missCount,
      incorrectTaps: _incorrectTaps,
      averageReactionTimeMs: avgReaction,
      bestReactionTimeMs: bestReaction,
      highestCombo: _highestCombo,
      difficultyReached: _currentLevel,
      totalXP: _currentXP,
      attempts: _attempts,
    );
  }

  @override
  void dispose() {
    _roundTimer?.cancel();
    _reactionStopwatch.stop();
    super.dispose();
  }
}
