import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

/// A point as a direction from the origin and a distance from the origin.
/// The direction is two angles: [azimuth] and [elevation].
///
/// Azimuth 0 and elevation 0 point along -z. An increase in azimuth turns
/// the direction toward +x. An increase in elevation turns it toward +y.
class DirectionAndDistance {
  const DirectionAndDistance({
    required this.azimuth,
    required this.elevation,
    required this.distance,
  });

  /// The direction and distance of [point] from the origin. The origin
  /// has no direction, so for the origin the azimuth and elevation are 0.
  factory DirectionAndDistance.of(Vector3 point) {
    final distance = point.length;
    if (distance == 0) {
      return const DirectionAndDistance(azimuth: 0, elevation: 0, distance: 0);
    }
    return DirectionAndDistance(
      // The angle in the xz plane, from -z toward +x.
      azimuth: math.atan2(point.x, -point.z),
      // The sine of the elevation is the height divided by the distance.
      // Rounding errors can make this value a little more than 1 or less
      // than -1. The clamp keeps it in the range where asin has a result.
      elevation: math.asin((point.y / distance).clamp(-1.0, 1.0)),
      distance: distance,
    );
  }

  /// The angle around world y, in rad.
  final double azimuth;

  /// The angle above the xz plane, in rad, from -π/2 to π/2.
  final double elevation;

  /// The distance from the origin, in world units.
  final double distance;

  Vector3 toVector3() {
    // The distance from the point to the y axis. This is the length of the
    // projection of the point on the xz plane.
    final flat = math.cos(elevation) * distance;
    return Vector3(
      flat * math.sin(azimuth),
      math.sin(elevation) * distance,
      -flat * math.cos(azimuth),
    );
  }
}

/// The angle in the range -π to π that has the same direction as [angle].
/// It is the shorter turn from 0 to that direction.
///
/// For example, a turn from azimuth 3 rad to azimuth -3 rad is -6 rad,
/// which is almost a full turn. `wrapAngle(-6)` is approximately 0.28 rad:
/// the same end direction, with a small turn across ±π.
double wrapAngle(double angle) => (angle + math.pi) % (2 * math.pi) - math.pi;
