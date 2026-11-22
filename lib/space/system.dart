import 'package:vector_math/vector_math_64.dart';

import '../content/content.dart';

import 'body.dart';
import 'body_look.dart';
import 'camera.dart';
import 'direction_and_distance.dart';
import 'orbit.dart';

/// The radius of the black disc that the hole at the origin appears as, in
/// world units.
///
/// A world unit is the hole's event-horizon radius. Light that passes
/// nearer than √27 / 2 ≈ 2.6 of those falls in.
const holeShadowRadius = 2.6;

/// The radius inside of which light rays are visibly bent, in world units.
/// CPU-based [Camera.project] and picking do not take lensing into account.
const holeLensingRadius = 8.0;

/// The outer radius of the disc of gas round the hole, in world units. The
/// disc lies in the plane of world x and z, and goes in to the hole.
const holeDiscOuterRadius = 10.2;

/// How fast the disc turns about world y, in rad per unit of orbit time.
const holeDiscSpinRate = 0.9;

/// The direction and distance from the hole that the bodies' start points
/// are laid out for: seen from there, they form one straight line.
const lineUpViewpoint = DirectionAndDistance(
  azimuth: 0,
  elevation: -0.12,
  distance: 36,
);

/// The body of each section that has one.
final Map<SectionId, Body> bodies = {
  SectionId.about: _body(
    across: -15,
    toward: -1,
    radius: 0.9,
    tilt: 0.22,
    spinRate: 0.9,
    obliquity: 0.4,
    look: KeplerLook.desert,
  ),
  SectionId.work: _body(
    across: -5.2,
    toward: 10,
    radius: 0.78,
    tilt: -0.16,
    spinRate: 1.5,
    obliquity: 0.12,
    look: RingedLook.gasGiant,
  ),
  SectionId.personal: _body(
    across: 5.3,
    toward: 8.7,
    radius: 0.58,
    tilt: 0.34,
    spinRate: 1.1,
    obliquity: 0.45,
    look: RingedLook.amber,
  ),
  SectionId.contact: _body(
    across: 13.5,
    toward: 1.5,
    radius: 0.7,
    tilt: -0.28,
    spinRate: 0.7,
    obliquity: 0.25,
    look: KeplerLook.ice,
  ),
};

/// A body whose orbit starts in the plane of world x and the line of sight
/// from [lineUpViewpoint], so seen from there all start points form one
/// straight line.
///
/// - [across]: world units along world x, which moves the start point
///   along the line (negative is to the left, as seen from
///   [lineUpViewpoint] with world y up).
/// - [toward]: world units toward [lineUpViewpoint], which brings the start
///   point nearer (negative is further away).
/// - [radius]: the body's size, in world units.
/// - [tilt]: turns the orbit's plane about the line from the hole to the
///   start point, in rad, so the body leaves its start point upward or
///   downward.
/// - [spinRate], [obliquity] and [look]: as [Body.spinRate],
///   [Body.obliquity] and [Body.look].
Body _body({
  required double across,
  required double toward,
  required double radius,
  required double tilt,
  required double spinRate,
  required double obliquity,
  required BodyLook look,
}) {
  final towardCamera = lineUpViewpoint.toVector3().normalized();
  return Body(
    orbit: Orbit(
      start: Vector3(across, 0, 0) + towardCamera * toward,
      tilt: tilt,
    ),
    radius: radius,
    spinRate: spinRate,
    obliquity: obliquity,
    look: look,
  );
}
