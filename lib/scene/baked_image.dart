import 'dart:ui';

extension BakedImage on FragmentShader {
  /// The image of [width] by [height] pixels that this shader draws. Then
  /// disposes the shader.
  Image bakeAndDispose(int width, int height) {
    final recorder = PictureRecorder();
    Canvas(recorder).drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      Paint()..shader = this,
    );
    final picture = recorder.endRecording();
    final image = picture.toImageSync(width, height);
    picture.dispose();
    dispose();
    return image;
  }
}
