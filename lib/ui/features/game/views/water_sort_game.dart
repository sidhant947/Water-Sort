import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:watersort/domain/models/tube.dart';
import 'package:watersort/ui/features/game/view_models/game_view_model.dart';
import 'package:watersort/ui/core/audio/game_audio.dart';
import 'package:watersort/ui/core/theme/app_colors.dart';

class WaterSortGame extends FlameGame with TapCallbacks {
  WaterSortGame({
    required GameViewModelState initialState,
    required this.onTubeTap,
    required this.onPourComplete,
  }) : _state = initialState;

  GameViewModelState _state;
  final Function(int) onTubeTap;
  final VoidCallback onPourComplete;

  final List<TubeComponent> _tubes = [];
  ActivePourAnimation? _activePour;

  final List<GameParticle> _particles = [];
  final List<TapRipple> _ripples = [];

  static const int _maxParticles = 240;
  static const int _maxRipples = 6;

  bool _pendingPourHandled = false;

  void updateState(GameViewModelState newState) {
    final GameViewModelState oldState = _state;
    final int tubeCount = newState.level?.tubes.length ?? 0;
    final bool levelChanged = _tubes.length != tubeCount ||
        oldState.level?.levelNumber != newState.level?.levelNumber ||
        oldState.randomSeed != newState.randomSeed;
    // Rebuilding the layout is expensive; the level object identity changes on
    // every move, so only relayout when the geometry actually changed.
    final bool needRelayout = levelChanged || oldState.tubeSize != newState.tubeSize;

    _state = newState;

    if (needRelayout) {
      _layoutTubes();
    }
    _syncTubes();

    if (newState.pouringFromIndex == null || newState.pouringToIndex == null) {
      _pendingPourHandled = false;
      return;
    }

    if (newState.isInstantPouringEnabled || _activePour != null || _pendingPourHandled) {
      return;
    }

    _pendingPourHandled = true;
    final bool started = _startLevelAnimation(
      newState.pouringFromIndex!,
      newState.pouringToIndex!,
    );
    if (!started) {
      // Nothing to animate. Release the view model instead of leaving it
      // locked in the "pouring" state, which would ignore every later tap.
      Future.microtask(onPourComplete);
    }
  }

  void _syncTubes() {
    final level = _state.level;
    if (level == null) return;

    for (int i = 0; i < _tubes.length; i++) {
      if (i < level.tubes.length) {
        final newTube = level.tubes[i];
        final oldTube = _tubes[i].tube;

        if (newTube.isSolved && !oldTube.isSolved && !newTube.isEmpty) {
          if (!_state.isInstantPouringEnabled) {
            _spawnVictoryBurst(_tubes[i], newTube.topColor ?? const Color(0xFF00FFCC));
            if (_state.isSoundEffectsEnabled) {
              GameAudio.play(GameAudio.tubeComplete);
            }
          }
        }

        _tubes[i].tube = newTube;
        _tubes[i].isSelected = _state.selectedTubeIndex == i;
        _tubes[i].isSuperHardModeEnabled = _state.isSuperHardModeEnabled;
        _tubes[i].isBlurSolvedTubesEnabled = _state.isBlurSolvedTubesEnabled;
        _tubes[i].isInstantPouringEnabled = _state.isInstantPouringEnabled;
        _tubes[i].isHintSource = _state.hintFromIndex == i;
        _tubes[i].isHintTarget = _state.hintToIndex == i;
      }
    }
  }

  /// Returns `true` when a pour animation was actually started.
  bool _startLevelAnimation(int fromIndex, int toIndex) {
    if (fromIndex < 0 || toIndex < 0 || fromIndex >= _tubes.length || toIndex >= _tubes.length) {
      return false;
    }

    final fromComp = _tubes[fromIndex];
    final toComp = _tubes[toIndex];

    final fromTube = fromComp.tube;
    final toTube = toComp.tube;

    if (fromTube.isEmpty) return false;
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

    if (pourCount == 0) return false;

    _activePour = ActivePourAnimation(
      fromComponent: fromComp,
      toComponent: toComp,
      color: colorToMove,
      pourCount: pourCount,
      duration: _state.isSoundEffectsEnabled ? 0.65 : 0.2,
    );
    if (_state.isSoundEffectsEnabled) {
      GameAudio.play(GameAudio.pouring);
    }
    return true;
  }

