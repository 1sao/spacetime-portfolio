import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'content/content.dart';
import 'navigation/map_location.dart';
import 'providers.dart';
import 'ui/list_page.dart';
import 'ui/map_page.dart';

/// Reads other providers inside its callbacks, so it builds once: a rebuild
/// would make a new [GoRouter] and reset navigation.
final routerProvider = Provider<GoRouter>((ref) {
  List<Category> content() => ref.read(contentProvider);

  final router = GoRouter(
    redirect: (_, state) => redirectFor(content(), state.uri.pathSegments),
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (_, _) => const NoTransitionPage<void>(
          key: _mapKey,
          child: MapPage(location: OverviewLocation()),
        ),
      ),
      // Before `/:category`, which would also match `/list`.
      GoRoute(
        path: '/list',
        pageBuilder: (_, state) =>
            NoTransitionPage<void>(key: state.pageKey, child: const ListPage()),
      ),
      // The redirect has already sent every unknown slug elsewhere, so the
      // `!`s in routes below are safe.
      GoRoute(
        path: '/:category',
        pageBuilder: (_, state) {
          final params = state.pathParameters;
          final category = _category(content(), params['category'])!;
          return NoTransitionPage<void>(
            key: _mapKey,
            child: MapPage(location: CategoryLocation(category)),
          );
        },
      ),
      GoRoute(
        path: '/:category/:message',
        pageBuilder: (_, state) {
          final params = state.pathParameters;
          final category = _category(content(), params['category'])!;
          final message = _message(category, params['message'])!;
          return NoTransitionPage<void>(
            key: _mapKey,
            child: MapPage(location: MessageLocation(category, message)),
          );
        },
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

/// The key every map URL's page shares, so the Navigator updates one page in
/// place and the page keeps its state.
const _mapKey = ValueKey('map');

/// Where a URL with these path segments should go instead, or null if it is
/// a page. A bad URL goes to the nearest page above it, so `/projects/nope`
/// goes to `/projects`.
String? redirectFor(List<Category> content, List<String> segments) {
  if (segments.isEmpty) return null;
  if (segments.first == 'list') return segments.length == 1 ? null : '/list';

  final category = _category(content, segments.first);
  if (category == null) return '/';
  if (segments.length == 1) return null;

  final message = _message(category, segments[1]);
  if (message == null) return '/${category.slug}';
  if (segments.length == 2) return null;

  return '/${category.slug}/${message.slug}';
}

Category? _category(List<Category> content, String? slug) =>
    content.where((category) => category.slug == slug).firstOrNull;

Message? _message(Category category, String? slug) =>
    category.messages.where((message) => message.slug == slug).firstOrNull;
