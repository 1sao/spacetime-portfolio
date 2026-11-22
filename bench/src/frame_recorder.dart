import 'frame_stats.dart';

/// A frame longer than this, in ms, shows that Chrome queued frames ahead
/// of the GPU and then waited for all of them. The queue should stay short
/// while the tour waits for the GPU after each frame, or while Chrome keeps
/// to the display's frame rate (`--vsync`). No frame of the tour comes near
/// this time otherwise.
const _longestValidFrameMs = 500.0;

/// A median shorter than this, in ms, shows the same queue: the queued
/// frames take almost no time.
const _shortestValidMedianMs = 0.2;

/// Collects the time of each frame, by segment of the tour.
///
/// A frame time is the interval from one frame to the next. It belongs to
/// the segment that is current at the frame that ends it.
class FrameRecorder {
  /// The segment that the frames now belong to, or null while frames are
  /// not measured.
  String? _segment;

  /// The time of the last frame.
  Duration? _lastFrame;

  /// The frame times of each segment, in ms, in the order of the tour.
  final Map<String, List<double>> _frameTimesMs = {};

  /// Puts the next frames in [segment]. A segment that starts again adds
  /// its frames to those it already has.
  void startSegment(String segment) {
    _segment = segment;
    _frameTimesMs.putIfAbsent(segment, () => []);
  }

  /// Stops measuring the frames.
  void stop() => _segment = null;

  /// Records a frame at [time], on a clock that all frames share.
  void recordFrame(Duration time) {
    final last = _lastFrame;
    _lastFrame = time;
    final segment = _segment;
    if (segment == null || last == null) return;
    _frameTimesMs[segment]!.add((time - last).inMicroseconds / 1000);
  }

  /// The statistics of each segment that has frames.
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
