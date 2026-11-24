import 'dart:ui';

import 'package:spacetime_portfolio/scene/hole_textures.dart';
import 'package:spacetime_portfolio/scene/sky_cache.dart';

class BlankHoleTextures implements HoleTextures {
  @override
  final diskPattern = _blankImage();

  @override
  final path = _blankImage();

  @override
  void dispose() {
    diskPattern.dispose();
    path.dispose();
  }
}

class BlankSky implements SkyCache {
  final _image = _blankImage();

  @override
  Image imageFor(double cells) => _image;

  @override
  void dispose() => _image.dispose();
}

Image _blankImage() {
  final recorder = PictureRecorder();
  // A recorder records nothing until a canvas is made on it.
  Canvas(recorder);
  final picture = recorder.endRecording();
  final image = picture.toImageSync(1, 1);
  picture.dispose();
  return image;
}
