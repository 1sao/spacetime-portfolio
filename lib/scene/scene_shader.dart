import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:vector_math/vector_math_64.dart';

import '../space/body.dart';
import '../space/body_look.dart';
import '../space/frame_snapshot.dart';
import '../space/rgb.dart';
import '../space/system.dart';
import 'checked_uniforms.dart';
import 'hole_textures.dart';
import 'kepler_textures.dart';
import 'lensing_radius.dart';
import 'looks.dart';
import 'sky_cache.dart';

/// The scene's shader, `shaders/scene.frag`, ready to draw.
///
/// This is the single place where the shader is created and its uniforms
/// are set. The constructor looks each uniform up by name and throws if one
/// is missing from the shader or has a different type, so renaming or
/// retyping a uniform on one side only fails as soon as the shader loads.
class SceneShader {
  /// [bodies] is the look of each body slot, in the order of
  /// [FrameSnapshot.bodies]. If [usesPlaceholders] is true, the shader
  /// draws every body as a sphere of one colour, the hole's shadow in
  /// [placeholderHoleColour], and black in place of the sky and the disc,
  /// for the render test.
  SceneShader(
    FragmentProgram program,
    Looks looks, {
    required List<BodyLook> bodies,
    required KeplerTextures keplerTextures,
    required HoleTextures holeTextures,
    required SkyCache skyCache,
    bool usesPlaceholders = false,
  }) : this._(
         program.fragmentShader(),
         looks,
         bodies,
         keplerTextures,
         holeTextures,
         skyCache,
         usesPlaceholders: usesPlaceholders,
       );

  SceneShader._(
    this.fragmentShader,
    Looks looks,
    this._looks,
    KeplerTextures keplerTextures,
    HoleTextures holeTextures,
    this._skyCache, {
    required bool usesPlaceholders,
  }) : _images = [
         keplerTextures.surface,
         keplerTextures.noise,
         keplerTextures.detail,
         holeTextures.discPattern,
         holeTextures.path,
       ],
       _targetPixel = fragmentShader.getUniformVec2('uTargetPixel'),
       _pixelRatio = fragmentShader.getSingleUniformFloat('uPixelRatio'),
       _scale = fragmentShader.getSingleUniformFloat('uScale'),
       _border = fragmentShader.getSingleUniformFloat('uBorder'),
       _focalLength = fragmentShader.getSingleUniformFloat('uFocalLength'),
       _skyCells = fragmentShader.getSingleUniformFloat('uSkyCells'),
       _camera = fragmentShader.getUniformVec3('uCamera'),
       _forward = fragmentShader.getUniformVec3('uForward'),
       _right = fragmentShader.getUniformVec3('uRight'),
       _up = fragmentShader.getUniformVec3('uUp'),
       _discAngle = fragmentShader.getSingleUniformFloat('uDiscAngle'),
       _bodies = List.generate(
         bodySlots,
         (i) => fragmentShader.getUniformVec4('uBody$i'),
       ),
       _slots = List.generate(
         bodySlots,
         (i) => fragmentShader.getUniformVec4('uSlot$i'),
       ),
       _lookBlocks = List.generate(
         bodySlots,
         (i) => fragmentShader.getLookBlock('uLook$i'),
       ),
       _bodiesInLensingRadius = fragmentShader.getUniformVec4(
         'uBodiesInLensingRadius',
       ) {
    assert(
      _looks.length <= bodySlots,
      'The scene draws $bodySlots bodies, not ${_looks.length}.',
    );
    fragmentShader
        .getSingleUniformFloat('uHoleShadowRadius')
        .set(holeShadowRadius);
    fragmentShader.getSingleUniformFloat('uLensingRadius').set(lensingRadius);
    fragmentShader.getSingleUniformFloat('uDiscOuter').set(holeDiscOuterRadius);
    fragmentShader.setHoleLook(looks.hole);
    fragmentShader.setLighting(looks.lighting);
    for (final (i, look) in _looks.indexed) {
      _lookBlocks[i].setLook(look);
    }
    fragmentShader
        .getSingleUniformFloat('uPlaceholders')
        .set(usesPlaceholders ? 1 : 0);
    fragmentShader
        .getUniformVec3('uPlaceholderHole')
        .setColour(placeholderHoleColour);
    fragmentShader
        .getUniformVec3('uTextureSizes')
        .set(
          keplerTextures.surface.width.toDouble(),
          keplerTextures.noise.width.toDouble(),
          keplerTextures.detail.width.toDouble(),
        );
    _setSamplers();
  }

