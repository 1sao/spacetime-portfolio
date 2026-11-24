/// The start of the tour's console line that holds its result, as JSON.
const resultPrefix = 'PERF_RESULT ';

/// A frame that takes longer misses a refresh of a 120 Hz screen.
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

  /// The number of intervals from one frame to the next.
  final int frames;

  final double meanMs;
  final double medianMs;
  final double p90Ms;
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

  /// When the app's `main` starts.
  final double dartMs;

  final double firstFrameMs;

  /// When the GPU has drawn the scene's first frame. Null when skwasm draws
  /// on a thread of its own, which the tour cannot wait for.
  final double? sceneMs;

  /// Downloaded until the scene was drawn, headers included; a worker's
  /// files are not counted.
  final int downloadedBytes;

  Map<String, Object?> toJson() => {
    'dartMs': dartMs,
    'firstFrameMs': firstFrameMs,
    'sceneMs': sceneMs,
    'downloadedBytes': downloadedBytes,
  };
}

extension Statistics on List<double> {
  double get mean => reduce((a, b) => a + b) / length;

  /// The smallest value that at least [fraction] of the values are less
  /// than or equal to. The list must be sorted and not empty.
  double percentile(double fraction) {
    final rank = (fraction * length).ceil();
    return this[(rank - 1).clamp(0, length - 1)];
  }

  /// For an even count, the lower of the two middle values.
  double get median => percentile(0.5);
}
