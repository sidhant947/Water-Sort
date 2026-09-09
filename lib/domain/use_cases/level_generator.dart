import 'dart:math';

import 'package:flutter/material.dart';

import 'package:watersort/domain/models/game_level.dart';
import 'package:watersort/domain/models/tube.dart';
import 'package:watersort/ui/core/theme/app_colors.dart';

class LevelGenerator {
  static const int _baseColors = 3;
  static const int _maxColors = 16;

  GameLevel generate(int levelNumber) {
    final random = Random(levelNumber);
    final colorCount = _getColorCount(levelNumber);
    final tubeCount = _getTubeCount(levelNumber);
    final capacity = _getCapacity(levelNumber);

    final colors = _pickColors(colorCount, random);

    final tubes = _generatePuzzle(
      colorCount: colorCount,
      tubeCount: tubeCount,
      capacity: capacity,
      colors: colors,
      random: random,
      levelNumber: levelNumber,
    );

    return GameLevel(
      levelNumber: levelNumber,
      tubes: tubes,
      optimalMoves: _getPredefinedOptimalMoves(colorCount, capacity, levelNumber),
    );
  }

  int _getCapacity(int levelNumber) {
    if (levelNumber > 0) {
      if (levelNumber % 10 == 0) return 6;
      if (levelNumber % 5 == 0) return 5;
    }
    return 4;
  }

  GameLevel generateRandom({
    required int colorCount,
    required int seed,
    int capacity = 4,
  }) {
    final random = Random(seed);
    final tubeCount = colorCount + _getVacantCount(colorCount);

    final colors = _pickColors(colorCount, random);

    final tubes = _generatePuzzle(
      colorCount: colorCount,
      tubeCount: tubeCount,
      capacity: capacity,
      colors: colors,
      random: random,
      levelNumber: -1,
    );

    return GameLevel(
      levelNumber: -1,
      tubes: tubes,
      optimalMoves: _getPredefinedOptimalMoves(colorCount, capacity, seed),
    );
  }

  int _getPredefinedOptimalMoves(int colorCount, int capacity, int seed) {
    final random = Random(seed);
    final baseMoves = (colorCount * capacity * 1.2).round();
    final variance = random.nextInt(5) - 2;
    return baseMoves + variance;
  }

  int _getColorCount(int level) {
    final count = _baseColors + (level - 1) ~/ 3;
    return count.clamp(_baseColors, _maxColors);
  }

  int _getVacantCount(int colorCount) {
    if (colorCount <= 4) return 1;
    if (colorCount <= 8) return 2;
    if (colorCount <= 12) return 2;
    return 3;
  }

  int _getTubeCount(int level) {
    final colorCount = _getColorCount(level);
    return colorCount + _getVacantCount(colorCount);
  }

  List<Color> _pickColors(int count, Random random) {
    final indices = List.generate(AppColors.waterColors.length, (i) => i)
      ..shuffle(random);
    return indices.take(count).map((i) => AppColors.waterColors[i]).toList();
  }

  List<Tube> _generatePuzzle({
    required int colorCount,
    required int tubeCount,
    required int capacity,
    required List<Color> colors,
    required Random random,
    required int levelNumber,
  }) {
    while (true) {
      final List<List<Color>> chunks = [];
      for (final color in colors) {
        if (levelNumber > 0 && levelNumber <= 3 && capacity == 4) {
          chunks.add([color, color]);
          chunks.add([color, color]);
        } else if (levelNumber > 0 && levelNumber <= 6 && capacity == 4) {
          if (random.nextBool()) {
            chunks.add([color, color]);
            chunks.add([color, color]);
          } else {
            chunks.add([color]);
            chunks.add([color]);
            chunks.add([color]);
            chunks.add([color]);
          }
        } else {
          for (int c = 0; c < capacity; c++) {
            chunks.add([color]);
          }
        }
      }

      chunks.shuffle(random);
      final colorSegments = chunks.expand((chunk) => chunk).toList();

      final tubeColors = List.generate(
        tubeCount,
        (index) => <Color>[],
      );

      int segmentIndex = 0;
      for (int i = 0; i < colorCount; i++) {
        for (int j = 0; j < capacity; j++) {
          if (segmentIndex < colorSegments.length) {
            tubeColors[i].add(colorSegments[segmentIndex]);
            segmentIndex++;
          }
        }
      }

      final candidateTubes = tubeColors
          .map((cList) => Tube(colors: cList, capacity: capacity))
          .toList();

      if (_isSolvable(candidateTubes)) {
        return candidateTubes;
      }
    }
  }

  bool _isSolvable(List<Tube> initialTubes) {
    final visited = <String>{};

    String getStateKey(List<Tube> tubes) {
      return tubes.map((t) => t.colors.map((c) => c.hashCode).join(',')).join(';');
    }

    bool dfs(List<Tube> currentTubes) {
      if (visited.length > 5000) return false;

      final key = getStateKey(currentTubes);
      if (visited.contains(key)) return false;
      visited.add(key);

      bool isComplete = true;
      for (final tube in currentTubes) {
        if (!tube.isEmpty && !tube.isSolved) {
          isComplete = false;
          break;
        }
      }
      if (isComplete) return true;

      for (int fromIdx = 0; fromIdx < currentTubes.length; fromIdx++) {
        final fromTube = currentTubes[fromIdx];
        if (fromTube.isEmpty) continue;

        final colorToMove = fromTube.topColor!;
        int countToMove = 0;
        for (int i = fromTube.colors.length - 1; i >= 0; i--) {
          if (fromTube.colors[i] == colorToMove) {
            countToMove++;
          } else {
            break;
          }
        }

        for (int toIdx = 0; toIdx < currentTubes.length; toIdx++) {
          if (fromIdx == toIdx) continue;
          final toTube = currentTubes[toIdx];

          if (toTube.isFull) continue;
          if (!toTube.isEmpty && toTube.topColor != colorToMove) continue;

          final availableSpace = toTube.capacity - toTube.colors.length;
          final pourCount = min(countToMove, availableSpace);
          if (pourCount == 0) continue;

          final fromHasOnlyOneColor = fromTube.colors.every((c) => c == colorToMove);
          if (toTube.isEmpty && fromHasOnlyOneColor) {
            continue;
          }

          final newFromColors = List<Color>.from(fromTube.colors)
            ..removeRange(fromTube.colors.length - pourCount, fromTube.colors.length);
          final newToColors = List<Color>.from(toTube.colors)
            ..addAll(List.filled(pourCount, colorToMove));

          final nextTubes = List<Tube>.from(currentTubes);
          nextTubes[fromIdx] = fromTube.copyWith(colors: newFromColors);
          nextTubes[toIdx] = toTube.copyWith(colors: newToColors);

          if (dfs(nextTubes)) return true;
        }
      }

      return false;
    }

    return dfs(initialTubes);
  }
}

