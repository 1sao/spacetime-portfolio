import '../space/body.dart';
import '../space/camera_rig.dart';
import '../space/flight.dart';
import '../space/framing.dart';
import 'map_location.dart';

/// Where the visitor is on the map, and how the camera moves there.
///
/// The state changes only when a flight starts or ends, and at a jump.
/// [rigAt] may change each frame, but won't notify the listeners of
/// [MapNavigationState].
sealed class MapNavigationState {
  MapNavigationState();

  /// The location that the visitor is at. During a flight, it is the
  /// location that the flight goes to.
  MapLocation get location;

  /// The rig at [time], in seconds on the clock of the scene.
  CameraRig rigAt(double time);
}

/// The camera is at its location and frames the body of the location. No
/// flight is in progress. When the framed body moves, the camera follows it.
///
/// A drag or a zoom changes the framing of this state, without notifying
/// the listeners of [AtRest].
final class AtRest extends MapNavigationState {
  /// The state at the start of a visit: at rest at the overview.
  AtRest.start()
    : location = const OverviewLocation(),
      _framing = const Framing.overview();

  /// The state at rest at the overview, with the yaw and pitch of [rig].
  /// When [rig] is the camera's rig, the camera goes to the overview
  /// without a turn.
  factory AtRest.atOverview(CameraRig rig) => AtRest._(
    location: const OverviewLocation(),
    framing: Framing.overviewWithAnglesOf(rig),
  );

  /// The state at rest at [location], with a framing of [body]. [body]
  /// should be the body of the category of [location].
  factory AtRest.atBody(BodyLocation location, Body body) => AtRest._(
    location: location,
    framing: switch (location) {
      CategoryLocation() => Framing.ofCategory(body),
      MessageLocation() => Framing.ofMessage(body),
    },
  );

  AtRest._({required this.location, required this._framing});

  @override
  final MapLocation location;

  /// How the camera frames the body of [location]. A drag or a zoom changes
  /// the framing, but does not notify the listeners of [AtRest].
  Framing get framing => _framing;
  Framing _framing;

  /// Turns the camera by [yaw] and [pitch], in rad, within the limits of
  /// the framing at [time].
  void turn({
    required double yaw,
    required double pitch,
    required double time,
  }) {
    _framing = _framing.turned(yaw: yaw, pitch: pitch, time: time);
  }

  /// Multiplies the distance of the camera by [factor], within the limits of
  /// the framing.
  void zoom(double factor) {
    _framing = _framing.zoomed(factor);
  }

  @override
  CameraRig rigAt(double time) => _framing.rigAt(time);
}

/// The camera flies to its location.
final class InFlight extends MapNavigationState {
  InFlight({required this.flight, required this.arrival});

  /// The movement of the camera.
  final Flight flight;

  /// The state that starts when [flight] ends. Its rig is the destination
  /// of [flight], so the camera does not jump.
  final AtRest arrival;

  @override
  MapLocation get location => arrival.location;

  @override
  CameraRig rigAt(double time) => flight.rigAt(time);
}
