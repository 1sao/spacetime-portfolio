import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import '../space/frame.dart';
import '../space/site_space.dart';
import 'scene_shader.dart';

/// Provides a listenable holding the current [FrameSnapshot]. While anything
/// watches this provider, a ticker replaces the snapshot every frame; it
/// stops when nothing does.
///
/// The scene's time stands still while the app isn't resumed: on the web,
/// while the window is unfocused or the tab hidden. It goes on from there,
/// so nothing jumps.
///
/// The provider's own value, the listenable, changes only when the content
/// or the bodies do, so watching the provider doesn't rebuild every frame.
/// Code that needs every frame, such as a painter, should listen to the
/// listenable, rather than copy its snapshots into Riverpod state, which
/// would rebuild every watcher each frame.
final frameSnapshotListenableProvider =
    Provider.autoDispose<ValueListenable<FrameSnapshot>>((ref) {
      final content = ref.watch(contentProvider);
      final bodies = ref.watch(bodiesProvider);
      final inOrder = [
        for (final category in content)
          bodies[category.slug] ??
              (throw StateError(
                'No body for the category "${category.slug}".',
              )),
      ];
      if (inOrder.length > SceneShader.bodySlots) {
        throw StateError(
          'The scene draws ${SceneShader.bodySlots} bodies, not '
          '${inOrder.length}.',
        );
      }

      FrameSnapshot at(double time) =>
          FrameSnapshot.at(time, overviewCamera, inOrder);

      final currentFrame = ValueNotifier(at(0));
      // The scene's time when the ticker last started. A restarted ticker
      // counts from zero.
      var startedAt = 0.0;
      final ticker = Ticker(
        (elapsed) =>
            currentFrame.value = at(startedAt + elapsed.inFractionalSeconds),
      );
      void followLifecycle(AppLifecycleState? state) {
        // Null until the platform first reports a state.
        final isResumed = state == null || state == AppLifecycleState.resumed;
        if (isResumed && !ticker.isActive) {
          ticker.start();
        } else if (!isResumed && ticker.isActive) {
          ticker.stop();
          startedAt = currentFrame.value.time;
        }
      }

      followLifecycle(SchedulerBinding.instance.lifecycleState);
      final lifecycle = AppLifecycleListener(onStateChange: followLifecycle);
      ref.onDispose(() {
        lifecycle.dispose();
        ticker.dispose();
        currentFrame.dispose();
      });
      return currentFrame;
    });

extension _FractionalSeconds on Duration {
  double get inFractionalSeconds =>
      inMicroseconds / Duration.microsecondsPerSecond;
}
