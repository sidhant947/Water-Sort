import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:watersort/data/repositories/progress_repository.dart';
import 'package:watersort/domain/models/game_level.dart';
import 'package:watersort/domain/models/tube.dart';
import 'package:watersort/domain/use_cases/level_generator.dart';
import 'package:watersort/domain/use_cases/level_solver.dart';

@immutable
class MoveSnapshot {
  const MoveSnapshot({required this.tubes, required this.moveCount});
  final List<Tube> tubes;
  final int moveCount;
}

@immutable
class GameViewModelState {
  const GameViewModelState({
    this.level,
    this.isLoading = false,
    this.isComplete = false,
    this.selectedTubeIndex,
    this.pouringFromIndex,
    this.pouringToIndex,
    this.moveCount = 0,
    this.error,
    this.isRandomMode = false,
    this.randomDifficulty,
    this.randomSeed,
    this.randomColorCount,
    this.randomCapacity,
    this.moveHistory = const [],
    this.timeLeft,
    this.isTimeOut = false,
    this.isProgressSaved = false,
    this.isSuperHardModeEnabled = false,
    this.isBlurSolvedTubesEnabled = false,
    this.isInstantPouringEnabled = false,
    this.isHintHelperEnabled = false,
    this.isSoundEffectsEnabled = true,
    this.hintFromIndex,
    this.hintToIndex,
    this.hintsRemaining = 0,
  });

  static const int hintsPerLevel = 3;
  static const int hintsUnlockLevel = 10;

  final GameLevel? level;
  final bool isLoading;
  final bool isComplete;
  final int? selectedTubeIndex;
  final int? pouringFromIndex;
  final int? pouringToIndex;
  final int moveCount;
  final String? error;
  final bool isRandomMode;
  final String? randomDifficulty;
  final int? randomSeed;
  final int? randomColorCount;
  final int? randomCapacity;
  final List<MoveSnapshot> moveHistory;
  final int? timeLeft;
  final bool isTimeOut;
  final bool isProgressSaved;
  final bool isSuperHardModeEnabled;
  final bool isBlurSolvedTubesEnabled;
  final bool isInstantPouringEnabled;
  final bool isHintHelperEnabled;
  final bool isSoundEffectsEnabled;
  final int? hintFromIndex;
  final int? hintToIndex;
  final int hintsRemaining;

  bool get canUndo => moveHistory.isNotEmpty && !isComplete && !isTimeOut;

  /// Tips button: campaign from level 10, or any random run. Independent of settings toggle.
  bool get showHintButton {
    if (isComplete || isTimeOut || level == null) return false;
    if (isRandomMode) return true;
    return level!.levelNumber >= hintsUnlockLevel;
  }

  GameViewModelState copyWith({
    GameLevel? level,
    bool? isLoading,
    bool? isComplete,
    int? Function()? selectedTubeIndex,
    int? Function()? pouringFromIndex,
    int? Function()? pouringToIndex,
    int? moveCount,
    String? error,
    bool? isRandomMode,
    String? randomDifficulty,
    int? randomSeed,
    int? randomColorCount,
    int? randomCapacity,
    List<MoveSnapshot>? moveHistory,
    int? Function()? timeLeft,
    bool? isTimeOut,
    bool? isProgressSaved,
    bool? isSuperHardModeEnabled,
    bool? isBlurSolvedTubesEnabled,
    bool? isInstantPouringEnabled,
    bool? isHintHelperEnabled,
    bool? isSoundEffectsEnabled,
    int? Function()? hintFromIndex,
    int? Function()? hintToIndex,
    int? hintsRemaining,
  }) {
    return GameViewModelState(
      level: level ?? this.level,
      isLoading: isLoading ?? this.isLoading,
      isComplete: isComplete ?? this.isComplete,
      selectedTubeIndex:
          selectedTubeIndex != null ? selectedTubeIndex() : this.selectedTubeIndex,
      pouringFromIndex:
          pouringFromIndex != null ? pouringFromIndex() : this.pouringFromIndex,
      pouringToIndex:
          pouringToIndex != null ? pouringToIndex() : this.pouringToIndex,
      moveCount: moveCount ?? this.moveCount,
      error: error,
      isRandomMode: isRandomMode ?? this.isRandomMode,
      randomDifficulty: randomDifficulty ?? this.randomDifficulty,
      randomSeed: randomSeed ?? this.randomSeed,
      randomColorCount: randomColorCount ?? this.randomColorCount,
      randomCapacity: randomCapacity ?? this.randomCapacity,
      moveHistory: moveHistory ?? this.moveHistory,
      timeLeft: timeLeft != null ? timeLeft() : this.timeLeft,
      isTimeOut: isTimeOut ?? this.isTimeOut,
      isProgressSaved: isProgressSaved ?? this.isProgressSaved,
      isSuperHardModeEnabled: isSuperHardModeEnabled ?? this.isSuperHardModeEnabled,
      isBlurSolvedTubesEnabled: isBlurSolvedTubesEnabled ?? this.isBlurSolvedTubesEnabled,
      isInstantPouringEnabled: isInstantPouringEnabled ?? this.isInstantPouringEnabled,
      isHintHelperEnabled: isHintHelperEnabled ?? this.isHintHelperEnabled,
      isSoundEffectsEnabled: isSoundEffectsEnabled ?? this.isSoundEffectsEnabled,
      hintFromIndex:
          hintFromIndex != null ? hintFromIndex() : this.hintFromIndex,
      hintToIndex:
          hintToIndex != null ? hintToIndex() : this.hintToIndex,
      hintsRemaining: hintsRemaining ?? this.hintsRemaining,
    );
  }
}

