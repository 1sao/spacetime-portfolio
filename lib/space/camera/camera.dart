import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

import 'direction_and_distance.dart';

/// A camera that looks at a point, its target.
class Camera {
  /// The camera clamps the elevation of [fromTarget] to ±[maxElevation].
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

  factory Camera.lookingAt(
    Vector3 target, {
    required Vector3 from,
    required double focalLength,
    Vector2? screenPoint,
    double roll = 0,
  }) => Camera(
    target: target,
    fromTarget: DirectionAndDistance.of(from - target),
    focalLength: focalLength,
    screenPoint: screenPoint,
    roll: roll,
  );

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

  final Vector3 target;

  /// Where [target] lands on the screen, as fractions of the screen's
  /// width and height from its top left. The camera still looks at
  /// [target]: the picture moves, it does not turn.
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

  final DirectionAndDistance fromTarget;
  final Vector3 position;
  final Vector3 forward;
  final Vector3 right;
  final Vector3 up;

  /// The same formula as `main()` in `shaders/scene.frag`, so the ray goes
  /// where the shader's ray goes.
  Vector3 rayThrough(Vector2 pixel, Screen screen) {
    final slope = (pixel - targetPixel(screen)) / focalLength;
    return (forward + right * slope.x - up * slope.y).normalized();
  }

  Vector2 targetPixel(Screen screen) =>
      Vector2(screenPoint.x * screen.width, screenPoint.y * screen.height);

  /// Null if [point] is behind the camera.
  Vector2? project(Vector3 point, Screen screen) {
    final offset = point - position;
    final depth = offset.dot(forward);
    if (depth <= 0) return null;
    final scale = focalLength / depth;
    return targetPixel(screen) +
        Vector2(offset.dot(right) * scale, -offset.dot(up) * scale);
  }

  /// A sphere away from the middle of the view looks a little larger.
  double projectedRadius(Vector3 center, double radius) =>
      radius * focalLength / (center - position).dot(forward);
}

/// The screen a [Camera] projects onto, in logical pixels.
class Screen {
  const Screen({required this.width, required this.height});

  final double width;
  final double height;
}

/// About 83°. A camera that looks straight up or down has no horizontal
/// right direction; past this angle the view turns upside down.
const maxElevation = 1.45;
