import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../scene/frame_loop.dart';
import '../space/frame_snapshot.dart';

/// The scene's frames per second, for debug builds.
///
/// Flutter's `PerformanceOverlay` draws nothing on the web, so this widget
/// counts the frame snapshots that the frame loop makes. It measures the
/// time between them on the scene's clock, which stands still while the
/// scene does, so a pause is not a slow frame. While the scene stands still,
/// the counter keeps its last value.
class FpsCounter extends ConsumerStatefulWidget {
  const FpsCounter({super.key});

  @override
  ConsumerState<FpsCounter> createState() => _FpsCounterState();
}

class _FpsCounterState extends ConsumerState<FpsCounter> {
  /// The scene time that each value covers, in seconds.
  static const _interval = 0.5;

  ValueListenable<FrameSnapshot>? _frames;

  /// The time of the last snapshot.
  double? _lastTime;

  /// The frames since [_fps] last changed.
  int _frameCount = 0;

  /// The scene time that [_frameCount] frames took, in seconds.
  double _frameTime = 0;

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
      _lastTime = null;
    });
  }

  @override
  void dispose() {
    _frames?.removeListener(_countFrame);
    super.dispose();
  }

  void _countFrame() {
    final time = _frames!.value.time;
    final lastTime = _lastTime;
    _lastTime = time;
    // A navigation change also makes a snapshot, at the same time as the
    // frame before it.
    if (lastTime == null || time <= lastTime) return;

    _frameCount++;
    _frameTime += time - lastTime;
    if (_frameTime < _interval) return;
    setState(() => _fps = (_frameCount / _frameTime).round());
    _frameCount = 0;
    _frameTime = 0;
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
          // All digits have the same width.
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