class GameViewModel extends StateNotifier<GameViewModelState> {
  GameViewModel({
    required this._progressRepository,
    required this._levelGenerator,
  }) : super(const GameViewModelState());

  final ProgressRepository _progressRepository;
  final LevelGenerator _levelGenerator;

  Timer? _timer;

  int _initialHintsFor({required bool isRandom, required int levelNumber}) {
    if (isRandom) return GameViewModelState.hintsPerLevel;
    if (levelNumber >= GameViewModelState.hintsUnlockLevel) {
      return GameViewModelState.hintsPerLevel;
    }
    return 0;
  }

  bool _shouldHaveTimer({required bool isRandom, required int levelNumber, required String difficulty}) {
    if (!_progressRepository.isTimerEnabled()) {
      return false;
    }
    if (isRandom) {
      return difficulty != 'Easy';
    } else {
      return levelNumber >= 4;
    }
  }

  int _calculateTimerDuration(int colorCount) {
    return ((30 + (colorCount * 15)) * 1.5).round();
  }

  void _startTimer(int seconds) {
    _timer?.cancel();
    state = state.copyWith(timeLeft: () => seconds, isTimeOut: false);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.timeLeft == null || state.timeLeft! <= 0) {
        timer.cancel();
        return;
      }
      final newTime = state.timeLeft! - 1;
      if (newTime == 0) {
        timer.cancel();
        state = state.copyWith(
          timeLeft: () => 0,
          isTimeOut: true,
        );
        HapticFeedback.heavyImpact();
      } else {
        state = state.copyWith(timeLeft: () => newTime);
      }
    });
  }

  Future<void> loadLevel(int levelNumber) async {
    _timer?.cancel();
    state = const GameViewModelState(isLoading: true);

    try {
      final savedMap = _progressRepository.getSavedLevelState();
      if (savedMap != null &&
          savedMap['levelNumber'] == levelNumber &&
          savedMap['isRandomMode'] == false) {
        final savedTubes = (savedMap['tubes'] as List).map((t) {
          final tMap = Map<dynamic, dynamic>.from(t as Map);
          return Tube(
            colors: (tMap['colors'] as List).map((c) => Color(c as int)).toList(),
            capacity: tMap['capacity'] as int,
          );
        }).toList();

        final savedHistory = (savedMap['moveHistory'] as List).map((h) {
          final hMap = Map<dynamic, dynamic>.from(h as Map);
          final tubes = (hMap['tubes'] as List).map((t) {
            final tMap = Map<dynamic, dynamic>.from(t as Map);
            return Tube(
              colors: (tMap['colors'] as List).map((c) => Color(c as int)).toList(),
              capacity: tMap['capacity'] as int,
            );
          }).toList();
          return MoveSnapshot(
            tubes: tubes,
            moveCount: hMap['moveCount'] as int,
          );
        }).toList();

        final level = GameLevel(
          levelNumber: levelNumber,
          tubes: savedTubes,
          optimalMoves: savedMap['optimalMoves'] as int,
        );

        final isSuperHard = _progressRepository.isSuperHardModeEnabled();
        final isBlurSolved = _progressRepository.isBlurSolvedTubesEnabled();
        final isInstantPouring = _progressRepository.isInstantPouringEnabled();
        final isHintHelper = _progressRepository.isHintHelperEnabled();
        final isSoundEffects = _progressRepository.isSoundEffectsEnabled();
        final defaultHints = _initialHintsFor(isRandom: false, levelNumber: levelNumber);
        final savedHints = savedMap['hintsRemaining'] as int?;

        state = GameViewModelState(
          level: level,
          moveCount: savedMap['moveCount'] as int,
          moveHistory: savedHistory,
          isSuperHardModeEnabled: isSuperHard,
          isBlurSolvedTubesEnabled: isBlurSolved,
          isInstantPouringEnabled: isInstantPouring,
          isHintHelperEnabled: isHintHelper,
          isSoundEffectsEnabled: isSoundEffects,
          hintsRemaining: savedHints ?? defaultHints,
        );

        if (savedMap['timeLeft'] != null) {
          _startTimer(savedMap['timeLeft'] as int);
        }
        return;
      }

      final level = _levelGenerator.generate(levelNumber);
      final isSuperHard = _progressRepository.isSuperHardModeEnabled();
      final isBlurSolved = _progressRepository.isBlurSolvedTubesEnabled();
      final isInstantPouring = _progressRepository.isInstantPouringEnabled();
      final isHintHelper = _progressRepository.isHintHelperEnabled();
      final isSoundEffects = _progressRepository.isSoundEffectsEnabled();
      debugPrint('LOAD LEVEL: isSuperHard = $isSuperHard');
      state = GameViewModelState(
        level: level,
        isSuperHardModeEnabled: isSuperHard,
        isBlurSolvedTubesEnabled: isBlurSolved,
        isInstantPouringEnabled: isInstantPouring,
        isHintHelperEnabled: isHintHelper,
        isSoundEffectsEnabled: isSoundEffects,
        hintsRemaining: _initialHintsFor(isRandom: false, levelNumber: levelNumber),
      );

      _progressRepository.clearActiveLevelState();

      if (_shouldHaveTimer(isRandom: false, levelNumber: levelNumber, difficulty: '')) {
        _startTimer(_calculateTimerDuration(level.colorCount));
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load level: $e');
    }
  }

  Future<void> loadRandomLevel(
    String difficulty, {
    int? colorCount,
    int? capacity,
    int? seed,
  }) async {
    _timer?.cancel();
    final int levelSeed = seed ?? DateTime.now().millisecondsSinceEpoch;
    final isSuperHard = _progressRepository.isSuperHardModeEnabled();
    final isBlurSolved = _progressRepository.isBlurSolvedTubesEnabled();
    final isInstantPouring = _progressRepository.isInstantPouringEnabled();
    final isHintHelper = _progressRepository.isHintHelperEnabled();
    final isSoundEffects = _progressRepository.isSoundEffectsEnabled();
    state = GameViewModelState(
      isLoading: true,
      isRandomMode: true,
      randomDifficulty: difficulty,
      randomSeed: levelSeed,
      randomColorCount: colorCount,
      randomCapacity: capacity,
      isSuperHardModeEnabled: isSuperHard,
      isBlurSolvedTubesEnabled: isBlurSolved,
      isInstantPouringEnabled: isInstantPouring,
      isHintHelperEnabled: isHintHelper,
      isSoundEffectsEnabled: isSoundEffects,
      hintsRemaining: _initialHintsFor(isRandom: true, levelNumber: -1),
    );

    try {
      final savedMap = _progressRepository.getSavedLevelState();
      final savedColorCount = savedMap?['randomColorCount'] as int?;
      final savedCapacity = savedMap?['randomCapacity'] as int?;
      if (savedMap != null &&
          savedMap['isRandomMode'] == true &&
          savedMap['randomDifficulty'] == difficulty &&
          savedColorCount == colorCount &&
          savedCapacity == capacity &&
          (seed == null || savedMap['randomSeed'] == seed)) {
        final savedTubes = (savedMap['tubes'] as List).map((t) {
          final tMap = Map<dynamic, dynamic>.from(t as Map);
          return Tube(
            colors: (tMap['colors'] as List).map((c) => Color(c as int)).toList(),
            capacity: tMap['capacity'] as int,
          );
        }).toList();

        final savedHistory = (savedMap['moveHistory'] as List).map((h) {
          final hMap = Map<dynamic, dynamic>.from(h as Map);
          final tubes = (hMap['tubes'] as List).map((t) {
            final tMap = Map<dynamic, dynamic>.from(t as Map);
            return Tube(
              colors: (tMap['colors'] as List).map((c) => Color(c as int)).toList(),
              capacity: tMap['capacity'] as int,
            );
          }).toList();
          return MoveSnapshot(
            tubes: tubes,
            moveCount: hMap['moveCount'] as int,
          );
        }).toList();

        final level = GameLevel(
          levelNumber: savedMap['levelNumber'] as int? ?? -1,
          tubes: savedTubes,
          optimalMoves: savedMap['optimalMoves'] as int? ?? 10,
        );

        state = GameViewModelState(
          level: level,
          isRandomMode: true,
          randomDifficulty: difficulty,
          randomSeed: savedMap['randomSeed'] as int?,
          randomColorCount: savedColorCount,
          randomCapacity: savedCapacity,
          moveCount: savedMap['moveCount'] as int,
          moveHistory: savedHistory,
          isSuperHardModeEnabled: isSuperHard,
          isBlurSolvedTubesEnabled: isBlurSolved,
          isInstantPouringEnabled: isInstantPouring,
          isHintHelperEnabled: isHintHelper,
          hintsRemaining: savedMap['hintsRemaining'] as int? ??
              _initialHintsFor(isRandom: true, levelNumber: -1),
        );

        if (savedMap['timeLeft'] != null) {
          _startTimer(savedMap['timeLeft'] as int);
        }
        return;
      }

      int finalColorCount = colorCount ?? 3;
      int finalCapacity = capacity ?? 4;
      if (colorCount == null && capacity == null) {
        if (difficulty == 'Medium') {
          finalColorCount = 6;
          finalCapacity = 4;
        } else if (difficulty == 'Hard') {
          finalColorCount = 9;
          finalCapacity = 5;
        } else if (difficulty == 'Super Hard') {
          finalColorCount = 12;
          finalCapacity = 5;
        } else if (difficulty == 'Super Duper Hard') {
          finalColorCount = 16;
          finalCapacity = 6;
        }
      } else {
        if (colorCount == null) {
          if (difficulty == 'Easy') finalColorCount = 3;
          else if (difficulty == 'Medium') finalColorCount = 6;
          else if (difficulty == 'Hard') finalColorCount = 9;
          else if (difficulty == 'Super Hard') finalColorCount = 12;
          else if (difficulty == 'Super Duper Hard') finalColorCount = 16;
        }
        if (capacity == null) {
          if (difficulty == 'Easy') finalCapacity = 4;
          else if (difficulty == 'Medium') finalCapacity = 4;
          else if (difficulty == 'Hard') finalCapacity = 5;
          else if (difficulty == 'Super Hard') finalCapacity = 5;
          else if (difficulty == 'Super Duper Hard') finalCapacity = 6;
        }
      }

      final level = _levelGenerator.generateRandom(
        colorCount: finalColorCount,
        seed: levelSeed,
        capacity: finalCapacity,
      );

      state = state.copyWith(
        level: level,
        isLoading: false,
        randomColorCount: finalColorCount,
        randomCapacity: finalCapacity,
      );

      _progressRepository.clearActiveLevelState();

      if (_shouldHaveTimer(isRandom: true, levelNumber: -1, difficulty: difficulty)) {
        _startTimer(_calculateTimerDuration(level.colorCount));
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load random level: $e',
      );
    }
  }

  bool isValidPour(int fromIndex, int toIndex) {
    if (state.level == null) return false;
    if (fromIndex == toIndex) return false;
    if (fromIndex < 0 || fromIndex >= state.level!.tubes.length) return false;
    if (toIndex < 0 || toIndex >= state.level!.tubes.length) return false;

    final fromTube = state.level!.tubes[fromIndex];
    final toTube = state.level!.tubes[toIndex];

    if (fromTube.isEmpty || toTube.isFull) return false;

    final colorToMove = fromTube.topColor!;
    return toTube.canReceive(colorToMove);
  }

  void selectTube(int index) {
    if (state.isComplete || state.isTimeOut || state.level == null || state.pouringFromIndex != null) return;

    if (state.hintFromIndex != null || state.hintToIndex != null) {
      state = state.copyWith(
        hintFromIndex: () => null,
        hintToIndex: () => null,
      );
    }

    if (state.selectedTubeIndex == null) {
      if (!state.level!.tubes[index].isEmpty) {
        HapticFeedback.lightImpact();
        state = state.copyWith(selectedTubeIndex: () => index);
      }
    } else {
      if (state.selectedTubeIndex == index) {
        HapticFeedback.lightImpact();
        state = state.copyWith(selectedTubeIndex: () => null);
      } else {
        if (isValidPour(state.selectedTubeIndex!, index)) {
          _pourWater(state.selectedTubeIndex!, index);
        } else {
          // If tap on another non-empty tube and we can't pour there, select that one instead
          if (!state.level!.tubes[index].isEmpty) {
            HapticFeedback.lightImpact();
            state = state.copyWith(selectedTubeIndex: () => index);
          } else {
            HapticFeedback.lightImpact();
            state = state.copyWith(selectedTubeIndex: () => null);
          }
        }
      }
    }
  }

  Future<void> _pourWater(int fromIndex, int toIndex) async {
    if (state.level == null) return;
    HapticFeedback.mediumImpact();
    state = state.copyWith(
      pouringFromIndex: () => fromIndex,
      pouringToIndex: () => toIndex,
    );
    if (state.isInstantPouringEnabled) {
      await completePendingPour();
    }
  }

  Future<void> completePendingPour() async {
    if (state.pouringFromIndex == null || state.pouringToIndex == null || state.level == null) return;
    final fromIndex = state.pouringFromIndex!;
    final toIndex = state.pouringToIndex!;

    final fromTube = state.level!.tubes[fromIndex];
    final toTube = state.level!.tubes[toIndex];
    final colorToMove = fromTube.topColor!;

    int countToMove = 0;
    for (int i = fromTube.colors.length - 1; i >= 0; i--) {
      if (fromTube.colors[i] == colorToMove) {
        countToMove++;
      } else {
        break;
      }
    }

    final availableSpace = toTube.capacity - toTube.colors.length;
    final pourCount = countToMove.clamp(0, availableSpace);

    if (pourCount == 0) {
      state = state.copyWith(
        selectedTubeIndex: () => null,
        pouringFromIndex: () => null,
        pouringToIndex: () => null,
      );
      return;
    }

    final snapshot = MoveSnapshot(
      tubes: state.level!.tubes.map((t) => Tube(colors: List<Color>.from(t.colors), capacity: t.capacity)).toList(),
      moveCount: state.moveCount,
    );

    final newFromColors = List<Color>.from(fromTube.colors)
      ..removeRange(fromTube.colors.length - pourCount, fromTube.colors.length);
    final newToColors = List<Color>.from(toTube.colors)
      ..addAll(List.filled(pourCount, colorToMove));

    final newTubes = List<Tube>.from(state.level!.tubes);
    newTubes[fromIndex] = fromTube.copyWith(colors: newFromColors);
    newTubes[toIndex] = toTube.copyWith(colors: newToColors);

    final newLevel = state.level!.copyWith(tubes: newTubes);
    final isComplete = newLevel.isComplete;

      if (isComplete) {
        _timer?.cancel();
        HapticFeedback.heavyImpact();
      }

      if (_cachedSolution != null && _cachedSolution!.isNotEmpty) {
        final expectedMove = _cachedSolution!.first;
        if (expectedMove.fromIndex == fromIndex && expectedMove.toIndex == toIndex) {
          _cachedSolution!.removeAt(0);
        } else {
          _cachedSolution = null;
        }
      }

      state = state.copyWith(
        level: newLevel,
        moveCount: state.moveCount + 1,
        selectedTubeIndex: () => null,
        pouringFromIndex: () => null,
        pouringToIndex: () => null,
        isComplete: isComplete,
        moveHistory: [...state.moveHistory, snapshot],
      );

      _saveCurrentState();

      if (isComplete) {
        await completeLevel();
      }
    }

    Future<void> completeLevel() async {
      if (state.level == null || !state.isComplete || state.isProgressSaved) return;
      state = state.copyWith(isProgressSaved: true);
      _progressRepository.clearActiveLevelState();
      final moves = state.moveCount;
      final optimal = state.level?.optimalMoves ?? 0;
      final int filledStars;
      if (moves < optimal) {
        filledStars = 3;
      } else if (moves == optimal) {
        filledStars = 2;
      } else {
        filledStars = 1;
      }
      await _progressRepository.saveLevelStars(state.level!.levelNumber, filledStars);
      if (state.isRandomMode) {
        await _progressRepository.addRandomLevelMoves(state.moveCount);
      } else {
        await _progressRepository.completeLevel(state.level!.levelNumber, state.moveCount);
      }
    }

    void resetLevel() {
      _cachedSolution = null;
      _progressRepository.clearActiveLevelState();
      if (state.level != null) {
        if (state.isRandomMode) {
          loadRandomLevel(
            state.randomDifficulty ?? 'Easy',
            colorCount: state.randomColorCount,
            capacity: state.randomCapacity,
            seed: state.randomSeed,
          );
        } else {
          loadLevel(state.level!.levelNumber);
        }
      }
    }

    void undoMove() {
      if (!state.canUndo || state.level == null) return;

      _cachedSolution = null;
      HapticFeedback.lightImpact();

      final snapshot = state.moveHistory.last;
      final newHistory = List<MoveSnapshot>.from(state.moveHistory)..removeLast();

      state = state.copyWith(
        level: state.level!.copyWith(tubes: snapshot.tubes),
        selectedTubeIndex: () => null,
        isComplete: false,
        moveHistory: newHistory,
        hintFromIndex: () => null,
        hintToIndex: () => null,
      );

    _saveCurrentState();
  }

  void _saveCurrentState() {
    if (state.level == null || state.isComplete) {
      _progressRepository.clearActiveLevelState();
      return;
    }
    final level = state.level!;
    final stateMap = <String, dynamic>{
      'levelNumber': level.levelNumber,
      'isRandomMode': state.isRandomMode,
      'randomDifficulty': state.randomDifficulty,
      'randomSeed': state.randomSeed,
      'randomColorCount': state.randomColorCount,
      'randomCapacity': state.randomCapacity,
      'moveCount': state.moveCount,
      'timeLeft': state.timeLeft,
      'optimalMoves': level.optimalMoves,
      'hintsRemaining': state.hintsRemaining,
      'tubes': level.tubes.map((t) => {
        'colors': t.colors.map((c) => c.value).toList(),
        'capacity': t.capacity,
      }).toList(),
      'moveHistory': state.moveHistory.map((s) => {
        'moveCount': s.moveCount,
        'tubes': s.tubes.map((t) => {
          'colors': t.colors.map((c) => c.value).toList(),
          'capacity': t.capacity,
        }).toList(),
      }).toList(),
    };
    _progressRepository.saveActiveLevelState(stateMap);
  }

  List<WaterSortMove>? _cachedSolution;

  bool showHint() {
    if (state.level == null || state.isComplete || state.isTimeOut) return false;
    if (!state.showHintButton || state.hintsRemaining <= 0) return false;

    final solver = LevelSolver();

    if (_cachedSolution == null || _cachedSolution!.isEmpty) {
      _cachedSolution = solver.solve(state.level!.tubes);
    }

    if (_cachedSolution != null && _cachedSolution!.isNotEmpty) {
      final firstMove = _cachedSolution!.first;
      if (!isValidPour(firstMove.fromIndex, firstMove.toIndex)) {
        _cachedSolution = solver.solve(state.level!.tubes);
      }
    }

    if (_cachedSolution != null && _cachedSolution!.isNotEmpty) {
      HapticFeedback.lightImpact();
      final nextMove = _cachedSolution!.first;
      state = state.copyWith(
        selectedTubeIndex: () => null,
        hintFromIndex: () => nextMove.fromIndex,
        hintToIndex: () => nextMove.toIndex,
        hintsRemaining: state.hintsRemaining - 1,
      );
      _saveCurrentState();
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
