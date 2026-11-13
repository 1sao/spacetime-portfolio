import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:homepage_v2/space/camera.dart';
import 'package:homepage_v2/space/direction_and_distance.dart';
import 'package:homepage_v2/space/framing.dart';
import 'package:homepage_v2/space/site_space.dart';

import 'samples.dart';

void main() {
  test('turned and zoomed framings stay within the limits', () {
    for (final MapEntry(key: slug, value: body) in bodies.entries) {
      for (final sign in [-1.0, 1.0]) {
        final framing = Framing.ofCategory(body)
            .turned(byYaw: 10 * sign, byPitch: 10 * sign)
            .zoomed(sign < 0 ? 0.01 : 100);
        expect(framing.yaw.abs(), bodyLimits.maxYaw, reason: slug);
        expect(framing.pitch.abs(), bodyLimits.maxPitch, reason: slug);
        expect(
          framing.distance,
          sign < 0 ? bodyLimits.nearest : bodyLimits.farthest,
          reason: slug,
        );
      }
    }
  });

  test('drag and zoom keep the camera almost as far from the central body '
      'as the body, or farther', () {
    // Not 1: on a tilted orbit, a quarter turn of yaw with the camera
    // turned down can put the camera a little in front of the body (see
    // bodyLimits). The worst case is about 0.985 of the body's distance.
    for (final MapEntry(key: slug, value: body) in bodies.entries) {
      for (final framing in framingsWithin(body, bodyLimits)) {
        for (final time in timesAlongOrbitOf(body)) {
          expect(
            framing.cameraAt(time).position.length,
            greaterThanOrEqualTo(0.98 * body.positionAt(time).length),
            reason:
                '$slug, yaw ${framing.yaw}, pitch ${framing.pitch}, '
                'distance ${framing.distance}, at ${time}s',
          );
        }
      }
    }
  });

  test('the camera stays outside the framed body', () {
    for (final MapEntry(key: slug, value: body) in bodies.entries) {
      expect(bodyLimits.nearest, greaterThan(body.radius), reason: slug);
    }
  });

  test('the overview without zoom is within the zoom limits', () {
    expect(overviewDistance, greaterThanOrEqualTo(overviewLimits.nearest));
    expect(overviewDistance, lessThanOrEqualTo(overviewLimits.farthest));
  });

  test('the overview at its nearest zoom is farther than every camera at a '
      'body', () {
    for (final MapEntry(key: slug, value: body) in bodies.entries) {
      for (final framing in framingsWithin(body, bodyLimits, angles: 3)) {
        for (final time in timesAlongOrbitOf(body)) {
          expect(
            framing.cameraAt(time).position.length,
            lessThan(overviewLimits.nearest),
            reason:
                '$slug, yaw ${framing.yaw}, pitch ${framing.pitch}, '
                'distance ${framing.distance}, at ${time}s',
          );
        }
      }
    }
  });

  test('at a body, the pitch limit keeps the camera within the elevation '
      'that the camera allows', () {
    // A framing's pitch is measured from straight behind the body, so the
    // camera's own elevation is the body's elevation plus the framing's
    // pitch.
    for (final MapEntry(key: slug, value: body) in bodies.entries) {
      final steepestElevation = timesAlongOrbitOf(body, count: 360)
          .map(
            (time) =>
                DirectionAndDistance.of(body.positionAt(time)).elevation.abs(),
          )
          .reduce(math.max);
      expect(
        steepestElevation + bodyLimits.maxPitch,
        lessThanOrEqualTo(maxElevation),
        reason: slug,
      );
    }
  });
}
