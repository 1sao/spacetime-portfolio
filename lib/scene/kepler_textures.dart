import 'dart:ui';

import 'baked_image.dart';
import 'checked_uniforms.dart';

const keplerTexturesAsset = 'shaders/kepler_textures.frag';

/// The three textures that `shaders/planet_kepler.glsl` reads, each with a
/// border of one texel on each side.
class KeplerTextures {
  KeplerTextures._(this.surface, this.noise, this.detail);

  /// Draws the textures with [program], `shaders/kepler_textures.frag`.
  factory KeplerTextures.bake(FragmentProgram program) {
    Image bake(int texels, int kind) {
      final size = texels + 2;
      final shader = program.fragmentShader();
      shader
          .getUniformVec2('uResolution')
          .set(size.toDouble(), size.toDouble());
      shader.getSingleUniformFloat('uKind').set(kind.toDouble());
      return shader.bakeAndDispose(size, size);
    }

    return KeplerTextures._(bake(1024, 0), bake(64, 1), bake(512, 2));
  }

  /// Textures of one black texel each, for a scene without Kepler planets.
  /// The shader needs an image for each sampler.
  factory KeplerTextures.blank() {
    Image blank() {
      final recorder = PictureRecorder();
      Canvas(recorder).drawRect(const Rect.fromLTWH(0, 0, 1, 1), Paint());
      final picture = recorder.endRecording();
      final image = picture.toImageSync(1, 1);
      picture.dispose();
      return image;
    }

    return KeplerTextures._(blank(), blank(), blank());
  }

  /// The clouds in red, the land in green, and in blue how much land is
  /// dry and how much the clouds swirl.
  final Image surface;

  /// Noise in each channel, for the ripples on the oceans.
  final Image noise;

  /// Dark patches in the land.
  final Image detail;

  void dispose() {
    surface.dispose();
    noise.dispose();
    detail.dispose();
  }
}
