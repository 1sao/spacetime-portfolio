import 'body.dart';
import 'camera_rig.dart';
import 'direction_and_distance.dart';
import 'site_space.dart';

/// The yaw of [Framing.ofCategory] and [Framing.ofMessage], in rad. The two
/// framings share their angles, so a flight between them moves the camera
/// straight in or out.
const _bodyYaw = 0.3;

/// The pitch of [Framing.ofCategory] and [Framing.ofMessage], in rad.
const _bodyPitch = 0.25;

/// Where the camera is around a body: a yaw, a pitch and a distance from
/// the body.
///
/// The angles are measured from the position directly behind the body.
/// That position is on the line from the central body, at the origin,
/// through the body, on the side away from the central body. When the body
/// moves along its orbit, the camera keeps the same angles to that line.
/// So the central body stays at almost the same position on the screen. It
/// moves a little on a tilted orbit, because the angles are a yaw and a
/// pitch, not a fixed rotation.
///
/// The central body has no direction from the origin. For the central
/// body, the angles are measured from azimuth 0 and elevation 0, so they
/// are the camera's own yaw and pitch.
class Framing {
  const Framing({
    required this.body,
    required this.yaw,
    required this.pitch,
    required this.distance,
  });

  /// The overview at the start of a visit.
  const Framing.overview()
    : body = centralBody,
      yaw = 0.3,
      pitch = 0.14,
      distance = overviewDistance;

  /// The overview, seen with the yaw and pitch of [rig]. A flight to the
  /// overview ends here, so the camera moves out without a turn.
  Framing.overviewWithAnglesOf(CameraRig rig)
    : body = centralBody,
      yaw = rig.yaw,
      pitch = rig.pitch,
      distance = overviewDistance;

  /// The framing of [body] when the camera focuses on its category.
  const Framing.ofCategory(this.body)
    : yaw = _bodyYaw,
      pitch = _bodyPitch,
      distance = 6;

  /// The framing of [body] when one of its messages is open. The camera is
  /// nearer to the body than in [Framing.ofCategory].
  const Framing.ofMessage(this.body)
    : yaw = _bodyYaw,
      pitch = _bodyPitch,
      distance = 2.5;

  /// The body that the camera looks at.
  final Body body;

  /// The angle around world y from the position directly behind [body] to
  /// the camera, in rad.
  final double yaw;

  /// The angle up from the position directly behind [body] to the camera,
  /// in rad.
  final double pitch;

  /// The distance from the centre of [body] to the camera, in world units.
  final double distance;

  /// The rig at [time], in seconds on the clock of the scene.
  CameraRig rigAt(double time) {
    final bodyPosition = body.positionAt(time);
    final behind = DirectionAndDistance.of(bodyPosition);
    return CameraRig(
      target: bodyPosition,
      yaw: behind.azimuth + yaw,
      pitch: behind.elevation + pitch,
      distance: distance,
    );
  }
}
