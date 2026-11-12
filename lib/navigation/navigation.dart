import 'package:riverpod/riverpod.dart';

import '../providers.dart';
import '../space/body.dart';
import '../space/flight.dart';
import '../space/scene_clock.dart';
import 'map_location.dart';
import 'map_navigation_state.dart';

final navigationProvider = NotifierProvider<Navigation, MapNavigationState>(
  Navigation.new,
);

/// Moves the visitor between the locations of the map. It is the single
/// place where flights start and end.
///
/// The state changes only when a flight starts or ends, and at a jump.
class Navigation extends Notifier<MapNavigationState> {
  late SceneClock _clock;

  @override
  MapNavigationState build() {
    _clock = ref.watch(sceneClockProvider);
    return const AtRest.start();
  }

  /// Starts a flight to [location] from the camera's rig at this time. If a
  /// flight is in progress, the new flight replaces it and starts from where
  /// the camera is, so the camera does not jump.
  void flyTo(MapLocation location) {
    if (location == state.location) return;

    final now = _clock.now;
    final from = state.rigAt(now);
    final arrival = _restAt(location);
    state = InFlight(
      flight: Flight(from: from, startTime: now, destinationAt: arrival.rigAt),
      arrival: arrival,
    );
  }

  /// Puts the camera at [location] immediately, without a flight. At the
  /// overview, the camera keeps its yaw and pitch, as at the end of a flight.
  void jumpTo(MapLocation location) {
    state = _restAt(location);
  }

  /// Ends the flight in progress if the clock of the scene is at or after
  /// the end of the flight. The frame loop should call this function for
  /// each frame, after it moves the clock.
  void endFinishedFlight() {
    final current = state;
    if (current is InFlight && _clock.now >= current.flight.endTime) {
      state = current.arrival;
    }
  }

  /// The state at rest at [location]. At the overview, the camera keeps the
  /// yaw and pitch that it has now, so it does not turn.
  AtRest _restAt(MapLocation location) => switch (location) {
    OverviewLocation() => AtRest.atOverview(state.rigAt(_clock.now)),
    BodyLocation() => AtRest.atBody(
      location,
      ref.read(bodiesProvider).of(location.category.slug),
    ),
  };
}
