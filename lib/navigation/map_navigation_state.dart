import '../space/body.dart';
import '../space/camera.dart';
import '../space/flight.dart';
import '../space/framing.dart';
import 'map_location.dart';

/// Where the visitor is on the map, and how the camera moves there.
///
/// The state changes only when a flight starts or ends, and at a jump.
/// [cameraAt] changes each frame without a new state.
sealed class MapNavigationState {
  /// The location that the visitor is at. During a flight, it is the
  /// location that the flight goes to.
  MapLocation get location;

  /// The camera at [time], in seconds on the clock of the scene.
  Camera cameraAt(double time);
}

/// The camera is at its location and frames the body of the location. No
/// flight is in progress. When the framed body moves, the camera follows it.
///
/// A drag or a zoom changes the framing of this state in place, without a
/// new state, so listeners hear only transitions.
final class AtRest extends MapNavigationState {
  /// The state at the start of a visit: at rest at the overview.
  AtRest.start()
    : location = const OverviewLocation(),
      _framing = const Framing.overview();

  /// The state at rest at the overview, with the angles of [camera] (see
  /// [Framing.overviewWithAnglesOf]).
  factory AtRest.atOverview(Camera camera) => AtRest._(
    location: const OverviewLocation(),
    framing: Framing.overviewWithAnglesOf(camera),
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

  /// How the camera frames the body of [location].
  Framing get framing => _framing;
  Framing _framing;

  /// Turns the framing by [yaw] and [pitch] (see [Framing.turned]).
  void turn({required double yaw, required double pitch}) {
    _framing = _framing.turned(byYaw: yaw, byPitch: pitch);
  }

  /// Zooms the framing by [factor] (see [Framing.zoomed]).
  void zoom(double factor) {
    _framing = _framing.zoomed(factor);
  }

  @override
  Camera cameraAt(double time) => _framing.cameraAt(time);
}

/// The camera flies to its location.
final class InFlight extends MapNavigationState {
  InFlight({required this.flight, required this.arrival});

  /// The movement of the camera.
  final Flight flight;

  /// The state that starts when [flight] ends. Its camera is the destination
  /// of [flight], so the camera does not jump.
  final AtRest arrival;

  @override
  MapLocation get location => arrival.location;

  @override
  Camera cameraAt(double time) => flight.cameraAt(time);
}
