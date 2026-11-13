import 'dart:math' as math;

import 'package:homepage_v2/space/body.dart';
import 'package:homepage_v2/space/flight.dart';
import 'package:homepage_v2/space/framing.dart';
import 'package:homepage_v2/space/site_space.dart';

/// The time between two samples of a flight, in seconds: one frame at
/// 120 Hz.
const _sampleStep = 1 / 120;

/// [count] values from [first] to [last], equally spaced.
List<double> range(double first, double last, int count) => [
  for (var i = 0; i < count; i++) first + (last - first) * i / (count - 1),
];

/// [count] times along one orbit of [body], equally spaced, from time 0.
List<double> timesAlongOrbitOf(Body body, {int count = 24}) => [
  for (var i = 0; i < count; i++)
    2 * math.pi / body.orbit.angularSpeed * i / count,
];

/// Framings of [body] across [limits]: [angles] yaws and pitches each, from
/// one limit to the other, and [distances] distances, from the nearest to
/// the farthest.
Iterable<Framing> framingsWithin(
  Body body,
  FramingLimits limits, {
  int angles = 9,
  int distances = 14,
}) sync* {
  for (final yaw in range(-limits.maxYaw, limits.maxYaw, angles)) {
    for (final pitch in range(-limits.maxPitch, limits.maxPitch, angles)) {
      for (final distance in range(
        limits.nearest,
        limits.farthest,
        distances,
      )) {
        yield Framing(
          body: body,
          yaw: yaw,
          pitch: pitch,
          distance: distance,
          limits: limits,
        );
      }
    }
  }
}

/// Each framing of each of the site's bodies: for its category, and for an
/// open message.
final bodyFramings = [
  for (final MapEntry(key: slug, value: body) in bodies.entries) ...[
    (name: '$slug framed', body: body, framing: Framing.ofCategory(body)),
    (
      name: '$slug with a message',
      body: body,
      framing: Framing.ofMessage(body),
    ),
  ],
];

extension FlightSamples on Flight {
  /// Times from the start of this flight to its end, one for each frame at
  /// 120 Hz.
  Iterable<double> get sampleTimes sync* {
    for (var time = startTime; time < endTime; time += _sampleStep) {
      yield time;
    }
    yield endTime;
  }
}
