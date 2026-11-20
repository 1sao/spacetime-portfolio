import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homepage_v2/scene/frame_loop.dart';
import 'package:homepage_v2/space/frame_snapshot.dart';

import '../fake_content.dart';

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
