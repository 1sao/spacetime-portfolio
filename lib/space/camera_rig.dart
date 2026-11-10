import 'package:vector_math/vector_math_64.dart';

import 'camera.dart';
import 'direction_and_distance.dart';

/// The camera as a target point and a position around that point. The
/// position is a yaw, a pitch and a distance from the target.
///
/// Flights, drag and zoom move the camera. They change these values, and
/// [camera] calculates the [Camera] from them.
///
/// CAUTION: [target] is mutable, and many readers can share one rig. Do not
/// change [target] in place.
class CameraRig {
  /// The rig clamps [pitch] to the range -[maxPitch] to [maxPitch].
  CameraRig({
    required this.target,
    required this.yaw,
    required double pitch,
    required this.distance,
  }) : pitch = pitch.clamp(-maxPitch, maxPitch),
       assert(distance > 0, 'The camera must not be at its target.');

  /// The point that the camera looks at, in world units.
  final Vector3 target;

  /// The direction from [target] to the camera around world y, in rad. It
  /// is a [DirectionAndDistance.azimuth].
  final double yaw;

  /// The direction from [target] to the camera above the xz plane, in rad.
  /// It is a [DirectionAndDistance.elevation], in the range ±[maxPitch].
  final double pitch;

  /// The distance from [target] to the camera, in world units.
  final double distance;

  Camera get camera => Camera(
    position:
        target +
        DirectionAndDistance(
          azimuth: yaw,
          elevation: pitch,
          distance: distance,
        ).toVector3(),
    target: target,
  );
}

/// The maximum angle up or down for the camera, in rad (approximately 83°).
/// When the camera looks straight up or down, it has no horizontal right
/// direction. Past that angle, the view turns upside down.
const maxPitch = 1.45;
