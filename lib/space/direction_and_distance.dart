import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

/// A point as a direction from the origin and a distance from the origin.
/// The direction is two angles: [azimuth] and [elevation].
///
/// Azimuth 0 and elevation 0 point along +z. An increase in azimuth turns
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
      azimuth: math.atan2(point.x, point.z),
      // Rounding can put the ratio a little outside the range of asin.
      elevation: math.asin((point.y / distance).clamp(-1.0, 1.0)),
      distance: distance,
    );
  }

  final double azimuth;
  final double elevation;
  final double distance;

  Vector3 toVector3() {
    final distanceFromYAxis = math.cos(elevation) * distance;
    return Vector3(
      distanceFromYAxis * math.sin(azimuth),
      math.sin(elevation) * distance,
      distanceFromYAxis * math.cos(azimuth),
    );
  }
}

/// The angle from -π to π with the same direction as [angle]: the shorter
/// turn from 0 to that direction.
double wrapAngle(double angle) => (angle + math.pi) % (2 * math.pi) - math.pi;
