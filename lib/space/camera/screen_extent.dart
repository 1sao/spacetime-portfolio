import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

import 'camera.dart';

typedef Sphere = ({Vector3 center, double radius});

extension ScreenExtent on Camera {
  /// The highest and lowest pixel rows that [spheres] reach on [screen].
  ({double top, double bottom}) verticalExtentOf(
    Iterable<Sphere> spheres,
    Screen screen,
  ) {
    var (top, bottom) = (double.infinity, double.negativeInfinity);
    for (final (:center, :radius) in spheres) {
      final pixel = project(center, screen)!;
      final pixelRadius = projectedRadius(center, radius);
      top = math.min(top, pixel.y - pixelRadius);
      bottom = math.max(bottom, pixel.y + pixelRadius);
    }
    return (top: top, bottom: bottom);
  }
}
