import 'package:flutter_test/flutter_test.dart';
import 'package:homepage_v2/navigation/map_location.dart';
import 'package:homepage_v2/navigation/map_navigation_state.dart';
import 'package:homepage_v2/navigation/navigation.dart';
import 'package:homepage_v2/providers.dart';
import 'package:homepage_v2/space/body.dart';
import 'package:homepage_v2/space/camera.dart';
import 'package:homepage_v2/space/scene_clock.dart';
import 'package:homepage_v2/space/site_space.dart';
import 'package:riverpod/riverpod.dart';

import '../camera_matchers.dart';
import '../fake_content.dart';

/// Puts a new navigation into the state that a test starts from.
typedef _Setup = void Function(Navigation navigation, SceneClock clock);

void main() {
  final projects = fakeContent.first;

  /// The states that a visitor can be in, each as a name and a setup:
  ///
  /// - At rest at each location, also after a drag and a zoom in or out.
  /// - During a flight from each location to each other location.
  /// - During a flight that started during a different flight.
  final starts = <(String, _Setup)>[
    for (final location in fakeLocations)
      ('at ${location.path}', (navigation, _) => navigation.jumpTo(location)),
    for (final location in fakeLocations)
      for (final factor in [0.1, 10.0])
        (
          'at ${location.path}, turned and zoomed by $factor',
          (navigation, _) => navigation
            ..jumpTo(location)
            ..turn(yaw: 4, pitch: 2)
            ..zoom(factor),
        ),
    for (final from in fakeLocations)
      for (final to in fakeLocations)
        if (from != to)
          (
            'during the flight from ${from.path} to ${to.path}',
            (navigation, clock) {
              navigation.jumpTo(from);
              clock.advanceBy(3);
              navigation.flyTo(to);
              clock.advanceBy(0.5);
            },
          ),
    for (final from in fakeLocations)
      for (final first in fakeLocations)
        for (final second in fakeLocations)
          if (from != first && first != second)
            (
              'during the flight to ${second.path} that started during the '
                  'flight from ${from.path} to ${first.path}',
              (navigation, clock) {
                navigation.jumpTo(from);
                navigation.flyTo(first);
                clock.advanceBy(0.7);
                navigation.flyTo(second);
                clock.advanceBy(0.4);
              },
            ),
  ];

  test('Esc from each state ends at rest at the overview', () {
    for (final (name, setup) in starts) {
      for (final isWaitingForEachFlight in [true, false]) {
        final visit = _Visit(setup);
        final wasAtRestAtOverview =
            visit.state is AtRest && visit.state.location is OverviewLocation;

        // Three presses at most, so a wrong parent fails the test instead
        // of hanging it.
        for (var presses = 0; presses < 3; presses++) {
          final parent = visit.state.location.parent;
          if (parent == null) break;
          visit.navigation.flyTo(parent);
          if (isWaitingForEachFlight) visit.finishFlight();
        }
        visit.finishFlight();

        final reason = '$name, waiting: $isWaitingForEachFlight';
        expect(visit.state, isA<AtRest>(), reason: reason);
        expect(visit.state.location, const OverviewLocation(), reason: reason);
        expect(visit.camera.target.length, 0, reason: '$reason: target');
        // At rest at the overview, Esc starts no flight, so a zoom stays.
        if (!wasAtRestAtOverview) {
          expect(
            visit.camera.fromTarget.distance,
            overviewDistance,
            reason: '$reason: distance',
          );
        }
      }
    }
  });

  test('the camera does not jump when a flight starts or ends', () {
    for (final (name, setup) in starts) {
      for (final destination in fakeLocations) {
        final visit = _Visit(setup);
        final reason = '$name, to ${destination.path}';

        final before = visit.camera;
        visit.navigation.flyTo(destination);
        expect(visit.camera, isCameraCloseTo(before), reason: reason);

        if (visit.state case InFlight(:final flight, :final arrival)) {
          // The later time shows that the camera at rest follows the body
          // as the flight does after its end.
          for (final time in [flight.endTime, flight.endTime + 10]) {
            expect(
              arrival.cameraAt(time),
              isCameraCloseTo(flight.cameraAt(time)),
              reason: '$reason: arrival at ${time}s',
            );
          }
        }
      }
    }
  });

  test('during a flight and at rest, the state does not change', () {
    final visit = _Visit();
    var changes = 0;
    visit.container.listen(navigationProvider, (_, _) => changes++);
    final location = CategoryLocation(projects);

    visit.navigation.flyTo(location);
    expect(changes, 1, reason: 'the flight starts');
    final flight = (visit.state as InFlight).flight;

    visit.navigation.flyTo(location);
    visit.clock.advanceTo(flight.endTime - 0.01);
    visit.navigation.endFinishedFlight();
    expect(changes, 1, reason: 'during the flight');

    visit.clock.advanceTo(flight.endTime);
    visit.navigation.endFinishedFlight();
    expect(changes, 2, reason: 'the flight ends');
    expect(visit.state, isA<AtRest>());
    expect(visit.state.location, location);

    visit.clock.advanceBy(5);
    visit.navigation.endFinishedFlight();
    visit.navigation.flyTo(location);
    expect(changes, 2, reason: 'after the flight');
  });

  test('a drag or a zoom at rest moves the camera without a new state', () {
    for (final location in fakeLocations) {
      final visit = _Visit((navigation, _) => navigation.jumpTo(location));
      var changes = 0;
      visit.container.listen(navigationProvider, (_, _) => changes++);
      final before = visit.camera;

      visit.navigation.turn(yaw: 0.2, pitch: 0.1);
      final turned = visit.camera;
      visit.navigation.zoom(1.2);

      final reason = location.path;
      expect(changes, 0, reason: reason);
      expect(
        turned,
        isNot(isCameraCloseTo(before, tolerance: 0.01)),
        reason: reason,
      );
      expect(
        visit.camera,
        isNot(isCameraCloseTo(turned, tolerance: 0.01)),
        reason: reason,
      );
    }
  });

  test('during a flight, a drag or a zoom does not move the camera', () {
    final visit = _Visit((navigation, clock) {
      navigation.flyTo(CategoryLocation(projects));
      clock.advanceBy(0.5);
    });
    final state = visit.state as InFlight;
    final before = visit.camera;
    final arrival = state.arrival.framing;

    visit.navigation.turn(yaw: 0.2, pitch: 0.1);
    visit.navigation.zoom(1.2);

    expect(visit.camera, isCameraCloseTo(before, tolerance: 0));
    // The flight ends where it was going, so the camera does not jump.
    expect(state.arrival.framing, same(arrival));
  });

  test('at rest, the camera frames the body of its location', () {
    Body bodyOf(MapLocation location) => switch (location) {
      OverviewLocation() => centralBody,
      BodyLocation(:final category) => fakeBodies.of(category.slug),
    };
    for (final (name, setup) in starts) {
      final visit = _Visit(setup)..finishFlight();
      final state = visit.state as AtRest;
      expect(state.framing.body, same(bodyOf(state.location)), reason: name);
    }
  });

  test('the camera is nearer to a body at a message than at its category', () {
    for (final category in fakeContent) {
      final body = fakeBodies.of(category.slug);
      double distanceAt(MapLocation location) {
        final visit = _Visit((navigation, _) => navigation.jumpTo(location));
        return visit.camera.position.distanceTo(body.positionAt(0));
      }

      expect(
        distanceAt(MessageLocation(category, category.messages.first)),
        lessThan(distanceAt(CategoryLocation(category))),
        reason: category.slug,
      );
    }
  });

  test('a jump to the overview keeps the azimuth and elevation of the '
      'camera', () {
    for (final (name, setup) in starts) {
      final visit = _Visit(setup);
      final before = visit.camera.fromTarget;
      visit.navigation.jumpTo(const OverviewLocation());
      final after = visit.camera.fromTarget;
      expect(after.azimuth, before.azimuth, reason: name);
      expect(after.elevation, before.elevation, reason: name);
      expect(after.distance, overviewDistance, reason: name);
    }
  });
}

/// A visit with the fake content, put into a state by its setup.
class _Visit {
  _Visit([_Setup? setup]) {
    setup?.call(navigation, clock);
  }

  final container = ProviderContainer.test(overrides: fakeOverrides);
  late final navigation = container.read(navigationProvider.notifier);
  late final clock = container.read(sceneClockProvider);

  MapNavigationState get state => container.read(navigationProvider);

  /// The camera at the time of the clock.
  Camera get camera => state.cameraAt(clock.now);

  /// Moves the clock to the end of the flight in progress, if there is one,
  /// and ends it.
  void finishFlight() {
    if (state case InFlight(:final flight)) {
      clock.advanceTo(flight.endTime);
      navigation.endFinishedFlight();
    }
  }
}

extension _AdvanceBy on SceneClock {
  void advanceBy(double seconds) => advanceTo(now + seconds);
}
