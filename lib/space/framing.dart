import 'dart:math' as math;

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

/// How far drag and zoom can change a framing.
class FramingLimits {
  const FramingLimits({
    required this.maxYaw,
    required this.maxPitch,
    required this.nearest,
    required this.farthest,
  });

  /// The largest yaw, in rad, either way from straight behind the body.
  final double maxYaw;

  /// The largest pitch, in rad, either way from straight behind the body.
  final double maxPitch;

  /// The nearest distance from the body, in world units.
  final double nearest;

  /// The farthest distance from the body, in world units.
  final double farthest;
}

/// The limits at the overview: any yaw and pitch. [Framing.turned] keeps the
/// pitch within the rig's clamp.
const overviewLimits = FramingLimits(
  maxYaw: double.infinity,
  maxPitch: double.infinity,
  nearest: 24,
  farthest: 60,
);

/// The limits at a category's body: a quarter turn of yaw and a quarter turn
/// of pitch from straight behind the body. Together, they turn the camera
/// up to about 116° from straight behind on the most tilted orbit. On an
/// orbit of radius R, the camera then stays at least 0.89 R from the
/// central body, for every distance from the body.
///
/// Why 0.89: with θ the angle at the body from straight behind to the
/// camera, and d the distance from the body, the camera is
/// √(R² + d² + 2·R·d·cos θ) from the central body. Yaw and pitch of up to
/// π/2 each give cos θ ≥ −|sin(2e)| / 2, where e is the elevation of the
/// body.
/// The orbits tilt 0.55 rad at most, so cos θ ≥ −0.45, and the distance is
/// at least √(R² + d² − 0.9·R·d) ≥ 0.89 R.
///
/// The nearest distance is more than the radius of every body, so the
/// camera stays outside the framed body. These limits do not keep the
/// camera outside other bodies.
const bodyLimits = FramingLimits(
  maxYaw: math.pi / 2,
  maxPitch: math.pi / 2,
  nearest: 1.5,
  farthest: 8,
);

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
    required this.limits,
  });

  /// The overview at the start of a visit.
  const Framing.overview()
    : body = centralBody,
      yaw = 0.3,
      pitch = 0.14,
      distance = overviewDistance,
      limits = overviewLimits;

  /// The overview, seen with the yaw and pitch of [rig]. A flight to the
  /// overview ends here, so the camera moves out without a turn.
  Framing.overviewWithAnglesOf(CameraRig rig)
    : body = centralBody,
      yaw = rig.yaw,
      pitch = rig.pitch,
      distance = overviewDistance,
      limits = overviewLimits;

  /// The framing of [body] when the camera focuses on its category.
  const Framing.ofCategory(this.body)
    : yaw = _bodyYaw,
      pitch = _bodyPitch,
      distance = 6,
      limits = bodyLimits;

  /// The framing of [body] when one of its messages is open. The camera is
  /// nearer to the body than in [Framing.ofCategory].
  const Framing.ofMessage(this.body)
    : yaw = _bodyYaw,
      pitch = _bodyPitch,
      distance = 2.5,
      limits = bodyLimits;

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

  /// How far drag and zoom can change this framing.
  final FramingLimits limits;

  /// This framing, turned by [yaw] and [pitch], in rad, within [limits].
  /// Also, the rig's pitch at [time] stays within ±[maxPitch], the range
  /// that [CameraRig] allows.
  Framing turned({
    required double yaw,
    required double pitch,
    required double time,
  }) {
    final behindElevation = DirectionAndDistance.of(body.positionAt(time))
        .elevation;
    return Framing(
      body: body,
      yaw: (this.yaw + yaw).clamp(-limits.maxYaw, limits.maxYaw),
      // The second clamp keeps the rig's pitch within ±[maxPitch]. It can't
      // move the pitch out of [limits], because both ranges contain
      // -behindElevation, the pitch of a level camera.
      pitch: (this.pitch + pitch)
          .clamp(-limits.maxPitch, limits.maxPitch)
          .clamp(-maxPitch - behindElevation, maxPitch - behindElevation),
      distance: distance,
      limits: limits,
    );
  }

  /// This framing, with its distance times [factor], within [limits].
  Framing zoomed(double factor) => Framing(
    body: body,
    yaw: yaw,
    pitch: pitch,
    distance: (distance * factor).clamp(limits.nearest, limits.farthest),
    limits: limits,
  );

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
