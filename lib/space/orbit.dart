import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

/// The hole's mass times the gravitational constant.
///
/// A world unit is the hole's event-horizon radius, 2GM / c². With the
/// speed of light c as 1, GM is half a world unit, and the time unit is the
/// time light takes to cross one world unit.
const _gravitationalParameter = 0.5;

/// The hole's time units in one unit of orbit time. Orbit time runs fast,
/// so the orbits move at a pace the visitor can see.
const _orbitTimeScale = 5.8 * math.sqrt2;

/// A circle round the origin, where the hole sits.
class Orbit {
  /// The circle through [start], which is the body's position at orbit
  /// time 0.
  ///
  /// With [tilt] 0, the circle is as flat as a circle through the origin
  /// and [start] can be. [tilt] turns the circle about the line from the
  /// origin to [start], in rad.
  factory Orbit({required Vector3 start, required double tilt}) {
    assert(start.length > 0, 'The orbit starts at the hole.');
    assert(
      start.x != 0 || start.z != 0,
      'The orbit starts straight above or below the hole.',
    );
    final radius = start.length;
    final outward = start / radius;
    // The orbit's plane holds the line from the hole to [start], and can
    // turn about it like a door on its hinge. The flattest of these planes
    // has the normal (the direction at right angles to the plane) nearest
    // to world up: world up with its part along the line taken away.
    // [tilt] turns the plane from there.
    final up = Vector3(0, 1, 0);
    final flattestNormal = (up - outward * up.dot(outward)).normalized();
    final normal = flattestNormal.turnedAbout(outward, tilt);
    return Orbit._(
      start: start.clone(),
      normal: normal,
      // At right angles to the normal and to [start], and as long as
      // [start], because the normal has length 1.
      quarterTurn: normal.cross(start),
      // Kepler's third law for a circular orbit.
      angularSpeed:
          math.sqrt(_gravitationalParameter / math.pow(radius, 3)) *
          _orbitTimeScale,
    );
  }

  const Orbit._({
    required this.start,
    required this.normal,
    required this._quarterTurn,
    required this.angularSpeed,
  });

  /// The position at orbit time 0, in world units.
  final Vector3 start;

  /// The direction at right angles to the orbit's plane, of length 1. Seen
  /// from its tip, the body goes round counterclockwise.
  final Vector3 normal;

  /// The position a quarter turn after [start], in world units.
  final Vector3 _quarterTurn;

  /// How fast a body on this orbit goes round, in rad per unit of orbit
  /// time.
  final double angularSpeed;

  /// The position at [orbitTime].
  Vector3 pointAt(double orbitTime) {
    final angle = angularSpeed * orbitTime;
    return start * math.cos(angle) + _quarterTurn * math.sin(angle);
  }
}

extension _Turn on Vector3 {
  /// This vector turned by [angle] rad about [axis], which has length 1.
  /// A positive angle turns counterclockwise, seen from the tip of [axis].
  ///
  /// Rodrigues' rotation formula: the part along [axis] stays, and the part
  /// at right angles to it turns in the plane that `axis × this` spans.
  Vector3 turnedAbout(Vector3 axis, double angle) {
    final cos = math.cos(angle);
    return this * cos +
        axis.cross(this) * math.sin(angle) +
        axis * (axis.dot(this) * (1 - cos));
  }
}
