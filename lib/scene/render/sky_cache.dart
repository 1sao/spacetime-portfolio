import 'dart:ui';

import 'baked_image.dart';
import 'checked_uniforms.dart';

const skyCacheAsset = 'shaders/sky_cache.frag';

/// The sky, baked by `shaders/sky_cache.frag` at a fixed set of
/// directions: each face of a cube around the camera is split into cells,
/// and each cell gives one direction and one pixel of the image.
class SkyCache {
  SkyCache(this._program);

  final FragmentProgram _program;
  double _cells = 0;
  Image? _image;

  /// The sky baked for [cells] cells across each face, baked again when
  /// [cells] changes.
  Image imageFor(double cells) {
    final image = _image;
    if (image != null && cells == _cells) return image;
    // Frames already drawn keep their own reference to the old image.
    image?.dispose();
    final shader = _program.fragmentShader();
    shader.getSingleUniformFloat('uSkyCells').set(cells);
    _cells = cells;
    // The faces are in 3 columns and 2 rows.
    return _image = shader.bakeAndDispose(
      (3 * cells).round(),
      (2 * cells).round(),
    );
  }

  void dispose() => _image?.dispose();
}
