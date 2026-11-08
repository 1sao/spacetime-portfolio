import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../space/camera.dart';
import '../space/frame.dart';
import 'frame_loop.dart';
import 'looks.dart';
import 'scene_shader.dart';

const sceneShaderAsset = 'shaders/scene.frag';

final sceneProgramProvider = FutureProvider<FragmentProgram>(
  (ref) => FragmentProgram.fromAsset(sceneShaderAsset),
);

/// The scene's shader, once its program has loaded. An [AsyncError] if the
/// program fails to load or a uniform doesn't match.
final sceneShaderProvider = Provider.autoDispose<AsyncValue<SceneShader>>(
  (ref) => ref.watch(sceneProgramProvider).whenData((program) {
    final shader = SceneShader(program, placeholderLooks);
    ref.onDispose(shader.dispose);
    return shader;
  }),
);

/// The scene: the central body and the category bodies, drawn by the shader
/// from the current [FrameSnapshot]. The map page puts its overlays and
/// controls on top of it.
class SceneView extends ConsumerWidget {
  const SceneView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFrame = ref.watch(frameSnapshotListenableProvider);
    return switch (ref.watch(sceneShaderProvider)) {
      // The boundary keeps the widgets on top from repainting with the scene
      // every frame.
      AsyncData(value: final shader) => RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _ScenePainter(shader, currentFrame),
        ),
      ),
      AsyncLoading() => const SizedBox.expand(),
      AsyncError(:final error, :final stackTrace) => Error.throwWithStackTrace(
        error,
        stackTrace,
      ),
    };
  }
}

class _ScenePainter extends CustomPainter {
  _ScenePainter(this.shader, this.currentFrame) : super(repaint: currentFrame);

  final SceneShader shader;
  final ValueListenable<FrameSnapshot> currentFrame;

  @override
  void paint(Canvas canvas, Size size) {
    shader.set(
      currentFrame.value,
      Screen(width: size.width, height: size.height),
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = shader.fragmentShader,
    );
  }

  @override
  bool shouldRepaint(_ScenePainter oldDelegate) =>
      oldDelegate.shader != shader || oldDelegate.currentFrame != currentFrame;
}
