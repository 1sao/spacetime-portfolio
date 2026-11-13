import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:homepage_v2/space/camera.dart';
import 'package:homepage_v2/space/direction_and_distance.dart';
import 'package:homepage_v2/space/flight.dart';
import 'package:homepage_v2/space/framing.dart';
import 'package:homepage_v2/space/site_space.dart';
import 'package:vector_math/vector_math_64.dart';

import '../camera_matchers.dart';
import 'samples.dart';

/// A camera that a flight can start from, at [time].
typedef _Start = ({String name, Camera camera, double time});

/// A flight to [destination] from [from], which starts at [at].
Flight _flightTo(Framing destination, {required Camera from, double at = 0}) =>
    Flight(from: from, startTime: at, destinationAt: destination.cameraAt);

void main() {
  /// The overview at different angles and zooms, because a visitor can drag
  /// and zoom it.
  final overviewStarts = <_Start>[
    for (final yaw in [0.0, math.pi / 2, math.pi, -math.pi / 2])
      for (final pitch in [-1.2, 0.0, 1.2])
        for (final distance in [
          overviewLimits.nearest,
          overviewDistance,
          overviewLimits.farthest,
        ])
          (
            name: 'the overview at yaw $yaw, pitch $pitch, distance $distance',
            camera: Framing(
              body: centralBody,
              yaw: yaw,
              pitch: pitch,
              distance: distance,
              limits: overviewLimits,
            ).cameraAt(0),
            time: 0,
          ),
  ];

  /// Each body, turned and zoomed to the limits of its framing.
  final draggedStarts = <_Start>[
    for (final MapEntry(key: slug, value: body) in bodies.entries)
      for (final yaw in [-double.infinity, double.infinity])
        for (final pitch in [-double.infinity, double.infinity])
          for (final factor in [0.0, double.infinity])
            (
              name: '$slug turned by $yaw and $pitch, and zoomed by $factor',
              camera: Framing.ofCategory(body)
                  .turned(byYaw: yaw, byPitch: pitch)
                  .zoomed(factor)
                  .cameraAt(0),
              time: 0,
            ),
  ];

  /// Each body in each of its framings, at two points along its orbit.
  final framedStarts = <_Start>[
    for (final (:name, body: _, :framing) in bodyFramings)
      for (final time in [0.0, 40.0])
        (name: '$name at ${time}s', camera: framing.cameraAt(time), time: time),
  ];

  /// Points during flights, because a visitor can select a different body
  /// before the camera arrives.
  final midFlightStarts = <_Start>[
    for (final (name, flight) in [
      for (final from in bodies.keys)
        for (final to in bodies.keys)
          if (from != to)
            (
              'from $from to $to',
              _flightTo(
                Framing.ofCategory(bodies[to]!),
                from: Framing.ofCategory(bodies[from]!).cameraAt(0),
              ),
            ),
      for (final MapEntry(key: slug, value: body) in bodies.entries) ...[
        (
          'from the overview to $slug',
          _flightTo(
            Framing.ofCategory(body),
            from: const Framing.overview().cameraAt(0),
          ),
        ),
        () {
          final from = Framing.ofCategory(body).cameraAt(0);
          return (
            'from $slug to the overview',
            _flightTo(Framing.overviewWithAnglesOf(from), from: from),
          );
        }(),
      ],
    ])
      for (final fraction in [0.1, 0.3, 0.5, 0.7])
        (
          name: '$fraction of the way $name',
          camera: flight.cameraAt(flight.duration * fraction),
          time: flight.duration * fraction,
        ),
  ];

  /// All flights from all starts, to each framing of each body and to the
  /// overview, with the destination's camera at the start and at the end.
  final flights = [
    for (final start in [
      ...overviewStarts,
      ...draggedStarts,
      ...framedStarts,
      ...midFlightStarts,
    ]) ...[
      for (final (:name, body: _, :framing) in bodyFramings)
        () {
          final flight = _flightTo(framing, from: start.camera, at: start.time);
          return (
            name: 'from ${start.name} to $name',
            flight: flight,
            destinationAtStart: framing.cameraAt(flight.startTime),
            destinationAtEnd: framing.cameraAt(flight.endTime),
          );
        }(),
      () {
        final overview = Framing.overviewWithAnglesOf(start.camera);
        return (
          name: 'from ${start.name} to the overview',
          flight: _flightTo(overview, from: start.camera, at: start.time),
          destinationAtStart: overview.cameraAt(0),
          destinationAtEnd: overview.cameraAt(0),
        );
      }(),
    ],
  ];

  /// A flight from the overview to each framing of each body, with times
  /// from its end on, also when the body has moved along its orbit.
  final arrivals = [
    for (final (:name, :body, :framing) in bodyFramings)
      () {
        final flight = _flightTo(
          framing,
          from: const Framing.overview().cameraAt(0),
        );
        return (
          name: name,
          body: body,
          framing: framing,
          flight: flight,
          times: [flight.endTime, flight.endTime + 10, flight.endTime + 37],
        );
      }(),
  ];

  test('the overview is the farthest view', () {
    final overview = const Framing.overview().cameraAt(0).position.length;
    for (final (:name, :body, :flight, framing: _, times: _) in arrivals) {
      for (final time in timesAlongOrbitOf(body, count: 100)) {
        expect(
          flight.cameraAt(flight.endTime + time).position.length,
          lessThan(overview),
          reason: '$name at ${flight.endTime + time}s',
        );
      }
    }
  });

  test('a flight keeps the camera outside the radius of the central body', () {
    for (final (:name, :flight, destinationAtStart: _, destinationAtEnd: _)
        in flights) {
      for (final time in flight.sampleTimes) {
        expect(
          flight.cameraAt(time).position.length,
          greaterThan(centralBody.radius),
          reason: '$name at ${time}s',
        );
      }
    }
  });

  test('a flight starts at the camera position and stops without a jump', () {
    // Use times very near each end. At the ends, cameraAt gives the start
    // camera and the destination camera directly.
    for (final (:name, :flight, destinationAtStart: _, destinationAtEnd: _)
        in flights) {
      expect(
        flight.cameraAt(flight.startTime + 1e-9),
        isCameraCloseTo(flight.from, tolerance: 1e-6),
        reason: '$name: start',
      );
      expect(
        flight.cameraAt(flight.endTime - 1e-9),
        isCameraCloseTo(flight.cameraAt(flight.endTime), tolerance: 1e-6),
        reason: '$name: end',
      );
    }
  });

  test('a flight turns the camera the shorter way', () {
    for (final (:name, :flight, :destinationAtStart, :destinationAtEnd)
        in flights) {
      // The azimuth of the camera turns a half turn or less to the
      // destination at the start time. It also turns as much as the
      // destination turns, because the body moves along its orbit.
      final destinationTurn = wrapAngle(
        destinationAtEnd.fromTarget.azimuth -
            destinationAtStart.fromTarget.azimuth,
      );
      var turn = 0.0;
      var azimuth = flight.from.fromTarget.azimuth;
      for (final time in flight.sampleTimes) {
        final next = flight.cameraAt(time).fromTarget.azimuth;
        turn += wrapAngle(next - azimuth);
        azimuth = next;
      }
      expect(
        turn.abs(),
        lessThanOrEqualTo(math.pi + destinationTurn.abs() + 1e-9),
        reason: name,
      );
    }
  });

  test('after a flight to a body, the camera has the angles of the framing '
      'and looks at the body', () {
    for (final (:name, :body, :framing, :flight, :times) in arrivals) {
      for (final time in times) {
        final camera = flight.cameraAt(time);
        final bodyPosition = body.positionAt(time);
        final reason = '$name at ${time}s';

        expect(
          camera.forward.distanceTo(
            (bodyPosition - camera.position).normalized(),
          ),
          lessThan(1e-9),
          reason: '$reason: looks at the body',
        );

        // From the body, the camera must be at the angles of the framing
        // from straight behind the body.
        final behind = DirectionAndDistance.of(bodyPosition);
        final seen = DirectionAndDistance.of(camera.position - bodyPosition);
        expect(
          wrapAngle(seen.azimuth - behind.azimuth),
          closeTo(framing.yaw, 1e-9),
          reason: '$reason: yaw',
        );
        expect(
          seen.elevation - behind.elevation,
          closeTo(framing.pitch, 1e-9),
          reason: '$reason: pitch',
        );
        expect(
          seen.distance,
          closeTo(framing.distance, 1e-9),
          reason: '$reason: distance',
        );
      }
    }
  });

  test('after a flight to a body, the body does not hide the central '
      'body', () {
    for (final (:name, :body, :framing, :flight, :times) in arrivals) {
      for (final time in times) {
        final camera = flight.cameraAt(time);
        final towardBody = body.positionAt(time) - camera.position;
        final towardCentralBody = -camera.position;
        // The disc's angular radius, seen from the camera, is
        // asin(radius / distance).
        expect(
          towardBody.angleTo(towardCentralBody),
          greaterThan(math.asin(body.radius / framing.distance)),
          reason: '$name at ${time}s',
        );
      }
    }
  });

  test('after a flight to a body, the central body is on screen', () {
    for (final (:name, :flight, :times, body: _, framing: _) in arrivals) {
      for (final time in times) {
        for (final screen in const [
          Screen(width: 400, height: 250),
          Screen(width: 250, height: 400),
        ]) {
          expect(
            flight.cameraAt(time).project(Vector3.zero(), screen),
            isOnScreen(screen),
            reason: '$name at ${time}s',
          );
        }
      }
    }
  });
}
