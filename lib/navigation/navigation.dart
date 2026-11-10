import 'package:riverpod/riverpod.dart';

import '../providers.dart';
import '../space/body.dart';
import '../space/flight.dart';
import '../space/scene_clock.dart';
import '../space/site_space.dart';
import 'map_location.dart';
import 'navigation_state.dart';

final navigationProvider = NotifierProvider<Navigation, NavigationState>(
  Navigation.new,
);

/// Moves the visitor between the locations of the map. It is the single
/// place where flights start and end.
///
/// The state changes only when a flight starts or ends, and at a jump.
class Navigation extends Notifier<NavigationState> {
  late SceneClock _clock;

  @override
  NavigationState build() {
    _clock = ref.watch(sceneClockProvider);
    return AtOverview(overviewRig);
  }

  /// Starts a flight to [location] from the camera's rig at this time. If a
  /// flight is in progress, the new flight replaces it and starts from where
  /// the camera is, so the camera does not jump.
  void flyTo(MapLocation location) {
    if (location == state.location) return;

    final now = _clock.now;
    final from = state.rigAt(now);
    final AtRest arrival = switch (location) {
      OverviewLocation() => AtOverview(overviewWithAnglesOf(from)),
      BodyLocation() => _atBody(location),
    };
    state = InFlight(
      flight: Flight(from: from, startTime: now, destinationAt: arrival.rigAt),
      arrival: arrival,
    );
  }

  /// Puts the camera at [location] immediately, without a flight.
  void jumpTo(MapLocation location) {
    state = switch (location) {
      OverviewLocation() => AtOverview(overviewRig),
      BodyLocation() => _atBody(location),
    };
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

  /// The state at rest at [location], with the body of its category.
  AtBody _atBody(BodyLocation location) => AtBody(
    location: location,
    body: ref.read(bodiesProvider).of(location.category.slug),
    framing: switch (location) {
      CategoryLocation() => bodyFraming,
      MessageLocation() => messageFraming,
    },
  );
}
