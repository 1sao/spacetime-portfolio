import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import '../space/camera.dart';
import '../viewport/window_size.dart';
import 'scene_layout.dart';

final sceneLayoutProvider = Provider<SceneLayout>((ref) {
  // The large height keeps the scene's size while the address bar hides.
  final (:width, :height) = ref.watch(
    windowSizeProvider.select(
      (window) => (width: window.width, height: window.largeHeight),
    ),
  );
  return SceneLayout(
    Screen(width: width, height: height),
    bodies: ref.watch(bodiesInPageOrderProvider),
    landingFloor: ref.watch(landingFloorProvider),
  );
});

/// [SceneLayout.landingFloor]. The page sets it above the Landing's text
/// once it has laid the text out.
final landingFloorProvider = NotifierProvider<LandingFloorNotifier, double>(
  LandingFloorNotifier.new,
);

class LandingFloorNotifier extends Notifier<double> {
  @override
  double build() => double.infinity;

  set floor(double floor) => state = floor;
}
