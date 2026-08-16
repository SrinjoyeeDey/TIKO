import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/activity_attempt.dart';
import '../../core/models/activity_session.dart';
import '../../core/services/activity_persistence_service.dart';
import '../../core/services/adaptive_learning_service.dart';
import '../config/find_nimo_difficulty.dart';
import '../models/grid_cell.dart';
import '../models/spatial_search.dart';

enum FindNimoPhase {
  previewing,
  hiding,
  searching,
  evaluatingStep,
  roundComplete,
  sessionFinished,
}

class FindNimoController extends ChangeNotifier {
  static const _uuid = Uuid();
  final math.Random _random = math.Random();

  final String sessionId = _uuid.v4();
  final String childId;
  final DateTime startedAt = DateTime.now();

  final AdaptiveLearningService adaptiveEngine;

  int _currentRound = 1;
  final int totalRounds = 8;
  int _currentLevel = 1;

  FindNimoPhase _phase = FindNimoPhase.previewing;
  int _currentSearchStepIndex = 0;

  // Grid Cell State
  List<GridCell> _cells = [];
  int _targetCellIndex = -1;

  // Search History for current round
  final Set<int> _usedTargetLocationsInRound = {};
  final Set<int> _tappedIncorrectInCurrentSearch = {};

  // Timers & Reaction measurement
  Timer? _previewTimer;
  final Stopwatch _searchStopwatch = Stopwatch();
  DateTime? _lastTapTime;

  // Stats & Error Metrics
  int _currentXP = 350;
  int _streak = 0;
  int _highestStreak = 0;
  int _withinSearchErrors = 0;
  int _betweenSearchErrors = 0;
  int _totalSuccessfulSearches = 0;
  int _totalSearches = 0;

  String? _feedbackHeadline;
  String? _feedbackDetail;

  final List<ActivityAttempt> _attempts = [];

  FindNimoController({
    required this.childId,
    this.adaptiveEngine = const AdaptiveLearningService(),
  });

  // Getters
  int get currentRound => _currentRound;
  int get currentLevel => _currentLevel;
  FindNimoDifficulty get currentConfig => FindNimoDifficulty.getForLevel(_currentLevel);
  FindNimoPhase get phase => _phase;
  int get currentSearchStepIndex => _currentSearchStepIndex;
  List<GridCell> get cells => List.unmodifiable(_cells);
  int get targetCellIndex => _targetCellIndex;
  int get currentXP => _currentXP;
  int get streak => _streak;
  int get highestStreak => _highestStreak;
  int get withinSearchErrors => _withinSearchErrors;
  int get betweenSearchErrors => _betweenSearchErrors;
  int get totalSuccessfulSearches => _totalSuccessfulSearches;
  int get totalSearches => _totalSearches;
  String? get feedbackHeadline => _feedbackHeadline;
  String? get feedbackDetail => _feedbackDetail;
  bool get isSessionFinished => _phase == FindNimoPhase.sessionFinished;

  /// Initializes grid cells and starts current round
  void startRound() {
    if (_currentRound > totalRounds) {
      _finishSession();
      return;
    }

    _previewTimer?.cancel();
    _searchStopwatch.reset();

    _usedTargetLocationsInRound.clear();
    _currentSearchStepIndex = 0;
    _startSearchStep();
  }

  /// Starts individual search step within round
  void _startSearchStep() {
    final config = currentConfig;
    final totalCells = config.totalCells;

    // Generate N x N Grid
    _cells = List.generate(totalCells, (index) {
      final row = index ~/ config.gridSize;
      final col = index % config.gridSize;
      return GridCell(row: row, col: col, index: index);
    });

    // Select random target cell avoiding previously used target locations in round if possible
    final availableIndices = List.generate(totalCells, (i) => i)
      ..removeWhere((i) => _usedTargetLocationsInRound.contains(i));

    if (availableIndices.isNotEmpty) {
      _targetCellIndex = availableIndices[_random.nextInt(availableIndices.length)];
    } else {
      _targetCellIndex = _random.nextInt(totalCells);
    }

    _tappedIncorrectInCurrentSearch.clear();

    // Set preview status on target cell
    _cells[_targetCellIndex] = _cells[_targetCellIndex].copyWith(status: GridCellStatus.previewTarget);
    _phase = FindNimoPhase.previewing;
    notifyListeners();

    // Start preview timer
    _previewTimer = Timer(config.previewDuration, () => _transitionToHidePhase());
  }

