import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

import '../space/body.dart';
import '../space/camera.dart';
import '../space/system.dart';
import '../viewport/window_size.dart';

/// How the scene is framed on [screen], the scene's own size.
class SceneLayout {
  SceneLayout(
    this.screen, {
    this.bodies = const [],
    this.landingFloor = double.infinity,
  }) : widthClass = WidthClass.of(screen.width);

  final Screen screen;
  final WidthClass widthClass;

  final List<Body> bodies;

  /// The lowest point on the screen that the Landing's hole and bodies
  /// may reach.
  final double landingFloor;

  /// On a phone held upright, a column leaves the bodies larger.
  bool get isLandingColumn => widthClass == WidthClass.compact;

  Camera get landingCamera => _landingCameraAt(landingScreenPoint);

  Camera _landingCameraAt(Vector2 screenPoint) => Camera(
    target: Vector3.zero(),
    fromTarget: lineUpViewpoint,
    focalLength: landingFocalLength,
    screenPoint: screenPoint,
    roll: landingRoll,
  );

  /// Moved up so that nothing reaches below [landingFloor].
  late final Vector2 landingScreenPoint = () {
    final point = isLandingColumn ? Vector2(0.3, 0.36) : Vector2(0.5, 0.32);
    final camera = _landingCameraAt(point);
    var (top, bottom) = (double.infinity, double.negativeInfinity);
    final disks = [
      (Vector3.zero(), holeShadowRadius),
      for (final body in bodies) (body.positionAt(0), body.reach),
    ];
    for (final (center, radius) in disks) {
      final pixel = camera.project(center, screen)!;
      final pixelRadius = camera.projectedRadius(center, radius);
      top = math.min(top, pixel.y - pixelRadius);
      bottom = math.max(bottom, pixel.y + pixelRadius);
    }
    // Moving the screen point shifts the whole picture by the same number
    // of pixels, so one projection is enough.
    final lift = (bottom - landingFloor).clamp(0.0, math.max(0.0, top));
    return Vector2(point.x, point.y - lift / screen.height);
  }();

  double get landingRoll => isLandingColumn ? math.pi / 2 : 0;

  double get landingFocalLength => isLandingColumn
      ? math.min(screen.height * 0.56, screen.width * 1.6)
      : defaultFocalLength;

  double get defaultFocalLength {
    final lineFractionOfWidth = isLandingColumn ? 0.8 : 0.84;
    return math.min(
      screen.width * lineFractionOfWidth / _lineLengthPerFocalLength,
      screen.height * 1.9,
    );
  }

  /// The shortest of this layout's, so that every sky cell gets a pixel in
  /// every framing, and the sky is not baked again between framings.
  double get skyFocalLength => math.min(landingFocalLength, defaultFocalLength);
}

const _lineLengthPerFocalLength = 0.8;
