// Built and run by `tool/measure_performance.dart`. The query sets `settle`
// and `dwell` in seconds, `segments` (comma-separated, all if absent) and
// `wait=0` (no GPU wait per frame). The app reads the rest, such as
// `lensing`.

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spacetime_portfolio/app.dart';
import 'package:spacetime_portfolio/scene/page_scroll.dart';
import 'package:spacetime_portfolio/scene/render/scene_assets.dart';
import 'package:spacetime_portfolio/scene/scene_running.dart';
import 'package:spacetime_portfolio/scene/softness.dart';
import 'package:web/web.dart' as web;

import 'src/frame_recorder.dart';
import 'src/frame_stats.dart';

/// The shader compiles on the GPU when it first draws.
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

/// Null measures all of them.
final Set<String>? _segments = _query['segments']?.split(',').toSet();

final _isGpuWaitOn = _query['wait'] != '0';

double get _sinceNavigationMs => web.window.performance.now();

Future<void> main() async {
  final container = ProviderContainer();
  final tour = _Tour(container)
    ..reportErrors()
    ..timeFirstFrame();
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

  /// See [StartupStats.dartMs].
  final double _dartMs = _sinceNavigationMs;

  /// See [StartupStats.firstFrameMs]. Null until that frame.
  double? _firstFrameMs;

  /// See [StartupStats.sceneMs].
  double? _sceneMs;

  /// See [StartupStats.downloadedBytes].
  int _downloadedBytesToScene = 0;

  final _recorder = FrameRecorder();

  final List<String> _problems = [];

  /// Why the result is not valid. Empty if it is valid.
  List<String> get problems => [..._problems, ..._recorder.problems];

  /// A WebGL context of one pixel, separate from the app's, that
  /// [_readPixel] reads.
  late final web.WebGL2RenderingContext _readbackContext;

  final _pixel = Uint8List(4).toJS;

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

  void timeFirstFrame() {
    web.window.addEventListener(
      'flutter-first-frame',
      (web.Event _) {
        _firstFrameMs = _sinceNavigationMs;
      }.toJS,
    );
  }

  Future<void> run() async {
    final readbackContext = web.OffscreenCanvas(1, 1).getContext('webgl2');
    if (readbackContext == null) {
      throw StateError('Chrome gave no WebGL2 context for the GPU wait.');
    }
    _readbackContext = readbackContext as web.WebGL2RenderingContext;

    SchedulerBinding.instance.addPersistentFrameCallback((_) {
      _recorder.recordFrame(
        SchedulerBinding.instance.currentSystemFrameTimeStamp,
      );
      // The engine sends each frame to the GPU after the frame's task, so
      // this read waits for the frame before this one.
      if (_isGpuWaitOn) _readPixel();
    });
    _container.listen(isSceneRunningProvider, (_, isRunning) {
      if (!isRunning) _problems.add('The scene stopped during the tour.');
    }, fireImmediately: true);

    await _container.read(sceneAssetsProvider.future);
    await SchedulerBinding.instance.endOfFrame;
    // The engine sends the frame to the GPU in microtasks after the frame,
    // and a timer runs after them. The read then waits for the GPU's work
    // on the first frame after the assets load, such as the shader's
    // compile.
    await Future<void>.delayed(Duration.zero);
    _readPixel();
    if (!web.window.crossOriginIsolated) _sceneMs = _sinceNavigationMs;
    _downloadedBytesToScene = _downloadedBytes;
    await SchedulerBinding.instance.endOfFrames(_warmUpFrames);
    await _measure('Landing');
    await _measureScroll();

    final softness = _container.read(sceneSoftnessProvider);
    softness.value = SceneSoftness.soft;
    await _measure('Landing soft');
  }

  /// Waits for the scene to settle, then measures it, if the query asks for
  /// [segment].
  Future<void> _measure(String segment) async {
    if (!(_segments?.contains(segment) ?? true)) return;
    await Future<void>.delayed(_settle);
    _recorder.startSegment(segment);
    await Future<void>.delayed(_dwell);
    _recorder.stop();
  }

  /// Scrolls from top to bottom at a steady rate.
  Future<void> _measureScroll() async {
    const segment = 'Scroll';
    if (!(_segments?.contains(segment) ?? true)) return;
    final scroll = _container.read(pageScrollControllerProvider);
    final maxScroll = scroll.position.maxScrollExtent;
    _recorder.startSegment(segment);
    final sinceStart = Stopwatch()..start();
    while (sinceStart.elapsed < _dwell) {
      scroll.jumpTo(
        maxScroll * sinceStart.elapsedMicroseconds / _dwell.inMicroseconds,
      );
      await SchedulerBinding.instance.endOfFrame;
    }
    _recorder.stop();
    scroll.jumpTo(0);
  }

  /// A read on its own WebGL context waits for the GPU work that the page's
  /// other contexts sent, so a frame's time includes it. It does not wait
  /// for skwasm on a thread of its own.
  void _readPixel() => _readbackContext.readPixels(
    0,
    0,
    1,
    1,
    web.WebGLRenderingContext.RGBA,
    web.WebGLRenderingContext.UNSIGNED_BYTE,
    _pixel,
  );

  /// Files that a worker downloads are not in the page's list.
  int get _downloadedBytes {
    final performance = web.window.performance;
    return [
      ...performance.getEntriesByType('navigation').toDart,
      ...performance.getEntriesByType('resource').toDart,
    ].fold(
      0,
      (bytes, entry) =>
          bytes + (entry as web.PerformanceResourceTiming).transferSize,
    );
  }

  Map<String, Object?> result() {
    final firstFrameMs = _firstFrameMs;
    return {
      'problems': [
        ...problems,
        if (firstFrameMs == null) 'The engine sent no first-frame event.',
        if (_readbackContext.isContextLost())
          'The context of the GPU wait was lost.',
      ],
      'isWasm': kIsWasm,
      'devicePixelRatio': web.window.devicePixelRatio,
      'width': web.window.innerWidth,
      'height': web.window.innerHeight,
      if (firstFrameMs != null)
        'startup': StartupStats(
          dartMs: _dartMs,
          firstFrameMs: firstFrameMs,
          sceneMs: _sceneMs,
          downloadedBytes: _downloadedBytesToScene,
        ).toJson(),
      'segments': {
        for (final MapEntry(key: segment, value: stats)
            in _recorder.stats.entries)
          segment: stats.toJson(),
      },
    };
  }
}

extension on SchedulerBinding {
  Future<void> endOfFrames(int count) async {
    for (var frame = 0; frame < count; frame++) {
      await endOfFrame;
    }
  }
}
