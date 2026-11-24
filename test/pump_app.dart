import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:spacetime_portfolio/app.dart';
import 'package:spacetime_portfolio/router.dart';
import 'package:spacetime_portfolio/scene/kepler_textures.dart';
import 'package:spacetime_portfolio/scene/scene_running.dart';
import 'package:spacetime_portfolio/scene/scene_view.dart';

import 'blank_scene.dart';
import 'fake_bodies.dart';

/// A running scene asks for a frame every frame, so the page never settles
/// unless the scene stands still. With [loadsBlankScene], the scene's
/// shader reads blank images: baking the real ones on the test's CPU takes
/// seconds.
Future<void> pumpApp(
  WidgetTester tester, {
  String firstUrl = '/',
  Size? window,
  bool fakeBodies = true,
  bool loadsBlankScene = false,
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
        sceneAssetsProvider.overrideWith(
          loadsBlankScene
              ? _loadBlankScene
              : (ref) => Completer<SceneAssets>().future,
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

Future<SceneAssets> _loadBlankScene(Ref ref) async {
  final program = await ui.FragmentProgram.fromAsset(sceneShaderAsset);
  final keplerTextures = KeplerTextures.blank();
  ref.onDispose(keplerTextures.dispose);
  final holeTextures = BlankHoleTextures();
  ref.onDispose(holeTextures.dispose);
  final sky = BlankSky();
  ref.onDispose(sky.dispose);
  return SceneAssets(program, keplerTextures, holeTextures, sky);
}
