import 'package:vector_math/vector_math_64.dart';

import '../camera/camera.dart';
import '../camera/direction_and_distance.dart';
import '../camera/turns.dart';

/// How the camera's position travels from one station to the next, and
/// what it keeps in view on the way.
sealed class CameraRoute {
  /// Around the hole, by distance, azimuth and elevation.
  const factory CameraRoute.aroundTheHole() = _AroundTheHoleRoute;

  Vector3 get keptInView;

  /// The position at [fraction] of the way from [from] to [to]. The
  /// azimuth turns the way nearest to [turnNear], in rad.
  Vector3 positionAt(
    Vector3 from,
    Vector3 to,
    double fraction, {
    double turnNear = 0,
  });
}

class _AroundTheHoleRoute implements CameraRoute {
  const _AroundTheHoleRoute();

  @override
  Vector3 positionAt(
    Vector3 from,
    Vector3 to,
    double fraction, {
    double turnNear = 0,
  }) => DirectionAndDistance.between(
    DirectionAndDistance.of(from),
    DirectionAndDistance.of(to),
    fraction,
    turnNear: turnNear,
  ).toVector3();

  @override
  Vector3 get keptInView => Vector3.zero();
}

/// Mixes [from] and [to] at [fraction] along [route], and keeps the route's
/// [CameraRoute.keptInView] in view. [fromAtDeparture] and [toAtDeparture]
/// are the two stations' cameras where the move starts.
Camera mixCameras(
  Camera from,
  Camera to,
  double fraction,
  CameraRoute route, {
  required Camera fromAtDeparture,
  required Camera toAtDeparture,
}) {
  final keptInView = route.keptInView;
  // The bodies move during a move, so a turn of about half a circle could
  // change sides midway. The cameras at the departure fix the side.
  final position = route.positionAt(
    from.position,
    to.position,
    fraction,
    turnNear: _azimuthTurn(fromAtDeparture.position, toAtDeparture.position),
  );
  Quaternion offsetOf(Camera camera) => turnBetween(
    keptInView - camera.position,
    camera.target - camera.position,
  );
  // A mix of the two looks by angle can lose the kept point. A mix of
  // their turns away from it keeps it as near as at either end.
  final offset = slerp(offsetOf(from), offsetOf(to), fraction);
  final lookDistance = mix(
    from.fromTarget.distance,
    to.fromTarget.distance,
    fraction,
  );
  final look = offset.rotated((keptInView - position).normalized());
  return Camera.lookingAt(
    position + look * lookDistance,
    from: position,
    focalLength: mix(from.focalLength, to.focalLength, fraction),
    screenPoint:
        from.screenPoint + (to.screenPoint - from.screenPoint) * fraction,
    roll: mix(from.roll, to.roll, fraction),
  );
}

double _azimuthTurn(Vector3 from, Vector3 to) => wrapAngle(
  DirectionAndDistance.of(to).azimuth - DirectionAndDistance.of(from).azimuth,
);
