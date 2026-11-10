import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:homepage_v2/space/camera_rig.dart';
import 'package:homepage_v2/space/direction_and_distance.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  test('the rig clamps the pitch, so the camera never looks straight up or '
      'down and never goes over the top', () {
    for (final pitch in [math.pi / 2, 2.0, -math.pi / 2, -2.0]) {
      final target = Vector3(1, 2, 3);
      final rig = CameraRig(
        target: target,
        yaw: 0.3,
        pitch: pitch,
        distance: 10,
      );
      final reason = 'pitch $pitch';
      expect(rig.pitch.abs(), maxPitch, reason: reason);
      // Without the clamp, a pitch of 2 rad moves the camera over the top of
      // the target to its far side. The direction from the target to the
      // camera then has an azimuth a half turn from the yaw, and an
      // elevation of π - 2 rad. These checks find that.
      final seen = DirectionAndDistance.of(rig.camera.position - target);
      expect(seen.azimuth, closeTo(rig.yaw, 1e-9), reason: reason);
      expect(seen.elevation, closeTo(rig.pitch, 1e-9), reason: reason);
    }
  });
}