  /// How many bodies the shader can draw. Each body has its own uniforms.
  static const bodySlots = 4;

  /// The colour of the hole's shadow when the shader draws placeholders.
  static const placeholderHoleColour = Color(0xFFFFFFFF);

  /// What a [Paint.shader] draws the scene with, once [set] has set this
  /// frame's uniforms.
  final FragmentShader fragmentShader;

  final List<BodyLook> _looks;

  /// The image of each sampler but the sky's, in the order in which
  /// `shaders/scene.frag` declares them.
  final List<Image> _images;
  final SkyCache _skyCache;

  /// The baked sky for the current lattice, once [set] has run.
  Image? _skyImage;
  final UniformVec2Slot _targetPixel;
  final UniformFloatSlot _pixelRatio;
  final UniformFloatSlot _scale;
  final UniformFloatSlot _border;
  final UniformFloatSlot _focalLength;
  final UniformFloatSlot _skyCells;
  final UniformVec3Slot _camera;
  final UniformVec3Slot _forward;
  final UniformVec3Slot _right;
  final UniformVec3Slot _up;
  final UniformFloatSlot _discAngle;
  final List<UniformVec4Slot> _bodies;
  final List<UniformVec4Slot> _slots;
  final List<UniformArray<UniformVec4Slot>> _lookBlocks;

  /// For each body slot, how far the body is drawn from its centre if any
  /// of it is within the lensing radius, else 0. The shader looks for only
  /// these bodies along the bent paths inside the lensing sphere.
  final UniformVec4Slot _bodiesInLensingRadius;

  void _setSamplers() {
    for (final (index, image) in [..._images, ?_skyImage].indexed) {
      // The planets and the hole read between texels.
      fragmentShader.setImageSampler(
        index,
        image,
        filterQuality: FilterQuality.low,
      );
    }
  }

  /// Sets the uniforms that change from frame to frame, all from [frame]:
  /// the camera, the bodies and the screen. The sky's lattice is made for
  /// [skyFocalLength] (see `SceneLayout.skyFocalLength`). The screen has
  /// [pixelRatio] device pixels for each logical pixel.
  ///
  /// For a soft scene (see `SceneSoftness`), the shader draws the screen at
  /// [scale] times its size, with [border] more of its pixels on each side.
  void set(
    FrameSnapshot frame, {
    required double skyFocalLength,
    required double pixelRatio,
    double scale = 1,
    double border = 0,
  }) {
    final bodies = frame.bodies;
    assert(
      bodies.length == _looks.length,
      'The frame has ${bodies.length} bodies, the looks ${_looks.length}.',
    );
    final camera = frame.camera;
    _pixelRatio.set(pixelRatio * scale);
    _scale.set(scale);
    _border.set(border);
    _focalLength.set(camera.focalLength);
    // The sharp scene's lattice, so the sky stays the same when the scene
    // turns soft.
    final skyCells = _calculateSkyCells(skyFocalLength, pixelRatio);
    _skyCells.set(skyCells);
    final skyImage = _skyCache.imageFor(skyCells);
    final isNewSky = skyImage != _skyImage;
    _skyImage = skyImage;
    final targetPixel = camera.targetPixel(frame.screen);
    _targetPixel.set(targetPixel.x, targetPixel.y);
    _camera.setVector(camera.position);
    _forward.setVector(camera.forward);
    _right.setVector(camera.right);
    _up.setVector(camera.up);
    // Wrapped to a turn, so that a 32-bit float keeps its precision.
    _discAngle.set((holeDiscSpinRate * frame.orbitTime) % (2 * math.pi));
    for (var i = 0; i < bodySlots; i++) {
      if (i < bodies.length) {
        final pose = bodies[i];
        final look = _looks[i];
        _bodies[i].setSphere(pose.sphere);
        final axis = pose.spinAxis;
        _slots[i].set(axis.x, axis.y, axis.z, look.kind);
        if (look is KeplerLook) _lookBlocks[i].setTurn(look, pose);
      } else {
        // A radius of 0 leaves the slot empty.
        _bodies[i].set(0, 0, 0, 0);
      }
    }
    double reachIfInLensingRadius(int i) {
      if (i >= bodies.length) return 0;
      final BodyPose(:sphere, :reach) = bodies[i];
      return sphere.isInLensingRadius(reach) ? reach : 0;
    }

    _bodiesInLensingRadius.set(
      reachIfInLensingRadius(0),
      reachIfInLensingRadius(1),
      reachIfInLensingRadius(2),
      reachIfInLensingRadius(3),
    );
    // On the web, the engine can free a sampler's image between frames, and
    // then the textures read as black. Each frame sets them again.
    if (kIsWeb || isNewSky) _setSamplers();
  }

