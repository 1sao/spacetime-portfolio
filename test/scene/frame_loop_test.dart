import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spacetime_portfolio/scene/frame_loop.dart';
import 'package:spacetime_portfolio/space/frame_snapshot.dart';

import '../fake_bodies.dart';
import '../pump_app.dart';

void main() {
  testWidgets('the scene stands still while the app is not resumed', (
    tester,
  ) async {
    final container = ProviderContainer.test(overrides: fakeOverrides);
    // Disposed here, not in the container's own teardown, which runs after
    // Flutter fails a test that ends with a ticker running.
    try {
      final currentFrame = container.startFrameLoop();
      final binding = tester.binding;

      await tester.runSceneFor(seconds: 1);
      expect(currentFrame.value.actualTime, 1);

      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump(const Duration(seconds: 5));
      expect(currentFrame.value.actualTime, 1, reason: 'paused');

      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.runSceneFor(seconds: 1);
      expect(
        currentFrame.value.actualTime,
        2,
        reason: 'resumed where it stopped',
      );
    } finally {
      container.dispose();
    }
  });

  testWidgets('while the scene stands still, a resize to a phone frames '
      'the Landing as a column', (tester) async {
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 800);
    await pumpApp(tester);
    FrameSnapshot currentFrame() =>
        tester.container().read(frameSnapshotListenableProvider).value;
    expect(currentFrame().camera.roll, 0);

    tester.view.physicalSize = const Size(390, 844);
    await tester.pump();
    expect(currentFrame().camera.roll, math.pi / 2);
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
