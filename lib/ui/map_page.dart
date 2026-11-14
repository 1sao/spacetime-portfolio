import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../debug/fps_counter.dart';
import '../navigation/map_location.dart';
import '../scene/scene_view.dart';
import 'camera_controls.dart';
import 'list_page.dart';

/// The page for every map URL. Each URL gives one [location].
///
/// Esc goes to the parent of [location].
class MapPage extends StatelessWidget {
  const MapPage({super.key, required this.location});

  final MapLocation location;

  @override
  Widget build(BuildContext context) {
    final parent = location.parent;
    return Actions(
      // The app maps Esc to DismissIntent.
      actions: {
        DismissIntent: _GoUpAction(
          parent == null ? null : () => context.go(parent.path),
        ),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: CameraControls(
            scene: const SceneView(),
            overlay: SafeArea(
              child: Stack(
                children: [
                  if (kDebugMode)
                    const Align(
                      alignment: Alignment.topLeft,
                      child: FpsCounter(),
                    ),
                  Align(
                    alignment: Alignment.topRight,
                    child: TextButton(
                      onPressed: () => context.go(ListPage.path),
                      child: const Text('List'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Goes to the parent location. Disabled at the overview, which has no
/// parent.
class _GoUpAction extends Action<DismissIntent> {
  _GoUpAction(this._goUp);

  /// Goes to the parent location. It is null at the overview.
  final VoidCallback? _goUp;

  @override
  bool isEnabled(DismissIntent intent) => _goUp != null;

  @override
  void invoke(DismissIntent intent) => _goUp!();
}
