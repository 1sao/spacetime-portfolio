import 'package:vector_math/vector_math_64.dart';

import 'body.dart';
import 'camera_rig.dart';
import 'framing.dart';
import 'orbit.dart';

/// The radius of the central body: the black hole at the origin, which
/// every category's body orbits.
///
/// A world unit is the hole's event-horizon radius. The hole looks black
/// out to √27 / 2 ≈ 2.6 of those, because light passing nearer than that
/// falls in, so 2.6 is the radius of the disc it appears as.
const double centralBodyRadius = 2.6;

/// The distance from the overview camera to the central body, in world
/// units. This distance must be more than the distance from the central
/// body to the camera in each body framing, so that the overview is the
/// farthest view.
const double overviewDistance = 30;

/// The rig at the start: the overview. It looks at the central body.
final overviewRig = CameraRig(
  target: Vector3.zero(),
  yaw: 0.3,
  pitch: 0.14,
  distance: overviewDistance,
);

/// The overview, seen with the yaw and pitch of [rig]. A flight to the
/// overview ends here, so the camera moves out without a turn.
CameraRig overviewWithAnglesOf(CameraRig rig) => CameraRig(
  target: Vector3.zero(),
  yaw: rig.yaw,
  pitch: rig.pitch,
  distance: overviewDistance,
);

/// The yaw offset of [bodyFraming] and [messageFraming], in rad. The two
/// framings share their angles, so a flight between them moves the camera
/// straight in or out.
const _framingYawOffset = 0.3;

/// The pitch offset of [bodyFraming] and [messageFraming], in rad.
const _framingPitchOffset = 0.25;

/// The framing for each body that the camera focuses on.
const BodyFraming bodyFraming = BehindBody(
  yawOffset: _framingYawOffset,
  pitchOffset: _framingPitchOffset,
  distance: 6,
);

/// The framing for a body when one of its messages is open. The camera is
/// nearer to the body than in [bodyFraming].
const BodyFraming messageFraming = BehindBody(
  yawOffset: _framingYawOffset,
  pitchOffset: _framingPitchOffset,
  distance: 2.5,
);

const _inner = Orbit(radius: 6.5, tilt: 0.35, node: 0);
const _middle = Orbit(radius: 9.5, tilt: -0.3, node: 1.1);
const _outer = Orbit(radius: 13.5, tilt: 0.55, node: 2.3);

/// The body each category is drawn as, keyed by category slug.
const Map<String, Body> bodies = {
  'projects': Body(orbit: _inner, phase: 0.4, radius: 0.6),
  'experience': Body(orbit: _middle, phase: 2.6, radius: 0.55),
  'contact': Body(orbit: _outer, phase: 1.2, radius: 0.6),
  'category-04': Body(orbit: _outer, phase: 4.0, radius: 0.55),
};