  /// Curtain / Grid pulse transition into Search phase
  void _transitionToHidePhase() {
    _phase = FindNimoPhase.hiding;
    _cells[_targetCellIndex] = _cells[_targetCellIndex].copyWith(status: GridCellStatus.normal);
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 350), () {
      _phase = FindNimoPhase.searching;
      _searchStopwatch.reset();
      _searchStopwatch.start();
      notifyListeners();
    });
  }

  /// Handles player tap on a grid cell
  void onCellTapped(int index) {
    if (_phase != FindNimoPhase.searching) return;

    // Rapid double-tap guard (150ms)
    final now = DateTime.now();
    if (_lastTapTime != null && now.difference(_lastTapTime!).inMilliseconds < 150) {
      return;
    }
    _lastTapTime = now;

    SystemSound.play(SystemSoundType.click);
    _totalSearches++;
    final reactionMs = _searchStopwatch.elapsedMilliseconds;

    if (index == _targetCellIndex) {
      // Correct target found!
      _searchStopwatch.stop();
      _phase = FindNimoPhase.evaluatingStep;
      _totalSuccessfulSearches++;
      _streak++;
      if (_streak > _highestStreak) _highestStreak = _streak;

      _usedTargetLocationsInRound.add(_targetCellIndex);
      _cells[index] = _cells[index].copyWith(status: GridCellStatus.foundCorrect);

      // XP Bonus
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

      // Check if more search steps remain in this round
      Future.delayed(const Duration(milliseconds: 900), () {
        _currentSearchStepIndex++;
        if (_currentSearchStepIndex < config.searchCountPerRound) {
          _startSearchStep();
        } else {
          _completeRound(isSuccess: true);
        }
      });
    } else {
      // Incorrect cell selected -> Classify spatial error
      SpatialErrorType errorType = SpatialErrorType.none;

      if (_tappedIncorrectInCurrentSearch.contains(index)) {
        errorType = SpatialErrorType.withinSearch;
        _withinSearchErrors++;
      } else if (_usedTargetLocationsInRound.contains(index)) {
        errorType = SpatialErrorType.betweenSearch;
        _betweenSearchErrors++;
      } else {
        _tappedIncorrectInCurrentSearch.add(index);
      }

      final status = (errorType == SpatialErrorType.betweenSearch)
          ? GridCellStatus.betweenError
          : GridCellStatus.withinError;

      _cells[index] = _cells[index].copyWith(status: status);
      _streak = 0;
      notifyListeners();
    }
  }

  void _completeRound({required bool isSuccess}) {
    _phase = FindNimoPhase.roundComplete;
    if (isSuccess) {
      _feedbackHeadline = 'Sharp spatial memory!';
      _feedbackDetail = 'You tracked NIMO across all search locations!';
    } else {
      _feedbackHeadline = 'Keep searching!';
      _feedbackDetail = 'Let\'s try another location chain.';
    }
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 1600), () {
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
    _previewTimer?.cancel();
    _searchStopwatch.stop();
    _phase = FindNimoPhase.sessionFinished;

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
      activityId: 'find_nimo',
      childId: childId,
      startedAt: startedAt,
      completedAt: DateTime.now(),
      totalRounds: totalRounds,
      successfulRounds: correctRounds,
      missedRounds: totalRounds - correctRounds,
      incorrectTaps: _withinSearchErrors + _betweenSearchErrors,
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
    _searchStopwatch.stop();
    super.dispose();
  }
}
