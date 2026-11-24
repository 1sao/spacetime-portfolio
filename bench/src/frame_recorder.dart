import 'frame_stats.dart';

/// A frame this long shows that Chrome queued frames ahead of the GPU and
/// then waited for all of them. No frame of the tour comes near it otherwise.
const _longestValidFrameMs = 500.0;

/// A median shorter than this, in ms, shows the same queue: the queued
/// frames take almost no time.
const _shortestValidMedianMs = 0.2;

/// Collects the time of each frame, by segment of the tour.
///
/// A frame time is the interval from one frame to the next. It belongs to
/// the segment that is current at the frame that ends it.
class FrameRecorder {
  /// Null while frames are not measured.
  String? _segment;

  Duration? _lastFrameTime;
  final Map<String, List<double>> _frameTimesMs = {};

  /// A segment that starts again adds its frames to those it already has.
  void startSegment(String segment) {
    _segment = segment;
    _frameTimesMs.putIfAbsent(segment, () => []);
  }

  void stop() => _segment = null;

  /// Records a frame at [time], on a clock that all frames share.
  void recordFrame(Duration time) {
    final last = _lastFrameTime;
    _lastFrameTime = time;
    final segment = _segment;
    if (segment == null || last == null) return;
    _frameTimesMs[segment]!.add((time - last).inMicroseconds / 1000);
  }

  Map<String, SegmentStats> get stats => {
    for (final MapEntry(key: segment, value: times) in _frameTimesMs.entries)
      if (times.isNotEmpty) segment: SegmentStats.of(times),
  };

  /// Why the frame times are not valid. Empty if they are valid.
  List<String> get problems => [
    for (final MapEntry(key: segment, value: times) in _frameTimesMs.entries)
      if (times.isEmpty) 'No frames in "$segment".',
    for (final MapEntry(key: segment, value: stats) in stats.entries) ...[
      if (stats.worstMs > _longestValidFrameMs)
        'A frame of ${stats.worstMs} ms in "$segment": queued frames?',
      if (stats.medianMs < _shortestValidMedianMs)
        'A median of ${stats.medianMs} ms in "$segment": queued frames?',
    ],
  ];
}
