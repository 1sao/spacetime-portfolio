import 'body.dart';
import 'camera.dart';
import 'orbit.dart';

/// The radius of the central body: the black hole at the origin, which
/// every category's body orbits.
///
/// A world unit is the hole's event-horizon radius. The hole looks black
/// out to √27 / 2 ≈ 2.6 of those, because light passing nearer than that
/// falls in, so 2.6 is the radius of the disc it appears as.
const double centralBodyRadius = 2.6;

final overviewCamera = Camera.orbiting(yaw: 0.3, pitch: 0.14, distance: 30);

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
