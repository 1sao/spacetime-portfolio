import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import '../space/camera.dart';
import '../space/frame_snapshot.dart';
import 'frame_loop.dart';
import 'hole_textures.dart';
import 'kepler_textures.dart';
import 'looks.dart';
import 'scene_shader.dart';
import 'sky_cache.dart';

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

/// The scene's shader, once its assets have loaded. An [AsyncError] if
/// they fail to load or a uniform doesn't match.
final sceneShaderProvider = Provider.autoDispose<AsyncValue<SceneShader>>((
  ref,
) {
  final looks = ref.watch(looksProvider);
  final content = ref.watch(contentProvider);
  final bodies = ref.watch(bodiesProvider);
  // In page order, as the frame loop orders the bodies.
  assert(
    bodies.keys.every(looks.bodies.containsKey),
    'Every body needs a look.',
  );
  final bodyLooks = [
    for (final section in content)
      if (bodies.containsKey(section.id)) looks.bodies[section.id]!,
  ];
  return ref.watch(sceneAssetsProvider).whenData((assets) {
    final shader = SceneShader(
      assets.program,
      looks,
      bodies: bodyLooks,
      keplerTextures: assets.keplerTextures,
      holeTextures: assets.holeTextures,
      skyCache: assets.skyCache,
    );
    ref.onDispose(shader.dispose);
    return shader;
  });
});

/// How soft the scene is drawn: at [scale] times the window's size,
/// blurred by [blur], and scaled up to fill the window. A soft scene costs
/// far less to draw, and the blur hides its low resolution.
@immutable
class SceneSoftness {
  const SceneSoftness({this.scale = 1, this.blur = 0})
    : assert(scale > 0 && scale <= 1 && blur >= 0);

  /// The sharp scene.
  static const sharp = SceneSoftness();

  /// The scene at its softest, while the visitor reads a section.
  static const soft = SceneSoftness(scale: 0.25, blur: 1.5);

  /// The logical pixels of the drawn scene for each logical pixel of the
  /// window, across and down.
  final double scale;

  /// The standard deviation of the blur, in the drawn scene's logical
  /// pixels.
  final double blur;

  bool get isSharp => scale == 1 && blur == 0;

  /// The drawn scene's border on each side, in its logical pixels, which
  /// is out of the window. The blur reads past the edge of what is drawn,
  /// and the border keeps the edge that this makes out of sight.
  double get border => isSharp ? 0 : (3 * blur).ceilToDouble() + 1;

  @override
  bool operator ==(Object other) =>
      other is SceneSoftness && other.scale == scale && other.blur == blur;

  @override
  int get hashCode => Object.hash(scale, blur);
}

/// The scene's softness, which can change from frame to frame. With
/// `--dart-define=SOFT_SCENE=true`, the scene starts soft.
final sceneSoftnessProvider = Provider<ValueNotifier<SceneSoftness>>((ref) {
  final softness = ValueNotifier(
    const bool.fromEnvironment('SOFT_SCENE')
        ? SceneSoftness.soft
        : SceneSoftness.sharp,
  );
  ref.onDispose(softness.dispose);
  return softness;
});

/// The scene: the hole and the sections' bodies, drawn by the shader from
/// the current [FrameSnapshot]. The page scrolls on top of it.
class SceneView extends ConsumerWidget {
  const SceneView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFrame = ref.watch(frameSnapshotListenableProvider);
    // Browser zoom changes it, so the sky's lattice follows the zoom.
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final softness = ref.watch(sceneSoftnessProvider);
    return switch (ref.watch(sceneShaderProvider)) {
      AsyncData(value: final shader) => RepaintBoundary(
        child: ValueListenableBuilder(
          valueListenable: softness,
          builder: (context, softness, child) => _softLayer(
            softness,
            CustomPaint(
              size: Size.infinite,
              painter: _ScenePainter(
                shader,
                currentFrame,
                pixelRatio,
                softness,
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

  /// [child], which draws the scene at [SceneSoftness.scale] times the
  /// window's size with a [SceneSoftness.border] round it, blurred and
  /// scaled up to the window, with the border out of the window.
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
  _ScenePainter(this.shader, this.currentFrame, this.pixelRatio, this.softness)
    : super(repaint: currentFrame);

  final SceneShader shader;
  final ValueListenable<FrameSnapshot> currentFrame;
  final double pixelRatio;
  final SceneSoftness softness;

  @override
  void paint(Canvas canvas, Size size) {
    final SceneSoftness(:scale, :border) = softness;
    shader.set(
      currentFrame.value,
      Screen(width: size.width, height: size.height),
      pixelRatio: pixelRatio,
      scale: scale,
      border: border,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        0,
        size.width * scale + 2 * border,
        size.height * scale + 2 * border,
      ),
      Paint()..shader = shader.fragmentShader,
    );
  }

  @override
  bool shouldRepaint(_ScenePainter oldDelegate) =>
      oldDelegate.shader != shader ||
      oldDelegate.currentFrame != currentFrame ||
      oldDelegate.pixelRatio != pixelRatio ||
      oldDelegate.softness != softness;
}
