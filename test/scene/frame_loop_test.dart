import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homepage_v2/navigation/map_location.dart';
import 'package:homepage_v2/navigation/map_navigation_state.dart';
import 'package:homepage_v2/navigation/navigation.dart';
import 'package:homepage_v2/providers.dart';
import 'package:homepage_v2/scene/frame_loop.dart';
import 'package:homepage_v2/space/frame.dart';
import 'package:homepage_v2/space/framing.dart';

import '../fake_content.dart';

void main() {
  testWidgets('time stands still while the app is not resumed', (tester) async {
    final container = ProviderContainer.test(
      overrides: [
        contentProvider.overrideWithValue(fakeContent),
        bodiesProvider.overrideWithValue(fakeBodies),
      ],
    );
    final ValueListenable<FrameSnapshot> currentFrame = container
        .listen(frameSnapshotListenableProvider, (_, _) {})
        .read();
    final binding = tester.binding;

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(currentFrame.value.time, 1);

    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump(const Duration(seconds: 5));
    expect(currentFrame.value.time, 1, reason: 'paused');

    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(currentFrame.value.time, 2, reason: 'resumed where it stopped');

    // Flutter fails a test that ends with a ticker running, and the
    // container's own teardown runs only after that check.
    container.dispose();
  });

  testWidgets('time goes on where it stopped when the frame loop comes back', (
    tester,
  ) async {
    final container = ProviderContainer.test(
      overrides: [
        contentProvider.overrideWithValue(fakeContent),
        bodiesProvider.overrideWithValue(fakeBodies),
      ],
    );
    final first = container.listen(frameSnapshotListenableProvider, (_, _) {});
    final firstLoop = first.read();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(firstLoop.value.time, 1);

    // Nothing watches the provider, as when the list page is open.
    first.close();
    await tester.pump(const Duration(seconds: 5));

    final ValueListenable<FrameSnapshot> secondLoop = container
        .listen(frameSnapshotListenableProvider, (_, _) {})
        .read();
    expect(secondLoop, isNot(same(firstLoop)));
    expect(secondLoop.value.time, 1);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(secondLoop.value.time, 2);

    container.dispose();
  });

  testWidgets('a jump shows while the app is not resumed', (tester) async {
    final container = ProviderContainer.test(
      overrides: [
        contentProvider.overrideWithValue(fakeContent),
        bodiesProvider.overrideWithValue(fakeBodies),
      ],
    );
    final ValueListenable<FrameSnapshot> currentFrame = container
        .listen(frameSnapshotListenableProvider, (_, _) {})
        .read();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    container
        .read(navigationProvider.notifier)
        .jumpTo(CategoryLocation(fakeContent.first));
    final frame = currentFrame.value;
    final expected = container
        .read(navigationProvider)
        .cameraAt(frame.time)
        .position;
    expect(frame.camera.position.distanceTo(expected), 0);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    container.dispose();
  });

  testWidgets('the camera of each frame is the camera of the navigation state, '
      'and the frame loop ends a flight', (tester) async {
    final container = ProviderContainer.test(
      overrides: [
        contentProvider.overrideWithValue(fakeContent),
        bodiesProvider.overrideWithValue(fakeBodies),
      ],
    );
    final ValueListenable<FrameSnapshot> currentFrame = container
        .listen(frameSnapshotListenableProvider, (_, _) {})
        .read();
    MapNavigationState state() => container.read(navigationProvider);
    void expectCameraOfState(String reason) {
      final frame = currentFrame.value;
      final expected = state().cameraAt(frame.time).position;
      expect(frame.camera.position.distanceTo(expected), 0, reason: reason);
    }

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    final category = fakeContent.first;
    container
        .read(navigationProvider.notifier)
        .flyTo(CategoryLocation(category));

    await tester.pump(const Duration(milliseconds: 500));
    expect(state(), isA<InFlight>());
    expectCameraOfState('during the flight');
    final overview = const Framing.overview().cameraAt(0).position;
    expect(currentFrame.value.camera.position.distanceTo(overview), isNot(0));

    await tester.pump(const Duration(seconds: 3));
    expect(state(), isA<AtRest>());
    expect(state().location, CategoryLocation(category));
    expectCameraOfState('after the flight');

    container.dispose();
  });
}
