import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homepage_v2/app.dart';
import 'package:homepage_v2/providers.dart';

import 'fake_content.dart';

/// Starts the app with the fake content at [firstPath], as a visit that
/// opens that URL. Map pages never settle, because the scene ticks every
/// frame, so tests pump fixed durations.
Future<void> pumpApp(WidgetTester tester, {String firstPath = '/'}) async {
  // The test binding sets this value back to `/` before each widget test.
  tester.binding.platformDispatcher.defaultRouteNameTestValue = firstPath;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        contentProvider.overrideWithValue(fakeContent),
        bodiesProvider.overrideWithValue(fakeBodies),
      ],
      child: const App(),
    ),
  );
}
