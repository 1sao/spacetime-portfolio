import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

import 'camera_rig.dart';
import 'direction_and_distance.dart';

/// The duration of a flight with no swing, in seconds.
const _shortestFlightSeconds = 1.2;

/// One eased movement of the camera from its start to a destination, such
/// as the framing of a body or the overview.
///
/// A flight is a function of time. It keeps only its start, its destination
/// and its start time. The navigation state can keep a flight, and the frame
/// loop can get the rig from it for each frame.
///
/// To change the destination during a flight, start a new flight from the
/// rig that [rigAt] gives at that time. Then the camera does not jump.
///
/// These values ease together from the start to the destination:
///
/// - The direction and distance of the target from the central body. The
///   target goes around the central body, not through it.
/// - The yaw and pitch of the camera, measured from the direction of the
///   target from the central body. The total turn of the camera's yaw is a
///   half turn or less.
/// - The distance from the camera to the target.
///
/// The flight gets the destination again for each time. Because of this,
/// the flight stops exactly at a body that moves.
class Flight {
  /// A flight from [from] to the rig that [destinationAt] gives for each
  /// time, in seconds on the clock of the scene. It starts at [startTime].
  /// The destination can move, such as the framing of a body.
  factory Flight({
    required CameraRig from,
    required double startTime,
    required CameraRig Function(double time) destinationAt,
  }) {
    final destination = destinationAt(startTime);
    // The target at the central body, at the origin, has no direction. In
    // a flight to or from the overview, the target moves straight out from
    // the central body or straight in. So an end at the central body takes
    // the direction of the other end. This direction does not move the
    // target, and the camera's yaw and pitch do not change because of it.
    final fromTarget = DirectionAndDistance.of(
      from.target,
      directionAtOrigin: DirectionAndDistance.of(destination.target),
    );
    final destinationTarget = DirectionAndDistance.of(
      destination.target,
      directionAtOrigin: fromTarget,
    );
    final destinationRelativeYaw = destination.yaw - destinationTarget.azimuth;

    // The yaw of the camera changes by two turns: the turn of the target
    // around the central body, plus the turn of the camera around the
    // target.
    //
    // The turn of the camera around the target is always the shorter turn.
    // The longer turn moves the camera past the side of the target that is
    // nearer to the central body.
    //
    // The two turns can add up to almost a full turn. If the sum is more
    // than a half turn, the target turns the other way around the central
    // body. Then the sum is a half turn or less. The distance from the
    // target to the central body is the same for the two directions.
    final cameraTurn = wrapAngle(
      destinationRelativeYaw - (from.yaw - fromTarget.azimuth),
    );
    final shortAzimuthTurn = wrapAngle(
      destinationTarget.azimuth - fromTarget.azimuth,
    );
    final shortSum = shortAzimuthTurn + cameraTurn;
    final azimuthTurn = shortSum > math.pi
        ? shortAzimuthTurn - 2 * math.pi
        : shortSum < -math.pi
        ? shortAzimuthTurn + 2 * math.pi
        : shortAzimuthTurn;

    // The swing is the angle of the change in the view. It adds the yaw turn
    // and the pitch turn as the two short sides of a right triangle
    // (Pythagoras). This is an approximation. When the camera looks up or
    // down at a pitch p, a yaw turn moves the view by approximately cos p
    // times the turn. The swing does not include this. Because of this, the
    // swing is too large for a steep pitch, and the flight is a little
    // slower.
    final yawTurn = azimuthTurn + cameraTurn;
    final pitchTurn = destination.pitch - from.pitch;
    final swing = math.sqrt(yawTurn * yawTurn + pitchTurn * pitchTurn);

    // The duration increases linearly with the swing, from the shortest
    // duration at no swing to two times the shortest at a swing of π rad (a
    // half turn). A larger swing gives the same duration as π rad. The
    // swing is to the destination at the start time, so the duration does
    // not include the movement of the destination during the flight.
    final duration =
        _shortestFlightSeconds * (1 + math.min(swing, math.pi) / math.pi);

    return Flight._eased(
      from: from,
      startTime: startTime,
      duration: duration,
      destinationAt: destinationAt,
      fromTarget: fromTarget,
      destinationAzimuthAtStart: destinationTarget.azimuth,
      azimuthTurn: azimuthTurn,
      destinationRelativeYawAtStart: destinationRelativeYaw,
      cameraTurn: cameraTurn,
    );
  }

