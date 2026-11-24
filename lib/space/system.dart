import 'package:vector_math/vector_math_64.dart';

import '../content/content.dart';

import 'body.dart';
import 'body_look.dart';
import 'camera.dart';
import 'direction_and_distance.dart';
import 'orbit.dart';

/// Light that passes nearer than √27 / 2 ≈ 2.6 event-horizon radii (world
/// units) falls in.
const holeShadowRadius = 2.6;

/// [Camera.project] and picking do not bend rays.
const holeLensingRadius = 8.0;

/// The disk of gas lies in the xz plane and goes in to the hole.
const holeDiskOuterRadius = 10.2;

/// In rad per unit of orbit time.
const holeDiskSpinRate = 0.9;

/// Seen from here, the bodies' start points form one straight line.
const lineUpViewpoint = DirectionAndDistance(
  azimuth: 0,
  elevation: -0.12,
  distance: 36,
);

final Map<SectionId, Body> bodies = {
  SectionId.about: _body(
    alongLine: -15,
    towardViewpoint: -1,
    radius: 0.9,
    tilt: 0.22,
    spinRate: 0.9,
    obliquity: 0.4,
    look: KeplerLook.desert,
  ),
  SectionId.work: _body(
    alongLine: -5.2,
    towardViewpoint: 10,
    radius: 0.78,
    tilt: -0.16,
    spinRate: 1.5,
    obliquity: 0.12,
    look: RingedLook.gasGiant,
  ),
  SectionId.personal: _body(
    alongLine: 5.3,
    towardViewpoint: 8.7,
    radius: 0.58,
    tilt: 0.34,
    spinRate: 1.1,
    obliquity: 0.45,
    look: RingedLook.amber,
  ),
  SectionId.contact: _body(
    alongLine: 13.5,
    towardViewpoint: 1.5,
    radius: 0.7,
    tilt: -0.28,
    spinRate: 0.7,
    obliquity: 0.25,
    look: KeplerLook.ice,
  ),
};

/// A body whose orbit starts in the plane of world x and the line of sight
/// from [lineUpViewpoint]. Seen from there, negative [alongLine] is left.
/// [tilt] turns the orbit, in rad, as in [Orbit].
Body _body({
  required double alongLine,
  required double towardViewpoint,
  required double radius,
  required double tilt,
  required double spinRate,
  required double obliquity,
  required BodyLook look,
}) {
  final toViewpoint = lineUpViewpoint.toVector3().normalized();
  return Body(
    orbit: Orbit(
      start: Vector3(alongLine, 0, 0) + toViewpoint * towardViewpoint,
      tilt: tilt,
    ),
    radius: radius,
    spinRate: spinRate,
    obliquity: obliquity,
    look: look,
  );
}
