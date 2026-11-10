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
sealed class NavigationState {
  const NavigationState();

  /// The location that the visitor is at. During a flight, it is the
  /// location that the flight goes to.
  MapLocation get location;

  /// The rig at [time], in seconds on the clock of the scene.
  CameraRig rigAt(double time);
}

/// The camera is at its location. No flight is in progress.
sealed class AtRest extends NavigationState {
  const AtRest();
}

/// The camera does not move, and it looks at the central body.
final class AtOverview extends AtRest {
  const AtOverview(this.rig);

  /// The rig of the camera.
  final CameraRig rig;

  @override
  OverviewLocation get location => const OverviewLocation();

  @override
  CameraRig rigAt(double time) => rig;
}

/// The camera follows a body along its orbit and keeps one framing of it.
final class AtBody extends AtRest {
  const AtBody({
    required this.location,
    required this.body,
    required this.framing,
  });

  @override
  final BodyLocation location;

  /// The body of the category of [location].
  final Body body;

  /// How the camera frames [body].
  final BodyFraming framing;

  @override
  CameraRig rigAt(double time) => framing.rigFor(body.positionAt(time));
}

/// The camera flies to its location.
final class InFlight extends NavigationState {
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
