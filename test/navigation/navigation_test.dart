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

import '../fake_content.dart';

// TODO: Split these tests by concern. The parent chain of the locations
// is a property of `MapLocation` alone. That a message is nearer than its
// category is a property of the framings in `site_space.dart`. This file
// should keep only the transitions of `Navigation`: the end states, the
// camera without jumps, and when the state changes.

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
      ('at ${location.name}', (navigation, _) => navigation.jumpTo(location)),
    for (final location in fakeLocations)
      for (final factor in [0.1, 10.0])
        (
          'at ${location.name}, turned and zoomed by $factor',
          (navigation, _) => navigation
            ..jumpTo(location)
            ..turn(yaw: 4, pitch: 2)
            ..zoom(factor),
        ),
    for (final from in fakeLocations)
      for (final to in fakeLocations)
        if (from != to)
          (
            'during the flight from ${from.name} to ${to.name}',
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
              'during the flight to ${second.name} that started during the '
                  'flight from ${from.name} to ${first.name}',
              (navigation, clock) {
                navigation.jumpTo(from);
                navigation.flyTo(first);
                clock.advanceBy(0.7);
                navigation.flyTo(second);
                clock.advanceBy(0.4);
              },
            ),
  ];

  ProviderContainer newContainer() => ProviderContainer.test(
    overrides: [bodiesProvider.overrideWithValue(fakeBodies)],
  );

  (ProviderContainer, Navigation, SceneClock) startedWith(_Setup setup) {
    final container = newContainer();
    final navigation = container.read(navigationProvider.notifier);
    final clock = container.read(sceneClockProvider);
    setup(navigation, clock);
    return (container, navigation, clock);
  }

  test('Esc from each state ends in the overview', () {
    for (final (name, setup) in starts) {
      for (final isWaitingForEachFlight in [true, false]) {
        final (container, navigation, clock) = startedWith(setup);
        MapNavigationState state() => container.read(navigationProvider);
        final isAtRestAtOverview =
            state() is AtRest && state().location is OverviewLocation;
        void finishFlight() {
          if (state() case InFlight(:final flight)) {
            clock.advanceTo(flight.endTime);
            navigation.endFinishedFlight();
          }
        }

        var presses = 0;
        MapLocation? parent;
        while ((parent = state().location.parent) != null) {
          navigation.flyTo(parent!);
          if (isWaitingForEachFlight) finishFlight();
          presses++;
          expect(presses, lessThanOrEqualTo(2), reason: name);
        }
        finishFlight();

        final reason = '$name, waiting: $isWaitingForEachFlight';
        expect(state(), isA<AtRest>(), reason: reason);
        expect(state().location, const OverviewLocation(), reason: reason);
        final rig = state().rigAt(clock.now);
        expect(rig.target.length, 0, reason: '$reason: target');
        // At rest at the overview, Esc starts no flight, so a zoom stays.
        if (!isAtRestAtOverview) {
          expect(rig.distance, overviewDistance, reason: '$reason: distance');
        }
      }
    }
  });

  test('the camera does not jump when a flight starts or ends', () {
    for (final (name, setup) in starts) {
      for (final destination in fakeLocations) {
        final (container, navigation, clock) = startedWith(setup);
        MapNavigationState state() => container.read(navigationProvider);
        final reason = '$name, to ${destination.name}';

        final before = state().rigAt(clock.now).camera;
        navigation.flyTo(destination);
        final after = state().rigAt(clock.now).camera;
        expect(after.distanceTo(before), lessThan(1e-9), reason: reason);

        if (state() case InFlight(:final flight, :final arrival)) {
          // The later time shows that the camera at rest follows the body
          // as the flight does after its end.
          for (final time in [flight.endTime, flight.endTime + 10]) {
            expect(
              arrival.rigAt(time).camera.distanceTo(flight.rigAt(time).camera),
              lessThan(1e-9),
              reason: '$reason: arrival at ${time}s',
            );
          }
        }
      }
    }
  });

  test('during a flight and at rest, the state does not change', () {
    final container = newContainer();
    final navigation = container.read(navigationProvider.notifier);
    final clock = container.read(sceneClockProvider);
    var changes = 0;
    container.listen(navigationProvider, (_, _) => changes++);
    final location = CategoryLocation(projects);

    navigation.flyTo(location);
    expect(changes, 1, reason: 'the flight starts');
    final flight = (container.read(navigationProvider) as InFlight).flight;

    navigation.flyTo(location);
    clock.advanceTo(flight.endTime - 0.01);
    navigation.endFinishedFlight();
    expect(changes, 1, reason: 'during the flight');

    clock.advanceTo(flight.endTime);
    navigation.endFinishedFlight();
    expect(changes, 2, reason: 'the flight ends');
    expect(container.read(navigationProvider), isA<AtRest>());
    expect(container.read(navigationProvider).location, location);

    clock.advanceBy(5);
    navigation.endFinishedFlight();
    navigation.flyTo(location);
    expect(changes, 2, reason: 'after the flight');
  });

  test('a drag or a zoom at rest moves the camera without a new state', () {
    for (final location in fakeLocations) {
      final (container, navigation, clock) = startedWith(
        (navigation, _) => navigation.jumpTo(location),
      );
      var changes = 0;
      container.listen(navigationProvider, (_, _) => changes++);
      final state = container.read(navigationProvider);
      final before = state.rigAt(clock.now).camera;

      navigation.turn(yaw: 0.2, pitch: 0.1);
      final turned = state.rigAt(clock.now).camera;
      navigation.zoom(1.2);
      final zoomed = state.rigAt(clock.now).camera;

      final reason = location.name;
      expect(changes, 0, reason: reason);
      expect(turned.distanceTo(before), greaterThan(0.01), reason: reason);
      expect(zoomed.distanceTo(turned), greaterThan(0.01), reason: reason);
    }
  });

  test('during a flight, a drag or a zoom does not move the camera', () {
    final (container, navigation, clock) = startedWith((navigation, clock) {
      navigation.flyTo(CategoryLocation(projects));
      clock.advanceBy(0.5);
    });
    final state = container.read(navigationProvider) as InFlight;
    final before = state.rigAt(clock.now).camera;
    final arrival = state.arrival.framing;

    navigation.turn(yaw: 0.2, pitch: 0.1);
    navigation.zoom(1.2);

    expect(state.rigAt(clock.now).camera.distanceTo(before), 0);
    // The flight ends where it was going, so the camera does not jump.
    expect(state.arrival.framing, same(arrival));
  });

  test('at rest, the camera frames the body of its location', () {
    Body bodyOf(MapLocation location) => switch (location) {
      OverviewLocation() => centralBody,
      BodyLocation(:final category) => fakeBodies.of(category.slug),
    };
    for (final (name, setup) in starts) {
      final (container, navigation, clock) = startedWith(setup);
      if (container.read(navigationProvider) case InFlight(:final flight)) {
        clock.advanceTo(flight.endTime);
        navigation.endFinishedFlight();
      }
      final state = container.read(navigationProvider) as AtRest;
      expect(state.framing.body, same(bodyOf(state.location)), reason: name);
    }
  });

  test('a jump to the overview keeps the yaw and pitch of the camera', () {
    for (final (name, setup) in starts) {
      final (container, navigation, clock) = startedWith(setup);
      final before = container.read(navigationProvider).rigAt(clock.now);
      navigation.jumpTo(const OverviewLocation());
      final after = container.read(navigationProvider).rigAt(clock.now);
      expect(after.yaw, before.yaw, reason: name);
      expect(after.pitch, before.pitch, reason: name);
      expect(after.distance, overviewDistance, reason: name);
    }
  });

  test('the camera is nearer to a body at a message than at its category', () {
    for (final category in fakeContent) {
      final body = fakeBodies.of(category.slug);
      double distanceAt(MapLocation location) {
        final (container, _, _) = startedWith(
          (navigation, _) => navigation.jumpTo(location),
        );
        final camera = container.read(navigationProvider).rigAt(0).camera;
        return camera.position.distanceTo(body.positionAt(0));
      }

      expect(
        distanceAt(MessageLocation(category, category.messages.first)),
        lessThan(distanceAt(CategoryLocation(category))),
        reason: category.slug,
      );
    }
  });
}

extension _Name on MapLocation {
  String get name => switch (this) {
    OverviewLocation() => 'the overview',
    CategoryLocation(:final category) => category.slug,
    MessageLocation(:final category, :final message) =>
      '${category.slug}/${message.slug}',
  };
}

extension _AdvanceBy on SceneClock {
  void advanceBy(double seconds) => advanceTo(now + seconds);
}

extension _DistanceTo on Camera {
  /// The larger of the distance between the positions of the two cameras
  /// and the distance between their forward directions.
  double distanceTo(Camera other) {
    final positions = position.distanceTo(other.position);
    final directions = forward.distanceTo(other.forward);
    return positions > directions ? positions : directions;
  }
}
