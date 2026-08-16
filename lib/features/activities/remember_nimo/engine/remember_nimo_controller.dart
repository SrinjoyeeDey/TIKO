import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/activity_attempt.dart';
import '../../core/models/activity_session.dart';
import '../../core/services/activity_persistence_service.dart';
import '../../core/services/adaptive_learning_service.dart';
import '../config/remember_nimo_difficulty.dart';
import '../models/memory_challenge.dart';
import '../models/memory_feature.dart';

enum RememberNimoPhase {
  previewing,
  hiding,
  reconstructing,
  evaluating,
  roundComplete,
  sessionFinished,
}

class RememberNimoController extends ChangeNotifier {
  static const _uuid = Uuid();

  final String sessionId = _uuid.v4();
  final String childId;
  final DateTime startedAt = DateTime.now();

  final AdaptiveLearningService adaptiveEngine;

  int _currentRound = 1;
  final int totalRounds = 8;
  int _currentLevel = 1;

  RememberNimoPhase _phase = RememberNimoPhase.previewing;
  MemoryChallenge? _currentChallenge;

  // Selected features during reconstruction phase
  final Map<FeatureCategory, MemoryFeatureOption> _playerSelections = {};

  // Timers & Reaction measurement
  Timer? _previewTimer;
  Timer? _countdownTicker;
  int _previewRemainingMs = 4000;
  final Stopwatch _reconstructionStopwatch = Stopwatch();

  // Metrics & Stats
  int _currentXP = 300;
  int _streak = 0;
  int _highestStreak = 0;

  // Evaluation details for completed round
  int _lastRoundCorrectCount = 0;
  int _lastRoundTotalCount = 0;
  double _lastRoundAccuracy = 0.0;
  String? _feedbackHeadline;
  String? _feedbackDetail;

  final List<ActivityAttempt> _attempts = [];

  RememberNimoController({
    required this.childId,
    this.adaptiveEngine = const AdaptiveLearningService(),
  });

  // Getters
  int get currentRound => _currentRound;
  int get currentLevel => _currentLevel;
  RememberNimoDifficulty get currentConfig => RememberNimoDifficulty.getForLevel(_currentLevel);
  RememberNimoPhase get phase => _phase;
  MemoryChallenge? get currentChallenge => _currentChallenge;
  Map<FeatureCategory, MemoryFeatureOption> get playerSelections => Map.unmodifiable(_playerSelections);
  int get previewRemainingMs => _previewRemainingMs;
  int get currentXP => _currentXP;
  int get streak => _streak;
  int get highestStreak => _highestStreak;
  int get lastRoundCorrectCount => _lastRoundCorrectCount;
  int get lastRoundTotalCount => _lastRoundTotalCount;
  double get lastRoundAccuracy => _lastRoundAccuracy;
  String? get feedbackHeadline => _feedbackHeadline;
  String? get feedbackDetail => _feedbackDetail;
  bool get isSessionFinished => _phase == RememberNimoPhase.sessionFinished;

  /// Starts or advances to next round
  void startRound() {
    if (_currentRound > totalRounds) {
      _finishSession();
      return;
    }

    _previewTimer?.cancel();
    _countdownTicker?.cancel();
    _reconstructionStopwatch.reset();

    final config = currentConfig;
    _currentChallenge = MemoryChallenge.generate(
      activeCategories: config.activeCategories,
      optionCount: config.optionsPerCategory,
    );

    _playerSelections.clear();
    _phase = RememberNimoPhase.previewing;
    _previewRemainingMs = config.previewDuration.inMilliseconds;

    // Start 100ms countdown ticker for smooth UI timer bar
    _countdownTicker = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _previewRemainingMs = (config.previewDuration.inMilliseconds - timer.tick * 100).clamp(0, config.previewDuration.inMilliseconds);
      notifyListeners();
    });

    // Start transition to HIDE phase when preview timer expires
    _previewTimer = Timer(config.previewDuration, () {
      _countdownTicker?.cancel();
      _transitionToHidePhase();
    });

    notifyListeners();
  }

  /// Curtain / Morph Transition into Reconstruction phase
  void _transitionToHidePhase() {
    _phase = RememberNimoPhase.hiding;
    notifyListeners();

    // 400ms curtain transition duration
    Timer(const Duration(milliseconds: 400), () {
      _phase = RememberNimoPhase.reconstructing;
      _reconstructionStopwatch.reset();
      _reconstructionStopwatch.start();
      notifyListeners();
    });
  }

  /// Selects a feature option for a category
  void selectOption(FeatureCategory category, MemoryFeatureOption option) {
    if (_phase != RememberNimoPhase.reconstructing) return;
    _playerSelections[category] = option;
    notifyListeners();
  }

  /// Evaluates submitted reconstruction
  void submitReconstruction() {
    if (_phase != RememberNimoPhase.reconstructing) return;
    if (_currentChallenge == null) return;

    _reconstructionStopwatch.stop();
    _phase = RememberNimoPhase.evaluating;

    final targetMap = _currentChallenge!.targetFeatures;
    int correct = 0;
    final total = targetMap.length;

    targetMap.forEach((category, targetOption) {
      final selected = _playerSelections[category];
      if (selected != null && selected.id == targetOption.id) {
        correct++;
      }
    });

    _lastRoundCorrectCount = correct;
    _lastRoundTotalCount = total;
    _lastRoundAccuracy = total > 0 ? (correct / total) : 0.0;
    final isFullMatch = correct == total;

    if (isFullMatch) {
      _streak++;
      if (_streak > _highestStreak) _highestStreak = _streak;
      _feedbackHeadline = 'Nice memory!';
      _feedbackDetail = 'You recalled all $total features perfectly!';
    } else if (correct > 0) {
      _streak = 0;
      _feedbackHeadline = 'Good effort!';
      _feedbackDetail = 'You got $correct out of $total features right.';
    } else {
      _streak = 0;
      _feedbackHeadline = 'Almost!';
      _feedbackDetail = 'Let\'s try another one.';
    }

    // Calculate XP
    final config = currentConfig;
    final reactionMs = _reconstructionStopwatch.elapsedMilliseconds;
    final baseScore = (config.baseXP * _lastRoundAccuracy).toInt();
    final streakBonus = _streak * 4;
    final earnedXP = baseScore + streakBonus;
    _currentXP += earnedXP;

    // Record attempt
    _attempts.add(ActivityAttempt(
      attemptId: _uuid.v4(),
      sessionId: sessionId,
      roundNumber: _currentRound,
      timestamp: DateTime.now(),
      responseTime: DateTime.now(),
      reactionTimeMs: reactionMs,
      isCorrect: isFullMatch,
      isMissed: false,
      isIncorrectTarget: !isFullMatch,
      score: earnedXP,
      difficultyLevel: _currentLevel,
    ));

    _evaluateAdaptiveEngine();
    _phase = RememberNimoPhase.roundComplete;
    notifyListeners();

    // Auto-advance to next round after 1.8s feedback display
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (_phase == RememberNimoPhase.roundComplete) {
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
    _previewTimer?.cancel();
    _countdownTicker?.cancel();
    _reconstructionStopwatch.stop();
    _phase = RememberNimoPhase.sessionFinished;

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
      activityId: 'remember_nimo',
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
    _previewTimer?.cancel();
    _countdownTicker?.cancel();
    _reconstructionStopwatch.stop();
    super.dispose();
  }
}
