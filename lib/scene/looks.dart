import 'dart:math' as math;
import 'dart:ui';

import 'package:riverpod/riverpod.dart';

import '../content/content.dart';

/// How the scene is drawn: the hole, the light it gives the bodies, and
/// each body's look.
class Looks {
  const Looks({
    this.hole = const HoleLook(),
    required this.light,
    required this.ambient,
    required this.rim,
    required this.bodies,
  });

  final HoleLook hole;

  /// The colour of the light that the hole gives the bodies.
  final Rgb light;

  /// Light that reaches every side of a body, so its night side is not
  /// black.
  final Rgb ambient;

  /// How much brighter the ambient light is at a body's edge.
  final double rim;

  /// The look of each section's body.
  final Map<SectionId, BodyLook> bodies;
}

const siteLooks = Looks(
  light: Rgb(1, 0.9, 0.8),
  ambient: Rgb(0.022, 0.026, 0.04),
  rim: 1,
  bodies: {
    SectionId.about: KeplerLook.desert,
    SectionId.work: RingedLook.gasGiant,
    SectionId.personal: RingedLook.amber,
    SectionId.contact: KeplerLook.ice,
  },
);

final looksProvider = Provider<Looks>((ref) => siteLooks);

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

/// A colour as red, green and blue. A component can be more than 1: the
/// shaders add and multiply light, and some looks use bright values.
class Rgb {
  const Rgb(this.red, this.green, this.blue);

  const Rgb.grey(double value) : this(value, value, value);

  final double red;
  final double green;
  final double blue;
}

/// How a body is drawn. `shaders/scene.frag` shades each kind.
sealed class BodyLook {
  const BodyLook();

  /// How far from the body's centre the look draws, in body radii.
  double get reach;
}

/// A sphere of one colour, without light: the placeholder for the render
/// test.
final class FlatLook extends BodyLook {
  const FlatLook(this.colour);

  final Color colour;

  @override
  double get reach => 1;
}

/// A banded planet, with or without rings, from mrange's "Planet Shader"
/// (`shaders/planet_ringed.glsl`).
final class RingedLook extends BodyLook {
  const RingedLook({
    this.base = const Rgb.grey(0.8),
    this.wideBand = const Rgb(0.7, 0.7, 0.8),
    this.thinBand = const Rgb(0.75, 0.7, 0.8),
    this.darkBand = const Rgb.grey(0.2),
    this.bandFrequencies = (20, 14, 21, 13),
    this.rim = const Rgb(0, 0, 0.5),
    this.absorption = const Rgb(0.3, 0.25, 0.15),
    this.ringColour = const Rgb(1, 0.8, 0.75),
    this.ringStripeColour = const Rgb.grey(1),
    this.ringLayout = (2.2, 0.3, 0.2, 0.1),
    this.ringFrequencies = (20, 14, 21, 15),
    this.ringOpacity = 0.5,
  });

  /// The planet's colour between its bands.
  final Rgb base;

  /// The colours of the three kinds of band: wide bands, thin bands and
  /// dark belts.
  final Rgb wideBand;
  final Rgb thinBand;
  final Rgb darkBand;

  /// How many bands of each kind there are for each half turn of
  /// latitude. The third kind uses the last two frequencies together.
  final (double, double, double, double) bandFrequencies;

  /// The colour added at the planet's edge.
  final Rgb rim;

  /// How much of each colour the planet absorbs from the light that shines
  /// through its thin edge.
  final Rgb absorption;

  /// The rings' colour, and the colour of the stripes across them.
  final Rgb ringColour;
  final Rgb ringStripeColour;

  /// The radius of the middle of the rings, then three widths, in planet radii.
  /// The first width makes one band round the middle; each of the other two
  /// splits every band into two with a gap between them, so the rings are up to
  /// four bands. All 0: no rings.
  final (double, double, double, double) ringLayout;

  /// The outer edge of the rings, or the planet's surface if that is
  /// further out. The same as `distanceToBody` in `shaders/scene.frag`.
  @override
  double get reach {
    final (middle, first, second, third) = ringLayout;
    return math.max(middle + first + second + third, 1);
  }

  /// The first three make ripples in the rings' opacity; the last one
  /// makes the stripes of [ringStripeColour].
  final (double, double, double, double) ringFrequencies;

  /// The opacity of the rings at their most opaque, seen face on. Seen
  /// at a low angle, they are more opaque.
  final double ringOpacity;

