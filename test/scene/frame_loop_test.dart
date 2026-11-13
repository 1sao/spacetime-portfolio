import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homepage_v2/navigation/map_location.dart';
import 'package:homepage_v2/navigation/map_navigation_state.dart';
import 'package:homepage_v2/navigation/navigation.dart';
import 'package:homepage_v2/scene/frame_loop.dart';
import 'package:homepage_v2/space/frame_snapshot.dart';
import 'package:homepage_v2/space/framing.dart';

import '../camera_matchers.dart';
import '../fake_content.dart';

void main() {
  _testFrameLoop('time stands still while the app is not resumed', (
    tester,
    container,
  ) async {
    final currentFrame = container.startFrameLoop();
    final binding = tester.binding;

    await tester.runSceneFor(seconds: 1);
    expect(currentFrame.value.time, 1);

    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump(const Duration(seconds: 5));
    expect(currentFrame.value.time, 1, reason: 'paused');

    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.runSceneFor(seconds: 1);
    expect(currentFrame.value.time, 2, reason: 'resumed where it stopped');
  });

  _testFrameLoop('time goes on where it stopped when the frame loop comes '
      'back', (tester, container) async {
    final first = container.listen(frameSnapshotListenableProvider, (_, _) {});
    final firstLoop = first.read();
    await tester.runSceneFor(seconds: 1);
    expect(firstLoop.value.time, 1);

    // Nothing watches the provider, as when the list page is open.
    first.close();
    await tester.pump(const Duration(seconds: 5));

    final secondLoop = container.startFrameLoop();
    expect(secondLoop, isNot(same(firstLoop)));
    expect(secondLoop.value.time, 1);
    await tester.runSceneFor(seconds: 1);
    expect(secondLoop.value.time, 2);
  });

  _testFrameLoop('a jump shows while the app is not resumed', (
    tester,
    container,
  ) async {
    final currentFrame = container.startFrameLoop();
    await tester.runSceneFor(seconds: 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    container
        .read(navigationProvider.notifier)
        .jumpTo(CategoryLocation(fakeContent.first));
    final frame = currentFrame.value;
    expect(
      frame.camera,
      isCameraCloseTo(
        container.read(navigationProvider).cameraAt(frame.time),
        tolerance: 0,
      ),
    );

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  _testFrameLoop('the camera of each frame is the camera of the navigation '
      'state, and the frame loop ends a flight', (tester, container) async {
    final currentFrame = container.startFrameLoop();
    MapNavigationState state() => container.read(navigationProvider);
    void expectCameraOfState(String reason) {
      final frame = currentFrame.value;
      expect(
        frame.camera,
        isCameraCloseTo(state().cameraAt(frame.time), tolerance: 0),
        reason: reason,
      );
    }

    await tester.runSceneFor(seconds: 1);
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
  });
}

/// A widget test with a container of the fake content. The container is
/// disposed at the end of [body], because Flutter fails a test that ends
/// with a ticker running, and the container's own teardown runs only after
/// that check.
void _testFrameLoop(
  String description,
  Future<void> Function(WidgetTester tester, ProviderContainer container) body,
) {
  testWidgets(description, (tester) async {
    final container = ProviderContainer.test(overrides: fakeOverrides);
    try {
      await body(tester, container);
    } finally {
      container.dispose();
    }
  });
}

extension on ProviderContainer {
  /// Starts the frame loop, and gives its current frame.
  ValueListenable<FrameSnapshot> startFrameLoop() =>
      listen(frameSnapshotListenableProvider, (_, _) {}).read();
}

extension on WidgetTester {
  /// Pumps a first frame, which starts the ticker, then a frame [seconds]
  /// later.
  Future<void> runSceneFor({required double seconds}) async {
    await pump();
    await pump(Duration(microseconds: (seconds * 1e6).round()));
  }
}
