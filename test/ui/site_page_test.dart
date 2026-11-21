import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homepage_v2/scene/scene_view.dart';
import 'package:homepage_v2/ui/reading_screen.dart';
import 'package:homepage_v2/ui/spacing.dart';
import 'package:homepage_v2/viewport/window_size.dart';

import '../pump_app.dart';

void main() {
  testWidgets('the scene and the Landing keep their sizes while the '
      "window's height changes with the address bar", (tester) async {
    const window = WindowSize(width: 400, smallHeight: 700, largeHeight: 780);
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1;
    await pumpApp(
      tester,
      overrides: [
        windowSizeProvider.overrideWithBuild((ref, notifier) => window),
      ],
    );

    for (final windowHeight in [window.smallHeight, window.largeHeight]) {
      tester.view.physicalSize = Size(window.width, windowHeight);
      await tester.pump();
      final reason = 'window $windowHeight tall';
      expect(
        tester.getRect(find.byType(SceneView)),
        Rect.fromLTWH(0, 0, window.width, window.largeHeight),
        reason: reason,
      );
      expect(
        tester.getTopLeft(find.byType(ReadingScreen)).dy,
        window.smallHeight - SiteSpacing.peek,
        reason: reason,
      );
    }
  });
}
