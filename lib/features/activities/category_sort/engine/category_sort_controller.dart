import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/activity_attempt.dart';
import '../../core/models/activity_session.dart';
import '../../core/services/activity_persistence_service.dart';
import '../../core/services/adaptive_learning_service.dart';
import '../config/category_sort_difficulty.dart';
import '../models/category_item.dart';
import '../models/semantic_category.dart';

enum CategorySortPhase {
  presenting,
  interacting,
  evaluating,
  roundComplete,
  sessionFinished,
}

class CategorySortController extends ChangeNotifier {
  static const _uuid = Uuid();
  final math.Random _random = math.Random();

  final String sessionId = _uuid.v4();
  final String childId;
  final DateTime startedAt = DateTime.now();

  final AdaptiveLearningService adaptiveEngine;

  int _currentRound = 1;
  final int totalRounds = 8;
  int _currentLevel = 1;

  CategorySortPhase _phase = CategorySortPhase.presenting;

  // Active round state
  CategoryItem? _currentItem;
  List<SemanticCategory> _activeCategories = [];
  String? _tappedCategoryKey;
  bool? _isCurrentTapCorrect;

  // Reaction stopwatch & tap debiasing
  final Stopwatch _roundStopwatch = Stopwatch();
  DateTime? _lastTapTime;

  // Stats & Metrics
  int _currentXP = 300;
  int _score = 0;
  int _streak = 0;
  int _highestStreak = 0;

  String? _feedbackHeadline;
  String? _feedbackDetail;

  final List<ActivityAttempt> _attempts = [];

  CategorySortController({
    required this.childId,
    this.adaptiveEngine = const AdaptiveLearningService(),
  });

  // Getters
  int get currentRound => _currentRound;
  int get currentLevel => _currentLevel;
  CategorySortDifficulty get currentConfig => CategorySortDifficulty.getForLevel(_currentLevel);
  CategorySortPhase get phase => _phase;
  CategoryItem? get currentItem => _currentItem;
  List<SemanticCategory> get activeCategories => List.unmodifiable(_activeCategories);
  String? get tappedCategoryKey => _tappedCategoryKey;
  bool? get isCurrentTapCorrect => _isCurrentTapCorrect;
  int get currentXP => _currentXP;
  int get score => _score;
  int get streak => _streak;
  int get highestStreak => _highestStreak;
  String? get feedbackHeadline => _feedbackHeadline;
  String? get feedbackDetail => _feedbackDetail;
  bool get isSessionFinished => _phase == CategorySortPhase.sessionFinished;

  /// Starts the round
  void startRound() {
    if (_currentRound > totalRounds) {
      _finishSession();
      return;
    }

    _roundStopwatch.reset();
    _tappedCategoryKey = null;
    _isCurrentTapCorrect = null;

    final config = currentConfig;
    final allCats = List<SemanticCategory>.from(SemanticCategory.allCategories)..shuffle(_random);
    _activeCategories = allCats.take(config.activeCategoryCount).toList();

    // Select random item belonging to one of the active categories
    final validItems = CategoryItem.defaultPool
        .where((item) => _activeCategories.any((cat) => cat.key == item.categoryKey))
        .toList();

    _currentItem = validItems[_random.nextInt(validItems.length)];
    _phase = CategorySortPhase.presenting;
    notifyListeners();

    Future.delayed(config.itemDisplayDelay, () {
      _phase = CategorySortPhase.interacting;
      _roundStopwatch.start();
      notifyListeners();
    });
  }

  /// Handles player tapping a category card
  void onCategoryTapped(SemanticCategory category) {
    if (_phase != CategorySortPhase.interacting) return;

    // Rapid double-tap guard (150ms)
    final now = DateTime.now();
    if (_lastTapTime != null && now.difference(_lastTapTime!).inMilliseconds < 150) {
      return;
    }
    _lastTapTime = now;

    SystemSound.play(SystemSoundType.click);
    _roundStopwatch.stop();
    final reactionMs = _roundStopwatch.elapsedMilliseconds;

    _tappedCategoryKey = category.key;
    final isCorrect = category.key == _currentItem?.categoryKey;
    _isCurrentTapCorrect = isCorrect;
    _phase = CategorySortPhase.evaluating;

    if (isCorrect) {
      _score++;
      _streak++;
      if (_streak > _highestStreak) _highestStreak = _streak;

      final config = currentConfig;
      final earnedXP = (config.baseXP + (_streak * 3)).toInt();
      _currentXP += earnedXP;

      _attempts.add(ActivityAttempt(
        attemptId: _uuid.v4(),
        sessionId: sessionId,
        roundNumber: _currentRound,
        timestamp: DateTime.now(),
        responseTime: DateTime.now(),
        reactionTimeMs: reactionMs,
        isCorrect: true,
        isMissed: false,
        isIncorrectTarget: false,
        score: earnedXP,
        difficultyLevel: _currentLevel,
      ));

      _evaluateAdaptiveEngine();
      notifyListeners();

      Future.delayed(const Duration(milliseconds: 1200), () {
        _completeRound(isSuccess: true);
      });
    } else {
      _streak = 0;
      _attempts.add(ActivityAttempt(
        attemptId: _uuid.v4(),
        sessionId: sessionId,
        roundNumber: _currentRound,
        timestamp: DateTime.now(),
        responseTime: DateTime.now(),
        reactionTimeMs: reactionMs,
        isCorrect: false,
        isMissed: false,
        isIncorrectTarget: true,
        score: 0,
        difficultyLevel: _currentLevel,
      ));

      notifyListeners();

      Future.delayed(const Duration(milliseconds: 800), () {
        _tappedCategoryKey = null;
        _isCurrentTapCorrect = null;
        _phase = CategorySortPhase.interacting;
        _roundStopwatch.start();
        notifyListeners();
      });
    }
  }

  void _completeRound({required bool isSuccess}) {
    _phase = CategorySortPhase.roundComplete;
    if (isSuccess) {
      _feedbackHeadline = 'Great sorting!';
      _feedbackDetail = '${_currentItem?.displayName} belongs to ${_currentItem?.categoryKey}!';
    }
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 1400), () {
      _currentRound++;
      startRound();
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
    _roundStopwatch.stop();
    _phase = CategorySortPhase.sessionFinished;

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
      activityId: 'category_sort',
      childId: childId,
      startedAt: startedAt,
      completedAt: DateTime.now(),
      totalRounds: totalRounds,
      successfulRounds: correctRounds,
      missedRounds: totalRounds - correctRounds,
      incorrectTaps: _attempts.where((a) => !a.isCorrect).length,
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
    _roundStopwatch.stop();
    super.dispose();
  }
}
