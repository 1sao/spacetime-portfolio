import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../scene/frame_loop.dart';
import '../space/frame_snapshot.dart';

/// Flutter's `PerformanceOverlay` draws nothing on the web, so this counts
/// frame snapshots. It times them in the scene's actual time, so a pause is
/// not a slow frame.
class FpsCounter extends ConsumerStatefulWidget {
  const FpsCounter({super.key});

  @override
  ConsumerState<FpsCounter> createState() => _FpsCounterState();
}

class _FpsCounterState extends ConsumerState<FpsCounter> {
  static const _secondsPerUpdate = 0.5;

  ValueListenable<FrameSnapshot>? _frames;
  double? _lastFrameTime;
  int _framesSinceUpdate = 0;
  double _secondsSinceUpdate = 0;

  int? _fps;

  @override
  void initState() {
    super.initState();
    ref.listenManual(frameSnapshotListenableProvider, fireImmediately: true, (
      _,
      frames,
    ) {
      _frames?.removeListener(_countFrame);
      _frames = frames..addListener(_countFrame);
      _lastFrameTime = null;
    });
  }

  @override
  void dispose() {
    _frames?.removeListener(_countFrame);
    super.dispose();
  }

  void _countFrame() {
    final time = _frames!.value.actualTime;
    final lastTime = _lastFrameTime;
    _lastFrameTime = time;
    // A ticker counts from zero each time it starts, so after a pause the
    // frame loop's first frame has the time of the last frame before it.
    if (lastTime == null || time <= lastTime) return;

    _framesSinceUpdate++;
    _secondsSinceUpdate += time - lastTime;
    if (_secondsSinceUpdate < _secondsPerUpdate) return;
    setState(() => _fps = (_framesSinceUpdate / _secondsSinceUpdate).round());
    _framesSinceUpdate = 0;
    _secondsSinceUpdate = 0;
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Colors.black.withValues(alpha: 0.6),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: DefaultTextStyle.merge(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
        // The hidden text of three digits sets the width, so the box and
        // the text do not move when the value has fewer digits.
        child: Stack(
          alignment: Alignment.centerRight,
          children: [
            const Opacity(opacity: 0, child: Text('000 fps')),
            Text('${_fps ?? '–'} fps'),
          ],
        ),
      ),
    ),
  );
}
