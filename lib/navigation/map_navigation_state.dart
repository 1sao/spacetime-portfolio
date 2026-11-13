import '../space/body.dart';
import '../space/camera.dart';
import '../space/flight.dart';
import '../space/framing.dart';
import 'map_location.dart';

/// Where the visitor is on the map, and how the camera moves there.
///
/// The state changes only when a flight starts or ends, and at a jump.
/// [cameraAt] may change each frame, but won't notify the listeners of
/// [MapNavigationState].
sealed class MapNavigationState {
  MapNavigationState();

  /// The location that the visitor is at. During a flight, it is the
  /// location that the flight goes to.
  MapLocation get location;

  /// The camera at [time], in seconds on the clock of the scene.
  Camera cameraAt(double time);
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

  /// The state at rest at the overview, with the angles of [camera]. When
  /// [camera] is the current camera, the camera goes to the overview
  /// without a turn.
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

  /// How the camera frames the body of [location]. A drag or a zoom changes
  /// the framing, but does not notify the listeners of [AtRest].
  Framing get framing => _framing;
  Framing _framing;

  /// Turns the camera by [yaw] and [pitch], in rad, within the limits of
  /// the framing.
  void turn({required double yaw, required double pitch}) {
    _framing = _framing.turned(byYaw: yaw, byPitch: pitch);
  }

  /// Multiplies the distance of the camera by [factor], within the limits of
  /// the framing.
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
