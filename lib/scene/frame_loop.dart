import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import '../space/clocks.dart';
import '../space/frame_snapshot.dart';
import 'framing/scene_screen.dart';
import 'framing/scroll_script_provider.dart';
import 'page_scroll.dart';
import 'scene_clock.dart';

/// The provider changes only with the layout, so a painter listens to the
/// listenable, which the clock and the scroll set.
final frameSnapshotListenableProvider =
    Provider.autoDispose<ValueListenable<FrameSnapshot>>((ref) {
      final clock = ref.watch(sceneClockProvider);
      final scroll = ref.watch(pageScrollControllerProvider);
      final script = ref.watch(scrollScriptProvider);
      final screen = ref.watch(sceneScreenProvider);
      final bodiesInPageOrder = ref.watch(bodiesInPageOrderProvider);

      FrameSnapshot currentSnapshot() {
        final SceneTime(:actualTime, :spinDrift) = clock.value;
        // Before the page lays out, the script holds at the Landing.
        final scrollOffset = scroll.hasClients ? scroll.offset : 0.0;
        final clocks = Clocks(
          scrollTime: script.scrollTimeAt(scrollOffset),
          spinDrift: spinDrift,
        );
        return FrameSnapshot.of(
          bodiesInPageOrder,
          actualTime: actualTime,
          orbitTime: clocks.orbitTime,
          spinTime: clocks.spinTime,
          screen: screen,
          camera: script.cameraAt(scrollOffset, clocks.orbitTime),
        );
      }

      final currentFrame = ValueNotifier(currentSnapshot());
      void showNewFrame() => currentFrame.value = currentSnapshot();

      final changes = Listenable.merge([clock, scroll]);
      changes.addListener(showNewFrame);
      ref.onDispose(() {
        changes.removeListener(showNewFrame);
        currentFrame.dispose();
      });
      return currentFrame;
    });
