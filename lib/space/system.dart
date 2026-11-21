import 'package:vector_math/vector_math_64.dart';

import '../content/content.dart';

import 'body.dart';
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

/// The camera of the Landing, which shows the whole system, with the hole
/// a third of the way down the screen.
final landingCamera = Camera(
  target: Vector3.zero(),
  fromTarget: const DirectionAndDistance(
    azimuth: 0,
    elevation: -0.12,
    distance: 36,
  ),
  screenPoint: Vector2(0.5, 0.32),
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
  ),
  SectionId.work: _body(
    across: -5.2,
    toward: 10,
    radius: 0.78,
    tilt: -0.16,
    spinRate: 1.5,
    obliquity: 0.12,
  ),
  SectionId.personal: _body(
    across: 5.3,
    toward: 8.7,
    radius: 0.58,
    tilt: 0.34,
    spinRate: 1.1,
    obliquity: 0.45,
  ),
  SectionId.contact: _body(
    across: 13.5,
    toward: 1.5,
    radius: 0.7,
    tilt: -0.28,
    spinRate: 0.7,
    obliquity: 0.25,
  ),
};

/// A body whose orbit starts in the plane of world x and the line of sight
/// from [landingCamera], so seen from that camera all start points form
/// one horizontal line.
///
/// - [across]: world units along world x, which moves the start point
///   sideways as seen from the camera (negative is left).
/// - [toward]: world units toward the camera, which brings the start point
///   nearer (negative is further away).
/// - [radius]: the body's size, in world units.
/// - [tilt]: turns the orbit's plane about the line from the hole to the
///   start point, in rad, so the body leaves its start point upward or
///   downward.
/// - [spinRate] and [obliquity]: as [Body.spinRate] and [Body.obliquity].
Body _body({
  required double across,
  required double toward,
  required double radius,
  required double tilt,
  required double spinRate,
  required double obliquity,
}) {
  final towardCamera = landingCamera.position.normalized();
  return Body(
    orbit: Orbit(
      start: Vector3(across, 0, 0) + towardCamera * toward,
      tilt: tilt,
    ),
    radius: radius,
    spinRate: spinRate,
    obliquity: obliquity,
  );
}
