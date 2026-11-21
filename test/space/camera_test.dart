import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:homepage_v2/space/camera.dart';
import 'package:homepage_v2/space/direction_and_distance.dart';
import 'package:vector_math/vector_math_64.dart';

import '../matchers.dart';

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
        focalLength: 500,
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
        nearlyEquals(camera.fromTarget.azimuth),
        reason: reason,
      );
      expect(
        seen.elevation,
        nearlyEquals(camera.fromTarget.elevation),
        reason: reason,
      );
    }
  });

  test('the ray through the pixel where a point lands passes through the '
      'point, at any roll, for a camera aimed off the middle', () {
    const screen = Screen(width: 400, height: 250);
    final points = [Vector3(3, 1, -2), Vector3(-6, 4, 1), Vector3(2, -5, 5)];
    for (final roll in [0.0, 0.6, math.pi / 2, -2.0]) {
      final camera = Camera(
        target: Vector3(0, 1, 0),
        fromTarget: DirectionAndDistance.of(Vector3(8, 3, 20)),
        focalLength: 320,
        screenPoint: Vector2(0.3, 0.6),
        roll: roll,
      );
      for (final point in points) {
        final pixel = camera.project(point, screen)!;
        final toPoint = (point - camera.position).normalized();
        final ray = camera.rayThrough(pixel, screen);
        expect(ray.distanceTo(toPoint), nearlyEquals(0), reason: 'roll $roll');
      }
    }
  });

  test('a quarter turn of roll shows what is left of the target above it', () {
    const screen = Screen(width: 400, height: 400);
    Camera cameraWith({required double roll}) => Camera(
      target: Vector3.zero(),
      fromTarget: const DirectionAndDistance(
        azimuth: 0,
        elevation: 0,
        distance: 10,
      ),
      focalLength: 400,
      roll: roll,
    );
    final left = Vector3(-1, 0, 0);
    final level = cameraWith(roll: 0);
    final rolled = cameraWith(roll: math.pi / 2);
    final middle = level.targetPixel(screen);
    expect(level.project(left, screen)!.x, lessThan(middle.x));
    final shown = rolled.project(left, screen)!;
    expect(shown.x, nearlyEquals(middle.x));
    expect(shown.y, lessThan(middle.y));
  });
}
