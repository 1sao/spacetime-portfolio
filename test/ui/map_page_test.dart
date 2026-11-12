import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homepage_v2/navigation/map_navigation_state.dart';
import 'package:homepage_v2/navigation/navigation.dart';
import 'package:homepage_v2/router.dart';
import 'package:homepage_v2/space/framing.dart';
import 'package:homepage_v2/ui/camera_controls.dart';

import '../pump_app.dart';

void main() {
  /// The framing of the camera at rest.
  Framing framingOf(WidgetTester tester) =>
      (tester.container().read(navigationProvider) as AtRest).framing;

  String currentPath(WidgetTester tester) => tester
      .container()
      .read(routerProvider)
      .routerDelegate
      .currentConfiguration
      .uri
      .path;

  /// The cursor of the mouse. A test gesture's mouse is device 1.
  MouseCursor? cursor() =>
      RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1);

  testWidgets('Esc goes one level up, and stops at the overview', (
    tester,
  ) async {
    await pumpApp(tester, firstPath: '/projects/one');
    await tester.pump();

    for (final expected in ['/projects', '/', '/']) {
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(currentPath(tester), expected);
    }
  });

  testWidgets('a drag turns the camera, and the cursor shows it', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.pump();
    final center = tester.getCenter(find.byType(CameraControls));
    final before = framingOf(tester);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: center);
    await tester.pump();
    expect(cursor(), SystemMouseCursors.grab, reason: 'hover');

    await mouse.down(center);
    await tester.pump();
    expect(cursor(), SystemMouseCursors.grabbing, reason: 'press');

    await mouse.moveBy(const Offset(100, 50));
    await mouse.moveBy(const Offset(100, 50));
    await mouse.up();
    await tester.pump();
    expect(cursor(), SystemMouseCursors.grab, reason: 'release');

    final after = framingOf(tester);
    // A drag to the right turns the camera to the left, and a drag down
    // turns it up, as if the visitor pulls the scene.
    expect(after.yaw, lessThan(before.yaw));
    expect(after.pitch, greaterThan(before.pitch));

    tester.container().read(routerProvider).go('/projects');
    await tester.pump();
    expect(cursor(), SystemMouseCursors.basic, reason: 'flight');
  });

  testWidgets('a right-button drag does not turn the camera', (tester) async {
    await pumpApp(tester);
    await tester.pump();
    final center = tester.getCenter(find.byType(CameraControls));
    final before = framingOf(tester);

    final mouse = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryButton,
    );
    await mouse.addPointer(location: center);
    await mouse.down(center);
    await tester.pump();
    expect(cursor(), SystemMouseCursors.grab);

    await mouse.moveBy(const Offset(100, 50));
    await mouse.moveBy(const Offset(100, 50));
    await mouse.up();
    await tester.pump();
    expect(framingOf(tester).yaw, before.yaw);
    expect(framingOf(tester).pitch, before.pitch);
  });

  testWidgets('the wheel and a trackpad pinch zoom the camera', (tester) async {
    await pumpApp(tester);
    await tester.pump();
    final center = tester.getCenter(find.byType(CameraControls));
    final start = framingOf(tester).distance;

    await tester.sendEventToBinding(
      PointerScrollEvent(position: center, scrollDelta: const Offset(0, 100)),
    );
    expect(framingOf(tester).distance, closeTo(start * math.exp(0.1), 1e-9));

    await tester.sendEventToBinding(
      PointerScaleEvent(position: center, scale: 1.1),
    );
    expect(
      framingOf(tester).distance,
      closeTo(start * math.exp(0.1) / 1.1, 1e-9),
    );
  });

  testWidgets('the wheel and a trackpad pinch do nothing while the scene '
      'stands still', (tester) async {
    await pumpApp(tester);
    await tester.pump();
    final center = tester.getCenter(find.byType(CameraControls));
    final start = framingOf(tester).distance;

    // The window loses the focus, but the browser still sends the wheel.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.sendEventToBinding(
      PointerScrollEvent(position: center, scrollDelta: const Offset(0, 100)),
    );
    await tester.sendEventToBinding(
      PointerScaleEvent(position: center, scale: 1.1),
    );
    expect(framingOf(tester).distance, start);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  testWidgets('a wheel event over the map stops the browser default', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.pump();
    final scene = tester.getCenter(find.byType(CameraControls));
    final button = tester.getCenter(find.text('List'));

    // A sideways scroll does not zoom, but the browser must not use it
    // either: on a Mac it goes back in history.
    for (final (position, delta) in [
      (scene, const Offset(0, 100)),
      (scene, const Offset(100, 0)),
      (button, const Offset(100, 0)),
    ]) {
      bool? isDefaultAllowed;
      await tester.sendEventToBinding(
        PointerScrollEvent(
          position: position,
          scrollDelta: delta,
          onRespond: ({required allowPlatformDefault}) =>
              isDefaultAllowed = allowPlatformDefault,
        ),
      );
      // The web engine stops the default action unless the app allows it.
      expect(isDefaultAllowed, isNot(isTrue), reason: '$position, $delta');
    }
  });
}
