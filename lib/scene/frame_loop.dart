import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../navigation/navigation.dart';
import '../providers.dart';
import '../space/body.dart';
import '../space/frame.dart';
import 'scene_shader.dart';

/// Provides a listenable holding the current [FrameSnapshot]. While anything
/// watches this provider, a ticker replaces the snapshot every frame; it
/// stops when nothing does.
///
/// The ticker moves the scene's clock, and each snapshot has the camera of
/// the navigation state at the clock's time.
///
/// The scene's time stands still while the app isn't resumed: on the web,
/// while the window is unfocused or the tab hidden. It also stands still
/// while nothing watches this provider. It goes on from there, so nothing
/// jumps.
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
      // The order of the content gives each body its slot in the shader.
      final bodiesInContentOrder = [
        for (final category in content) bodies.of(category.slug),
      ];
      if (bodiesInContentOrder.length > SceneShader.bodySlots) {
        throw StateError(
          'The scene draws ${SceneShader.bodySlots} bodies, not '
          '${bodiesInContentOrder.length}.',
        );
      }

      final clock = ref.watch(sceneClockProvider);
      final navigationNotifier = ref.read(navigationProvider.notifier);
      var navigation = ref.read(navigationProvider);
      FrameSnapshot frameAtClockTime() => FrameSnapshot.at(
        clock.now,
        navigation.rigAt(clock.now).camera,
        bodiesInContentOrder,
      );

      final currentFrame = ValueNotifier(frameAtClockTime());
      // The snapshot also changes here, so a change shows while the ticker
      // is stopped.
      ref.listen(navigationProvider, (_, next) {
        navigation = next;
        currentFrame.value = frameAtClockTime();
      });
      // The clock's time when the ticker last started. A started ticker
      // counts from zero.
      var startedAt = clock.now;
      final ticker = Ticker((elapsed) {
        clock.advanceTo(startedAt + elapsed.inFractionalSeconds);
        navigationNotifier.endFinishedFlight();
        currentFrame.value = frameAtClockTime();
      });
      void followLifecycle(AppLifecycleState? state) {
        // Null until the platform first reports a state.
        final isResumed = state == null || state == AppLifecycleState.resumed;
        if (isResumed && !ticker.isActive) {
          startedAt = clock.now;
          ticker.start();
        } else if (!isResumed && ticker.isActive) {
          ticker.stop();
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
