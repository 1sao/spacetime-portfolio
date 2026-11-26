import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
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
