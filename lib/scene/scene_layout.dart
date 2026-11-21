import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

import '../space/camera.dart';
import '../space/system.dart';

/// The first three of Material 3's window size classes, by width.
enum WidthClass {
  /// Under 600 logical pixels: phones held upright.
  compact,

  /// 600 to 839.
  medium,

  /// 840 or more, which also covers Material 3's wider classes.
  expanded;

  static WidthClass of(double width) => switch (width) {
    < 600 => compact,
    < 840 => medium,
    _ => expanded,
  };
}

/// How the scene is framed on [screen], the scene's own size.
class SceneLayout {
  SceneLayout(this.screen) : widthClass = WidthClass.of(screen.width);

  final Screen screen;
  final WidthClass widthClass;

  /// Whether the Landing's line of bodies stands upright, in page order
  /// from the top. On a phone held upright, a column leaves the bodies
  /// larger.
  bool get isColumn => widthClass == WidthClass.compact;

  /// The camera of the Landing, which shows the whole system.
  Camera get landingCamera => Camera(
    target: Vector3.zero(),
    fromTarget: lineUpViewpoint,
    focalLength: landingFocalLength,
    screenPoint: landingScreenPoint,
    roll: landingRoll,
  );

  /// Where the hole lands on the Landing, as fractions of the screen. The
  /// row is a third of the way down, so that the titles and the intro fit
  /// under it. The column is near the left edge, so that the titles fit to
  /// its right.
  Vector2 get landingScreenPoint =>
      isColumn ? Vector2(0.3, 0.36) : Vector2(0.5, 0.32);

  /// The Landing camera's roll: a quarter turn makes the line a column.
  double get landingRoll => isColumn ? math.pi / 2 : 0;

  /// The Landing's focal length, in logical pixels. The column spans about
  /// 45 % of the height, up to a limit set by the width.
  double get landingFocalLength => isColumn
      ? math.min(screen.height * 0.56, screen.width * 1.6)
      : sectionFocalLength;

  /// The focal length in the sections and on the row Landing, in logical
  /// pixels: the row then spans 84 % of the width (80 % of a compact
  /// width), up to a limit set by the height.
  double get sectionFocalLength {
    final span = isColumn ? 0.8 : 0.84;
    return math.min(
      screen.width * span / _lineLengthPerFocalLength,
      screen.height * 1.9,
    );
  }

  /// The focal length that the sky's lattice is made for: the shortest of
  /// this layout's, so that every cell gets a pixel in every framing, and
  /// the sky is not baked again when the camera moves between them.
  double get skyFocalLength => math.min(landingFocalLength, sectionFocalLength);
}

/// How long the line of the bodies' start points is on the screen, as seen
/// from the Landing camera, for each pixel of focal length.
const _lineLengthPerFocalLength = 0.8;
