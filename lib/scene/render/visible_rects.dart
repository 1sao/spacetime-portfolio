import 'dart:ui';

extension VisibleRects on Rect {
  /// The parts of this rectangle outside all of [hiddenRects], as
  /// rectangles that do not overlap.
  List<Rect> visibleRects(Iterable<Rect> hiddenRects) {
    var parts = [this];
    for (final hidden in hiddenRects) {
      parts = [for (final part in parts) ...part._outside(hidden)];
    }
    return parts;
  }

  /// The full-width bands above and below [hidden], and the two sides
  /// between those bands.
  Iterable<Rect> _outside(Rect hidden) {
    final overlap = hidden.intersect(this);
    if (overlap.isEmpty) return [this];
    return [
      Rect.fromLTRB(left, top, right, overlap.top),
      Rect.fromLTRB(left, overlap.bottom, right, bottom),
      Rect.fromLTRB(left, overlap.top, overlap.left, overlap.bottom),
      Rect.fromLTRB(overlap.right, overlap.top, right, overlap.bottom),
    ].where((part) => !part.isEmpty);
  }
}
