import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../content/content.dart';

/// The page for every map URL: the overview at `/`, a focused [category] at
/// `/<category>`, and an open [message] at `/<category>/<message>`.
class MapPage extends StatelessWidget {
  const MapPage({super.key, this.category, this.message});

  final Category? category;
  final Message? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topRight,
          child: TextButton(
            onPressed: () => context.go('/list'),
            child: const Text('List'),
          ),
        ),
      ),
    );
  }
}