  void _spawnVictoryBurst(TubeComponent tubeComp, Color color) {
    final random = math.Random();
    final center = tubeComp.position + tubeComp.size / 2;

    for (int i = 0; i < 35; i++) {
      final double speed = 80.0 + random.nextDouble() * 220.0;
      final double angle = -math.pi / 2 + (random.nextDouble() - 0.5) * math.pi * 1.5;
      final double maxLife = 0.6 + random.nextDouble() * 0.6;

      _particles.add(
        GameParticle(
          position: center.clone(),
          velocity: Vector2(math.cos(angle) * speed, math.sin(angle) * speed),
          color: color,
          size: 4.0 + random.nextDouble() * 4.0,
          life: 0.0,
          maxLife: maxLife,
          angle: random.nextDouble() * math.pi * 2,
          spinSpeed: (random.nextDouble() - 0.5) * 8.0,
          isStar: random.nextBool(),
        ),
      );
    }

    if (_particles.length > _maxParticles) {
      _particles.removeRange(0, _particles.length - _maxParticles);
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await GameAudio.init();
  }

  @override
  Color backgroundColor() => AppColors.bg;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _layoutTubes();
  }

  void _layoutTubes() {
    final level = _state.level;
    if (level == null) return;

    final double containerWidth = size.x;
    final double containerHeight = size.y;
    if (containerWidth <= 0 || containerHeight <= 0) return;

    final int tubeCount = level.tubes.length;
    if (tubeCount == 0) return;

    const double minMarginX = 10.0;
    const double minMarginY = 16.0;

    final int capacity = level.tubes.isNotEmpty ? level.tubes.first.capacity : 4;
    final int colorCount = level.colorCount;
    final double targetAspectRatio;
    final double minAspectRatio;
    final double maxAllowedWidth;

    switch (_state.tubeSize) {
      case 'slim':
        targetAspectRatio = 4.4;
        minAspectRatio = 3.6;
        maxAllowedWidth = 44.0;
        break;
      case 'medium':
        targetAspectRatio = 3.4;
        minAspectRatio = 2.9;
        maxAllowedWidth = 54.0;
        break;
      case 'wide':
        targetAspectRatio = 2.6;
        minAspectRatio = 2.2;
        maxAllowedWidth = 68.0;
        break;
      case 'adaptive':
      default:
        if (capacity >= 6 || colorCount >= 10) {
          targetAspectRatio = 4.4;
          minAspectRatio = 3.6;
          maxAllowedWidth = 44.0;
        } else if (capacity == 5 || colorCount >= 6) {
          targetAspectRatio = 3.6;
          minAspectRatio = 3.0;
          maxAllowedWidth = 52.0;
        } else {
          targetAspectRatio = 2.8;
          minAspectRatio = 2.3;
          maxAllowedWidth = 64.0;
        }
        break;
    }

    final List<int> candidateRows = [];
    if (tubeCount <= 4) {
      candidateRows.add(1);
    } else if (tubeCount <= 8) {
      candidateRows.addAll([2, capacity >= 6 ? 3 : 2]);
    } else if (tubeCount <= 12) {
      candidateRows.addAll([2, 3]);
    } else if (tubeCount <= 16) {
      candidateRows.addAll([3, 4]);
    } else {
      candidateRows.addAll([4, 5]);
    }

    List<int> bestRowCounts = [tubeCount];
    double bestTubeWidth = 40.0;
    double bestTubeHeight = 120.0;
    double bestSpacingX = 8.0;
    double bestSpacingY = 12.0;
    double bestStartY = 0.0;
    double bestScore = -1.0;

    for (final r in candidateRows) {
      final base = tubeCount ~/ r;
      final rem = tubeCount % r;
      final rowCounts = List.generate(r, (i) => base + (i < rem ? 1 : 0));
      final maxCols = rowCounts.first;
      if (maxCols == 0) continue;

      final availW = containerWidth - (minMarginX * 2);
      final availH = containerHeight - (minMarginY * 2);

      final double minSpacingX = (maxCols >= 5 || containerWidth < 360) ? 6.0 : 8.0;
      final double maxSpacingX = maxCols <= 3 ? 24.0 : 18.0;
      final double spacingY = (r >= 4 || containerHeight < 600) ? 8.0 : 12.0;

      final maxWFromWidth = (availW - (maxCols - 1) * minSpacingX) / maxCols;
      final maxHFromHeight = (availH - (r - 1) * spacingY) / r;

      for (double ar = targetAspectRatio; ar >= minAspectRatio; ar -= 0.05) {
        double w = math.min(maxWFromWidth, maxHFromHeight / ar);
        w = w.clamp(18.0, maxAllowedWidth);
        double h = (w * ar).clamp(18.0 * ar, maxHFromHeight);
        w = h / ar;

        final totalGridW = maxCols * w + (maxCols - 1) * minSpacingX;
        final totalGridH = r * h + (r - 1) * spacingY;

        if (totalGridW > availW + 0.5 || totalGridH > availH + 0.5) continue;

        double actualSpacingX = minSpacingX;
        if (maxCols > 1) {
          final remainingWidth = availW - (maxCols * w);
          actualSpacingX = (remainingWidth / (maxCols - 1)).clamp(minSpacingX, maxSpacingX);
        }

        final widestRowW = maxCols * w + (maxCols - 1) * actualSpacingX;
        final totalH = r * h + (r - 1) * spacingY;
        final widthUtil = widestRowW / containerWidth;

        final arCloseness = 1.0 - ((targetAspectRatio - ar) / (targetAspectRatio - minAspectRatio + 0.001)) * 0.35;
        final double score = (w * h) * (0.3 + widthUtil * 0.7) * arCloseness;

        if (score > bestScore) {
          bestScore = score;
          bestRowCounts = rowCounts;
          bestTubeWidth = w;
          bestTubeHeight = h;
          bestSpacingX = actualSpacingX;
          bestSpacingY = spacingY;
          bestStartY = (containerHeight - totalH) / 2;
        }
      }
    }

    if (_tubes.length != tubeCount) {
      removeAll(_tubes);
      _tubes.clear();

      for (int i = 0; i < tubeCount; i++) {
        final comp = TubeComponent(
          index: i,
          tube: level.tubes[i],
          isSelected: _state.selectedTubeIndex == i,
        )
          ..isSuperHardModeEnabled = _state.isSuperHardModeEnabled
          ..isBlurSolvedTubesEnabled = _state.isBlurSolvedTubesEnabled
          ..isInstantPouringEnabled = _state.isInstantPouringEnabled
          ..isHintSource = _state.hintFromIndex == i
          ..isHintTarget = _state.hintToIndex == i;
        _tubes.add(comp);
        add(comp);
      }
    }

    int currentTube = 0;
    for (int r = 0; r < bestRowCounts.length; r++) {
      final countInRow = bestRowCounts[r];
      final double rowWidth = countInRow * bestTubeWidth + (countInRow - 1) * bestSpacingX;
      final double rowStartX = (containerWidth - rowWidth) / 2;
      final double py = bestStartY + r * (bestTubeHeight + bestSpacingY);

      for (int c = 0; c < countInRow; c++) {
        if (currentTube >= tubeCount) break;
        final double px = rowStartX + c * (bestTubeWidth + bestSpacingX);
        _tubes[currentTube].size = Vector2(bestTubeWidth, bestTubeHeight);
        _tubes[currentTube].originalPosition = Vector2(px, py);
        _tubes[currentTube].position = _tubes[currentTube].originalPosition;
        _tubes[currentTube].angle = 0;
        currentTube++;
      }
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (_activePour != null) return;
    
    TubeComponent? tappedTube;

    // 1. Direct hit check
    for (final tube in _tubes) {
      if (tube.containsPoint(event.localPosition)) {
        tappedTube = tube;
        break;
      }
    }

    // 2. Proximity check with expanded margin if no direct hit
    if (tappedTube == null) {
      double minDistance = double.infinity;
      const double maxTouchMargin = 24.0;

      for (final tube in _tubes) {
        final Rect expandedBounds = tube.toRect().inflate(maxTouchMargin);
        if (expandedBounds.contains(event.localPosition.toOffset())) {
          final Vector2 center = tube.position + tube.size / 2;
          final double dist = center.distanceTo(event.localPosition);
          if (dist < minDistance) {
            minDistance = dist;
            tappedTube = tube;
          }
        }
      }
    }

    if (tappedTube != null) {
      final center = tappedTube.position + tappedTube.size / 2;
      if (!_state.isInstantPouringEnabled) {
        if (_ripples.length >= _maxRipples) {
          _ripples.removeRange(0, _ripples.length - _maxRipples + 1);
        }
        _ripples.add(
          TapRipple(
            position: center,
            radius: 5.0,
            maxRadius: tappedTube.size.x * 1.3,
            life: 0.0,
            maxLife: 0.3,
            color: const Color(0xFF00FFCC),
          ),
        );
      }
      onTubeTap(tappedTube.index);
    }
  }

  @override
  void update(double dt) {
    // A stalled frame must not fast-forward the animations in one jump.
    if (dt > 0.05) dt = 0.05;
    super.update(dt);

    if (_activePour != null) {
      final done = _activePour!.update(dt);
      if (done) {
        _activePour!.reset();
        _activePour = null;
        _syncTubes();
        onPourComplete();
      }
    }

    for (int i = _particles.length - 1; i >= 0; i--) {
      final p = _particles[i];
      p.life += dt;
      if (p.life >= p.maxLife) {
        _particles.removeAt(i);
      } else {
        p.position += p.velocity * dt;
        p.velocity.y += 280.0 * dt;
        p.angle += p.spinSpeed * dt;
      }
    }

    for (int i = _ripples.length - 1; i >= 0; i--) {
      final r = _ripples[i];
      r.life += dt;
      if (r.life >= r.maxLife) {
        _ripples.removeAt(i);
      } else {
        final double t = r.life / r.maxLife;
        r.radius = r.startRadius + (r.maxRadius - r.startRadius) * t;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    for (final r in _ripples) {
      final double progress = (r.life / r.maxLife).clamp(0.0, 1.0);
      final double opacity = 1.0 - progress;

      final paint = Paint()
        ..color = r.color.withValues(alpha: opacity * 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4 - (1.2 * progress);
      canvas.drawCircle(Offset(r.position.x, r.position.y), r.radius, paint);

      final glowPaint = Paint()
        ..color = r.color.withValues(alpha: opacity * 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r.radius * 0.15
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
      canvas.drawCircle(Offset(r.position.x, r.position.y), r.radius, glowPaint);
    }

    for (final p in _particles) {
      final double progress = (p.life / p.maxLife).clamp(0.0, 1.0);
      final double opacity = 1.0 - progress;

      canvas.save();
      canvas.translate(p.position.x, p.position.y);
      canvas.rotate(p.angle);

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      if (p.isStar) {
        final path = Path();
        final double rOuter = p.size;
        final double rInner = p.size * 0.4;
        for (int step = 0; step < 5; step++) {
          final double outerAngle = -math.pi / 2 + step * (math.pi * 2 / 5);
          final double innerAngle = -math.pi / 2 + (step + 0.5) * (math.pi * 2 / 5);
          if (step == 0) {
            path.moveTo(math.cos(outerAngle) * rOuter, math.sin(outerAngle) * rOuter);
          } else {
            path.lineTo(math.cos(outerAngle) * rOuter, math.sin(outerAngle) * rOuter);
          }
          path.lineTo(math.cos(innerAngle) * rInner, math.sin(innerAngle) * rInner);
        }
        path.close();
        canvas.drawPath(path, paint);
      } else {
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: p.size * 1.5, height: p.size * 0.6), paint);
      }

      canvas.restore();
    }
  }
}

class TubeComponent extends PositionComponent {
  TubeComponent({
    required this.index,
    required this.tube,
    required this.isSelected,
  });

  final int index;
  Tube tube;
  bool isSelected;
  bool isSuperHardModeEnabled = false;
  bool isBlurSolvedTubesEnabled = false;
  bool isInstantPouringEnabled = false;
  bool isHintSource = false;
  bool isHintTarget = false;

  Vector2 originalPosition = Vector2.zero();
  double time = 0.0;
  final int bubbleSeed = math.Random().nextInt(1000000);

  bool isAnimatingSource = false;
  bool isAnimatingTarget = false;
  double animationProgress = 0.0;
  Color? animatingColor;
  int animatingPourCount = 0;

  bool _wasSelected = false;
  double sloshDisplacement = 0.0;
  double sloshVelocity = 0.0;

  @override
  void update(double dt) {
    super.update(dt);
    time += dt;

    if (isInstantPouringEnabled) {
      sloshVelocity = 0.0;
      sloshDisplacement = 0.0;
      if (isSelected) {
        position.y = originalPosition.y - 18;
      } else {
        position.y = originalPosition.y;
      }
      return;
    }

    if (isSelected != _wasSelected) {
      _wasSelected = isSelected;
      sloshVelocity += isSelected ? 32.0 : -24.0;
    }

    final double springConstant = 120.0;
    final double damping = 4.5;
    final double acceleration = -springConstant * sloshDisplacement - damping * sloshVelocity;
    sloshVelocity += acceleration * dt;
    sloshDisplacement += sloshVelocity * dt;

    if (isSelected) {
      position.y = originalPosition.y - 18 + 3.0 * math.sin(time * 6.0);
    } else if (isHintSource) {
      position.y = originalPosition.y - 14 + 2.5 * math.sin(time * 6.0);
    } else if (position.y != originalPosition.y) {
      position.y = originalPosition.y;
    }
  }

  IconData _getIconForColor(Color color) {
    final hex = color.toARGB32() & 0xFFFFFF;
    final index = AppColors.waterColors.indexWhere((c) => (c.toARGB32() & 0xFFFFFF) == hex);
    if (index == -1) return Icons.brightness_1_rounded;
    switch (index) {
      case 0: return Icons.favorite_rounded;
      case 1: return Icons.water_drop_rounded;
      case 2: return Icons.eco_rounded;
      case 3: return Icons.wb_sunny_rounded;
      case 4: return Icons.star_rounded;
      case 5: return Icons.dark_mode_rounded;
      case 6: return Icons.auto_awesome_rounded;
      case 7: return Icons.ac_unit_rounded;
      case 8: return Icons.palette_rounded;
      case 9: return Icons.whatshot_rounded;
      case 10: return Icons.cloud_rounded;
      case 11: return Icons.diamond_rounded;
      case 12: return Icons.cookie_rounded;
      case 13: return Icons.bolt_rounded;
      case 14: return Icons.nightlight_rounded;
      case 15: return Icons.grass_rounded;
      default: return Icons.brightness_1_rounded;
    }
  }

  @override
  void render(Canvas canvas) {
    final double bottomRadius = size.x / 2;
    const double topRadius = 6.0;
    const double borderWidth = 1.8;

    final paint = Paint()
      ..color = const Color(0xFF16161C).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final RRect outerRRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(0, 0, size.x, size.y),
      bottomLeft: Radius.circular(bottomRadius),
      bottomRight: Radius.circular(bottomRadius),
      topLeft: const Radius.circular(topRadius),
      topRight: const Radius.circular(topRadius),
    );
    canvas.drawRRect(outerRRect, paint);

    canvas.save();
    canvas.clipRRect(RRect.fromRectAndCorners(
      Rect.fromLTWH(borderWidth, borderWidth, size.x - borderWidth * 2, size.y - borderWidth * 2),
      bottomLeft: Radius.circular(bottomRadius - borderWidth),
      bottomRight: Radius.circular(bottomRadius - borderWidth),
      topLeft: Radius.circular(topRadius - borderWidth),
      topRight: Radius.circular(topRadius - borderWidth),
    ));

    _renderLiquid(canvas);
    _renderIcons(canvas);
    _renderBubbles(canvas);
    _renderHighlights(canvas);

    if (isBlurSolvedTubesEnabled && tube.isSolved) {
      _renderIceFrostOverlay(canvas);
    }

    canvas.restore();

    final glowBorderWidth = isSelected || isHintSource || isHintTarget ? 2.8 : borderWidth;
    Paint borderPaint;
    if (isSelected) {
      borderPaint = Paint()
        ..color = isInstantPouringEnabled
            ? const Color(0xFF00FFCC)
            : Color.fromARGB(
                255,
                (128 + 127 * math.sin(time * 5.0)).round(),
                255,
                (200 + 55 * math.sin(time * 5.0)).round(),
              )
        ..style = PaintingStyle.stroke
        ..strokeWidth = glowBorderWidth;
    } else if (isHintSource) {
      borderPaint = Paint()
        ..color = const Color(0xFFFFB300)
        ..style = PaintingStyle.stroke
        ..strokeWidth = glowBorderWidth;
    } else if (isHintTarget) {
      borderPaint = Paint()
        ..color = const Color(0xFF4CAF50)
        ..style = PaintingStyle.stroke
        ..strokeWidth = glowBorderWidth;
    } else {
      borderPaint = Paint()
        ..color = const Color(0xFF2E2E38)
        ..style = PaintingStyle.stroke
        ..strokeWidth = glowBorderWidth;
    }

    if (isSelected) {
      final glowPaint = Paint()
        ..color = const Color(0xFF00FFCC).withValues(
            alpha: isInstantPouringEnabled
                ? 0.35
                : 0.35 + 0.15 * math.sin(time * 5.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = glowBorderWidth + 4.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
      canvas.drawRRect(outerRRect, glowPaint);
    } else if (isHintSource || isHintTarget) {
      final hintColor = isHintSource ? const Color(0xFFFFB300) : const Color(0xFF4CAF50);
      final glowPaint = Paint()
        ..color = hintColor.withValues(
            alpha: 0.35 + 0.15 * math.sin(time * 5.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = glowBorderWidth + 4.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
      canvas.drawRRect(outerRRect, glowPaint);
    }

    canvas.drawRRect(outerRRect, borderPaint);

    final rimPaint = Paint()
      ..color = const Color(0xFF1F1F28)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(-2, -2.5, size.x + 2, 2.5),
        const Radius.circular(2.5),
      ),
      rimPaint,
    );

    final rimBorderPaint = Paint()
      ..color = isSelected
          ? const Color(0xFF00FFCC)
          : isHintSource
              ? const Color(0xFFFFB300)
              : isHintTarget
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFF383845)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected || isHintSource || isHintTarget ? 1.5 : 1.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(-2, -2.5, size.x + 2, 2.5),
        const Radius.circular(2.5),
      ),
      rimBorderPaint,
    );

    if (isHintSource) {
      final pulse = math.sin(time * 6.0);
      final arrowPaint = Paint()
        ..color = const Color(0xFFFFB300)
        ..style = PaintingStyle.fill;
      final arrowPath = Path()
        ..moveTo(size.x / 2, -6.0 + pulse * 2.0)
        ..lineTo(size.x / 2 - 5.5, -14.0 + pulse * 2.0)
        ..lineTo(size.x / 2 + 5.5, -14.0 + pulse * 2.0)
        ..close();
      canvas.drawPath(arrowPath, arrowPaint);
    } else if (isHintTarget) {
      final pulse = math.sin(time * 6.0);
      final arrowPaint = Paint()
        ..color = const Color(0xFF4CAF50)
        ..style = PaintingStyle.fill;
      final arrowPath = Path()
        ..moveTo(size.x / 2, -6.0 - pulse * 2.0)
        ..lineTo(size.x / 2 - 5.5, -14.0 - pulse * 2.0)
        ..lineTo(size.x / 2 + 5.5, -14.0 - pulse * 2.0)
        ..close();
      canvas.drawPath(arrowPath, arrowPaint);
    }
  }

  void _renderLiquid(Canvas canvas) {
    final double segmentHeight = (size.y - 12) / tube.capacity;

    double liquidHeight = tube.colors.length.toDouble();
    if (isAnimatingSource) {
      liquidHeight = tube.colors.length - (animatingPourCount * animationProgress);
    } else if (isAnimatingTarget) {
      liquidHeight = tube.colors.length + (animatingPourCount * animationProgress);
    }

    if (liquidHeight <= 0.0) return;

    final int maxSegmentsToDraw = liquidHeight.ceil();

    final List<Color> visibleColors = [];
    for (int j = 0; j < maxSegmentsToDraw; j++) {
      if (j < tube.colors.length) {
        visibleColors.add(tube.colors[j]);
      } else {
        visibleColors.add(animatingColor ?? Colors.transparent);
      }
    }

    for (int i = 0; i < maxSegmentsToDraw; i++) {
      Color color = visibleColors[i];
      if (isBlurSolvedTubesEnabled && tube.isSolved) {
        // Subtle frosted icy tint keeping underlying liquid colors vibrant
        color = Color.alphaBlend(const Color(0x38E0F7FA), color);
      } else if (isSuperHardModeEnabled && visibleColors.isNotEmpty) {
        final Color topColor = visibleColors.last;
        int firstDifferentIndex = -1;
        for (int j = visibleColors.length - 1; j >= 0; j--) {
          if (visibleColors[j] != topColor) {
            firstDifferentIndex = j;
            break;
          }
        }
        if (i <= firstDifferentIndex) {
          color = const Color(0xFFFFFFFF);
        }
      }

      double heightFactor = 1.0;
      if (i >= liquidHeight - 1 && i < liquidHeight) {
        heightFactor = liquidHeight - i;
      }

      if (heightFactor <= 0.0) continue;

      double bottomY = size.y - (i * segmentHeight);
      double topY = bottomY - (segmentHeight * heightFactor);

      final double currentSlosh = (i == maxSegmentsToDraw - 1) ? sloshDisplacement.clamp(-15.0, 15.0) : 0.0;
      final double leftY = topY + currentSlosh;
      final double rightY = topY - currentSlosh;

      final path = Path();
      path.moveTo(0, bottomY);

      if (i == 0) {
        path.lineTo(size.x, bottomY);
      } else {
        path.quadraticBezierTo(size.x / 2, bottomY + 3.5, size.x, bottomY);
      }

      path.lineTo(size.x, rightY);

      if (i == maxSegmentsToDraw - 1) {
        if (isInstantPouringEnabled) {
          for (double x = size.x; x >= 0; x -= 2) {
            final double t = x / size.x;
            final double targetBaseY = leftY + (rightY - leftY) * t;
            path.lineTo(x, targetBaseY);
          }
        } else {
          final double amplitude = isSelected ? 3.5 : 2.0;
          for (double x = size.x; x >= 0; x -= 2) {
            final double t = x / size.x;
            final double targetBaseY = leftY + (rightY - leftY) * t;
            final double waveY = targetBaseY +
                math.sin((x / size.x * 2.0 * math.pi) + (time * 5.0)) * amplitude +
                math.cos((x / size.x * 4.0 * math.pi) - (time * 2.5)) * (amplitude * 0.4);
            path.lineTo(x, waveY);
          }
        }
      } else {
        path.quadraticBezierTo(size.x / 2, topY + 3.5, 0, topY);
      }

      path.close();

      final Color highlightColor = Color.alphaBlend(Colors.white.withValues(alpha: 0.22), color);
      final Color shadowColor = Color.alphaBlend(Colors.black.withValues(alpha: 0.18), color);

      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [shadowColor, highlightColor, color, shadowColor],
          stops: const [0.0, 0.22, 0.65, 1.0],
        ).createShader(Rect.fromLTRB(0, topY, size.x, bottomY));

      canvas.drawPath(path, paint);
    }
  }

