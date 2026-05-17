import 'dart:async';
import 'package:flutter/foundation.dart';

// @AETHER: Using ValueNotifier + a single Timer.periodic at 100ms.
// This avoids rebuilding the entire widget tree on every tick —
// only the ValueListenableBuilder watching this notifier rebuilds.
class CountdownService extends ChangeNotifier {
  CountdownService({required DateTime bossSpawnTime})
    : _bossSpawnTime = bossSpawnTime {
    _startTicker();
  }

  final DateTime _bossSpawnTime;
  Timer? _timer;
  Duration _remaining = Duration.zero;

  Duration get remaining => _remaining;

  void _startTicker() {
    _updateRemaining();
    // @AETHER: 100ms interval as required. Using Timer.periodic is
    // more accurate than recursive Future.delayed which drifts over time.
    _timer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => _updateRemaining(),
    );
  }

  void _updateRemaining() {
    final Duration diff = _bossSpawnTime.difference(DateTime.now());
    _remaining = diff.isNegative ? Duration.zero : diff;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get formattedTime {
    final int minutes = _remaining.inMinutes.remainder(60);
    final int seconds = _remaining.inSeconds.remainder(60);
    final int tenths = (_remaining.inMilliseconds.remainder(1000) ~/ 100);
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}.'
        '$tenths';
  }
}
