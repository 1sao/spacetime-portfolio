import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:homepage_v2/app.dart';
import 'package:homepage_v2/navigation/map_navigation_state.dart';
import 'package:homepage_v2/navigation/navigation.dart';
import 'package:homepage_v2/router.dart';

import 'fake_content.dart';

/// Starts the app with the fake content at [firstPath], as a visit that
/// opens that URL. Map pages never settle, because the scene ticks every
/// frame, so tests pump fixed durations.
Future<void> pumpApp(WidgetTester tester, {String firstPath = '/'}) async {
  // The test binding sets this value back to `/` before each widget test.
  tester.binding.platformDispatcher.defaultRouteNameTestValue = firstPath;
  await tester.pumpWidget(
    ProviderScope(overrides: fakeOverrides, child: const App()),
  );
}

/// The app's state, for a test that [pumpApp] started.
extension AppState on WidgetTester {
  GoRouter get router => container().read(routerProvider);

  MapNavigationState get navigationState =>
      container().read(navigationProvider);

  /// The path of the URL that the router shows.
  String get currentPath => router.routerDelegate.currentConfiguration.uri.path;

  /// Goes to [path], as a link does, and pumps one frame.
  Future<void> goTo(String path) async {
    router.go(path);
    await pump();
  }
}
