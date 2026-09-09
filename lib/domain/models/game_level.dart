import 'package:flutter/material.dart';

import 'tube.dart';

@immutable
class GameLevel {
  const GameLevel({
    required this.levelNumber,
    required this.tubes,
    this.totalMoves = 0,
    required this.optimalMoves,
  });

  final int levelNumber;
  final List<Tube> tubes;
  final int totalMoves;
  final int optimalMoves;

  int get colorCount =>
      tubes.expand((t) => t.colors).toSet().length;

  int get tubeCount => tubes.length;

  bool get isComplete => tubes.every((t) => t.isSolved || t.isEmpty);

  int calculateStars(int moves) {
    if (moves <= optimalMoves) {
      return 3;
    } else if (moves <= (optimalMoves * 1.3).round()) {
      return 2;
    }
    return 1;
  }



  GameLevel copyWith({
    int? levelNumber,
    List<Tube>? tubes,
    int? totalMoves,
    int? optimalMoves,
  }) {
    return GameLevel(
      levelNumber: levelNumber ?? this.levelNumber,
      tubes: tubes ?? this.tubes,
      totalMoves: totalMoves ?? this.totalMoves,
      optimalMoves: optimalMoves ?? this.optimalMoves,
    );
  }
}
