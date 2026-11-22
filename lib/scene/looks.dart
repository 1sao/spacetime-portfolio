import 'package:riverpod/riverpod.dart';

import '../space/rgb.dart';

/// How the scene is drawn: the hole, and how the bodies are lit.
class Looks {
  const Looks({this.hole = const HoleLook(), this.lighting = const Lighting()});

  final HoleLook hole;
  final Lighting lighting;
}

const siteLooks = Looks();

final looksProvider = Provider<Looks>((ref) => siteLooks);

/// How the bodies are lit.
class Lighting {
  const Lighting({
    this.direct = const Rgb(1, 0.9, 0.8),
    this.ambient = const Rgb(0.022, 0.026, 0.04),
    this.rim = 1,
  });

  /// The colour of the light that the hole gives the bodies.
  final Rgb direct;

  /// Light that reaches every side of a body, so its night side is not
  /// black.
  final Rgb ambient;

  /// How much brighter the ambient light is at a body's edge.
  final double rim;
}

/// How the hole and its disc are drawn, from nethe550's "Black Hole"
/// (`shaders/hole.glsl`). Its size is in `lib/space/system.dart`.
class HoleLook {
  const HoleLook({
    this.pull = 0.0025,
    this.discInnerColour = const Rgb(1, 0.8, 0.6),
    this.discOuterColour = const Rgb(0.5, 0.46, 0.4),
    this.discBrightness = 0.75,
    this.jetColour = const Rgb(0.5, 0.7, 0.99),
    this.jetBrightness = 0.0015,
    this.jetLength = 16,
    this.glowColour = const Rgb(1, 0.9, 0.85),
    this.tint = const Rgb(1, 0.9, 0.85),
    this.contrast = const Rgb(1.5, 1.6, 1.7),
  });

  /// How strongly the hole bends light: the turn of a ray, in rad, for each
  /// step of 0.02 at 1 hole unit (see `shaders/hole.glsl`) from the hole,
  /// before it fades toward the edge of the sphere it bends light in. A weak
  /// pull bends the rays just outside the shadow little. A pull that is too
  /// strong catches some of them before they leave the sphere, which shows as a
  /// ragged edge round the shadow.
  final double pull;

  /// The disc's colour near the hole and further out.
  final Rgb discInnerColour;
  final Rgb discOuterColour;

  final double discBrightness;

  /// The colour and brightness of the jets along the disc's axis.
  final Rgb jetColour;
  final double jetBrightness;

  /// How far the jets reach from the hole, in world units. They fade out
  /// over the second half of it.
  final double jetLength;

  /// The colour of the glow round the hole. Its brightness comes from the
  /// pull.
  final Rgb glowColour;

  /// The colour that the hole's light is multiplied by.
  final Rgb tint;

  /// The power that each channel of the hole's light is raised to: above
  /// 1, dim light dims more than bright light.
  final Rgb contrast;
}
