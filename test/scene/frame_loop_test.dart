import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homepage_v2/providers.dart';
import 'package:homepage_v2/scene/frame_loop.dart';
import 'package:homepage_v2/space/frame.dart';

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
}
