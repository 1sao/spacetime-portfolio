import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

/// A world unit is the event-horizon radius, 2GM / c², and a time unit is
/// the time light takes to cross it. With c = 1, GM is half a world unit.
const _gravitationalParameter = 0.5;

/// Time units per unit of orbit time, so that the orbits move at a
/// pace the visitor can see.
const _orbitTimeScale = 5.8 * math.sqrt2;

/// A circle around the hole.
class Orbit {
  /// With [tilt] 0, the circle is as flat as a circle through the hole and
  /// [start] can be. [tilt] turns it about the line from the hole to
  /// [start], in rad.
  factory Orbit({required Vector3 start, required double tilt}) {
    assert(start.length > 0, 'The orbit starts at the hole.');
    assert(
      start.x != 0 || start.z != 0,
      'The orbit starts straight above or below the hole.',
    );
    final radius = start.length;
    final outward = start / radius;
    // The flattest plane through the line from the hole to [start] has the
    // normal nearest to world up: world up without its part along the line.
    final up = Vector3(0, 1, 0);
    final flattestNormal = (up - outward * up.dot(outward)).normalized();
    final normal = flattestNormal.turnedAbout(outward, tilt);
    return Orbit._(
      start: start.clone(),
      normal: normal,
      // As long as [start], because the normal has length 1.
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

  /// The position at orbit time 0.
  final Vector3 start;

  /// Seen from its tip, the body goes around counterclockwise.
  final Vector3 normal;

  final Vector3 _quarterTurn;

  /// In rad per unit of orbit time.
  final double angularSpeed;

  Vector3 pointAt(double orbitTime) {
    final angle = angularSpeed * orbitTime;
    return start * math.cos(angle) + _quarterTurn * math.sin(angle);
  }
}

extension _Turn on Vector3 {
  /// Rodrigues' rotation formula. A positive angle turns counterclockwise,
  /// seen from the tip of [axis], which has length 1.
  Vector3 turnedAbout(Vector3 axis, double angle) {
    final cos = math.cos(angle);
    return this * cos +
        axis.cross(this) * math.sin(angle) +
        axis * (axis.dot(this) * (1 - cos));
  }
}
