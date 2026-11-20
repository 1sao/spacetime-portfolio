import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'router.dart';
import 'ui/colours.dart';

/// The root widget. Expects a `ProviderScope` above it.
class App extends ConsumerWidget {
  const App({super.key});

  static const Color background = SiteColours.deepSpace;

  /// The browser tab's title once the app runs. Should match `<title>` in
  /// `web/index.html`, which shows before that and in link previews.
  static const String title = '[Name placeholder] – [Role placeholder]';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: title,
      // On the web this becomes the page's theme-color.
      color: background,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        textTheme: ThemeData(brightness: Brightness.dark).textTheme.apply(
          bodyColor: SiteColours.readingCream,
          displayColor: SiteColours.lampWhite,
        ),
      ),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
