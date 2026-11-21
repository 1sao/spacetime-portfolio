import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homepage_v2/scene/scene_view.dart';
import 'package:homepage_v2/ui/reading_screen.dart';
import 'package:homepage_v2/ui/spacing.dart';
import 'package:homepage_v2/viewport/viewport_heights.dart';

import '../pump_app.dart';

void main() {
  testWidgets('the scene and the Landing keep their sizes while the '
      "window's height changes with the address bar", (tester) async {
    const width = 400.0;
    const heights = ViewportHeights(small: 700, large: 780);
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1;
    await pumpApp(
      tester,
      overrides: [
        viewportHeightsProvider.overrideWithBuild((ref, notifier) => heights),
      ],
    );

    for (final windowHeight in [heights.small, heights.large]) {
      tester.view.physicalSize = Size(width, windowHeight);
      await tester.pump();
      final reason = 'window $windowHeight tall';
      expect(
        tester.getRect(find.byType(SceneView)),
        Rect.fromLTWH(0, 0, width, heights.large),
        reason: reason,
      );
      expect(
        tester.getTopLeft(find.byType(ReadingScreen)).dy,
        heights.small - SiteSpacing.peek,
        reason: reason,
      );
    }
  });
}
