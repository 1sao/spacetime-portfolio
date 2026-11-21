import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homepage_v2/viewport/viewport_heights.dart';

void main() {
  testWidgets('without the address bar package, both heights follow the '
      "window's height", (tester) async {
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(800, 1200);
    final container = ProviderContainer.test();

    expect(
      container.read(viewportHeightsProvider),
      const ViewportHeights(small: 600, large: 600),
    );
    tester.view.physicalSize = const Size(800, 1000);
    expect(
      container.read(viewportHeightsProvider),
      const ViewportHeights(small: 500, large: 500),
    );
  });
}
