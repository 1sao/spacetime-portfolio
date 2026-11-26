import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

/// The shortest turn from the direction of [from] to that of [to], as
/// [Quaternion.rotated] applies it.
Quaternion turnBetween(Vector3 from, Vector3 to) {
  final (start, end) = (from.normalized(), to.normalized());
  final axis = start.cross(end);
  final cosine = start.dot(end);
  // Opposite directions have no shortest turn, so any half turn does.
  final turn = cosine < -1 + 1e-12
      ? Quaternion.axisAngle(start.anyPerpendicular, math.pi)
      : (Quaternion(axis.x, axis.y, axis.z, 1 + cosine)..normalize());
  // [Quaternion.rotated] turns the other way.
  return turn.conjugated();
}

/// The turn at [fraction] of the way from [from] to [to], at a constant
/// rate, the short way around.
Quaternion slerp(Quaternion from, Quaternion to, double fraction) {
  var cosine = from.x * to.x + from.y * to.y + from.z * to.z + from.w * to.w;
  // q and -q are the same turn: the nearer one turns the short way.
  final end = cosine < 0 ? to.scaled(-1) : to;
  cosine = cosine.abs();
  if (cosine > 1 - 1e-9) {
    return (from.scaled(1 - fraction) + end.scaled(fraction))..normalize();
  }
  final angle = math.acos(cosine);
  final sine = math.sin(angle);
  return from.scaled(math.sin((1 - fraction) * angle) / sine) +
      end.scaled(math.sin(fraction * angle) / sine);
}

extension on Vector3 {
  Vector3 get anyPerpendicular {
    final other = x.abs() < 0.9 ? Vector3(1, 0, 0) : Vector3(0, 1, 0);
    return cross(other).normalized();
  }
}
