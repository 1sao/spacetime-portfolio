import 'package:vector_math/vector_math_64.dart';

import 'orbit.dart';

/// A sphere that orbits the hole: the body of a section.
class Body {
  const Body({required this.orbit, required this.radius});

  /// The circle the body's centre moves along.
  final Orbit orbit;

  /// The sphere's radius, in world units.
  final double radius;

  /// The centre of the body at [orbitTime].
  Vector3 positionAt(double orbitTime) => orbit.pointAt(orbitTime);
}
