import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'router.dart';
import 'ui/colors.dart';
import 'ui/theme.dart';
import 'viewport/window_size.dart';

class App extends ConsumerWidget {
  const App({super.key});

  static const Color backgroundColor = SiteColors.deepSpace;

  static const String title = '[Name placeholder] – [Role placeholder]';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: title,
      // On the web this becomes the page's theme-color.
      color: backgroundColor,
      debugShowCheckedModeBanner: false,
      theme: siteTheme(
        ref.watch(windowSizeProvider.select((window) => window.widthClass)),
      ),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
