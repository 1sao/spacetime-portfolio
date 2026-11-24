import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'ui/site_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    redirect: (_, state) => state.uri.path == SitePage.path
        ? null
        : Uri(
            path: SitePage.path,
            fragment: state.uri.hasFragment ? state.uri.fragment : null,
          ).toString(),
    routes: [
      GoRoute(
        path: SitePage.path,
        pageBuilder: (_, _) => const NoTransitionPage(child: SitePage()),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
