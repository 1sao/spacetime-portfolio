import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import '../space/frame_snapshot.dart';
import 'frame_loop.dart';
import 'hole_textures.dart';
import 'kepler_textures.dart';
import 'looks.dart';
import 'opaque_surface.dart';
import 'scene_layout_provider.dart';
import 'scene_running.dart';
import 'scene_shader.dart';
import 'sky_cache.dart';
import 'visible_rects.dart';

const sceneShaderAsset = 'shaders/scene.frag';

/// The scene shader's program and the textures it reads, made once.
class SceneAssets {
  const SceneAssets(
    this.program,
    this.keplerTextures,
    this.holeTextures,
    this.skyCache,
  );

  final FragmentProgram program;
  final KeplerTextures keplerTextures;
  final HoleTextures holeTextures;
  final SkyCache skyCache;
}

final sceneAssetsProvider = FutureProvider<SceneAssets>((ref) async {
  final hole = ref.watch(looksProvider.select((looks) => looks.hole));
  final (program, keplerProgram, holeProgram, skyProgram) = await (
    FragmentProgram.fromAsset(sceneShaderAsset),
    FragmentProgram.fromAsset(keplerTexturesAsset),
    FragmentProgram.fromAsset(holeTexturesAsset),
    FragmentProgram.fromAsset(skyCacheAsset),
  ).wait;
  // The provider can be gone by the time the programs have loaded.
  if (!ref.mounted) throw StateError('The scene went while it loaded.');
  final keplerTextures = KeplerTextures.bake(keplerProgram);
  ref.onDispose(keplerTextures.dispose);
  final holeTextures = HoleTextures.bake(holeProgram, hole);
  ref.onDispose(holeTextures.dispose);
  final skyCache = SkyCache(skyProgram);
  ref.onDispose(skyCache.dispose);
  return SceneAssets(program, keplerTextures, holeTextures, skyCache);
});

final sceneShaderProvider = Provider.autoDispose<AsyncValue<SceneShader>>((
  ref,
) {
  final looks = ref.watch(looksProvider);
  final bodies = ref.watch(bodiesInPageOrderProvider);
  return ref.watch(sceneAssetsProvider).whenData((assets) {
    final shader = SceneShader(
      assets.program,
      looks,
      bodies: [for (final body in bodies) body.look],
      keplerTextures: assets.keplerTextures,
      holeTextures: assets.holeTextures,
      skyCache: assets.skyCache,
    );
    ref.onDispose(shader.dispose);
    return shader;
  });
});

/// A soft scene is drawn small, blurred and scaled up. It costs far less
/// to draw, and the blur hides its low resolution.
@immutable
class SceneSoftness {
  const SceneSoftness({this.scale = 1, this.blur = 0})
    : assert(scale > 0 && scale <= 1 && blur >= 0);

  static const sharp = SceneSoftness();

  static const soft = SceneSoftness(scale: 0.25, blur: 1.5);

  /// The drawn scene's logical pixels for each logical pixel of the window.
  final double scale;

  /// The blur's sigma, in the drawn scene's logical pixels.
  final double blur;

  bool get isSharp => scale == 1 && blur == 0;

  /// The blur reads past the edge of what is drawn; the border keeps that
  /// edge out of the window.
  double get border => isSharp ? 0 : (3 * blur).ceilToDouble() + 1;

  @override
  bool operator ==(Object other) =>
      other is SceneSoftness && other.scale == scale && other.blur == blur;

  @override
  int get hashCode => Object.hash(scale, blur);
}

extension SoftSceneRect on Rect {
  /// Maps this rectangle from the scene's logical pixels to those of the
  /// scene drawn with [softness], smaller by its border on each side: the
  /// blur reads that far into it.
  Rect offset(SceneSoftness softness) {
    final SceneSoftness(:scale, :border) = softness;
    return (topLeft * scale & size * scale)
        .shift(Offset(border, border))
        .deflate(border);
  }
}

final sceneSoftnessProvider = Provider<ValueNotifier<SceneSoftness>>((ref) {
  final softness = ValueNotifier(
    const bool.fromEnvironment('SOFT_SCENE')
        ? SceneSoftness.soft
        : SceneSoftness.sharp,
  );
  ref.onDispose(softness.dispose);
  return softness;
});

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
      sceneLayoutProvider.select((layout) => layout.skyFocalLength),
    );
    return switch (ref.watch(sceneShaderProvider)) {
      AsyncData(value: final shader) => RepaintBoundary(
        child: ValueListenableBuilder(
          valueListenable: softness,
          builder: (_, softness, _) => _softLayer(
            softness,
            CustomPaint(
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

  Widget _softLayer(SceneSoftness softness, Widget child) {
    final SceneSoftness(:scale, :blur, :border) = softness;
    final enlargement = 1 / scale;
    final shift = -border * enlargement;
    final matrix = Matrix4.identity()
      ..translateByDouble(shift, shift, 0, 1)
      ..scaleByDouble(enlargement, enlargement, 1, 1);
    return ImageFiltered(
      enabled: !softness.isSharp,
      imageFilter: ImageFilter.compose(
        outer: ImageFilter.matrix(
          matrix.storage,
          filterQuality: FilterQuality.low,
        ),
        inner: ImageFilter.blur(
          sigmaX: blur,
          sigmaY: blur,
          tileMode: TileMode.clamp,
        ),
      ),
      child: child,
    );
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
