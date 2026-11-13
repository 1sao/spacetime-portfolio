import 'body.dart';
import 'orbit.dart';

/// The black hole at the origin, which every category's body orbits. It
/// does not move.
///
/// A world unit is the hole's event-horizon radius. The hole looks black
/// out to √27 / 2 ≈ 2.6 of those, because light passing nearer than that
/// falls in, so 2.6 is the radius of the disc it appears as.
const centralBody = Body(orbit: NoOrbit(), phase: 0, radius: 2.6);

/// The default distance from the overview camera to the central body, in
/// world units.
const double overviewDistance = 30;

const _inner = CircularOrbit(radius: 6.5, tilt: 0.35, node: 0);
const _middle = CircularOrbit(radius: 9.5, tilt: -0.3, node: 1.1);
const _outer = CircularOrbit(radius: 13.5, tilt: 0.55, node: 2.3);

/// The body each category is drawn as, by category slug.
const Map<String, Body> bodies = {
  'projects': Body(orbit: _inner, phase: 0.4, radius: 0.6),
  'experience': Body(orbit: _middle, phase: 2.6, radius: 0.55),
  'contact': Body(orbit: _outer, phase: 1.2, radius: 0.6),
  'category-04': Body(orbit: _outer, phase: 4.0, radius: 0.55),
};