  void _renderIcons(Canvas canvas) {
    final double segmentHeight = (size.y - 12) / tube.capacity;

    int totalIcons = tube.colors.length;
    if (isAnimatingSource) {
      totalIcons = math.max(0, tube.colors.length - animatingPourCount);
    }

    final List<Color> visibleColors = [];
    for (int j = 0; j < totalIcons; j++) {
      visibleColors.add(tube.colors[j]);
    }

    for (int i = 0; i < totalIcons; i++) {
      if (isBlurSolvedTubesEnabled && tube.isSolved) continue;

      bool isWhite = false;
      if (isSuperHardModeEnabled && visibleColors.isNotEmpty) {
        final Color topColor = visibleColors.last;
        int firstDifferentIndex = -1;
        for (int j = visibleColors.length - 1; j >= 0; j--) {
          if (visibleColors[j] != topColor) {
            firstDifferentIndex = j;
            break;
          }
        }
        if (i <= firstDifferentIndex) {
          isWhite = true;
        }
      }

      if (isWhite) continue;

      final color = tube.colors[i];
      final double bottomY = size.y - (i * segmentHeight);
      final double centerY = bottomY - segmentHeight / 2;

      final icon = _getIconForColor(color);
      final codePoint = icon.codePoint;
      final fontFamily = icon.fontFamily ?? 'MaterialIcons';

      final maxDiameter = math.min(size.x * 0.85, segmentHeight * 0.85);
      final bgPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.18)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(Offset(size.x / 2, centerY), maxDiameter / 2, bgPaint);

      final iconSize = maxDiameter * 0.8;
      final textPainter = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(
          text: String.fromCharCode(codePoint),
          style: TextStyle(
            fontSize: iconSize,
            fontFamily: fontFamily,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          (size.x - textPainter.width) / 2,
          centerY - textPainter.height / 2,
        ),
      );
    }
  }

  void _renderBubbles(Canvas canvas) {
    if (tube.colors.isEmpty || isInstantPouringEnabled) return;

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    final double speedMultiplier = isSelected ? 1.8 : 1.0;
    final random = math.Random(bubbleSeed);

    double totalLiquidHeight = (tube.colors.length / tube.capacity) * (size.y - 12);
    if (isAnimatingSource) {
      totalLiquidHeight -= (animatingPourCount * animationProgress / tube.capacity) * (size.y - 12);
    } else if (isAnimatingTarget) {
      totalLiquidHeight += (animatingPourCount * animationProgress / tube.capacity) * (size.y - 12);
    }

    if (totalLiquidHeight <= 0.0) return;

    for (int i = 0; i < 7; i++) {
      final xRatio = random.nextDouble();
      final yRatio = random.nextDouble();
      final bubbleSize = random.nextDouble() * 2.2 + 1.2;
      final speed = (random.nextInt(2) + 1).toDouble();

      final x = xRatio * size.x + math.sin(time * 2.0 + i) * 1.5;
      double y = size.y - ((yRatio + time * 0.22 * speed * speedMultiplier) % 1.0) * totalLiquidHeight;
      if (y > size.y - totalLiquidHeight && y < size.y) {
        canvas.drawCircle(Offset(x, y), bubbleSize, paint);
      }
    }
  }

  void _renderHighlights(Canvas canvas) {
    final sheenPaint1 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.withValues(alpha: 0.3),
          Colors.white.withValues(alpha: 0.08),
          Colors.white.withValues(alpha: 0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(3.5, 4, 8, size.y - 8));
    canvas.drawRect(Rect.fromLTWH(3.5, 4, 8, size.y - 8), sheenPaint1);

    final sheenPaint2 = Paint()..color = Colors.white.withValues(alpha: 0.08);
    canvas.drawRect(Rect.fromLTWH(size.x - 5.5, 4, 2.5, size.y - 8), sheenPaint2);
  }

  void _renderIceFrostOverlay(Canvas canvas) {
    // 1. Frosted ice glass depth gradient & specular sheen
    final glassIcePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0x66E0F7FA),
          const Color(0x2280DEEA),
          const Color(0x88B2EBF2),
          const Color(0x44E0F7FA),
        ],
        stops: const [0.0, 0.35, 0.7, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.x, size.y));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), glassIcePaint);

    // 2. Realistic Procedural Ice Crack Patterns
    final crackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;

    final crackGlowPaint = Paint()
      ..color = const Color(0xFFE0F7FA).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

    final random = math.Random(bubbleSeed + 101);

    for (int i = 0; i < 4; i++) {
      final startX = random.nextDouble() * (size.x - 12) + 6;
      final startY = random.nextDouble() * (size.y - 20) + 10;
      final Path crackPath = Path()..moveTo(startX, startY);

      double cx = startX;
      double cy = startY;
      int branches = random.nextInt(3) + 3;

      for (int b = 0; b < branches; b++) {
        final angle = (random.nextDouble() * math.pi * 2);
        final len = random.nextDouble() * 12.0 + 8.0;
        cx += math.cos(angle) * len;
        cy += math.sin(angle) * len;
        cx = cx.clamp(4.0, size.x - 4.0);
        cy = cy.clamp(4.0, size.y - 4.0);
        crackPath.lineTo(cx, cy);

        // Sub-branch crack
        if (random.nextBool()) {
          final subAngle = angle + (random.nextBool() ? 0.6 : -0.6);
          final subLen = len * 0.6;
          final subX = (cx + math.cos(subAngle) * subLen).clamp(4.0, size.x - 4.0);
          final subY = (cy + math.sin(subAngle) * subLen).clamp(4.0, size.y - 4.0);
          crackPath.moveTo(cx, cy);
          crackPath.lineTo(subX, subY);
          crackPath.moveTo(cx, cy);
        }
      }

      canvas.drawPath(crackPath, crackGlowPaint);
      canvas.drawPath(crackPath, crackPaint);
    }

    // 3. Corner & Edge Ice Vignette (Frosted Rim Crystallization)
    final vignettePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.85,
        colors: [
          Colors.transparent,
          const Color(0x40E0F7FA),
          const Color(0xBA80DEEA),
        ],
        stops: const [0.55, 0.82, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.x, size.y));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), vignettePaint);

    // 4. Fine Frost Crystal Sparkles (Star/Hexagon Points)
    final sparklePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final glowSparklePaint = Paint()
      ..color = const Color(0xFF80DEEA).withValues(alpha: 0.6)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

    for (int i = 0; i < 7; i++) {
      final sx = random.nextDouble() * (size.x - 10) + 5;
      final sy = random.nextDouble() * (size.y - 14) + 7;
      final radius = random.nextDouble() * 1.8 + 1.0;

      canvas.drawCircle(Offset(sx, sy), radius + 1.5, glowSparklePaint);
      canvas.drawCircle(Offset(sx, sy), radius, sparklePaint);

      // Star cross flare
      final Path flarePath = Path()
        ..moveTo(sx - radius * 2.5, sy)
        ..lineTo(sx + radius * 2.5, sy)
        ..moveTo(sx, sy - radius * 2.5)
        ..lineTo(sx, sy + radius * 2.5);
      final flarePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8;
      canvas.drawPath(flarePath, flarePaint);
    }

    // 5. Elegant Frosted Glass Sheen Stripe
    final sheenPath = Path()
      ..moveTo(2, 0)
      ..lineTo(size.x * 0.45, 0)
      ..lineTo(0, size.y * 0.8)
      ..close();
    final sheenPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.45),
          Colors.white.withValues(alpha: 0.05),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.x, size.y));
    canvas.drawPath(sheenPath, sheenPaint);
  }
}

