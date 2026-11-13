import 'dart:math' as math;

import 'body.dart';
import 'camera.dart';
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

/// The limits at the overview: any yaw, and the camera's own elevation
/// limit as the pitch limit. At the central body, a framing's pitch is the
/// camera's elevation (see [Framing]), so the two limits are the same.
const overviewLimits = FramingLimits(
  maxYaw: double.infinity,
  maxPitch: maxElevation,
  nearest: 24,
  farthest: 60,
);

/// The limits at a category's body.
///
/// The yaw limit keeps the camera beside the body or behind it, so the
/// camera is about as far from the central body as the body is, or
/// farther. It can be a little nearer, because yaw turns around world y
/// and not around straight behind the body: when the body is above the
/// xz plane and the camera is turned down, or the opposite, a quarter turn
/// of yaw puts the camera a little in front of the body. With the pitch
/// limit below, the camera stays at least 0.98 of the body's distance from
/// the central body, for every orbit tilt.
///
/// The pitch limit plus the steepest orbit tilt is less than
/// [maxElevation]. So a drag never stores a turn that the camera does not
/// show.
///
/// The nearest distance is more than the radius of every body, so the
/// camera stays outside the framed body. These limits do not keep the
/// camera outside other bodies.
const bodyLimits = FramingLimits(
  maxYaw: math.pi / 2,
  maxPitch: 0.85,
  nearest: 1.5,
  farthest: 8,
);

/// Where the camera is around a body: a yaw, a pitch and a distance from
/// the body.
///
/// The angles are measured from straight behind the body. Straight behind
/// a body is the direction from the central body through the body. So the
/// camera turns with the
/// orbit. For the central body, they are the camera's own azimuth and
/// elevation.
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

  /// The overview, with the camera at the azimuth and elevation that
  /// [camera] has from its target. Navigation gives the current camera, so
  /// at the overview the camera looks in the same direction as before.
  Framing.overviewWithAnglesOf(Camera camera)
    : body = centralBody,
      yaw = camera.fromTarget.azimuth,
      pitch = camera.fromTarget.elevation,
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

  /// The angle around world y from straight behind [body] to
  /// the camera, in rad.
  final double yaw;

  /// The angle up from straight behind [body] to the camera,
  /// in rad.
  final double pitch;

  /// The distance from the centre of [body] to the camera, in world units.
  final double distance;

  /// How far drag and zoom can change this framing.
  final FramingLimits limits;

  /// This framing, turned by [byYaw] and [byPitch], in rad, within
  /// [limits].
  Framing turned({required double byYaw, required double byPitch}) => Framing(
    body: body,
    yaw: (yaw + byYaw).clamp(-limits.maxYaw, limits.maxYaw),
    pitch: (pitch + byPitch).clamp(-limits.maxPitch, limits.maxPitch),
    distance: distance,
    limits: limits,
  );

  /// This framing, with its distance times [factor], within [limits].
  Framing zoomed(double factor) => Framing(
    body: body,
    yaw: yaw,
    pitch: pitch,
    distance: (distance * factor).clamp(limits.nearest, limits.farthest),
    limits: limits,
  );

  /// The camera at [time], in seconds on the clock of the scene.
  Camera cameraAt(double time) {
    final bodyPosition = body.positionAt(time);
    final behind = DirectionAndDistance.of(bodyPosition);
    return Camera(
      target: bodyPosition,
      fromTarget: DirectionAndDistance(
        azimuth: behind.azimuth + yaw,
        elevation: behind.elevation + pitch,
        distance: distance,
      ),
    );
  }
}
