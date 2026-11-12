import 'package:vector_math/vector_math_64.dart';

import 'orbit.dart';

/// A sphere in the scene: a category's body, which moves along an orbit
/// round the central body, or the central body, at the origin.
class Body {
  const Body({required this.orbit, required this.phase, required this.radius});

  /// The circle the body's centre moves along.
  final Orbit orbit;

  /// Where along [orbit] the body is at time 0, as an angle in rad (see
  /// [Orbit.pointAt]). Bodies that share an orbit are kept apart by their
  /// phases.
  final double phase;

  /// The sphere's radius, in world units.
  final double radius;

  Vector3 positionAt(double seconds) =>
      orbit.pointAt(phase + orbit.angularSpeed * seconds);
}

extension BodyOfSlug on Map<String, Body> {
  /// The body of the category with [slug]. It throws a [StateError] if the
  /// category has no body.
  Body of(String slug) =>
      this[slug] ?? (throw StateError('No body for the category "$slug".'));
}
