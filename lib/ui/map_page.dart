import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../navigation/map_location.dart';
import '../scene/scene_view.dart';

/// The page for every map URL. Each URL gives one [location].
class MapPage extends StatelessWidget {
  const MapPage({super.key, required this.location});

  final MapLocation location;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const SceneView(),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () => context.go('/list'),
                child: const Text('List'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
