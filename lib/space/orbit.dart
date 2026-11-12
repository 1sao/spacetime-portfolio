import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

/// The pace of every orbit, set by one reference: an orbit of this radius,
/// in world units, goes round once in [_referencePeriodSeconds], and
/// Kepler's third law scales every other orbit's period from it.
const _referenceRadius = 6.5;

const _referencePeriodSeconds = 120.0;

/// How a body moves round the origin, where the central body sits.
sealed class Orbit {
  const Orbit();

  /// How fast a body on this orbit goes round, in rad per second.
  double get angularSpeed;

  /// The point [angle] rad round the orbit, in world units.
  Vector3 pointAt(double angle);
}

/// A circle round the origin.
///
/// The circle starts flat in the xz plane, is tilted by [tilt] about the x
/// axis, and is then turned by [node] about the y axis.
final class CircularOrbit extends Orbit {
  const CircularOrbit({
    required this.radius,
    required this.tilt,
    required this.node,
  }) : assert(radius > 0, 'A body without an orbit has NoOrbit.');

  /// The circle's radius, in world units.
  final double radius;

  /// How far the circle is tilted out of the xz plane, about the x axis, in
  /// rad.
  final double tilt;

  /// How far the tilted circle is then turned about the y axis, in rad, which
  /// sets the direction it tilts in. Astronomers call this angle the
  /// longitude of the ascending node.
  final double node;

  /// By Kepler's third law, an orbit's period grows with its radius to the
  /// power 1.5, so outer bodies are slower.
  @override
  double get angularSpeed {
    final periodSeconds =
        _referencePeriodSeconds * math.pow(radius / _referenceRadius, 1.5);
    return 2 * math.pi / periodSeconds;
  }

  /// Angle 0 is where the circle crosses the xz plane on the +x side before
  /// [node] turns it.
  @override
  Vector3 pointAt(double angle) => Matrix3.rotationY(node).transformed(
    Matrix3.rotationX(tilt).transformed(
      Vector3(radius * math.cos(angle), 0, radius * math.sin(angle)),
    ),
  );
}

/// The body stays at the origin, as the central body does.
final class NoOrbit extends Orbit {
  const NoOrbit();

  @override
  double get angularSpeed => 0;

  @override
  Vector3 pointAt(double angle) => Vector3.zero();
}
