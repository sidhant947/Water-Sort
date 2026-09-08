import 'package:flame_audio/flame_audio.dart';

/// Pooled, rate-limited sound effects.
///
/// `FlameAudio.play` allocates a brand new `AudioPlayer` per call and never
/// disposes it, so rapid taps pile up native players until playback stalls and
/// the app slows down. Pools reuse a bounded number of players instead.
class GameAudio {
  GameAudio._();

  static const String pouring = 'pouring.mp3';
  static const String tubeComplete = 'tube_complete.mp3';
  static const String levelComplete = 'level_complete.mp3';

  static const Map<String, int> _maxPlayers = {
    pouring: 3,
    tubeComplete: 3,
    levelComplete: 1,
  };

  /// Minimum gap between two plays of the same effect, so that spamming moves
  /// cannot queue up dozens of overlapping copies.
  static const Map<String, Duration> _minInterval = {
    pouring: Duration(milliseconds: 90),
    tubeComplete: Duration(milliseconds: 120),
    levelComplete: Duration(milliseconds: 500),
  };

  static final Map<String, AudioPool> _pools = {};
  static final Map<String, int> _lastPlayedMs = {};
  static Future<void>? _initFuture;

  static Future<void> init() => _initFuture ??= _load();

  static Future<void> _load() async {
    for (final entry in _maxPlayers.entries) {
      try {
        _pools[entry.key] = await FlameAudio.createPool(
          entry.key,
          maxPlayers: entry.value,
        );
      } catch (_) {
        // Missing/undecodable asset: that effect stays silent.
      }
    }
  }

  static void play(String file) {
    final pool = _pools[file];
    if (pool == null) return;

    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    final int? lastMs = _lastPlayedMs[file];
    final int minMs = (_minInterval[file] ?? Duration.zero).inMilliseconds;
    if (lastMs != null && nowMs - lastMs < minMs) return;
    _lastPlayedMs[file] = nowMs;

    pool.start().then((_) {}, onError: (_) {});
  }
}
