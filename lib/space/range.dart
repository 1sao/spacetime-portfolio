/// The numbers from [start] to [end].
class Range {
  const Range(this.start, this.end) : assert(start <= end);

  final double start;
  final double end;

  double get length => end - start;

  double at(double fraction) => start + length * fraction;

  /// Clamped to 0 to 1. 0 in an interval of no length.
  double fractionAt(double value) =>
      length == 0 ? 0 : ((value - start) / length).clamp(0.0, 1.0);

  @override
  bool operator ==(Object other) =>
      other is Range && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => '[$start, $end]';
}
