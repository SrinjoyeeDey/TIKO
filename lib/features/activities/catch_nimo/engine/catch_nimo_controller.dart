import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/activity_attempt.dart';
import '../../core/models/activity_session.dart';
import '../../core/services/activity_persistence_service.dart';
import '../../core/services/adaptive_learning_service.dart';
import '../config/catch_nimo_difficulty.dart';

/// Catch NIMO Game Controller inspired by research repository target mechanics.
class CatchNimoController extends ChangeNotifier {
  static const _uuid = Uuid();
  final math.Random _random = math.Random();

  final String sessionId = _uuid.v4();
  final String childId;
  final DateTime startedAt = DateTime.now();

  final AdaptiveLearningService adaptiveEngine;

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
  String? _adaptiveReason;

  // Stopwatch for millisecond precision reaction measurement
  final Stopwatch _reactionStopwatch = Stopwatch();
  DateTime? _spawnTime;

  // Timers
  Timer? _roundTimer;
  Timer? _movementTimer;

  // Attempt History for session analytics & adaptive evaluation
  final List<ActivityAttempt> _attempts = [];

  CatchNimoController({
    required this.childId,
    this.adaptiveEngine = const AdaptiveLearningService(),
  });

  // Getters
  int get currentRound => _currentRound;
  int get currentLevel => _currentLevel;
  CatchNimoDifficulty get currentConfig => CatchNimoDifficulty.getForLevel(_currentLevel);
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
  String? get adaptiveReason => _adaptiveReason;

  /// Spawns next target within safe screen boundaries avoiding top HUD & bottom bar.
  void startRound(Size screenSize) {
    if (_currentRound > totalRounds) {
      _finishSession();
      return;
    }

    _roundTimer?.cancel();
    _movementTimer?.cancel();
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

    // Initial position generation
    if (config.level == 1) {
      _nimoPosition = Offset((screenSize.width - targetSize) / 2, (screenSize.height - targetSize) / 2);
    } else {
      final newX = minX + _random.nextDouble() * (maxX - minX);
      final newY = minY + _random.nextDouble() * (maxY - minY);
      _nimoPosition = Offset(newX, newY);
    }

    // Spawn Distractor targets for Levels 3+
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

    // Start movement tick timer if Level >= 3
    if (config.isMoving) {
      _startMovementTrajectory(screenSize, minX, maxX, minY, maxY, config.speedMultiplier);
    }

    // Start Round Timeout Timer
    _roundTimer = Timer(config.timeout, () => _handleRoundTimeout(screenSize));

    notifyListeners();
  }