class ActivePourAnimation {
  ActivePourAnimation({
    required this.fromComponent,
    required this.toComponent,
    required this.color,
    required this.pourCount,
    this.duration = 0.65,
  });

  final TubeComponent fromComponent;
  final TubeComponent toComponent;
  final Color color;
  final int pourCount;
  final double duration;

  double elapsed = 0.0;

  void reset() {
    fromComponent.isAnimatingSource = false;
    fromComponent.animationProgress = 0.0;
    toComponent.isAnimatingTarget = false;
    toComponent.animationProgress = 0.0;
    toComponent.animatingColor = null;
  }

  bool update(double dt) {
    elapsed += dt;
    final progress = (elapsed / duration).clamp(0.0, 1.0);
    final easedProgress = Curves.easeInOutCubic.transform(progress);

    fromComponent.isAnimatingSource = true;
    fromComponent.animationProgress = easedProgress;
    fromComponent.animatingPourCount = pourCount;

    toComponent.isAnimatingTarget = true;
    toComponent.animationProgress = easedProgress;
    toComponent.animatingColor = color;
    toComponent.animatingPourCount = pourCount;

    return elapsed >= duration;
  }
}

class GameParticle {
  GameParticle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    required this.life,
    required this.maxLife,
    required this.angle,
    required this.spinSpeed,
    required this.isStar,
  });

  Vector2 position;
  Vector2 velocity;
  Color color;
  double size;
  double life;
  double maxLife;
  double angle;
  double spinSpeed;
  bool isStar;
}

class TapRipple {
  TapRipple({
    required this.position,
    required this.radius,
    required this.maxRadius,
    required this.life,
    required this.maxLife,
    required this.color,
  }) : startRadius = radius;

  Vector2 position;
  final double startRadius;
  double radius;
  double maxRadius;
  double life;
  double maxLife;
  Color color;
}
