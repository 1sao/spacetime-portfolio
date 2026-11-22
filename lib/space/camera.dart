import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

import 'direction_and_distance.dart';

/// A camera that looks at a point, its target.
///
/// The camera's position is given as a direction and a distance from the
/// target. From them and [roll], the camera calculates its position as a
/// point and its forward, right and up directions, which the shader and
/// the projection read.
class Camera {
  /// The camera clamps the elevation of [fromTarget] to ±[maxElevation].
  /// [screenPoint] is where [target] lands on the screen: the middle by
  /// default.
  factory Camera({
    required Vector3 target,
    required DirectionAndDistance fromTarget,
    required double focalLength,
    Vector2? screenPoint,
    double roll = 0,
  }) {
    assert(fromTarget.distance > 0, 'The camera is at its target.');
    assert(focalLength > 0, 'The focal length is $focalLength.');
    final clamped = DirectionAndDistance(
      azimuth: fromTarget.azimuth,
      elevation: fromTarget.elevation.clamp(-maxElevation, maxElevation),
      distance: fromTarget.distance,
    );
    final offset = clamped.toVector3();
    final forward = -offset.normalized();
    // The directions of the camera that does not roll.
    final levelRight = forward.cross(Vector3(0, 1, 0)).normalized();
    final levelUp = levelRight.cross(forward);
    final (cos, sin) = (math.cos(roll), math.sin(roll));
    return Camera._(
      target: target,
      fromTarget: clamped,
      focalLength: focalLength,
      screenPoint: screenPoint ?? Vector2(0.5, 0.5),
      roll: roll,
      position: target + offset,
      forward: forward,
      right: levelRight * cos + levelUp * sin,
      up: levelUp * cos - levelRight * sin,
    );
  }

  const Camera._({
    required this.target,
    required this.fromTarget,
    required this.focalLength,
    required this.screenPoint,
    required this.roll,
    required this.position,
    required this.forward,
    required this.right,
    required this.up,
  });

  /// The point that the camera looks at, in world units.
  final Vector3 target;

  /// Where [target] lands on the screen, as fractions of the screen's
  /// width and height from its top left: (0.5, 0.5) is the middle.
  ///
  /// The camera still looks at [target]; the picture moves so that
  /// [target] lands at this point.
  final Vector2 screenPoint;

  /// How far the camera zooms in, in logical pixels: a point that is s
  /// units to the side for each unit ahead of the camera lands
  /// s × [focalLength] pixels from [targetPixel].
  final double focalLength;

  /// The angle in rad by which the camera turns about [forward],
  /// counterclockwise as seen from behind the camera. The picture turns
  /// clockwise by the same angle: at π/2, what is to the left of the
  /// target shows above it.
  final double roll;

  /// The direction and the distance from [target] to the camera. The
  /// elevation stays within ±[maxElevation].
  final DirectionAndDistance fromTarget;

  /// Where the camera is, in world units.
  final Vector3 position;

  /// The direction the camera looks in, of length 1.
  final Vector3 forward;

  /// The direction to the right of the view, of length 1.
  ///
  /// A camera on the +z axis looking at the origin, with no roll, seen
  /// from just behind it:
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

  /// The direction to the top of the view, of length 1, at right angles
  /// to [forward] and [right].
  final Vector3 up;

  /// The direction of the ray from the camera through [pixel] of [screen],
  /// of length 1. It is the same formula as `main()` in
  /// `shaders/scene.frag`, so the ray goes where the shader's ray goes.
  Vector3 rayThrough(Vector2 pixel, Screen screen) {
    final slope = (pixel - targetPixel(screen)) / focalLength;
    return (forward + right * slope.x - up * slope.y).normalized();
  }

  /// Where [target] lands in [screen], in pixels from its top left.
  Vector2 targetPixel(Screen screen) =>
      Vector2(screenPoint.x * screen.width, screenPoint.y * screen.height);

  /// Where [point] lands in [screen], in pixels from its top left, or null
  /// if it is behind the camera.
  Vector2? project(Vector3 point, Screen screen) {
    final offset = point - position;
    final depth = offset.dot(forward);
    if (depth <= 0) return null;
    final scale = focalLength / depth;
    return targetPixel(screen) +
        Vector2(offset.dot(right) * scale, -offset.dot(up) * scale);
  }
}

/// The screen a [Camera] projects onto, in logical pixels.
class Screen {
  const Screen({required this.width, required this.height});

  final double width;
  final double height;
}

/// The maximum angle up or down from the target to the camera, in rad
/// (approximately 83°). When the camera looks straight up or down, it has
/// no horizontal right direction. Past that angle, the view turns upside
/// down.
const maxElevation = 1.45;