  Flight._eased({
    required this.from,
    required this.startTime,
    required this.duration,
    required this._destinationAt,
    required this._fromTarget,
    required this._destinationAzimuthAtStart,
    required this._azimuthTurn,
    required this._destinationRelativeYawAtStart,
    required this._cameraTurn,
  });

  /// The rig at the start of the flight.
  final CameraRig from;

  /// The time when the flight starts, in seconds on the clock of the scene.
  final double startTime;

  /// The duration of the flight, in seconds. A larger swing of the camera
  /// around the central body gives a longer duration. This prevents a fast
  /// movement of the sky.
  final double duration;

  double get endTime => startTime + duration;

  final CameraRig Function(double time) _destinationAt;

  /// The target at the start, as a direction and distance from the central
  /// body.
  final DirectionAndDistance _fromTarget;

  /// The azimuth of the target of the destination at the start time, in
  /// rad.
  final double _destinationAzimuthAtStart;

  /// The turn of the target's azimuth from the start to the destination at
  /// the start time, in rad.
  final double _azimuthTurn;

  /// The yaw of the destination at the start time, in rad. It is measured
  /// from the direction of the destination's target from the central body.
  final double _destinationRelativeYawAtStart;

  /// The turn of the camera's yaw around the target, from the start to the
  /// destination at the start time, in rad. The yaw is measured from the
  /// direction of the target from the central body. This turn is the
  /// shorter turn.
  final double _cameraTurn;

  double get _fromRelativeYaw => from.yaw - _fromTarget.azimuth;

  double get _fromRelativePitch => from.pitch - _fromTarget.elevation;

  /// The rig at [time], in seconds on the clock of the scene. Before
  /// [startTime], it is the start rig. At [endTime] and after it, it is the
  /// destination. Because of this, the camera follows the body after a
  /// flight to a body.
  CameraRig rigAt(double time) {
    final progress = (time - startTime) / duration;
    if (progress <= 0) return from;
    final destination = _destinationAt(time);
    if (progress >= 1) return destination;
    final eased = _easeInOutCubic(progress);

    // As at the start, a destination at the central body takes the
    // direction of the start.
    final destinationTarget = DirectionAndDistance.of(
      destination.target,
      directionAtOrigin: _fromTarget,
    );
    // The destination azimuth for the ease. It is the start azimuth, plus
    // the turn from the start time, plus the movement of the destination
    // after the start time. With this calculation, the turn keeps its
    // direction when the destination azimuth goes past ±π. The movement of
    // the destination during the flight must be less than a half turn.
    // A larger movement makes the camera jump.
    final destinationAzimuth =
        _fromTarget.azimuth +
        _azimuthTurn +
        wrapAngle(destinationTarget.azimuth - _destinationAzimuthAtStart);
    final target = DirectionAndDistance(
      azimuth: mix(_fromTarget.azimuth, destinationAzimuth, eased),
      elevation: mix(_fromTarget.elevation, destinationTarget.elevation, eased),
      distance: mix(_fromTarget.distance, destinationTarget.distance, eased),
    );

    // The yaw and pitch of the camera around the target, measured from the
    // direction of the target from the central body. The calculation of the
    // destination yaw is the same as the calculation of the destination
    // azimuth.
    final destinationRelativeYaw =
        _fromRelativeYaw +
        _cameraTurn +
        wrapAngle(
          (destination.yaw - destinationTarget.azimuth) -
              _destinationRelativeYawAtStart,
        );
    final relativeYaw = mix(_fromRelativeYaw, destinationRelativeYaw, eased);
    final relativePitch = mix(
      _fromRelativePitch,
      destination.pitch - destinationTarget.elevation,
      eased,
    );

    return CameraRig(
      target: target.toVector3(),
      yaw: target.azimuth + relativeYaw,
      pitch: target.elevation + relativePitch,
      distance: mix(from.distance, destination.distance, eased),
    );
  }
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
