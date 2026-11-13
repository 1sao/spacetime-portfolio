// The performance tour: the real app, moved through its locations by URL
// changes. Built and run by `tool/measure_performance.dart`.

import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:homepage_v2/app.dart';
import 'package:homepage_v2/navigation/map_location.dart';
import 'package:homepage_v2/navigation/map_navigation_state.dart';
import 'package:homepage_v2/navigation/navigation.dart';
import 'package:homepage_v2/providers.dart';
import 'package:homepage_v2/router.dart';
import 'package:homepage_v2/scene/scene_running.dart';
import 'package:homepage_v2/scene/scene_view.dart';
import 'package:web/web.dart' as web;

import 'src/frame_recorder.dart';
import 'src/frame_stats.dart';

/// The frames to wait for after the shader's program loads. The shader
/// compiles on the GPU when it first draws.
const _warmUpFrames = 30;

/// The time after [_warmUpFrames] until the first measured frame.
const _settle = Duration(seconds: 2);

/// The time at rest at each location.
const _dwell = Duration(seconds: 2);

/// The longest time that a flight can take before the tour stops.
const _flightTimeout = Duration(seconds: 10);

Future<void> main() async {
  usePathUrlStrategy();
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

  /// The location that the tour is at.
  MapLocation _location = const OverviewLocation();

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

    await _container.read(sceneProgramProvider.future);
    await SchedulerBinding.instance.endOfFrames(_warmUpFrames);
    await Future<void>.delayed(_settle);
    await _rest();

    final categories = _container.read(contentProvider);
    for (final category in categories) {
      final categoryLocation = CategoryLocation(category);
      await _goTo(categoryLocation);
      if (category.messages.isNotEmpty) {
        await _goTo(MessageLocation(category, category.messages.first));
        await _goBack(to: categoryLocation);
      }
      await _goBack(to: const OverviewLocation());
    }
    // A flight from one body to another, without the overview between.
    if (categories.length > 1) {
      await _goTo(CategoryLocation(categories[0]));
      await _goTo(CategoryLocation(categories[1]));
    }
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

  Future<void> _rest() async {
    _recorder.startSegment('rest ${_location.path}');
    await Future<void>.delayed(_dwell);
  }

  /// Goes to [location] as a click does, then rests there.
  Future<void> _goTo(MapLocation location) => _fly(
    to: location,
    start: () => _container.read(routerProvider).go(location.path),
  );

  /// Goes back in the browser's history, then rests at [to].
  Future<void> _goBack({required MapLocation to}) =>
      _fly(to: to, start: () => web.window.history.back());

  Future<void> _fly({
    required MapLocation to,
    required void Function() start,
  }) async {
    _recorder.startSegment('fly ${_location.path} -> ${to.path}');
    final arrival = _arrivalAt(to);
    start();
    await arrival;
    _location = to;
    await _rest();
  }

  /// Completes when the camera comes to rest at [location].
  Future<void> _arrivalAt(MapLocation location) {
    final arrived = Completer<void>();
    final subscription = _container.listen(navigationProvider, (_, state) {
      if (state is AtRest && state.location == location) {
        if (!arrived.isCompleted) arrived.complete();
      }
    });
    return arrived.future
        .timeout(
          _flightTimeout,
          onTimeout: () => throw StateError(
            'The flight from ${_location.path} to ${location.path} did not '
            'arrive.',
          ),
        )
        .whenComplete(subscription.close);
  }
}

extension on SchedulerBinding {
  /// Completes when [count] more frames have ended.
  Future<void> endOfFrames(int count) async {
    for (var frame = 0; frame < count; frame++) {
      await endOfFrame;
    }
  }
}
