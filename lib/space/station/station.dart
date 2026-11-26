import 'package:vector_math/vector_math_64.dart';

import '../camera/aim.dart';
import '../camera/camera.dart';
import '../camera/direction_and_distance.dart';
import '../system/body.dart';
import '../system/system.dart';
import 'backdrop.dart';
import 'framing.dart';

/// A place on the scroll where the camera holds: what it looks at, and
/// from where.
sealed class Station {
  const Station._(this.framing);

  /// The Landing: the hole, seen from [lineUpViewpoint].
  factory Station.landing(Framing framing) = _LandingStation;

  /// [body], from where [backdrop] shows at its offset from the body.
  factory Station.body(
    Body body,
    Framing framing, {
    required Backdrop backdrop,
  }) = _BodyStation;

  /// The hole, from [holeViewpoint] turned to [sideOf]'s side, so the move
  /// in from [sideOf] goes nearly straight and keeps the hole in front.
  factory Station.hole(Framing framing, {required Station sideOf}) =
      _HoleStation;

  final Framing framing;

  Camera cameraAt(double orbitTime, {double scrollOffset = 0});
}

class _LandingStation extends Station {
  _LandingStation(super.framing) : super._();

  @override
  Camera cameraAt(double orbitTime, {double scrollOffset = 0}) => framing
      .cameraAt(Vector3.zero(), lineUpViewpoint, scrollOffset: scrollOffset);
}

class _BodyStation extends Station {
  _BodyStation(this.body, super.framing, {required this.backdrop})
    : assert(framing.roll == 0, 'A body station does not roll.'),
      super._();

  final Body body;
  final Backdrop backdrop;

  @override
  Camera cameraAt(double orbitTime, {double scrollOffset = 0}) {
    final bodyPosition = body.positionAt(orbitTime);
    return framing.cameraAt(
      bodyPosition,
      levelViewpointShowing(
        backdrop.offsetFromBody,
        fromSecondPoint: bodyPosition - backdrop.positionAt(orbitTime),
        distance: body.radius * body.cameraDistanceInRadii,
      ),
      scrollOffset: scrollOffset,
    );
  }
}

class _HoleStation extends Station {
  _HoleStation(super.framing, {required this.sideOf}) : super._();

  final Station sideOf;

  @override
  Camera cameraAt(double orbitTime, {double scrollOffset = 0}) {
    final sideAzimuth = DirectionAndDistance.of(
      sideOf.cameraAt(orbitTime).position,
    ).azimuth;
    return framing.cameraAt(
      Vector3.zero(),
      DirectionAndDistance(
        azimuth: sideAzimuth + holeViewpoint.azimuth,
        elevation: holeViewpoint.elevation,
        distance: holeViewpoint.distance,
      ),
      scrollOffset: scrollOffset,
    );
  }
}
