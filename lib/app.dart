import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'router.dart';

/// The root widget. Expects a `ProviderScope` above it.
class App extends ConsumerWidget {
  const App({super.key});

  static const Color background = Colors.black;

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
      ),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
