import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

/// A camera looking from a position at a target, upright: it never rolls.
///
/// Caution: its vectors are mutable, and a camera is shared by everything
/// that reads it, so they shouldn't be changed in place.
class Camera {
  factory Camera({required Vector3 position, required Vector3 target}) {
    final toTarget = target - position;
    assert(toTarget.length2 > 0, 'The camera is at its target.');
    final forward = toTarget.normalized();
    final level = Vector3(0, 1, 0).cross(forward);
    assert(level.length2 > 0, 'The camera looks straight up or down.');
    final right = level.normalized();
    return Camera._(
      position: position,
      forward: forward,
      right: right,
      up: forward.cross(right),
    );
  }

  const Camera._({
    required this.position,
    required this.forward,
    required this.right,
    required this.up,
  });

  /// Where the camera is, in world units.
  final Vector3 position;

  /// The direction the camera looks in, of length 1.
  final Vector3 forward;

  /// The direction to the right of the view, of length 1.
  ///
  /// It is world y × [forward], which keeps it level. A camera at the origin
  /// looking along +z, seen from just behind it:
  ///
  /// ```text
  ///            +y  world up
  ///             ^
  ///             |    +z  forward, into the screen
  ///             |   /
  ///             |  /
  ///             | /
  ///   camera    o--------> +x  right
  /// ```
  ///
  /// Whichever way the camera looks, seen from above with +x to the east
  /// and +z to the north, [right] is a quarter turn clockwise from it, as
  /// east is from north.
  final Vector3 right;

  /// The direction to the top of the view, of length 1: world y, tilted
  /// with [forward] so the two stay at right angles.
  final Vector3 up;

  /// Where [point] lands in [screen], in pixels from its top left, or null
  /// if it is behind the camera.
  Vector2? project(Vector3 point, Screen screen) {
    final offset = point - position;
    final depth = offset.dot(forward);
    if (depth <= 0) return null;
    final scale = screen.focal / depth;
    return Vector2(
      screen.width / 2 + offset.dot(right) * scale,
      screen.height / 2 - offset.dot(up) * scale,
    );
  }
}

/// The screen a [Camera] projects onto, in logical pixels.
class Screen {
  const Screen({required this.width, required this.height});

  final double width;
  final double height;

  /// Pixels per unit of slope off the view axis, so the shorter side spans
  /// [fieldOfView]. A ray's slope is how far it strays from the axis for
  /// each unit it travels forward: the tangent of its angle off the axis.
  double get focal => math.min(width, height) / 2 / math.tan(fieldOfView / 2);
}

/// The angle that the shorter side of the screen spans, in rad. For
/// example, from a camera 30 units from the central body, an orbit with a
/// radius of 13.5 units fills approximately half of the shorter side.
final fieldOfView = radians(82);
