import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A soft scene is drawn small, blurred and scaled up. It costs far less
/// to draw, and the blur hides its low resolution.
@immutable
class SceneSoftness {
  const SceneSoftness({this.scale = 1, this.blur = 0})
    : assert(scale > 0 && scale <= 1 && blur >= 0);

  static const sharp = SceneSoftness();

  static const soft = SceneSoftness(scale: 0.25, blur: 1.5);

  /// The drawn scene's logical pixels for each logical pixel of the window.
  final double scale;

  /// The blur's sigma, in the drawn scene's logical pixels.
  final double blur;

  bool get isSharp => scale == 1 && blur == 0;

  /// The blur reads past the edge of what is drawn; the border keeps that
  /// edge out of the window.
  double get border => isSharp ? 0 : (3 * blur).ceilToDouble() + 1;

  @override
  bool operator ==(Object other) =>
      other is SceneSoftness && other.scale == scale && other.blur == blur;

  @override
  int get hashCode => Object.hash(scale, blur);
}

extension SoftSceneRect on Rect {
  /// Maps this rectangle from the scene's logical pixels to those of the
  /// scene drawn with [softness], smaller by its border on each side: the
  /// blur reads that far into it.
  Rect offset(SceneSoftness softness) {
    final SceneSoftness(:scale, :border) = softness;
    return (topLeft * scale & size * scale)
        .shift(Offset(border, border))
        .deflate(border);
  }
}

final sceneSoftnessProvider = Provider<ValueNotifier<SceneSoftness>>((ref) {
  final softness = ValueNotifier(
    const bool.fromEnvironment('SOFT_SCENE')
        ? SceneSoftness.soft
        : SceneSoftness.sharp,
  );
  ref.onDispose(softness.dispose);
  return softness;
});

/// Draws [child] small, blurred and scaled up, as [softness] sets.
class SoftLayer extends StatelessWidget {
  const SoftLayer({super.key, required this.softness, required this.child});

  final SceneSoftness softness;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final SceneSoftness(:scale, :blur, :border) = softness;
    final enlargement = 1 / scale;
    final shift = -border * enlargement;
    final matrix = Matrix4.identity()
      ..translateByDouble(shift, shift, 0, 1)
      ..scaleByDouble(enlargement, enlargement, 1, 1);
    return ImageFiltered(
      enabled: !softness.isSharp,
      imageFilter: ImageFilter.compose(
        outer: ImageFilter.matrix(
          matrix.storage,
          filterQuality: FilterQuality.low,
        ),
        inner: ImageFilter.blur(
          sigmaX: blur,
          sigmaY: blur,
          tileMode: TileMode.clamp,
        ),
      ),
      child: child,
    );
  }
}
