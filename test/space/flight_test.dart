import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:homepage_v2/space/camera.dart';
import 'package:homepage_v2/space/camera_rig.dart';
import 'package:homepage_v2/space/direction_and_distance.dart';
import 'package:homepage_v2/space/flight.dart';
import 'package:homepage_v2/space/framing.dart';
import 'package:homepage_v2/space/site_space.dart';
import 'package:vector_math/vector_math_64.dart';

/// The time between two samples of a flight, in seconds.
const _step = 0.001;

void main() {
  Flight toBody(String slug, CameraRig from, double startTime) => Flight.toBody(
    from: from,
    body: bodies[slug]!,
    framing: bodyFraming,
    startTime: startTime,
  );

  Flight toOverview(CameraRig from, double startTime) => Flight.toOverview(
    from: from,
    distance: overviewDistance,
    startTime: startTime,
  );

  /// The start rigs for the flights, each with the time when it applies:
  ///
  /// - The overview at different angles, because a visitor can drag it.
  /// - Each body in its framing.
  /// - Points during flights, because a visitor can select a different body
  ///   before the camera arrives.
  final starts = <(String, CameraRig, double)>[
    for (final yaw in [0.0, math.pi / 2, math.pi, -math.pi / 2])
      for (final pitch in [-1.2, 0.0, 1.2])
        (
          'the overview at yaw $yaw, pitch $pitch',
          CameraRig(
            target: overviewRig.target,
            yaw: yaw,
            pitch: pitch,
            distance: overviewDistance,
          ),
          0.0,
        ),
    for (final slug in bodies.keys)
      for (final time in [0.0, 40.0])
        (
          '$slug framed at ${time}s',
          bodyFraming.rigFor(bodies[slug]!.positionAt(time)),
          time,
        ),
    for (final (name, flight) in [
      for (final from in bodies.keys)
        for (final to in bodies.keys)
          if (from != to)
            (
              'from $from to $to',
              toBody(to, bodyFraming.rigFor(bodies[from]!.positionAt(0)), 0),
            ),
      for (final slug in bodies.keys) ...[
        ('from the overview to $slug', toBody(slug, overviewRig, 0)),
        (
          'from $slug to the overview',
          toOverview(bodyFraming.rigFor(bodies[slug]!.positionAt(0)), 0),
        ),
      ],
    ])
      for (final fraction in [0.1, 0.3, 0.5, 0.7])
        (
          '$fraction of the way $name',
          flight.rigAt(flight.duration * fraction),
          flight.duration * fraction,
        ),
  ];

  /// All flights from all starts, to each body and to the overview. Each
  /// flight has the rigs of its destination at its start time and at its
  /// end time. For a flight to the overview, this value is null, because
  /// the destination does not move.
  final flights = [
    for (final (startName, from, time) in starts) ...[
      for (final MapEntry(key: slug, value: body) in bodies.entries)
        () {
          final flight = toBody(slug, from, time);
          return (
            'from $startName to $slug',
            flight,
            (
              bodyFraming.rigFor(body.positionAt(flight.startTime)),
              bodyFraming.rigFor(body.positionAt(flight.endTime)),
            ),
          );
        }(),
      ('from $startName to the overview', toOverview(from, time), null),
    ],
  ];

  test('the overview is the farthest view', () {
    final overview = overviewRig.camera.position.length;
    for (final MapEntry(key: slug, value: body) in bodies.entries) {
      final flight = toBody(slug, overviewRig, 0);
      final period = 2 * math.pi / body.orbit.angularSpeed;
      for (var i = 0; i < 100; i++) {
        final time = flight.endTime + period * i / 100;
        expect(
          flight.rigAt(time).camera.position.length,
          lessThan(overview),
          reason: 'framing $slug at ${time}s',
        );
      }
    }
  });

  test('a flight keeps the camera outside the radius of the central body', () {
    for (final (name, flight, _) in flights) {
      for (var time = flight.startTime; time <= flight.endTime; time += _step) {
        expect(
          flight.rigAt(time).camera.position.length,
          greaterThan(centralBodyRadius),
          reason: '$name at ${time}s',
        );
      }
    }
  });

  test('a flight starts at the camera position and stops without a jump', () {
    // Use times very near each end. At the ends, rigAt gives the start rig
    // and the destination rig directly, and the test does not examine the eased
    // path.
    for (final (name, flight, _) in flights) {
      final start = flight.from.camera.position;
      expect(
        flight.rigAt(flight.startTime + 1e-9).camera.position.distanceTo(start),
        lessThan(1e-6),
        reason: '$name: start',
      );
      final end = flight.rigAt(flight.endTime).camera.position;
      expect(
        flight.rigAt(flight.endTime - 1e-9).camera.position.distanceTo(end),
        lessThan(1e-6),
        reason: '$name: end',
      );
    }
  });

  test('a flight turns the camera the shorter way', () {
    for (final (name, flight, destination) in flights) {
      // The yaw of the camera turns a half turn or less to the destination at
      // the start time. It also turns as much as the destination turns,
      // because the body moves along its orbit.
      final destinationTurn = destination == null
          ? 0.0
          : wrapAngle(destination.$2.yaw - destination.$1.yaw);
      var turn = 0.0;
      var yaw = flight.from.yaw;
      for (var time = flight.startTime; time <= flight.endTime; time += _step) {
        final next = flight.rigAt(time).yaw;
        turn += wrapAngle(next - yaw);
        yaw = next;
      }
      expect(
        turn.abs(),
        lessThanOrEqualTo(math.pi + destinationTurn.abs() + 1e-9),
        reason: name,
      );
    }
  });

  test('after a flight to a body, the camera has the angles of the framing '
      'and shows the central body, also when the body moves', () {
    // A new kind of framing causes a compile error here. Add a test for the
    // new kind.
    final framing = switch (bodyFraming) {
      final BehindBody framing => framing,
    };
    for (final MapEntry(key: slug, value: body) in bodies.entries) {
      final flight = toBody(slug, overviewRig, 0);
      for (final time in [
        flight.endTime,
        flight.endTime + 10,
        flight.endTime + 37,
      ]) {
        final camera = flight.rigAt(time).camera;
        final bodyPosition = body.positionAt(time);
        final reason = '$slug at ${time}s';

        final towardBody = (bodyPosition - camera.position).normalized();
        expect(
          camera.forward.distanceTo(towardBody),
          lessThan(1e-9),
          reason: '$reason: looks at the body',
        );

        // The position directly behind the body is on the line from the
        // central body through the body. From the body, the camera must be
        // at the offsets of the framing from that line.
        final behind = DirectionAndDistance.of(bodyPosition);
        final seen = DirectionAndDistance.of(camera.position - bodyPosition);
        expect(
          wrapAngle(seen.azimuth - behind.azimuth),
          closeTo(framing.yawOffset, 1e-9),
          reason: '$reason: yaw',
        );
        expect(
          seen.elevation - behind.elevation,
          closeTo(framing.pitchOffset, 1e-9),
          reason: '$reason: pitch',
        );
        expect(
          seen.distance,
          closeTo(framing.distance, 1e-9),
          reason: '$reason: distance',
        );

        for (final screen in const [
          Screen(width: 400, height: 250),
          Screen(width: 250, height: 400),
        ]) {
          final centralBody = camera.project(Vector3.zero(), screen);
          final size = '${screen.width}x${screen.height}';
          expect(centralBody, isNotNull, reason: '$reason, $size: in front');
          expect(
            centralBody!.x,
            inInclusiveRange(0, screen.width),
            reason: '$reason, $size: on screen',
          );
          expect(
            centralBody.y,
            inInclusiveRange(0, screen.height),
            reason: '$reason, $size: on screen',
          );
        }
      }
    }
  });
}
