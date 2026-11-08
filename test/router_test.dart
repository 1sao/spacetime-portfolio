import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:homepage_v2/app.dart';
import 'package:homepage_v2/content/content.dart';
import 'package:homepage_v2/providers.dart';
import 'package:homepage_v2/router.dart';
import 'package:homepage_v2/ui/map_page.dart';

import 'fake_content.dart';

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
      '/list/x': '/list',
    };

    final actual = {
      for (final path in expected.keys)
        path: redirectFor(fakeContent, Uri.parse(path).pathSegments),
    };
    expect(actual, expected);
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
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentProvider.overrideWithValue(fakeContent),
          bodiesProvider.overrideWithValue(fakeBodies),
        ],
        child: const App(),
      ),
    );
    final router = tester.container().read(routerProvider);
    final page = tester.element(find.byType(MapPage));
    final projects = fakeContent.first;

    for (final (path, category, message) in [
      ('/projects', projects, null),
      ('/projects/two', projects, projects.messages[1]),
    ]) {
      router.go(path);
      // The scene ticks every frame, so the map page never settles.
      await tester.pump();

      final map = tester.widget<MapPage>(find.byType(MapPage));
      expect(tester.element(find.byType(MapPage)), same(page), reason: path);
      expect(map.category, same(category), reason: path);
      expect(map.message, same(message), reason: path);
    }
  });
}
