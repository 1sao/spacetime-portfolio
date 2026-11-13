import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:homepage_v2/content/content.dart';
import 'package:homepage_v2/navigation/map_location.dart';
import 'package:homepage_v2/navigation/map_navigation_state.dart';
import 'package:homepage_v2/providers.dart';
import 'package:homepage_v2/router.dart';
import 'package:homepage_v2/ui/list_page.dart';
import 'package:homepage_v2/ui/map_page.dart';

import 'fake_content.dart';
import 'pump_app.dart';

void main() {
  test('a bad URL redirects to the nearest page above it', () {
    const expected = {
      '/': null,
      '/list': null,
      '/projects': null,
      '/projects/one': null,
      '/nope': '/',
      '/nope/one': '/',
      '/Projects': '/',
      '/projects/nope': '/projects',
      '/projects/one/x': '/projects/one',
      '/projects/': '/projects',
      '/list/x': '/list',
    };

    final actual = {
      for (final path in expected.keys)
        path: redirectFor(fakeContent, Uri.parse(path)),
    };
    expect(actual, expected);
  });

  test('the path of each location leads back to it, without a redirect', () {
    // The parser gives the nearest page, so a wrong path can still parse to
    // the right location. The redirect shows that the path is not a page.
    for (final location in fakeLocations) {
      final url = Uri.parse(location.path);
      expect(mapLocationFor(fakeContent, url), location, reason: location.path);
      expect(redirectFor(fakeContent, url), isNull, reason: location.path);
    }
  });

  testWidgets('every fixed top-level route segment is a reserved slug', (
    tester,
  ) async {
    // Routes inside a shell route are top-level too.
    Iterable<GoRoute> topLevel(List<RouteBase> routes) sync* {
      for (final route in routes) {
        if (route is GoRoute) yield route;
        if (route is ShellRouteBase) yield* topLevel(route.routes);
      }
    }

    final router = ProviderContainer.test().read(routerProvider);
    final fixed = [
      for (final route in topLevel(router.configuration.routes))
        ?Uri.parse(route.path).pathSegments.firstOrNull,
    ].where((segment) => !segment.startsWith(':'));

    expect(fixed, isNotEmpty);
    expect(reservedSlugs, containsAll(fixed));
  });

  testWidgets('map URLs share one page and pass it the resolved content', (
    tester,
  ) async {
    await pumpApp(tester);
    final page = tester.element(find.byType(MapPage));
    final projects = fakeContent.first;

    for (final (path, location) in <(String, MapLocation)>[
      ('/projects', CategoryLocation(projects)),
      ('/projects/two', MessageLocation(projects, projects.messages[1])),
      ('/', const OverviewLocation()),
    ]) {
      await tester.goTo(path);

      final map = tester.widget<MapPage>(find.byType(MapPage));
      expect(tester.element(find.byType(MapPage)), same(page), reason: path);
      expect(map.location, location, reason: path);
    }
  });

  final projects = fakeContent.first;

  testWidgets('the first URL puts the camera there, and later URLs fly', (
    tester,
  ) async {
    await pumpApp(tester, firstPath: '/projects/one');

    // No frame is pumped here: the jump must be done before the scene's
    // first frame.
    expect(tester.navigationState, isA<AtRest>());
    expect(
      tester.navigationState.location,
      MessageLocation(projects, projects.messages[0]),
    );

    await tester.goTo('/projects');
    expect(tester.navigationState, isA<InFlight>());
    expect(tester.navigationState.location, CategoryLocation(projects));
  });

  testWidgets('back and forward fly the camera', (tester) async {
    await pumpApp(tester);
    final router = tester.router;

    // The browser sends a URL without a state for a new history entry, and
    // with the state that go_router saved for back and forward.
    await tester.goTo('/projects');
    final saved = router.routeInformationParser.restoreRouteInformation(
      router.routerDelegate.currentConfiguration,
    )!;
    await tester.goTo('/');

    for (final (name, location, routeState) in [
      ('without a state', '/contact', null),
      ('with a state', saved.uri.toString(), saved.state),
    ]) {
      await _pushRouteInformation(tester, location, routeState);
      await tester.pump();
      expect(tester.navigationState, isA<InFlight>(), reason: name);
      expect(tester.navigationState.location.path, location, reason: name);
    }
  });

  testWidgets('the list view leaves the state, and its time stands still', (
    tester,
  ) async {
    await pumpApp(tester);
    final clock = tester.container().read(sceneClockProvider);
    await tester.pump(const Duration(seconds: 1));
    final before = tester.navigationState;

    tester.router.go(ListPage.path);
    // The scene ticks for two more frames: the map page goes away in the
    // first, and the provider that owns the ticker after the second.
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));
    final time = clock.now;
    await tester.pump(const Duration(seconds: 5));
    expect(clock.now, time);
    expect(tester.navigationState, same(before));

    await tester.goTo('/');
    expect(tester.navigationState, same(before));
  });
}

/// Sends a URL to the app as the browser does, for example at back.
Future<void> _pushRouteInformation(
  WidgetTester tester,
  String location,
  Object? state,
) async {
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    SystemChannels.navigation.name,
    SystemChannels.navigation.codec.encodeMethodCall(
      MethodCall('pushRouteInformation', {
        'location': location,
        'state': state,
      }),
    ),
    (_) {},
  );
}
