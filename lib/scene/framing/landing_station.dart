import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_math/vector_math_64.dart';

import '../../providers.dart';
import '../../space/camera/camera.dart';
import '../../space/camera/screen_extent.dart';
import '../../space/station/framing.dart';
import '../../space/station/screen_point.dart';
import '../../space/station/station.dart';
import '../../space/system/body.dart';
import '../../space/system/system.dart';
import '../../viewport/window_size.dart';
import 'focal_lengths.dart';
import 'scene_screen.dart';

final landingStationProvider = Provider<Station>(
  (ref) => Station.landing(
    landingFraming(
      ref.watch(sceneScreenProvider),
      focalLength: ref.watch(focalLengthsProvider).landing,
      bodies: ref.watch(bodiesInPageOrderProvider),
      floor: ref.watch(measuredLandingFloorProvider),
    ),
  ),
);

// TODO: Measure the floor during layout, not after the frame, so that the
// scene gets it in the same frame.
final measuredLandingFloorProvider =
    NotifierProvider<LandingFloorNotifier, double>(LandingFloorNotifier.new);

/// The page sets the floor above the Landing's text after it lays the text
/// out.
class LandingFloorNotifier extends Notifier<double> {
  @override
  double build() => double.infinity;

  set floor(double floor) => state = floor;
}

/// The Landing's framing on [screen], moved up so that neither the hole
/// nor [bodies] reach below [floor], the lowest point on the screen they
/// may reach.
Framing landingFraming(
  Screen screen, {
  required double focalLength,
  required List<Body> bodies,
  required double floor,
}) {
  final isVertical =
      WidthClass.of(screen.width).landingNavigationOrientation ==
      LandingNavigationOrientation.vertical;
  Framing framingAt(Vector2 point) => Framing(
    screenPoint: ScreenPoint.fixed(point),
    focalLength: focalLength,
    roll: isVertical ? math.pi / 2 : 0,
  );
  final point = isVertical ? Vector2(0.3, 0.36) : Vector2(0.5, 0.32);
  final (:top, :bottom) = Station.landing(framingAt(point))
      .cameraAt(0)
      .verticalExtentOf([
        (center: Vector3.zero(), radius: holeShadowRadius),
        for (final body in bodies)
          (center: body.positionAt(0), radius: body.reach),
      ], screen);
  // Moving the screen point shifts the whole picture by the same number of
  // pixels, so one projection is enough.
  final lift = (bottom - floor).clamp(0.0, math.max(0.0, top));
  return framingAt(Vector2(point.x, point.y - lift / screen.height));
}
