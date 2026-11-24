import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:spacetime_portfolio/app.dart';
import 'package:spacetime_portfolio/router.dart';
import 'package:spacetime_portfolio/scene/scene_running.dart';
import 'package:spacetime_portfolio/scene/scene_view.dart';

import 'fake_bodies.dart';

/// A running scene asks for a frame every frame, so the page never settles
/// unless the scene stands still.
Future<void> pumpApp(
  WidgetTester tester, {
  String firstUrl = '/',
  Size? window,
  bool fakeBodies = true,
  bool loadsScene = false,
  bool isSceneRunning = false,
  List<Override> overrides = const [],
}) async {
  if (window != null) {
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = window;
  }
  // The test binding sets this value back to `/` before each widget test.
  tester.binding.platformDispatcher.defaultRouteNameTestValue = firstUrl;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        // Drawing the scene on the test's CPU is very slow.
        if (!loadsScene)
          sceneAssetsProvider.overrideWith(
            (ref) => Completer<SceneAssets>().future,
          ),
        isSceneRunningProvider.overrideWithBuild((_, _) => isSceneRunning),
        if (fakeBodies) ...fakeOverrides,
        ...overrides,
      ],
      child: const App(),
    ),
  );
}

/// The app's state, for a test that [pumpApp] started.
extension AppState on WidgetTester {
  Uri get currentUrl =>
      container().read(routerProvider).routerDelegate.currentConfiguration.uri;
}
