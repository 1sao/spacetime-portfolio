// The performance tour: the real app at rest, sharp and soft, on the
// Landing and with the hole up close. Built and run by
// `tool/measure_performance.dart`.
//
// The URL's query sets the tour: `settle` and `dwell` in seconds, and
// `segments`, the names of the segments to measure, separated by commas
// (all if it is left out). The app reads the rest of the query, such as
// `lensing`.

import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homepage_v2/app.dart';
import 'package:homepage_v2/scene/frame_loop.dart';
import 'package:homepage_v2/scene/scene_running.dart';
import 'package:homepage_v2/scene/scene_view.dart';
import 'package:homepage_v2/space/camera.dart';
import 'package:homepage_v2/space/direction_and_distance.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:web/web.dart' as web;

import 'src/frame_recorder.dart';
import 'src/frame_stats.dart';

/// The frames to wait for after the shader's assets load. The shader
/// compiles on the GPU when it first draws.
const _warmUpFrames = 30;

final _query = Uri.base.queryParameters;

Duration _seconds(String name, double byDefault) => Duration(
  milliseconds: ((double.tryParse(_query[name] ?? '') ?? byDefault) * 1000)
      .round(),
);

/// The time after each change of the scene until the segment starts.
final _settle = _seconds('settle', 1);

/// The time that each segment measures.
final _dwell = _seconds('dwell', 2);

/// The segments to measure, or null for all of them.
final Set<String>? _segments = _query['segments']?.split(',').toSet();

/// The camera of the Credits section, with the hole in the middle of the
/// screen: the scene at its most costly.
final _holeUpClose = Camera(
  target: Vector3.zero(),
  fromTarget: const DirectionAndDistance(
    azimuth: 0.55,
    elevation: 0.13,
    distance: 15,
  ),
);

Future<void> main() async {
  final container = ProviderContainer();
  final tour = _Tour(container)..reportErrors();
  runApp(UncontrolledProviderScope(container: container, child: const App()));

  Map<String, Object?> result;
  try {
    await tour.run();
    result = tour.result();
  } catch (error, stackTrace) {
    result = {
      'problems': [...tour.problems, '$error\n$stackTrace'],
    };
  }
  // ignore: avoid_print, the driver reads the console.
  print('$resultPrefix${jsonEncode(result)}');
}

class _Tour {
  _Tour(this._container);

  final ProviderContainer _container;

  final _recorder = FrameRecorder();

  /// Errors and other problems during the tour, apart from those of the
  /// frame times.
  final List<String> _problems = [];

  /// Why the result is not valid. Empty if it is valid.
  List<String> get problems => [..._problems, ..._recorder.problems];

  /// A pixel drawn and read after each frame to force the frame.
  final Picture _pixel = () {
    final recorder = PictureRecorder();
    Canvas(recorder).drawRect(const Rect.fromLTWH(0, 0, 1, 1), Paint());
    return recorder.endRecording();
  }();

  /// Adds each error of the app to [problems].
  void reportErrors() {
    final flutterOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      _problems.add('Flutter error: ${details.exceptionAsString()}');
      flutterOnError?.call(details);
    };
    final platformOnError = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, stackTrace) {
      _problems.add('Error: $error');
      return platformOnError?.call(error, stackTrace) ?? false;
    };
  }

  Future<void> run() async {
    SchedulerBinding.instance.addPersistentFrameCallback((_) {
      _recorder.recordFrame(
        SchedulerBinding.instance.currentSystemFrameTimeStamp,
      );
      _waitForGpu();
    });
    _container.listen(isSceneRunningProvider, (_, isRunning) {
      if (!isRunning) _problems.add('The scene stopped during the tour.');
    }, fireImmediately: true);

    await _container.read(sceneAssetsProvider.future);
    await SchedulerBinding.instance.endOfFrames(_warmUpFrames);
    await _measure('Landing');

    final softness = _container.read(sceneSoftnessProvider);
    softness.value = SceneSoftness.soft;
    await _measure('Landing soft');

    _container.read(sceneCameraProvider).value = _holeUpClose;
    softness.value = SceneSoftness.sharp;
    await _measure('Hole up close');
    softness.value = SceneSoftness.soft;
    await _measure('Hole up close soft');
  }

  /// Waits for the scene to settle, then measures it as [segment], if the
  /// query asks for it.
  Future<void> _measure(String segment) async {
    if (!(_segments?.contains(segment) ?? true)) return;
    await Future<void>.delayed(_settle);
    _recorder.startSegment(segment);
    await Future<void>.delayed(_dwell);
    _recorder.stop();
  }

  /// After each frame, reads one pixel back from the GPU. The read waits
  /// until the GPU has done the work queued before it, so frames cannot
  /// queue ahead of the GPU, and a frame's time includes its GPU work.
  void _waitForGpu() {
    Timer.run(() => _pixel.toImageSync(1, 1).dispose());
  }

  Map<String, Object?> result() => {
    'problems': problems,
    'devicePixelRatio': web.window.devicePixelRatio,
    'width': web.window.innerWidth,
    'height': web.window.innerHeight,
    'segments': {
      for (final MapEntry(key: segment, value: stats)
          in _recorder.stats.entries)
        segment: stats.toJson(),
    },
  };
}

extension on SchedulerBinding {
  /// Completes when [count] more frames have ended.
  Future<void> endOfFrames(int count) async {
    for (var frame = 0; frame < count; frame++) {
      await endOfFrame;
    }
  }
}
