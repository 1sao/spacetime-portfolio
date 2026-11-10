import 'package:flutter_test/flutter_test.dart';
import 'package:homepage_v2/navigation/map_location.dart';
import 'package:homepage_v2/navigation/navigation.dart';
import 'package:homepage_v2/navigation/navigation_state.dart';
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

  final locations = <MapLocation>[
    const OverviewLocation(),
    for (final category in fakeContent) ...[
      CategoryLocation(category),
      for (final message in category.messages)
        MessageLocation(category, message),
    ],
  ];

  /// The states that a visitor can be in, each as a name and a setup:
  ///
  /// - At rest at each location.
  /// - During a flight from each location to each other location.
  /// - During a flight that started during a different flight.
  final starts = <(String, _Setup)>[
    for (final location in locations)
      ('at ${location.name}', (navigation, _) => navigation.jumpTo(location)),
    for (final from in locations)
      for (final to in locations)
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
    for (final from in locations)
      for (final first in locations)
        for (final second in locations)
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
        NavigationState state() => container.read(navigationProvider);
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
        expect(state(), isA<AtOverview>(), reason: reason);
        final rig = state().rigAt(clock.now);
        expect(rig.target.length, 0, reason: '$reason: target');
        expect(rig.distance, overviewDistance, reason: '$reason: distance');
      }
    }
  });

  test('the camera does not jump when a flight starts or ends', () {
    for (final (name, setup) in starts) {
      for (final destination in locations) {
        final (container, navigation, clock) = startedWith(setup);
        NavigationState state() => container.read(navigationProvider);
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
    expect(container.read(navigationProvider), isA<AtBody>());

    clock.advanceBy(5);
    navigation.endFinishedFlight();
    navigation.flyTo(location);
    expect(changes, 2, reason: 'after the flight');
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
