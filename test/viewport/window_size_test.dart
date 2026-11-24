import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spacetime_portfolio/viewport/window_size.dart';

void main() {
  testWidgets('when the address bar is static, WindowSize matches the '
      'window size in logical pixels', (tester) async {
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(800, 1200);
    final container = ProviderContainer.test();

    expect(
      container.read(windowSizeProvider),
      const WindowSize(width: 400, smallHeight: 600, largeHeight: 600),
    );
    tester.view.physicalSize = const Size(1000, 1000);
    expect(
      container.read(windowSizeProvider),
      const WindowSize(width: 500, smallHeight: 500, largeHeight: 500),
    );
  });
}
