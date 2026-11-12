import '../space/body.dart';
import '../space/camera_rig.dart';
import '../space/flight.dart';
import '../space/framing.dart';
import 'map_location.dart';

/// Where the visitor is on the map, and how the camera moves there.
///
/// The state changes only when a flight starts or ends, and at a jump.
/// Between these changes, [rigAt] gives the camera for each
/// frame, so the state does not keep the progress of a flight.
sealed class MapNavigationState {
  const MapNavigationState();

  /// The location that the visitor is at. During a flight, it is the
  /// location that the flight goes to.
  MapLocation get location;

  /// The rig at [time], in seconds on the clock of the scene.
  CameraRig rigAt(double time);
}

/// The camera is at its location and keeps one framing. No flight is in
/// progress. When the framed body moves, the camera follows it.
final class AtRest extends MapNavigationState {
  /// The state at the start of a visit: at rest at the overview.
  const AtRest.start()
    : location = const OverviewLocation(),
      framing = const Framing.overview();

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

  const AtRest._({required this.location, required this.framing});

  @override
  final MapLocation location;

  /// How the camera frames the body of [location]: the central body at the
  /// overview, and the body of the category at a category or a message.
  final Framing framing;

  @override
  CameraRig rigAt(double time) => framing.rigAt(time);
}

/// The camera flies to its location.
final class InFlight extends MapNavigationState {
  const InFlight({required this.flight, required this.arrival});

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
