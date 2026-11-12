import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:homepage_v2/space/body.dart';
import 'package:homepage_v2/space/camera_rig.dart';
import 'package:homepage_v2/space/direction_and_distance.dart';
import 'package:homepage_v2/space/framing.dart';
import 'package:homepage_v2/space/orbit.dart';
import 'package:homepage_v2/space/site_space.dart';

/// [count] values from [first] to [last], equally spaced.
List<double> _range(double first, double last, int count) => [
  for (var i = 0; i < count; i++) first + (last - first) * i / (count - 1),
];

void main() {
  /// Times along one orbit of [body].
  List<double> timesAlongOrbitOf(Body body, {int count = 24}) => [
    for (var i = 0; i < count; i++)
      2 * math.pi / body.orbit.angularSpeed * i / count,
  ];

  test('turned and zoomed framings stay within the limits', () {
    for (final MapEntry(key: slug, value: body) in bodies.entries) {
      for (final sign in [-1.0, 1.0]) {
        final framing = Framing.ofCategory(body)
            .turned(yaw: 10 * sign, pitch: 10 * sign, time: 0)
            .zoomed(sign < 0 ? 0.01 : 100);
        expect(framing.yaw.abs(), lessThanOrEqualTo(math.pi / 2), reason: slug);
        expect(
          framing.pitch.abs(),
          lessThanOrEqualTo(math.pi / 2),
          reason: slug,
        );
        expect(
          framing.distance,
          sign < 0 ? bodyLimits.nearest : bodyLimits.farthest,
          reason: slug,
        );
      }
    }
  });

  test('drag and zoom keep the camera outside the central body', () {
    for (final MapEntry(key: slug, value: body) in bodies.entries) {
      final radius = (body.orbit as CircularOrbit).radius;
      for (final yaw in _range(-math.pi / 2, math.pi / 2, 9)) {
        for (final pitch in _range(-math.pi / 2, math.pi / 2, 9)) {
          for (final distance in _range(
            bodyLimits.nearest,
            bodyLimits.farthest,
            14,
          )) {
            final framing = Framing(
              body: body,
              yaw: yaw,
              pitch: pitch,
              distance: distance,
              limits: bodyLimits,
            );
            for (final time in timesAlongOrbitOf(body)) {
              expect(
                framing.rigAt(time).camera.position.length,
                greaterThanOrEqualTo(0.89 * radius),
                reason:
                    '$slug, yaw $yaw, pitch $pitch, distance $distance, '
                    'at ${time}s',
              );
            }
          }
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
      for (final yaw in [-math.pi / 2, 0.0, math.pi / 2]) {
        for (final pitch in [-math.pi / 2, 0.0, math.pi / 2]) {
          final framing = Framing(
            body: body,
            yaw: yaw,
            pitch: pitch,
            distance: bodyLimits.farthest,
            limits: bodyLimits,
          );
          for (final time in timesAlongOrbitOf(body)) {
            expect(
              framing.rigAt(time).camera.position.length,
              lessThan(overviewLimits.nearest),
              reason: '$slug, yaw $yaw, pitch $pitch, at ${time}s',
            );
          }
        }
      }
    }
  });

  test('a drag back from the pitch clamp moves the camera at once', () {
    // On a tilted orbit, the clamp of the rig is nearer than the limit of
    // the framing when the body is high.
    final body = bodies['projects']!;
    double elevationAt(double time) =>
        DirectionAndDistance.of(body.positionAt(time)).elevation;
    final time = timesAlongOrbitOf(
      body,
      count: 360,
    ).reduce((a, b) => elevationAt(a) > elevationAt(b) ? a : b);

    final up = Framing.ofCategory(body).turned(yaw: 0, pitch: 10, time: time);
    expect(up.rigAt(time).pitch, maxPitch);

    final back = up.turned(yaw: 0, pitch: -0.05, time: time);
    expect(back.rigAt(time).pitch, closeTo(maxPitch - 0.05, 1e-9));
  });
}
