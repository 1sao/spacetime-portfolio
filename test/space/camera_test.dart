import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:homepage_v2/space/camera.dart';
import 'package:homepage_v2/space/direction_and_distance.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  test('the camera clamps the elevation, so the camera never looks straight up '
      'or down and never goes over the top', () {
    for (final elevation in [math.pi / 2, 2.0, -math.pi / 2, -2.0]) {
      final target = Vector3(1, 2, 3);
      final camera = Camera(
        target: target,
        fromTarget: DirectionAndDistance(
          azimuth: 0.3,
          elevation: elevation,
          distance: 10,
        ),
      );
      final reason = 'elevation $elevation';
      expect(camera.fromTarget.elevation.abs(), maxElevation, reason: reason);
      // Without the clamp, an elevation of 2 rad moves the camera over the
      // top of the target to its far side. The direction from the target to
      // the camera then has an azimuth a half turn from the camera's, and an
      // elevation of π - 2 rad. These checks find that.
      final seen = DirectionAndDistance.of(camera.position - target);
      expect(
        seen.azimuth,
        closeTo(camera.fromTarget.azimuth, 1e-9),
        reason: reason,
      );
      expect(
        seen.elevation,
        closeTo(camera.fromTarget.elevation, 1e-9),
        reason: reason,
      );
    }
  });
}
