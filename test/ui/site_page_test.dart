import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spacetime_portfolio/scene/opaque_surface.dart';
import 'package:spacetime_portfolio/scene/scene_layout_provider.dart';
import 'package:spacetime_portfolio/scene/scene_view.dart';
import 'package:spacetime_portfolio/scene/visible_rects.dart';
import 'package:spacetime_portfolio/space/system.dart';
import 'package:spacetime_portfolio/ui/reading_screen.dart';
import 'package:spacetime_portfolio/viewport/window_size.dart';

import '../pump_app.dart';
import '../site_fonts.dart';

void main() {
  setUpAll(loadSiteFonts);

  testWidgets('the scene and the Landing keep their sizes while the '
      "window's height changes with the address bar", (tester) async {
    const window = WindowSize(width: 400, smallHeight: 700, largeHeight: 780);
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1;
    await pumpApp(
      tester,
      overrides: [
        windowSizeProvider.overrideWithBuild((ref, notifier) => window),
      ],
    );

    Future<(Rect, double)> sizesAt(double windowHeight) async {
      tester.view.physicalSize = Size(window.width, windowHeight);
      await tester.pump();
      return (
        tester.getRect(find.byType(SceneView)),
        tester.getTopLeft(find.byType(ReadingScreen)).dy,
      );
    }

    expect(
      await sizesAt(window.largeHeight),
      await sizesAt(window.smallHeight),
    );
  });

  testWidgets('on the Landing, every body is whole in the window and above '
      'the intro', (tester) async {
    // The phone held sideways is too short for the intro under the bodies.
    const sideways = Size(844, 390);
    const windows = [
      Size(1600, 1000),
      Size(1280, 720),
      Size(2560, 900),
      Size(600, 800),
      Size(599, 800),
      Size(390, 844),
      sideways,
    ];
    await pumpApp(tester, window: windows.first, fakeBodies: false);

    for (final window in windows) {
      tester.view.physicalSize = window;
      // The floor is set after a frame, so a second frame applies it.
      await tester.pump();
      await tester.pump();
      final reason = '${window.width}x${window.height}';
      final layout = tester.container().read(sceneLayoutProvider);
      final camera = layout.landingCamera;
      final intro = tester.getRect(_intro);

      for (final body in bodies.values) {
        final center = body.positionAt(0);
        final pixel = camera.project(center, layout.screen)!;
        final radius = camera.projectedRadius(center, body.reach);
        expect(pixel.x - radius, greaterThan(0), reason: reason);
        expect(pixel.x + radius, lessThan(window.width), reason: reason);
        expect(pixel.y - radius, greaterThanOrEqualTo(0), reason: reason);
        expect(pixel.y + radius, lessThan(window.height), reason: reason);
        if (window != sideways) {
          expect(pixel.y + radius, lessThan(intro.top), reason: reason);
        }
      }
    }
  });

  group('after a scroll', () {
    const scrollOffset = 300.0;
    // Small, as the test's CPU bakes the sky for the window's size.
    const windows = {'a panel': Size(860, 480), 'cards': Size(390, 600)};

    Future<void> pumpAndScroll(
      WidgetTester tester,
      Size window, {
      required bool isSceneRunning,
    }) async {
      await pumpApp(
        tester,
        window: window,
        loadsScene: true,
        isSceneRunning: isSceneRunning,
      );
      // The scene's assets load outside the test's fake time.
      await tester.runAsync(
        () => tester.container().read(sceneAssetsProvider.future),
      );
      await tester.pump();
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .jumpTo(scrollOffset);
      await tester.pump();
    }

    Finder scenePainting() => find.descendant(
      of: find.byType(SceneView),
      matching: find.byType(CustomPaint),
    );

    for (final MapEntry(key: name, value: window) in windows.entries) {
      testWidgets('with $name, the running scene is drawn only outside the '
          "opaque surfaces' inner rectangles", (tester) async {
        await pumpAndScroll(tester, window, isSceneRunning: true);
        final hiddenRects = [
          for (final surface in tester.widgetList<OpaqueSurface>(
            find.byType(OpaqueSurface),
          ))
            tester
                .getRect(find.byWidget(surface))
                .deflate(surface.borderRadius.topLeft.x),
        ];
        final parts = tester
            .getRect(find.byType(SceneView))
            .visibleRects(hiddenRects);
        expect(parts.length, greaterThan(1));

        final expected = paints;
        for (final part in parts) {
          expected.rect(rect: part);
        }
        expect(scenePainting(), expected);
        expect(
          scenePainting(),
          paintsExactlyCountTimes(#drawRect, parts.length),
        );
      });
    }

    testWidgets('the scene that stands still is drawn in full', (tester) async {
      await pumpAndScroll(tester, windows['cards']!, isSceneRunning: false);
      final scene = tester.getRect(find.byType(SceneView));
      expect(scenePainting(), paints..rect(rect: scene));
      expect(scenePainting(), paintsExactlyCountTimes(#drawRect, 1));
    });
  });

  group('the reading screen below the Landing', () {
    Future<void> pumpPage(WidgetTester tester) async {
      await pumpApp(tester, window: const Size(1280, 800));
      await tester.pump();
    }

    ScrollPosition position(WidgetTester tester) =>
        tester.state<ScrollableState>(find.byType(Scrollable).first).position;

    Future<void> scrollTo(WidgetTester tester, double offset) async {
      position(tester).jumpTo(offset);
      await tester.pump();
    }

    testWidgets('a tap on it scrolls until About is 40 px below the '
        "window's top, while the Landing shows", (tester) async {
      await pumpPage(tester);
      await tester.tapAt(tester.getCenter(find.text('About')));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('About')).dy, moreOrLessEquals(40));
    });

    testWidgets('a tap on the sky beside the panel does nothing', (
      tester,
    ) async {
      await pumpPage(tester);
      final heading = tester.getCenter(find.text('About'));
      await tester.tapAt(Offset(1200, heading.dy));
      await tester.pumpAndSettle();
      expect(position(tester).pixels, 0);
    });

    testWidgets('a tap does nothing once the page has scrolled', (
      tester,
    ) async {
      await pumpPage(tester);
      await scrollTo(tester, 10);
      await tester.tapAt(tester.getCenter(find.text('About')));
      await tester.pumpAndSettle();
      expect(position(tester).pixels, 10);
    });

    testWidgets('a drag selects no text while the Landing shows, and '
        'selects text once the page has scrolled', (tester) async {
      await pumpPage(tester);
      for (final (offset, isSelected) in [(0.0, false), (10.0, true)]) {
        await scrollTo(tester, offset);
        final heading = tester.getRect(find.text('About'));
        final drag = await tester.startGesture(
          heading.centerLeft + const Offset(2, 0),
          kind: PointerDeviceKind.mouse,
        );
        await tester.pump();
        await drag.moveTo(heading.centerRight - const Offset(2, 0));
        await tester.pump();
        await drag.up();
        await tester.pump();
        expect(
          tester.selectedParagraphs,
          isSelected ? isNotEmpty : isEmpty,
          reason: 'at $offset px',
        );
      }
    });
  });
}

final _intro = find
    .ancestor(of: find.text('[Name]'), matching: find.byType(Column))
    .first;

extension on WidgetTester {
  List<RenderParagraph> get selectedParagraphs => [
    for (final paragraph in renderObjectList<RenderParagraph>(
      find.byType(RichText),
    ))
      if (paragraph.selections.isNotEmpty) paragraph,
  ];
}
