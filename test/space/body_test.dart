import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:homepage_v2/space/system.dart';

import '../matchers.dart';

void main() {
  test("each body's spin axis leans from its orbit's normal by its "
      'obliquity, toward the way the body starts to move', () {
    for (final MapEntry(key: id, value: body) in bodies.entries) {
      final axis = body.spinAxis;
      final normal = body.orbit.normal;
      final heading = body.positionAt(1e-6) - body.positionAt(0);
      expect(axis.length, nearlyEquals(1), reason: id.name);
      expect(
        math.acos(axis.dot(normal).clamp(-1, 1)),
        nearlyEquals(body.obliquity),
        reason: id.name,
      );
      expect(axis.dot(heading), greaterThan(0), reason: id.name);
      // The axis stays in the plane of the normal and the heading.
      expect(axis.dot(body.orbit.start), nearlyEquals(0), reason: id.name);
    }
  });
}
