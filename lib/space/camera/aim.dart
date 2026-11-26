import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

import 'camera.dart';
import 'direction_and_distance.dart';

/// Where a level camera that looks at a target from [distance] must be, as
/// seen from the target, so that a second point shows at [offset] from the
/// target: right and up, in focal lengths. [fromSecondPoint] goes from the
/// second point to the target.
DirectionAndDistance levelViewpointShowing(
  Vector2 offset, {
  required Vector3 fromSecondPoint,
  required double distance,
}) {
  // In the camera's axes (right, up, forward): the direction to the second
  // point, and its distance along it.
  final toSecondPoint = Vector3(offset.x, offset.y, 1).normalized();
  final cosine = toSecondPoint.z;
  final sineSquared = 1 - cosine * cosine;
  final rangeSquared =
      fromSecondPoint.length2 - distance * distance * sineSquared;
  assert(rangeSquared >= 0, 'No camera shows the point at that offset.');
  final range = distance * cosine + math.sqrt(rangeSquared);
  // The target seen from the second point, in the camera's axes. The
  // camera's turn makes it fromSecondPoint.
  final seen = Vector3(0, 0, distance) - toSecondPoint * range;
  final (seenRight, seenUp, seenForward) = (seen.x, seen.y, seen.z);
  // A level camera at elevation e has up.y = cos e and forward.y = sin e:
  // seenUp·cos e + seenForward·sin e = fromSecondPoint.y.
  final upAndForward = math.sqrt(seenUp * seenUp + seenForward * seenForward);
  final middle = math.atan2(seenForward, seenUp);
  final spread = math.acos((fromSecondPoint.y / upAndForward).clamp(-1.0, 1.0));
  // The other answer looks nearly straight up or down.
  final elevation = [
    wrapAngle(middle + spread),
    wrapAngle(middle - spread),
  ].reduce((a, b) => a.abs() < b.abs() ? a : b);
  assert(
    elevation.abs() < maxElevation,
    'The offset $offset needs a camera elevation of $elevation, past the '
    'clamp.',
  );
  // From above, the vector is seenRight along the camera's right and ahead
  // along its forward, so its azimuth adds their angle.
  final ahead =
      seenForward * math.cos(elevation) - seenUp * math.sin(elevation);
  final azimuth =
      DirectionAndDistance.of(fromSecondPoint).azimuth -
      math.atan2(-seenRight, ahead);
  final forward = DirectionAndDistance(
    azimuth: azimuth,
    elevation: elevation,
    distance: 1,
  ).toVector3();
  return DirectionAndDistance.of(forward * -distance);
}
