import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

import 'direction_and_distance.dart';

/// A camera that looks at a point, its target, upright: it never rolls.
///
/// The camera's position is given as a direction and a distance from the
/// target. From them, the camera calculates its position as a point and
/// its forward, right and up directions, which the shader and the
/// projection read.
class Camera {
  /// The camera clamps the elevation of [fromTarget] to ±[maxElevation].
  factory Camera({
    required Vector3 target,
    required DirectionAndDistance fromTarget,
  }) {
    assert(fromTarget.distance > 0, 'The camera is at its target.');
    final clamped = DirectionAndDistance(
      azimuth: fromTarget.azimuth,
      elevation: fromTarget.elevation.clamp(-maxElevation, maxElevation),
      distance: fromTarget.distance,
    );
    final offset = clamped.toVector3();
    final forward = -offset.normalized();
    final right = forward.cross(Vector3(0, 1, 0)).normalized();
    return Camera._(
      target: target,
      fromTarget: clamped,
      position: target + offset,
      forward: forward,
      right: right,
      up: right.cross(forward),
    );
  }

  const Camera._({
    required this.target,
    required this.fromTarget,
    required this.position,
    required this.forward,
    required this.right,
    required this.up,
  });

  /// The point that the camera looks at, in world units.
  final Vector3 target;

  /// The direction and the distance from [target] to the camera. The
  /// elevation stays within ±[maxElevation].
  final DirectionAndDistance fromTarget;

  /// Where the camera is, in world units.
  final Vector3 position;

  /// The direction the camera looks in, of length 1.
  final Vector3 forward;

  /// The direction to the right of the view, of length 1.
  ///
  /// It is [forward] × world y, which keeps it level. A camera on the +z
  /// axis looking at the origin, seen from just behind it:
  ///
  /// ```text
  ///            +y  world up
  ///             ^
  ///             |    -z  forward, into the screen
  ///             |   /
  ///             |  /
  ///             | /
  ///   camera    o--------> +x  right
  /// ```
  final Vector3 right;

  /// The direction to the top of the view, of length 1: world y, tilted
  /// with [forward] so the two stay at right angles.
  final Vector3 up;

  /// The direction of the ray from the camera through [pixel] of [screen],
  /// of length 1. It is the same formula as `main()` in
  /// `shaders/scene.frag`, so the ray goes where the shader's ray goes.
  Vector3 rayThrough(Vector2 pixel, Screen screen) {
    final slopeX = (pixel.x - screen.width / 2) / screen.focal;
    final slopeY = (pixel.y - screen.height / 2) / screen.focal;
    return (forward + right * slopeX - up * slopeY).normalized();
  }

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

/// The maximum angle up or down from the target to the camera, in rad
/// (approximately 83°). When the camera looks straight up or down, it has
/// no horizontal right direction. Past that angle, the view turns upside
/// down.
const maxElevation = 1.45;

/// The angle that the shorter side of the screen spans, in rad.
final fieldOfView = radians(82);
