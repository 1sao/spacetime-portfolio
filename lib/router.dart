import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'content/content.dart';
import 'navigation/map_location.dart';
import 'navigation/navigation.dart';
import 'providers.dart';
import 'ui/list_page.dart';
import 'ui/map_page.dart';

/// Reads other providers inside its callbacks, so it builds once: a rebuild
/// would make a new [GoRouter] and reset navigation.
final routerProvider = Provider<GoRouter>((ref) {
  List<Category> content() => ref.read(contentProvider);

  Page<void> mapPage(GoRouterState state) => NoTransitionPage<void>(
    key: _mapKey,
    child: MapPage(location: mapLocationFor(content(), state.uri)!),
  );

  final router = GoRouter(
    redirect: (_, state) => redirectFor(content(), state.uri),
    routes: [
      GoRoute(
        path: const OverviewLocation().path,
        pageBuilder: (_, state) => mapPage(state),
      ),
      // Before `/:category`, which would also match `/list`.
      GoRoute(
        path: ListPage.path,
        pageBuilder: (_, state) =>
            NoTransitionPage<void>(key: state.pageKey, child: const ListPage()),
      ),
      GoRoute(path: '/:category', pageBuilder: (_, state) => mapPage(state)),
      GoRoute(
        path: '/:category/:message',
        pageBuilder: (_, state) => mapPage(state),
      ),
    ],
  );

  // The first map URL of a visit puts the camera there. Later ones fly.
  var hasPlacedCamera = false;
  void moveCameraToUrl() {
    final location = mapLocationFor(
      content(),
      router.routerDelegate.currentConfiguration.uri,
    );
    if (location == null) return;
    final navigation = ref.read(navigationProvider.notifier);
    if (hasPlacedCamera) {
      navigation.flyTo(location);
    } else {
      // The Router reads the first URL during the first build, where a
      // provider must not change. The microtask runs after that build, and
      // before the next pointer, key or browser event.
      scheduleMicrotask(() => navigation.jumpTo(location));
    }
    hasPlacedCamera = true;
  }

  router.routerDelegate.addListener(moveCameraToUrl);
  ref.onDispose(() {
    router.routerDelegate.removeListener(moveCameraToUrl);
    router.dispose();
  });
  return router;
});

/// The key every map URL's page shares, so the Navigator updates one page in
/// place and the page keeps its state.
const _mapKey = ValueKey('map');

/// The map location of [url], or of the nearest page above it if no page
/// has that URL. Null for the list view.
MapLocation? mapLocationFor(List<Category> content, Uri url) {
  if (url.isListView) return null;

  final segments = url.pathSegments;
  final category = segments.isEmpty ? null : content.withSlug(segments.first);
  if (category == null) return const OverviewLocation();

  final message = segments.length < 2
      ? null
      : category.messages.withSlug(segments[1]);
  if (message == null) return CategoryLocation(category);

  return MessageLocation(category, message);
}

/// Where [url] should go instead, or null if it is a page. A bad URL goes
/// to the nearest page above it, so `/projects/nope` goes to `/projects`.
String? redirectFor(List<Category> content, Uri url) {
  if (url.isListView) {
    return url.pathSegments.length == 1 ? null : ListPage.path;
  }

  final location = mapLocationFor(content, url)!;
  return location.path == url.path ? null : location.path;
}

extension on Uri {
  bool get isListView =>
      pathSegments.isNotEmpty && '/${pathSegments.first}' == ListPage.path;
}
