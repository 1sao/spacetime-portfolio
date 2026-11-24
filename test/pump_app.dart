import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homepage_v2/app.dart';
import 'package:homepage_v2/router.dart';
import 'package:homepage_v2/scene/scene_running.dart';
import 'package:homepage_v2/scene/scene_view.dart';
import 'package:riverpod/misc.dart' show Override;

import 'fake_bodies.dart';

/// Starts the app. The scene stands still unless [isSceneRunning] is true,
/// because a running scene asks for a frame every frame, and the page then
/// never settles.
Future<void> pumpApp(
  WidgetTester tester, {
  String firstUrl = '/',
  Size? window,
  bool fakeBodies = true,
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
        // The scene never loads: drawing it on the test's CPU is very slow.
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
  /// The URL that the router shows.
  Uri get currentUrl =>
      container().read(routerProvider).routerDelegate.currentConfiguration.uri;
}
