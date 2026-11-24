import 'dart:math' as math;

import 'rgb.dart';

/// How a body is drawn. `shaders/scene.frag` shades each kind.
sealed class BodyLook {
  const BodyLook();

  /// How far from the body's center the look draws, in body radii.
  double get reachInRadii;
}

/// A sphere of one color, without light: a placeholder for tests.
final class FlatLook extends BodyLook {
  const FlatLook(this.color);

  final Rgb color;

  @override
  double get reachInRadii => 1;
}

/// A banded planet, with or without rings, from mrange's "Planet Shader"
/// (`shaders/planet_ringed.glsl`).
final class RingedLook extends BodyLook {
  const RingedLook({
    this.base = const Rgb.gray(0.8),
    this.wideBand = const Rgb(0.7, 0.7, 0.8),
    this.thinBand = const Rgb(0.75, 0.7, 0.8),
    this.darkBand = const Rgb.gray(0.2),
    this.bandFrequencies = (20, 14, 21, 13),
    this.rim = const Rgb(0, 0, 0.5),
    this.absorption = const Rgb(0.3, 0.25, 0.15),
    this.ringColor = const Rgb(1, 0.8, 0.75),
    this.ringStripeColor = const Rgb.gray(1),
    this.ringLayout = (2.2, 0.3, 0.2, 0.1),
    this.ringFrequencies = (20, 14, 21, 15),
    this.ringOpacity = 0.5,
  });

  /// The planet's color between its bands.
  final Rgb base;

  /// The colors of the three kinds of band: wide bands, thin bands and
  /// dark belts.
  final Rgb wideBand;
  final Rgb thinBand;
  final Rgb darkBand;

  /// How many bands of each kind there are for each half turn of
  /// latitude. The third kind uses the last two frequencies together.
  final (double, double, double, double) bandFrequencies;

  /// The color added at the planet's edge.
  final Rgb rim;

  /// How much of each color the planet absorbs from the light that shines
  /// through its thin edge.
  final Rgb absorption;

  /// The rings' color, and the color of the stripes across them.
  final Rgb ringColor;
  final Rgb ringStripeColor;

  /// The radius of the middle of the rings, then three widths, in planet radii.
  /// The first width makes one band around the middle; each of the other two
  /// splits every band into two with a gap between them, so the rings are up to
  /// four bands. All 0: no rings.
  final (double, double, double, double) ringLayout;

  /// The outer edge of the rings, or the planet's surface if that is
  /// farther out. The same as `distanceToBody` in `shaders/scene.frag`.
  @override
  double get reachInRadii {
    final (middle, first, second, third) = ringLayout;
    return math.max(middle + first + second + third, 1);
  }

  /// The first three make ripples in the rings' opacity; the last one
  /// makes the stripes of [ringStripeColor].
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
    ringColor: Rgb(0.9, 0.75, 0.5),
    ringStripeColor: Rgb(0.6, 0.5, 0.4),
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
    this.polarIce = const Rgb.gray(7),
    this.clouds = const Rgb.gray(3),
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
  double get reachInRadii => 1.05;

  /// The color of the air and the oceans.
  final Rgb air;

  /// The color of green land and of dry land.
  final Rgb greenLand;
  final Rgb dryLand;

  /// The color of land near the poles.
  final Rgb polarIce;

  final Rgb clouds;

  /// The land texture is land where it is above this value.
  final double seaLevel;

  /// How much of the land is dry.
  final double dryness;

  /// The color of the glints near the edge, where the light is behind the
  /// planet.
  final Rgb glint;

  /// The color of the light reflected on the oceans.
  final Rgb oceanReflection;

  /// The color of the light that shines through the atmosphere when the
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
