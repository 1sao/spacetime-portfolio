import 'package:flutter_test/flutter_test.dart';
import 'package:spacetime_portfolio/space/camera/camera.dart';
import 'package:spacetime_portfolio/space/system/system.dart';
import 'package:vector_math/vector_math_64.dart';

import '../../matchers.dart';
import 'stations.dart';

void main() {
  const screen = Screen(width: 1600, height: 1000);
  const orbitTimes = [0.0, 1.3, 7.9, -4.2, 23.6];

  test("a body's station puts its body on the framing's screen point, at any "
      'orbit time', () {
    for (final body in bodies.values) {
      final station = wideWindowBodyStation(body);
      final expected = station.cameraAt(0).targetPixel(screen);
      for (final orbitTime in orbitTimes) {
        final pixel = station
            .cameraAt(orbitTime)
            .project(body.positionAt(orbitTime), screen)!;
        expect(
          pixel.distanceTo(expected),
          nearlyEquals(0),
          reason: 'at $orbitTime',
        );
      }
    }
  });

  test("a body's station shows its backdrop at its offset from the body, at "
      'any orbit time', () {
    for (final body in bodies.values) {
      final station = wideWindowBodyStation(body);
      for (final orbitTime in orbitTimes) {
        final view = station.cameraAt(orbitTime);
        final offset = wideWindowBackdrop.offsetFromBody * view.focalLength;
        final expected =
            view.targetPixel(screen) + Vector2(offset.x, -offset.y);
        final pixel = view.project(
          wideWindowBackdrop.positionAt(orbitTime),
          screen,
        )!;
        expect(
          pixel.distanceTo(expected),
          nearlyEquals(0),
          reason: 'at $orbitTime',
        );
      }
    }
  });
}
