import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

/// The pace of every orbit, set by one reference: an orbit of this radius,
/// in world units, goes round once in [_referencePeriodSeconds], and
/// Kepler's third law scales every other orbit's period from it.
const _referenceRadius = 6.5;

const _referencePeriodSeconds = 120.0;

/// A circular orbit round the central body, which sits at the origin.
///
/// The circle starts flat in the xz plane, is tilted by [tilt] about the x
/// axis, and is then turned by [node] about the y axis.
class Orbit {
  const Orbit({required this.radius, required this.tilt, required this.node});

  /// The circle's radius, in world units.
  final double radius;

  /// How far the circle is tilted out of the xz plane, about the x axis, in
  /// rad.
  final double tilt;

  /// How far the tilted circle is then turned about the y axis, in rad, which
  /// sets the direction it tilts in. Astronomers call this angle the
  /// longitude of the ascending node.
  final double node;

  /// How fast a body on this orbit goes round, in rad per second. By
  /// Kepler's third law, an orbit's period grows with its radius to the
  /// power 1.5, so outer bodies are slower.
  double get angularSpeed {
    final periodSeconds =
        _referencePeriodSeconds * math.pow(radius / _referenceRadius, 1.5);
    return 2 * math.pi / periodSeconds;
  }

  /// The point [angle] rad round the circle, in world units. Angle 0 is
  /// where the circle crosses the xz plane on the +x side before [node]
  /// turns it.
  Vector3 pointAt(double angle) => Matrix3.rotationY(node).transformed(
    Matrix3.rotationX(tilt).transformed(
      Vector3(radius * math.cos(angle), 0, radius * math.sin(angle)),
    ),
  );
}
