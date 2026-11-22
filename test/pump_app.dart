import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homepage_v2/app.dart';
import 'package:homepage_v2/router.dart';
import 'package:riverpod/misc.dart' show Override;

import 'fake_content.dart';

/// Starts the app with the fake content at [firstUrl], as a visit that
/// opens that URL. The page never settles, because the scene ticks every
/// frame, so tests pump fixed durations.
Future<void> pumpApp(
  WidgetTester tester, {
  String firstUrl = '/',
  List<Override> overrides = const [],
}) async {
  // The test binding sets this value back to `/` before each widget test.
  tester.binding.platformDispatcher.defaultRouteNameTestValue = firstUrl;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [...fakeOverrides, ...overrides],
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
