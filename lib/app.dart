import 'package:material_ui/material_ui.dart';

/// The root widget. Expects a `ProviderScope` above it.
class App extends StatelessWidget {
  const App({super.key});

  static const Color background = Colors.black;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Homepage',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
      ),
      home: const Scaffold(),
    );
  }
}
