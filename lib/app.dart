import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'router.dart';

/// The root widget. Expects a `ProviderScope` above it.
class App extends ConsumerWidget {
  const App({super.key});

  static const Color background = Colors.black;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Homepage',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
      ),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
