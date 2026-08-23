import 'dart:math';
import 'package:flutter/material.dart';
import 'package:watersort/domain/models/tube.dart';

class WaterSortMove {
  final int fromIndex;
  final int toIndex;
  WaterSortMove({required this.fromIndex, required this.toIndex});
}

class LevelSolver {
  List<WaterSortMove>? solve(List<Tube> initialTubes, {int maxVisited = 150000}) {
    final visited = <String>{};
    List<WaterSortMove>? result;

    String serializeState(List<Tube> tubes) {
      final keys = tubes.map((t) {
        if (t.isEmpty) return 'E:${t.capacity}';
        final cStr = t.colors.map((c) => c.value.toRadixString(16)).join(',');
        return '$cStr:${t.capacity}';
      }).toList()..sort();
      return keys.join('|');
    }

    bool isComplete(List<Tube> tubes) {
      return tubes.every((t) => t.isEmpty || t.isSolved);
    }

    bool dfs(List<Tube> currentTubes, List<WaterSortMove> path) {
      if (visited.length >= maxVisited) return false;

      if (isComplete(currentTubes)) {
        result = List.from(path);
        return true;
      }

      final stateKey = serializeState(currentTubes);
      if (visited.contains(stateKey)) return false;
      visited.add(stateKey);

      final moves = _getValidMoves(currentTubes);

      for (final move in moves) {
        if (path.isNotEmpty) {
          final lastMove = path.last;
          if (lastMove.fromIndex == move.toIndex && lastMove.toIndex == move.fromIndex) {
            continue;
          }
        }

        final nextTubes = _performPour(currentTubes, move.fromIndex, move.toIndex);
        if (nextTubes != null) {
          path.add(move);
          if (dfs(nextTubes, path)) return true;
          path.removeLast();
        }
      }

      return false;
    }

    dfs(initialTubes, []);
    return result;
  }

  List<WaterSortMove> _getValidMoves(List<Tube> tubes) {
    final moves = <_ScoredMove>[];
    int firstEmptyIndex = -1;
    for (int i = 0; i < tubes.length; i++) {
      if (tubes[i].isEmpty) {
        firstEmptyIndex = i;
        break;
      }
    }

    for (int i = 0; i < tubes.length; i++) {
      final fromTube = tubes[i];
      if (fromTube.isEmpty || fromTube.isSolved) continue;

      final colorToMove = fromTube.topColor!;
      int countToMove = 0;
      for (int k = fromTube.colors.length - 1; k >= 0; k--) {
        if (fromTube.colors[k] == colorToMove) {
          countToMove++;
        } else {
          break;
        }
      }

      final fromIsMono = fromTube.colors.every((c) => c == colorToMove);

      for (int j = 0; j < tubes.length; j++) {
        if (i == j) continue;
        final toTube = tubes[j];

        if (toTube.isFull) continue;

        if (toTube.isEmpty) {
          if (fromIsMono) continue;
          if (j != firstEmptyIndex) continue;
        } else {
          if (toTube.topColor != colorToMove) continue;
        }

        final space = toTube.capacity - toTube.colors.length;
        final pourCount = min(countToMove, space);
        if (pourCount == 0) continue;

        int score = 0;
        final willSolveTarget = (toTube.colors.length + pourCount == toTube.capacity) &&
            (toTube.isEmpty || toTube.colors.every((c) => c == colorToMove));
        final willEmptySource = (fromTube.colors.length == pourCount);
        final willRevealNewColor = !willEmptySource && countToMove == pourCount;

        if (willSolveTarget) {
          score += 150;
        } else if (willEmptySource) {
          score += 80;
        } else if (willRevealNewColor) {
          score += 50;
        } else if (!toTube.isEmpty) {
          if (pourCount == countToMove) {
            score += 35;
          } else {
            score += 10;
          }
        } else {
          if (fromTube.colors.length - pourCount > 0) {
            score += 25;
          } else {
            score += 5;
          }
        }

        moves.add(_ScoredMove(move: WaterSortMove(fromIndex: i, toIndex: j), score: score));
      }
    }

    moves.sort((a, b) => b.score.compareTo(a.score));
    return moves.map((m) => m.move).toList();
  }

  List<Tube>? _performPour(List<Tube> tubes, int fromIndex, int toIndex) {
    final fromTube = tubes[fromIndex];
    final toTube = tubes[toIndex];
    if (fromTube.isEmpty || toTube.isFull) return null;
    final colorToMove = fromTube.topColor!;
    if (!toTube.canReceive(colorToMove)) return null;

    int countToMove = 0;
    for (int i = fromTube.colors.length - 1; i >= 0; i--) {
      if (fromTube.colors[i] == colorToMove) {
        countToMove++;
      } else {
        break;
      }
    }

    final availableSpace = toTube.capacity - toTube.colors.length;
    final pourCount = min(countToMove, availableSpace);
    if (pourCount == 0) return null;

    final newFromColors = List<Color>.from(fromTube.colors)
      ..removeRange(fromTube.colors.length - pourCount, fromTube.colors.length);
    final newToColors = List<Color>.from(toTube.colors)
      ..addAll(List.filled(pourCount, colorToMove));

    final newTubes = List<Tube>.from(tubes);
    newTubes[fromIndex] = fromTube.copyWith(colors: newFromColors);
    newTubes[toIndex] = toTube.copyWith(colors: newToColors);
    return newTubes;
  }
}

class _ScoredMove {
  final WaterSortMove move;
  final int score;
  _ScoredMove({required this.move, required this.score});
}
