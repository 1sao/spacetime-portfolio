import 'package:vector_math/vector_math_64.dart';

import '../camera/camera.dart';

/// Where a station shows its camera's target, as [Camera.screenPoint], at
/// each scroll offset.
sealed class ScreenPoint {
  factory ScreenPoint.fixed(Vector2 point) = _FixedScreenPoint;

  /// At [x], and as high as a point that reaches the top of the view at
  /// scroll offset [scrollOffsetAtTop]: it scrolls with the page, but stays
  /// on the screen.
  const factory ScreenPoint.onPage({
    required double x,
    required double scrollOffsetAtTop,
    required double screenHeight,
  }) = _ScreenPointOnPage;

  Vector2 at(double scrollOffset);
}

class _FixedScreenPoint implements ScreenPoint {
  _FixedScreenPoint(this.point);

  final Vector2 point;

  @override
  Vector2 at(double scrollOffset) => point;
}

class _ScreenPointOnPage implements ScreenPoint {
  const _ScreenPointOnPage({
    required this.x,
    required this.scrollOffsetAtTop,
    required this.screenHeight,
  });

  final double x;
  final double scrollOffsetAtTop;
  final double screenHeight;

  // A move mixes the screen points of its two stations, so a point far off
  // the screen would sweep the picture across it.
  @override
  Vector2 at(double scrollOffset) => Vector2(
    x,
    ((scrollOffsetAtTop - scrollOffset) / screenHeight).clamp(0.0, 1.0),
  );
}
