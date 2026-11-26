import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../space/clocks.dart';
import '../viewport/motion.dart';
import 'scene_running.dart';

/// The time runs on across the ticker's stops and across rebuilds of the frame.
final sceneClockProvider = Provider.autoDispose<ValueListenable<SceneTime>>((
  ref,
) {
  final time = ValueNotifier(const SceneTime(actualTime: 0, spinDrift: 0));
  final spinDrift = SpinDrift();
  final ticker = _ActualTimeTicker((actualTime) {
    if (!ref.read(isMotionReducedProvider)) {
      spinDrift.advance(actualTime - time.value.actualTime);
    }
    time.value = SceneTime(actualTime: actualTime, spinDrift: spinDrift.value);
  });
  ref.listen(isSceneRunningProvider, fireImmediately: true, (_, isRunning) {
    if (isRunning) {
      ticker.start(from: time.value.actualTime);
    } else {
      ticker.stop();
    }
  });
  ref.onDispose(() {
    ticker.dispose();
    time.dispose();
  });
  return time;
});

/// The seconds that the scene has run, and the spin drift they added.
@immutable
class SceneTime {
  const SceneTime({required this.actualTime, required this.spinDrift});

  final double actualTime;
  final double spinDrift;
}

/// A [Ticker] counts from zero each time it starts; this one goes on from
/// the actual time it starts from.
class _ActualTimeTicker {
  _ActualTimeTicker(this._onTick);

  final void Function(double actualTime) _onTick;
  late final _ticker = Ticker(
    (sinceStart) => _onTick(_startTime + sinceStart.inFractionalSeconds),
  );
  var _startTime = 0.0;

  void start({required double from}) {
    if (_ticker.isActive) return;
    _startTime = from;
    _ticker.start();
  }

  void stop() => _ticker.stop();

  void dispose() => _ticker.dispose();
}

extension _FractionalSeconds on Duration {
  double get inFractionalSeconds =>
      inMicroseconds / Duration.microsecondsPerSecond;
}