  void dispose() => fragmentShader.dispose();
}

extension on Sphere {
  /// Whether a body drawn up to [reach] from this sphere's centre comes
  /// within the lensing radius of the hole.
  bool isInLensingRadius(double reach) => center.length - reach < lensingRadius;
}

extension on FragmentShader {
  void setLighting(Lighting lighting) {
    getUniformVec3('uLight').setRgb(lighting.direct);
    getUniformVec3('uAmbient').setRgb(lighting.ambient);
    getSingleUniformFloat('uRim').set(lighting.rim);
  }

  void setHoleLook(HoleLook look) {
    getSingleUniformFloat('uPull').set(look.pull);
    getUniformVec3('uDiscInnerColour').setRgb(look.discInnerColour);
    getUniformVec3('uDiscOuterColour').setRgb(look.discOuterColour);
    getSingleUniformFloat('uDiscBrightness').set(look.discBrightness);
    getUniformVec3('uJetColour').setRgb(look.jetColour);
    getSingleUniformFloat('uJetBrightness').set(look.jetBrightness);
    getSingleUniformFloat('uJetLength').set(look.jetLength);
    getUniformVec3('uGlowColour').setRgb(look.glowColour);
    getUniformVec3('uTint').setRgb(look.tint);
    getUniformVec3('uContrast').setRgb(look.contrast);
  }
}

/// The number of cells across each face of the sky's lattice
/// (`latticePlace` in `shaders/sky.glsl`) for [focalLength] and
/// [pixelRatio], so that every cell gets at least one device pixel.
///
/// A face spans π/2 rad, so each of its N cells spans π/(2N) rad. Take f as
/// [focalLength] and r as the pixel ratio. At the middle of the screen, a
/// device pixel spans 1/(f · r) rad, because f is in logical pixels per unit
/// of slope. So with N = π/2 · f · r, a cell is one pixel wide there. With a
/// longer focal length, a cell is wider than that.
///
/// But a cell can be narrower than that: near an edge of the cube, a cell
/// is cos(π/4) ≈ 0.71 as wide along the edge. And when the view is turned
/// against the cube, the pixel grid is turned against the cells. A cell
/// narrower than a pixel can get no pixel, and then its stars blink.
/// [_skyCellsPerPixel] makes the cells wider than a pixel.
///
/// N is a multiple of 32. Because N is even, the edge of the face at π/4
/// is a cell edge, so there are no narrow cells along the cube's edges.
/// The steps of 32 also keep the lattice the same through small changes
/// of the screen size.
///
/// On a very large screen, N stops at [_maxSkyCells], and the cells are
/// wider than a pixel.
double _calculateSkyCells(double focalLength, double pixelRatio) {
  final cells = _skyCellsPerPixel * math.pi / 2 * focalLength * pixelRatio;
  return (math.max(1, (cells / 32).round()) * 32.0).clamp(32, _maxSkyCells);
}

/// The most cells across a face of the sky's lattice: the baked sky is 3
/// faces wide, and 3 · 1344 is the largest multiple of 32 that stays within
/// 4096 pixels, the widest image that almost every GPU on the web can hold.
const _maxSkyCells = 1344.0;

/// The sky's lattice cells per device pixel at the middle of the screen.
///
/// Chosen with a simulation of the lattice at 1280x800 at a pixel ratio of
/// 2, over 15 views from straight ahead to near straight down: with 1, about
/// 14 % of the cells get no pixel; with 0.7, up to 4 %; with 0.65, none. A
/// smaller number makes the stars more blocky.
const _skyCellsPerPixel = 0.65;

