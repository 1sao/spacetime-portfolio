import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

import 'camera.dart';
import 'direction_and_distance.dart';

/// The duration of a flight with no swing, in seconds.
const _shortestFlightSeconds = 1.2;

/// One eased move of the camera from a start to a destination.
///
/// A flight is a function of time: it keeps its start, its start time and
/// its destination. The destination can move, and the flight stops exactly
/// on it.
///
/// The target goes around the central body, not through it: its direction
/// and distance from the central body ease. The camera's direction and
/// distance from the target ease too.
class Flight {
  /// A flight from [from] to the camera that [destinationAt] gives for each
  /// time, in seconds on the clock of the scene. It starts at [startTime].
  factory Flight({
    required Camera from,
    required double startTime,
    required Camera Function(double time) destinationAt,
  }) {
    final destination = destinationAt(startTime);
    // Each target as a direction and distance from the central body.
    final startTarget = _targetOf(
      from,
      otherEnd: DirectionAndDistance.of(destination.target),
    );
    final destinationTarget = _targetOf(destination, otherEnd: startTarget);

    // The direction and distance from each target to its camera.
    final startAroundTarget = from.fromTarget;
    final destinationAroundTarget = destination.fromTarget;

    // The camera's azimuth changes by two turns added together: the
    // target's turn around the central body, and the change of the yaw,
    // the camera's angle around the target from straight behind it.
    //
    // - The camera's azimuth turns a half turn or less, so the view turns
    //   the shorter way.
    // - The yaw also turns a half turn or less. A camera at rest has a yaw
    //   within a quarter turn of straight behind its target. So the camera
    //   does not go round to the side of the target that faces the central
    //   body.
    // - The target's turn is the difference, and can be more than a half
    //   turn.
    final cameraAzimuthTurn = wrapAngle(
      destinationAroundTarget.azimuth - startAroundTarget.azimuth,
    );
    final yawTurn = wrapAngle(
      (destinationAroundTarget.azimuth - destinationTarget.azimuth) -
          (startAroundTarget.azimuth - startTarget.azimuth),
    );
    final targetAzimuthTurn = cameraAzimuthTurn - yawTurn;

    // The swing is approximately the angle of the change in the view. It
    // adds the azimuth turn and the elevation turn as the short sides of a
    // right triangle. At a steep elevation it is too large, so the flight
    // is a little slower.
    final elevationTurn =
        destinationAroundTarget.elevation - startAroundTarget.elevation;
    final swing = math.sqrt(
      cameraAzimuthTurn * cameraAzimuthTurn + elevationTurn * elevationTurn,
    );

    // The duration goes from the shortest, at no swing, to two times the
    // shortest, at a half turn or more.
    final duration =
        _shortestFlightSeconds * (1 + math.min(swing, math.pi) / math.pi);

    return Flight._eased(
      from: from,
      startTime: startTime,
      duration: duration,
      destinationAt: destinationAt,
      startTarget: startTarget,
      targetAzimuth: _MovingAngle(
        from: startTarget.azimuth,
        turn: targetAzimuthTurn,
        destinationAtStart: destinationTarget.azimuth,
      ),
      cameraAzimuth: _MovingAngle(
        from: startAroundTarget.azimuth,
        turn: cameraAzimuthTurn,
        destinationAtStart: destinationAroundTarget.azimuth,
      ),
    );
  }

  Flight._eased({
    required this.from,
    required this.startTime,
    required this.duration,
    required this._destinationAt,
    required this._startTarget,
    required this._targetAzimuth,
    required this._cameraAzimuth,
  });

  /// The camera at the start of the flight.
  final Camera from;

  /// The time when the flight starts, in seconds on the clock of the scene.
  final double startTime;

  /// The duration of the flight, in seconds. A larger swing of the camera
  /// around the central body gives a longer duration. This prevents a fast
  /// movement of the sky.
  final double duration;

  double get endTime => startTime + duration;

  final Camera Function(double time) _destinationAt;

  /// The target at the start, as a direction and distance from the central
  /// body.
  final DirectionAndDistance _startTarget;

  /// The azimuth of the target from the central body.
  final _MovingAngle _targetAzimuth;

  /// The azimuth of the camera from the target.
  final _MovingAngle _cameraAzimuth;

  /// The camera at [time], in seconds on the clock of the scene. Before
  /// [startTime], it is the start camera. At [endTime] and after it, it is the
  /// destination. Because of this, the camera follows the body after a
  /// flight to a body.
  Camera cameraAt(double time) {
    final progress = (time - startTime) / duration;
    if (progress <= 0) return from;
    final destination = _destinationAt(time);
    if (progress >= 1) return destination;
    final eased = _easeInOutCubic(progress);

    final destinationTarget = _targetOf(destination, otherEnd: _startTarget);
    final target = DirectionAndDistance(
      azimuth: _targetAzimuth.at(
        eased,
        destinationNow: destinationTarget.azimuth,
      ),
      elevation: mix(
        _startTarget.elevation,
        destinationTarget.elevation,
        eased,
      ),
      distance: mix(_startTarget.distance, destinationTarget.distance, eased),
    );
    final startAroundTarget = from.fromTarget;
    final destinationAroundTarget = destination.fromTarget;
    return Camera(
      target: target.toVector3(),
      fromTarget: DirectionAndDistance(
        azimuth: _cameraAzimuth.at(
          eased,
          destinationNow: destinationAroundTarget.azimuth,
        ),
        elevation: mix(
          startAroundTarget.elevation,
          destinationAroundTarget.elevation,
          eased,
        ),
        distance: mix(
          startAroundTarget.distance,
          destinationAroundTarget.distance,
          eased,
        ),
      ),
    );
  }
}

/// The target of [camera] as a direction and distance from the central body.
///
/// The central body has no direction. In a flight to or from the overview,
/// the target moves straight out from the central body or straight in. So
/// an end at the central body takes the direction of [otherEnd]. This
/// direction does not move the target. It does not change the camera's
/// direction from the target.
DirectionAndDistance _targetOf(
  Camera camera, {
  required DirectionAndDistance otherEnd,
}) {
  final target = DirectionAndDistance.of(camera.target);
  if (target.distance > 0) return target;
  return DirectionAndDistance(
    azimuth: otherEnd.azimuth,
    elevation: otherEnd.elevation,
    distance: 0,
  );
}

/// An angle that eases to a destination that can move. The turn keeps its
/// direction when the destination goes past ±π. The destination should
/// move less than a half turn during the flight.
class _MovingAngle {
  const _MovingAngle({
    required this.from,
    required this.turn,
    required this.destinationAtStart,
  });

  /// The angle at the start, in rad.
  final double from;

  /// The turn to the destination at the start time, in rad.
  final double turn;

  /// The destination at the start time, in rad.
  final double destinationAtStart;

  /// The angle when the ease is at [eased], with the destination at
  /// [destinationNow].
  double at(double eased, {required double destinationNow}) =>
      from + eased * (turn + wrapAngle(destinationNow - destinationAtStart));
}

/// Eases [progress] from 0 to 1. The movement starts at rest, is fastest
/// at the middle, and stops at rest.
///
/// For the first half, the result is 4 · progress³, from 0 to 0.5. The
/// second half is the first half, rotated 180° around the point (0.5, 0.5).
/// Its result goes from 0.5 to 1.
double _easeInOutCubic(double progress) => progress < 0.5
    ? 4 * progress * progress * progress
    : 1 - math.pow(2 - 2 * progress, 3) / 2;
