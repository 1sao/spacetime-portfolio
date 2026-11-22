/// The start of the tour's console line that holds its result, as JSON.
const resultPrefix = 'PERF_RESULT ';

/// One frame at 120 Hz, in ms. A frame that takes longer misses a refresh
/// of a 120 Hz screen.
const frameBudgetMs = 1000 / 120;

/// The frame times of one segment of the tour, such as the Landing at rest.
class SegmentStats {
  const SegmentStats({
    required this.frames,
    required this.meanMs,
    required this.medianMs,
    required this.p90Ms,
    required this.worstMs,
    required this.slowFrames,
  });

  /// The statistics of [frameTimesMs], which must not be empty.
  factory SegmentStats.of(Iterable<double> frameTimesMs) {
    final sorted = frameTimesMs.toList()..sort();
    if (sorted.isEmpty) throw ArgumentError('A segment has no frames.');
    return SegmentStats(
      frames: sorted.length,
      meanMs: sorted.mean,
      medianMs: sorted.median,
      p90Ms: sorted.percentile(0.9),
      worstMs: sorted.last,
      slowFrames: sorted.where((ms) => ms > frameBudgetMs).length,
    );
  }

  factory SegmentStats.fromJson(Map<String, Object?> json) => SegmentStats(
    frames: json['frames']! as int,
    meanMs: (json['meanMs']! as num).toDouble(),
    medianMs: (json['medianMs']! as num).toDouble(),
    p90Ms: (json['p90Ms']! as num).toDouble(),
    worstMs: (json['worstMs']! as num).toDouble(),
    slowFrames: json['slowFrames']! as int,
  );

  /// The number of frame times: the intervals from one frame to the next.
  final int frames;

  /// The mean frame time, in ms: the sum of the frame times divided by
  /// [frames].
  final double meanMs;

  /// Half of the frames take this time or less, in ms.
  final double medianMs;

  /// 90 % of the frames take this time or less, in ms.
  final double p90Ms;

  /// The longest frame, in ms.
  final double worstMs;

  /// The frames that take longer than [frameBudgetMs].
  final int slowFrames;

  Map<String, Object?> toJson() => {
    'frames': frames,
    'meanMs': meanMs,
    'medianMs': medianMs,
    'p90Ms': p90Ms,
    'worstMs': worstMs,
    'slowFrames': slowFrames,
  };
}

/// The times of the app's start-up, in ms since the navigation started,
/// and the bytes that the page downloaded until the scene was drawn.
class StartupStats {
  const StartupStats({
    required this.dartMs,
    required this.firstFrameMs,
    required this.sceneMs,
    required this.downloadedBytes,
  });

  factory StartupStats.fromJson(Map<String, Object?> json) => StartupStats(
    dartMs: (json['dartMs']! as num).toDouble(),
    firstFrameMs: (json['firstFrameMs']! as num).toDouble(),
    sceneMs: (json['sceneMs'] as num?)?.toDouble(),
    downloadedBytes: json['downloadedBytes']! as int,
  );

  /// When the app's `main` starts: the engine and the app's code have
  /// loaded.
  final double dartMs;

  /// When the browser shows the app's first frame.
  final double firstFrameMs;

  /// When the GPU has drawn the first frame of the scene. Null when skwasm
  /// draws on a thread of its own, because the tour cannot wait for that
  /// thread.
  final double? sceneMs;

  /// The bytes that the page downloaded until the scene was drawn, headers
  /// included. Files that a worker downloads are not counted.
  final int downloadedBytes;

  Map<String, Object?> toJson() => {
    'dartMs': dartMs,
    'firstFrameMs': firstFrameMs,
    'sceneMs': sceneMs,
    'downloadedBytes': downloadedBytes,
  };
}

extension Statistics on List<double> {
  /// The sum of the values divided by their count. The list must not be
  /// empty.
  double get mean => reduce((a, b) => a + b) / length;

  /// The smallest value that at least [fraction] of the values are less
  /// than or equal to. The list must be sorted and not empty.
  double percentile(double fraction) {
    final rank = (fraction * length).ceil();
    return this[(rank - 1).clamp(0, length - 1)];
  }

  /// The percentile at one half. For an even count, it is the lower of the
  /// two middle values.
  double get median => percentile(0.5);
}