extension _LookBlocks on FragmentShader {
  /// The uniform [name], which must be an array of [_lookSize] vec4s.
  UniformArray<UniformVec4Slot> getLookBlock(String name) {
    final block = getUniformVec4Array(name);
    assert(
      block.length == _lookSize,
      'Uniform `$name` has ${block.length} vec4s, not $_lookSize.',
    );
    return block;
  }
}

/// The vec4s of each body's look, `lookSize` in `shaders/scene.frag`.
const _lookSize = 11;

extension on BodyLook {
  /// The kind of look, as `scene.frag` names it: `flatKind`, `ringedKind`
  /// or `keplerKind`.
  double get kind => switch (this) {
    FlatLook() => 0,
    RingedLook() => 1,
    KeplerLook() => 2,
  };
}

/// Sets a body's look into its block of vec4s, in the order in which
/// `shadeBody` in `shaders/scene.frag` reads them.
extension _LookBlock on UniformArray<UniformVec4Slot> {
  void setLook(BodyLook look) {
    final values = switch (look) {
      FlatLook(:final colour) => [colour.withW(0)],
      RingedLook() => [
        look.base.withW(look.ringOpacity),
        look.wideBand.withW(0),
        look.thinBand.withW(0),
        look.darkBand.withW(0),
        look.bandFrequencies,
        look.rim.withW(0),
        look.absorption.withW(0),
        look.ringColour.withW(0),
        look.ringStripeColour.withW(0),
        look.ringLayout,
        look.ringFrequencies,
      ],
      KeplerLook() => [
        look.air.withW(look.seaLevel),
        look.greenLand.withW(look.dryness),
        look.dryLand.withW(0),
        look.polarIce.withW(0),
        look.clouds.withW(0),
        look.glint.withW(0),
        look.oceanReflection.withW(0),
        look.glare.withW(0),
        // The turn, which setTurn sets for each frame.
        (look.seed.$1, look.seed.$2, 0.0, 0.0),
      ],
    };
    for (final (i, (x, y, z, w)) in values.paddedTo(length).indexed) {
      this[i].set(x, y, z, w);
    }
  }

  /// Sets how far a Kepler planet with [look] has turned in [pose], and how
  /// far its clouds have moved.
  ///
  /// `planet_kepler.glsl` reads the turn in texture units, 4 to a turn.
  /// Each value is wrapped to its period, so that a 32-bit float keeps its
  /// precision as the angle grows: the clouds repeat after 2 units, because
  /// the shader reads their texture at half scale too.
  void setTurn(KeplerLook look, BodyPose pose) {
    final turn = pose.spinAngle * 2 / math.pi;
    final spin = (turn + _keplerStartTurn) % 4;
    final cloudShift = (turn * look.cloudDrift) % 2;
    this[8].set(look.seed.$1, look.seed.$2, spin, cloudShift);
  }
}

/// How far a Kepler planet has turned at spin angle 0, in texture units:
/// the original's start.
const _keplerStartTurn = 0.7;

typedef _Vec4 = (double, double, double, double);

extension on List<_Vec4> {
  /// This list, with vec4s of 0 added up to [length].
  List<_Vec4> paddedTo(int length) => [
    ...this,
    ...List.filled(length - this.length, (0.0, 0.0, 0.0, 0.0)),
  ];
}

extension on Rgb {
  /// A vec4 with this colour in x, y and z, and [w] in its fourth
  /// component.
  _Vec4 withW(double w) => (red, green, blue, w);
}

extension _Vec3Values on UniformVec3Slot {
  void setVector(Vector3 vector) => set(vector.x, vector.y, vector.z);

  void setColour(Color colour) => set(colour.r, colour.g, colour.b);

  void setRgb(Rgb colour) => set(colour.red, colour.green, colour.blue);
}

extension _SphereValue on UniformVec4Slot {
  /// Sets [sphere] as the shader reads it: its centre in xyz and its radius
  /// in w.
  void setSphere(Sphere sphere) {
    final centre = sphere.center;
    set(centre.x, centre.y, centre.z, sphere.radius);
  }
}
