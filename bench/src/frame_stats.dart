/// The start of the tour's console line that holds its result, as JSON.
const resultPrefix = 'PERF_RESULT ';

/// One frame at 120 Hz, in ms. A frame that takes longer misses a refresh
/// of a 120 Hz screen.
const frameBudgetMs = 1000 / 120;

/// The frame times of one segment of the tour, such as a flight or a dwell.
class SegmentStats {
  const SegmentStats({
    required this.frames,
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
      medianMs: sorted.median,
      p90Ms: sorted.percentile(0.9),
      worstMs: sorted.last,
      slowFrames: sorted.where((ms) => ms > frameBudgetMs).length,
    );
  }

  factory SegmentStats.fromJson(Map<String, Object?> json) => SegmentStats(
    frames: json['frames']! as int,
    medianMs: (json['medianMs']! as num).toDouble(),
    p90Ms: (json['p90Ms']! as num).toDouble(),
    worstMs: (json['worstMs']! as num).toDouble(),
    slowFrames: json['slowFrames']! as int,
  );

  /// The number of frame times: the intervals from one frame to the next.
  final int frames;

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
    'medianMs': medianMs,
    'p90Ms': p90Ms,
    'worstMs': worstMs,
    'slowFrames': slowFrames,
  };
}

extension NearestRank on List<double> {
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
