import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spacetime_portfolio/providers.dart';
import 'package:spacetime_portfolio/scene/frame_loop.dart';
import 'package:spacetime_portfolio/scene/framing/reading_screen_geometry.dart';
import 'package:spacetime_portfolio/scene/framing/scroll_script_provider.dart';
import 'package:spacetime_portfolio/scene/page_scroll.dart';
import 'package:spacetime_portfolio/space/frame_snapshot.dart';
import 'package:spacetime_portfolio/space/scroll/scroll_script.dart';
import 'package:spacetime_portfolio/space/system/system.dart';
import 'package:spacetime_portfolio/ui/sections/about_section.dart';
import 'package:spacetime_portfolio/ui/sections/contact_section.dart';
import 'package:spacetime_portfolio/ui/sections/credits_section.dart';
import 'package:spacetime_portfolio/ui/sections/personal_section.dart';
import 'package:spacetime_portfolio/ui/sections/work_section.dart';

import '../fake_bodies.dart';
import '../matchers.dart';
import '../pump_app.dart';

void main() {
  testWidgets('the scene stands still while the app is not resumed', (
    tester,
  ) async {
    final container = ProviderContainer.test(overrides: fakeOverrides);
    // Disposed here, not in the container's own teardown, which runs after
    // Flutter fails a test that ends with a ticker running.
    try {
      final currentFrame = container.startFrameLoop();
      final binding = tester.binding;

      await tester.runSceneFor(seconds: 1);
      expect(currentFrame.value.actualTime, 1);

      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump(const Duration(seconds: 5));
      expect(currentFrame.value.actualTime, 1, reason: 'paused');

      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.runSceneFor(seconds: 1);
      expect(
        currentFrame.value.actualTime,
        2,
        reason: 'resumed where it stopped',
      );
    } finally {
      container.dispose();
    }
  });

  testWidgets('while the scene stands still, a resize to a phone frames '
      'the Landing as a column', (tester) async {
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 800);
    await pumpApp(tester);
    FrameSnapshot currentFrame() =>
        tester.container().read(frameSnapshotListenableProvider).value;
    expect(currentFrame().camera.roll, 0);

    tester.view.physicalSize = const Size(390, 844);
    await tester.pump();
    expect(currentFrame().camera.roll, math.pi / 2);
  });

  for (final window in [const Size(1280, 800), const Size(390, 844)]) {
    final width = '${window.width.toInt()} px wide';

    testWidgets('with the scene standing still, each section\'s station '
        'frames its body, or the hole, $width', (tester) async {
      await pumpApp(tester, window: window);
      await tester.pump();
      final container = tester.container();
      final scroll = container.read(pageScrollControllerProvider);
      final holds = container
          .read(scrollScriptProvider)
          .cues
          .whereType<Hold>()
          .toList();
      final sections = container.read(sectionsProvider);
      for (final (index, section) in sections.indexed) {
        scroll.jumpTo(holds[index + 1].scrollOffsets.at(0.5));
        await tester.pump();
        final frame = container.read(frameSnapshotListenableProvider).value;
        final reason = section.id.name;
        switch (fakeBodies[section.id]) {
          case final body?:
            expect(
              frame.camera.target.distanceTo(body.positionAt(frame.orbitTime)),
              nearlyEquals(0),
              reason: reason,
            );
          case null:
            expect(frame.camera.target.length, nearlyEquals(0), reason: reason);
            expect(
              frame.camera.position.length,
              nearlyEquals(holeViewpoint.distance),
              reason: reason,
            );
        }
      }
    });

    testWidgets('the page reports where its sections start and end, also '
        'after the text grows, $width', (tester) async {
      await pumpApp(tester, window: window);
      await tester.pump();
      final container = tester.container();

      List<SectionSpan> sectionsOnScreen() => [
        for (final type in [
          AboutSection,
          WorkSection,
          PersonalSection,
          ContactSection,
          CreditsSection,
        ])
          (
            top: tester.getRect(find.byType(type)).top,
            bottom: tester.getRect(find.byType(type)).bottom,
          ),
      ];

      final sectionsBefore = sectionsOnScreen();
      expect(
        container.read(measuredReadingScreenGeometryProvider)!.sections,
        sectionsBefore,
      );

      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pump();
      await tester.pump();
      expect(sectionsOnScreen(), isNot(sectionsBefore));
      expect(
        container.read(measuredReadingScreenGeometryProvider)!.sections,
        sectionsOnScreen(),
      );
    });
  }
}

extension on ProviderContainer {
  /// Starts the frame loop, and gives its current frame.
  ValueListenable<FrameSnapshot> startFrameLoop() =>
      listen(frameSnapshotListenableProvider, (_, _) {}).read();
}

extension on WidgetTester {
  /// Pumps a first frame, which starts the ticker, then a frame [seconds]
  /// later.
  Future<void> runSceneFor({required double seconds}) async {
    await pump();
    await pump(Duration(microseconds: (seconds * 1e6).round()));
  }
}
