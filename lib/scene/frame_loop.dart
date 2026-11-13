import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../navigation/navigation.dart';
import '../providers.dart';
import '../space/body.dart';
import '../space/frame_snapshot.dart';
import 'scene_running.dart';
import 'scene_shader.dart';

/// The current [FrameSnapshot], as a listenable. While something watches
/// this provider and the scene runs, a ticker moves the scene's clock and
/// replaces the snapshot each frame. The provider's own value changes only
/// with the content or the bodies, so a painter should listen to the
/// listenable.
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
      final navigation = ref.read(navigationProvider.notifier);
      FrameSnapshot frameAtClockTime() => FrameSnapshot.at(
        clock.now,
        ref.read(navigationProvider).cameraAt(clock.now),
        bodiesInContentOrder,
      );

      final currentFrame = ValueNotifier(frameAtClockTime());
      // The snapshot also changes here, so a transition shows while the
      // ticker is stopped.
      ref.listen(
        navigationProvider,
        (_, _) => currentFrame.value = frameAtClockTime(),
      );
      // The clock's time when the ticker last started. A started ticker
      // counts from zero.
      var startedAt = clock.now;
      final ticker = Ticker((elapsed) {
        clock.advanceTo(startedAt + elapsed.inFractionalSeconds);
        navigation.endFinishedFlight();
        currentFrame.value = frameAtClockTime();
      });
      ref.listen(isSceneRunningProvider, fireImmediately: true, (_, isRunning) {
        if (isRunning && !ticker.isActive) {
          startedAt = clock.now;
          ticker.start();
        } else if (!isRunning && ticker.isActive) {
          ticker.stop();
        }
      });
      ref.onDispose(() {
        ticker.dispose();
        currentFrame.dispose();
      });
      return currentFrame;
    });

extension _FractionalSeconds on Duration {
  double get inFractionalSeconds =>
      inMicroseconds / Duration.microsecondsPerSecond;
}
