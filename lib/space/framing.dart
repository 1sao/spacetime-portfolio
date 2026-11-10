import 'package:vector_math/vector_math_64.dart';

import 'camera_rig.dart';
import 'direction_and_distance.dart';

/// How the camera frames a body when the camera is focused on that body.
/// The framing sets where a flight to the body stops, and how the camera
/// follows the body after the flight.
sealed class BodyFraming {
  const BodyFraming();

  /// The rig that frames a body with its centre at [bodyPosition].
  CameraRig rigFor(Vector3 bodyPosition);
}

/// The camera is behind the body, on the side away from the central body.
/// It is a small angle to the side of and above the line from the central
/// body through the body. It looks at the body, and the central body shows
/// next to the body on the screen.
///
/// The camera keeps the same angles to the direction of the body when the
/// body moves along its orbit. The central body then stays at the same
/// position on the screen.
final class BehindBody extends BodyFraming {
  const BehindBody({
    required this.yawOffset,
    required this.pitchOffset,
    required this.distance,
  });

  /// The angle around world y from the position directly behind the body to
  /// the camera, in rad.
  final double yawOffset;

  /// The angle up from the position directly behind the body to the camera,
  /// in rad.
  final double pitchOffset;

  /// The distance from the centre of the body to the camera, in world units.
  final double distance;

  @override
  CameraRig rigFor(Vector3 bodyPosition) {
    // The position directly behind the body is on the line from the central
    // body, at the origin, through the body.
    final behind = DirectionAndDistance.of(bodyPosition);
    return CameraRig(
      target: bodyPosition,
      yaw: behind.azimuth + yawOffset,
      pitch: behind.elevation + pitchOffset,
      distance: distance,
    );
  }
}
