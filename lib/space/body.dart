import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

import 'body_look.dart';
import 'orbit.dart';

/// A sphere that orbits the hole and turns on its axis: the body of a
/// section.
class Body {
  Body({
    required this.orbit,
    required this.radius,
    required this.spinRate,
    required this.obliquity,
    required this.look,
  }) : spinAxis = _spinAxis(orbit, obliquity);

  /// The circle the body's centre moves along.
  final Orbit orbit;

  /// The sphere's radius, in world units.
  final double radius;

  /// How fast the body turns on its axis, in rad per unit of spin time.
  final double spinRate;

  /// How far the body's axis leans from the orbit's normal, in rad, toward
  /// the way the body moves at orbit time 0.
  final double obliquity;

  /// How the body is drawn.
  final BodyLook look;

  /// The axis the body turns about, of length 1. Seen from its tip, the
  /// body turns counterclockwise.
  final Vector3 spinAxis;

  /// How far from its centre the body is drawn, in world units, rings
  /// included.
  double get reach => radius * look.reachInRadii;

  static Vector3 _spinAxis(Orbit orbit, double obliquity) {
    final heading = orbit.normal.cross(orbit.start).normalized();
    return orbit.normal * math.cos(obliquity) + heading * math.sin(obliquity);
  }

  /// The centre of the body at [orbitTime].
  Vector3 positionAt(double orbitTime) => orbit.pointAt(orbitTime);

  /// The body at [orbitTime] and [spinTime].
  BodyPose poseAt({required double orbitTime, required double spinTime}) =>
      BodyPose(
        sphere: Sphere.centerRadius(positionAt(orbitTime), radius),
        reach: reach,
        spinAxis: spinAxis,
        spinAngle: spinRate * spinTime,
      );
}

/// A body at one moment: where it is, and how far it has turned.
class BodyPose {
  const BodyPose({
    required this.sphere,
    required this.reach,
    required this.spinAxis,
    required this.spinAngle,
  });

  /// The body's centre and radius, in world units.
  final Sphere sphere;

  /// How far from its centre the body is drawn, in world units (see
  /// [Body.reach]).
  final double reach;

  /// The axis the body turns about, of length 1 (see [Body.spinAxis]).
  final Vector3 spinAxis;

  /// How far the body has turned about [spinAxis] since spin time 0, in
  /// rad.
  final double spinAngle;
}
