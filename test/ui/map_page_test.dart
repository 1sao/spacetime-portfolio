import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_test/flutter_test.dart';
import 'package:homepage_v2/navigation/map_navigation_state.dart';
import 'package:homepage_v2/space/framing.dart';
import 'package:homepage_v2/ui/camera_controls.dart';

import '../pump_app.dart';

void main() {
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
      expect(tester.currentPath, expected);
    }
  });

  testWidgets('a drag turns the camera, and the cursor shows it', (
    tester,
  ) async {
    final center = await tester.pumpMap();
    final before = tester.framing;

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

    final after = tester.framing;
    // A drag to the right turns the camera to the left, and a drag down
    // turns it up, as if the visitor pulls the scene.
    expect(after.yaw, lessThan(before.yaw));
    expect(after.pitch, greaterThan(before.pitch));

    await tester.goTo('/projects');
    expect(cursor(), SystemMouseCursors.basic, reason: 'flight');
  });

  testWidgets('a right-button drag does not turn the camera', (tester) async {
    final center = await tester.pumpMap();
    final before = tester.framing;

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
    expect(tester.framing.yaw, before.yaw);
    expect(tester.framing.pitch, before.pitch);
  });

  testWidgets('the wheel and a trackpad pinch zoom the camera', (tester) async {
    final center = await tester.pumpMap();
    final start = tester.framing.distance;

    await tester.scroll(at: center, by: const Offset(0, 100));
    expect(tester.framing.distance, closeTo(start * math.exp(0.1), 1e-9));

    await tester.pinch(at: center, scale: 1.1);
    expect(tester.framing.distance, closeTo(start * math.exp(0.1) / 1.1, 1e-9));
  });

  testWidgets('the wheel and a trackpad pinch do nothing while the scene '
      'stands still', (tester) async {
    final center = await tester.pumpMap();
    final start = tester.framing.distance;

    // The window loses the focus, but the browser still sends the wheel.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.scroll(at: center, by: const Offset(0, 100));
    await tester.pinch(at: center, scale: 1.1);
    expect(tester.framing.distance, start);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  testWidgets('a wheel event over the map stops the browser default', (
    tester,
  ) async {
    final scene = await tester.pumpMap();
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

extension on WidgetTester {
  /// Starts the app at the overview, and gives the centre of the scene.
  Future<Offset> pumpMap() async {
    await pumpApp(this);
    await pump();
    return getCenter(find.byType(CameraControls));
  }

  /// The framing of the camera at rest.
  Framing get framing => (navigationState as AtRest).framing;

  /// Sends a wheel event at [at] that scrolls [by] logical pixels.
  Future<void> scroll({required Offset at, required Offset by}) =>
      sendEventToBinding(PointerScrollEvent(position: at, scrollDelta: by));

  /// Sends a trackpad pinch at [at], as a browser does.
  Future<void> pinch({required Offset at, required double scale}) =>
      sendEventToBinding(PointerScaleEvent(position: at, scale: scale));
}
