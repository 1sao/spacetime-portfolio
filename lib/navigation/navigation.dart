import 'package:riverpod/riverpod.dart';

import '../providers.dart';
import '../space/body.dart';
import '../space/camera.dart';
import '../space/flight.dart';
import '../space/scene_clock.dart';
import 'map_location.dart';
import 'map_navigation_state.dart';

final navigationProvider = NotifierProvider<Navigation, MapNavigationState>(
  Navigation.new,
);

/// Moves the visitor between the locations of the map. It is the single
/// place where flights start and end.
class Navigation extends Notifier<MapNavigationState> {
  late SceneClock _clock;

  @override
  MapNavigationState build() {
    _clock = ref.watch(sceneClockProvider);
    return AtRest.start();
  }

  /// Starts a flight to [location] from the camera at this time. If a
  /// flight is in progress, the new flight replaces it and starts from where
  /// the camera is, so the camera does not jump.
  void flyTo(MapLocation location) {
    if (location == state.location) return;

    final now = _clock.now;
    final from = state.cameraAt(now);
    final arrival = _restAt(location, from: from);
    state = InFlight(
      flight: Flight(
        from: from,
        startTime: now,
        destinationAt: arrival.cameraAt,
      ),
      arrival: arrival,
    );
  }

  /// Puts the camera at [location] immediately, without a flight.
  void jumpTo(MapLocation location) {
    state = _restAt(location, from: state.cameraAt(_clock.now));
  }

  /// Turns the camera at rest (see [AtRest.turn]). During a flight, it does
  /// nothing.
  void turn({required double yaw, required double pitch}) {
    final current = state;
    if (current is! AtRest) return;
    current.turn(yaw: yaw, pitch: pitch);
  }

  /// Zooms the camera at rest (see [AtRest.zoom]). During a flight, it does
  /// nothing.
  void zoom(double factor) {
    final current = state;
    if (current is! AtRest) return;
    current.zoom(factor);
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

  /// The state at rest at [location], for a camera that is at [from] now.
  AtRest _restAt(MapLocation location, {required Camera from}) =>
      switch (location) {
        OverviewLocation() => AtRest.atOverview(from),
        BodyLocation() => AtRest.atBody(
          location,
          ref.read(bodiesProvider).of(location.category.slug),
        ),
      };
}
