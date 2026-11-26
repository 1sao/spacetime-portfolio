import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../space/frame_snapshot.dart';
import 'frame_loop.dart';
import 'framing/focal_lengths.dart';
import 'render/opaque_surface.dart';
import 'render/scene_assets.dart';
import 'render/scene_shader.dart';
import 'render/visible_rects.dart';
import 'scene_running.dart';
import 'softness.dart';

class SceneView extends ConsumerWidget {
  const SceneView({super.key, required this.opaqueSurfaces});

  final OpaqueSurfaceRegistry opaqueSurfaces;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFrame = ref.watch(frameSnapshotListenableProvider);
    final isRunning = ref.watch(isSceneRunningProvider);
    // Browser zoom changes it, so the sky's lattice follows the zoom.
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final softness = ref.watch(sceneSoftnessProvider);
    final skyFocalLength = ref.watch(
      focalLengthsProvider.select((focalLengths) => focalLengths.sky),
    );
    return switch (ref.watch(sceneShaderProvider)) {
      AsyncData(value: final shader) => RepaintBoundary(
        child: ValueListenableBuilder(
          valueListenable: softness,
          builder: (_, softness, _) => SoftLayer(
            softness: softness,
            child: CustomPaint(
              size: Size.infinite,
              painter: _ScenePainter(
                shader,
                currentFrame,
                pixelRatio,
                skyFocalLength,
                softness,
                // The page can move over a still scene with no new frame.
                isRunning ? opaqueSurfaces : null,
                context,
              ),
            ),
          ),
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
  _ScenePainter(
    this.shader,
    this.currentFrame,
    this.pixelRatio,
    this.skyFocalLength,
    this.softness,
    this.opaqueSurfaces,
    this.sceneContext,
  ) : super(repaint: currentFrame);

  final SceneShader shader;
  final ValueListenable<FrameSnapshot> currentFrame;
  final double pixelRatio;
  final double skyFocalLength;
  final SceneSoftness softness;
  final OpaqueSurfaceRegistry? opaqueSurfaces;
  final BuildContext sceneContext;

  @override
  void paint(Canvas canvas, Size size) {
    final SceneSoftness(:scale, :border) = softness;
    final frame = currentFrame.value;
    assert(
      size.width == frame.screen.width && size.height == frame.screen.height,
      'The scene is $size, its frame '
      '${frame.screen.width}x${frame.screen.height}.',
    );
    shader.set(
      frame,
      skyFocalLength: skyFocalLength,
      pixelRatio: pixelRatio,
      scale: scale,
      border: border,
    );
    final drawnArea = Rect.fromLTWH(
      0,
      0,
      size.width * scale + 2 * border,
      size.height * scale + 2 * border,
    );
    // The surfaces' boxes are read after layout, so they are this frame's.
    final hiddenRects =
        opaqueSurfaces
            ?.rectsIn(sceneContext.findRenderObject()!)
            .map((rect) => rect.offset(softness)) ??
        [];
    // Without antialiasing, parts that share an edge leave no seam.
    final paint = Paint()
      ..shader = shader.fragmentShader
      ..isAntiAlias = false;
    for (final part in drawnArea.visibleRects(hiddenRects)) {
      canvas.drawRect(part, paint);
    }
  }

  @override
  bool shouldRepaint(_ScenePainter oldDelegate) =>
      oldDelegate.shader != shader ||
      oldDelegate.currentFrame != currentFrame ||
      oldDelegate.pixelRatio != pixelRatio ||
      oldDelegate.skyFocalLength != skyFocalLength ||
      oldDelegate.softness != softness ||
      oldDelegate.opaqueSurfaces != opaqueSurfaces;
}
