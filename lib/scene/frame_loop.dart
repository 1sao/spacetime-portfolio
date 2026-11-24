import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import '../space/frame_snapshot.dart';
import 'scene_layout_provider.dart';
import 'scene_running.dart';

/// The current [FrameSnapshot], as a listenable. While something watches
/// this provider and the scene runs, a ticker replaces the snapshot each
/// frame. The provider's own value changes only with the content or the
/// bodies, so a painter should listen to the listenable.
final frameSnapshotListenableProvider =
    Provider.autoDispose<ValueListenable<FrameSnapshot>>((ref) {
      final bodiesInPageOrder = ref.watch(bodiesInPageOrderProvider);
      var layout = ref.read(sceneLayoutProvider);

      FrameSnapshot frameAt(double actualTime) => FrameSnapshot.of(
        bodiesInPageOrder,
        actualTime: actualTime,
        orbitTime: 0,
        spinTime: 0,
        screen: layout.screen,
        camera: layout.landingCamera,
      );

      final currentFrame = ValueNotifier(frameAt(0));
      // Listened to, not watched: a rebuild of this provider would start
      // the actual time again from zero.
      ref.listen(sceneLayoutProvider, (_, newLayout) {
        layout = newLayout;
        currentFrame.value = frameAt(currentFrame.value.actualTime);
      });
      // The actual time when the ticker last started. A started ticker
      // counts from zero.
      var startedAt = 0.0;
      final ticker = Ticker((sinceStart) {
        currentFrame.value = frameAt(
          startedAt + sinceStart.inFractionalSeconds,
        );
      });
      ref.listen(isSceneRunningProvider, fireImmediately: true, (_, isRunning) {
        if (isRunning && !ticker.isActive) {
          startedAt = currentFrame.value.actualTime;
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
