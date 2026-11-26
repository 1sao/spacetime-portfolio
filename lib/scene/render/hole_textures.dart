import 'dart:ui';

import '../../space/system/system.dart';
import 'baked_image.dart';
import 'checked_uniforms.dart';
import 'lensing_radius.dart';
import 'looks.dart';

const holeTexturesAsset = 'shaders/hole_textures.frag';

/// The textures that the scene shader reads for the hole, baked by
/// `shaders/hole_textures.frag`.
class HoleTextures {
  HoleTextures._(this.diskPattern, this.path);

  /// Bakes the textures with [program] for [look].
  factory HoleTextures.bake(FragmentProgram program, HoleLook look) {
    Image bake(int width, int height, int kind) {
      final shader = program.fragmentShader();
      shader
          .getUniformVec2('uResolution')
          .set(width.toDouble(), height.toDouble());
      shader.getSingleUniformFloat('uKind').set(kind.toDouble());
      shader.getSingleUniformFloat('uLensingRadius').set(lensingRadius);
      shader.getSingleUniformFloat('uDiskOuter').set(holeDiskOuterRadius);
      shader.getSingleUniformFloat('uPull').set(look.pull);
      return shader.bakeAndDispose(width, height);
    }

    // The path table is pathColumns by pathRows texels (shaders/hole.glsl).
    return HoleTextures._(bake(1024, 1024, 0), bake(512, 34, 1));
  }

  /// The disk's pattern, which the disk turns with.
  final Image diskPattern;

  /// For each distance at which a straight ray would pass the hole: where
  /// the ray goes inside the sphere in which the hole bends light, how far
  /// it turns there, and the glow it gathers (see `shaders/hole.glsl`).
  final Image path;

  void dispose() {
    diskPattern.dispose();
    path.dispose();
  }
}
