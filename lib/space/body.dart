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

  final Orbit orbit;
  final double radius;

  /// In rad per unit of spin time.
  final double spinRate;

  /// How far the body's axis leans from the orbit's normal, in rad, toward
  /// the way the body moves at orbit time 0.
  final double obliquity;

  final BodyLook look;

  /// Seen from its tip, the body turns counterclockwise.
  final Vector3 spinAxis;

  /// How far from its center the body is drawn, rings included.
  double get reach => radius * look.reachInRadii;

  static Vector3 _spinAxis(Orbit orbit, double obliquity) {
    final heading = orbit.normal.cross(orbit.start).normalized();
    return orbit.normal * math.cos(obliquity) + heading * math.sin(obliquity);
  }

  Vector3 positionAt(double orbitTime) => orbit.pointAt(orbitTime);

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

  final Sphere sphere;
  final double reach;
  final Vector3 spinAxis;
  final double spinAngle;
}