  /// Trajectory movement logic for Levels 3+
  void _startMovementTrajectory(Size screenSize, double minX, double maxX, double minY, double maxY, double speedMult) {
    double vx = (1.5 + _random.nextDouble() * 2.0) * (_random.nextBool() ? 1 : -1) * speedMult;
    double vy = (1.5 + _random.nextDouble() * 2.0) * (_random.nextBool() ? 1 : -1) * speedMult;

    _movementTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (_isCaught || _isEscaped || _isSessionFinished) {
        timer.cancel();
        return;
      }

      double nextX = _nimoPosition.dx + vx;
      double nextY = _nimoPosition.dy + vy;

      if (nextX < minX || nextX > maxX) {
        vx = -vx;
        nextX = nextX.clamp(minX, maxX);
      }
      if (nextY < minY || nextY > maxY) {
        vy = -vy;
        nextY = nextY.clamp(minY, maxY);
      }

      _nimoPosition = Offset(nextX, nextY);
      notifyListeners();
    });
  }

  /// Handles NIMO tap: calculates millisecond reaction time & updates adaptive difficulty.
  void onNimoTapped(Size screenSize) {
    if (_isCaught || _isEscaped || _isSessionFinished) return; // Edge-case: double tap guard

    _reactionStopwatch.stop();
    _roundTimer?.cancel();
    _movementTimer?.cancel();

    _isCaught = true;
    _catchCount++;
    _comboCount++;
    if (_comboCount > _highestCombo) _highestCombo = _comboCount;

    final reactionMs = _reactionStopwatch.elapsedMilliseconds;
    final tappedTime = DateTime.now();

    // XP Calculation
    final speedBonus = math.max(0, (1500 - reactionMs) ~/ 50);
    final comboBonus = _comboCount * 3;
    final earnedXP = (currentConfig.baseXP + speedBonus + comboBonus).toInt();
    _currentXP += earnedXP;

    // Record attempt
    _attempts.add(ActivityAttempt(
      attemptId: _uuid.v4(),
      sessionId: sessionId,
      roundNumber: _currentRound,
      timestamp: _spawnTime ?? tappedTime,
      responseTime: tappedTime,
      reactionTimeMs: reactionMs,
      isCorrect: true,
      isMissed: false,
      isIncorrectTarget: false,
      score: earnedXP,
      difficultyLevel: _currentLevel,
    ));

    _evaluateAdaptiveEngine();
    notifyListeners();

    // Advance to next round after short catch visual animation
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!_isSessionFinished) {
        _currentRound++;
        startRound(screenSize);
      }
    });
  }

  /// Handles Distractor target tap: records incorrect target & shows gentle feedback.
  void onDistractorTapped() {
    if (_isCaught || _isEscaped || _isSessionFinished) return;

    _incorrectTaps++;
    _comboCount = 0; // Gentle streak reset
    _statusNotification = 'Almost.';
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 900), () {
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
    _movementTimer?.cancel();
    _isEscaped = true;
    _missCount++;
    _comboCount = 0;
    _statusNotification = 'NIMO escaped!';

    _attempts.add(ActivityAttempt(
      attemptId: _uuid.v4(),
      sessionId: sessionId,
      roundNumber: _currentRound,
      timestamp: _spawnTime ?? DateTime.now(),
      responseTime: null,
      reactionTimeMs: currentConfig.timeout.inMilliseconds,
      isCorrect: false,
      isMissed: true,
      isIncorrectTarget: false,
      score: 0,
      difficultyLevel: _currentLevel,
    ));

    _evaluateAdaptiveEngine();
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!_isSessionFinished) {
        _currentRound++;
        startRound(screenSize);
      }
    });
  }

  /// Evaluates recent attempt history using AdaptiveLearningService.
  void _evaluateAdaptiveEngine() {
    final decision = adaptiveEngine.evaluatePerformance(
      attempts: _attempts,
      currentDifficulty: _currentLevel,
    );

    if (decision.levelChanged) {
      _currentLevel = decision.nextDifficulty;
      _adaptiveReason = decision.reason;
      debugPrint('AdaptiveEngine Decision: Level changed to $_currentLevel. Reason: ${decision.reason}');
    }
  }

  /// Concludes session and builds ActivitySession record.
  void _finishSession() {
    _roundTimer?.cancel();
    _movementTimer?.cancel();
    _reactionStopwatch.stop();
    _isSessionFinished = true;

    final session = buildCompletedSession();
    ActivityPersistenceService.saveSession(session);
    notifyListeners();
  }

  /// Constructs completed ActivitySession metric record.
  ActivitySession buildCompletedSession() {
    final validReactionTimes = _attempts.where((a) => a.isCorrect).map((a) => a.reactionTimeMs).toList();
    final avgReaction = validReactionTimes.isNotEmpty
        ? validReactionTimes.reduce((a, b) => a + b) / validReactionTimes.length
        : 0.0;
    final bestReaction = validReactionTimes.isNotEmpty
        ? validReactionTimes.reduce(math.min)
        : 0;

    return ActivitySession(
      sessionId: sessionId,
      activityId: 'catch_nimo',
      childId: childId,
      startedAt: startedAt,
      completedAt: DateTime.now(),
      totalRounds: totalRounds,
      successfulRounds: _catchCount,
      missedRounds: _missCount,
      incorrectTaps: _incorrectTaps,
      averageReactionTimeMs: avgReaction,
      bestReactionTimeMs: bestReaction,
      highestStreak: _highestCombo,
      difficultyReached: _currentLevel,
      totalXP: _currentXP,
      attempts: _attempts,
    );
  }

  @override
  void dispose() {
    _roundTimer?.cancel();
    _movementTimer?.cancel();
    _reactionStopwatch.stop();
    super.dispose();
  }
}