  static const amber = RingedLook(
    base: Rgb(0.9, 0.7, 0.45),
    wideBand: Rgb(0.85, 0.55, 0.3),
    thinBand: Rgb(0.95, 0.85, 0.7),
    darkBand: Rgb(0.35, 0.15, 0.08),
    bandFrequencies: (16, 11, 27, 5),
    rim: Rgb(0.15, 0.05, 0),
    absorption: Rgb(0.15, 0.3, 0.5),
    ringColour: Rgb(0.9, 0.75, 0.5),
    ringStripeColour: Rgb(0.6, 0.5, 0.4),
    ringLayout: (2.5, 0.4, 0.25, 0.15),
    ringOpacity: 0.6,
  );

  static const gasGiant = RingedLook(
    base: Rgb(0.85, 0.75, 0.6),
    wideBand: Rgb(0.8, 0.6, 0.4),
    thinBand: Rgb(0.95, 0.9, 0.8),
    darkBand: Rgb(0.4, 0.22, 0.12),
    bandFrequencies: (9, 6, 11, 7),
    rim: Rgb(0.1, 0.05, 0.1),
    absorption: Rgb(0.2, 0.3, 0.45),
    ringLayout: (0, 0, 0, 0),
  );
}

/// A planet with oceans, land, ice caps, clouds and a glowing atmosphere,
/// from otaviogood's "Kepler 256o" (`shaders/planet_kepler.glsl`).
///
/// The defaults are the original's values, written as the original
/// writes them.
final class KeplerLook extends BodyLook {
  const KeplerLook({
    this.air = const Rgb(0.075 * 0.45, 0.35 * 0.45, 0.99 * 0.45),
    this.greenLand = const Rgb(0.13, 0.65, 0.01),
    this.dryLand = const Rgb(0.8, 0.4, 0.01),
    this.polarIce = const Rgb.grey(7),
    this.clouds = const Rgb.grey(3),
    this.seaLevel = 0.25,
    this.dryness = 6,
    this.glint = const Rgb(3.75, 0.8, 0.02),
    this.oceanReflection = const Rgb(
      258 / 15 * 0.005,
      208 / 15 * 0.005,
      100 / 15 * 0.005,
    ),
    this.glare = const Rgb(3060, 0.25 * 3060, 0.05 * 3060),
    this.seed = (0, 0),
    this.cloudDrift = 0.25,
  });

  /// The edge of the atmosphere's glow: `keplerGlowRadius` in
  /// `shaders/planet_kepler.glsl`.
  @override
  double get reach => 1.05;

  /// The colour of the air and the oceans.
  final Rgb air;

  /// The colour of green land and of dry land.
  final Rgb greenLand;
  final Rgb dryLand;

  /// The colour of land near the poles.
  final Rgb polarIce;

  final Rgb clouds;

  /// The land texture is land where it is above this value.
  final double seaLevel;

  /// How much of the land is dry.
  final double dryness;

  /// The colour of the glints near the edge, where the light is behind the
  /// planet.
  final Rgb glint;

  /// The colour of the light reflected on the oceans.
  final Rgb oceanReflection;

  /// The colour of the light that shines through the atmosphere when the
  /// light is behind the planet.
  final Rgb glare;

  /// An offset into the textures, for other continents.
  final (double, double) seed;

  /// How far the clouds move over the surface while the planet turns, as a
  /// share of the turn.
  final double cloudDrift;

  static const desert = KeplerLook(
    air: Rgb(0.35 * 0.45, 0.18 * 0.45, 0.06 * 0.45),
    greenLand: Rgb(0.7, 0.45, 0.2),
    dryLand: Rgb(0.9, 0.5, 0.15),
    polarIce: Rgb(2.5, 2.2, 2),
    clouds: Rgb(0.6, 0.5, 0.4),
    seaLevel: -0.2,
    dryness: 3,
    glint: Rgb(3, 1.2, 0.3),
    oceanReflection: Rgb(0.026, 0.021, 0.01),
    glare: Rgb(3060, 1200, 300),
    seed: (0.37, 0.21),
  );

  static const ice = KeplerLook(
    air: Rgb(0.5 * 0.3, 0.75 * 0.3, 0.95 * 0.3),
    greenLand: Rgb(0.8, 0.9, 1),
    dryLand: Rgb(0.6, 0.7, 0.8),
    polarIce: Rgb(4, 4.5, 5),
    clouds: Rgb(2.5, 2.6, 2.8),
    seaLevel: 0.35,
    dryness: 1,
    glint: Rgb(2, 2.5, 3),
    oceanReflection: Rgb(0.13, 0.104, 0.05),
    glare: Rgb(1500, 2000, 3060),
    seed: (0.5, 0),
  );
}
