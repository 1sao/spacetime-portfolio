import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:spacetime_portfolio/content/site_content.dart';
import 'package:spacetime_portfolio/scene/scene_layout.dart';
import 'package:spacetime_portfolio/space/camera.dart';
import 'package:spacetime_portfolio/space/system.dart';
import 'package:spacetime_portfolio/ui/reading_screen.dart';
import 'package:spacetime_portfolio/viewport/window_size.dart';
import 'package:vector_math/vector_math_64.dart';

import '../matchers.dart';

void main() {
  /// Desktop, short, wide, both sides of the column's breakpoint, and a
  /// phone upright and on its side.
  const screens = [
    Screen(width: 1600, height: 1000),
    Screen(width: 1280, height: 720),
    Screen(width: 2560, height: 900),
    Screen(width: 600, height: 800),
    Screen(width: 599, height: 800),
    Screen(width: 390, height: 844),
    Screen(width: 844, height: 390),
  ];

  final pageOrder = [for (final section in sections) ?bodies[section.id]];

  final disks = [
    (Vector3.zero(), holeShadowRadius),
    for (final body in pageOrder) (body.positionAt(0), body.reach),
  ];

  ({double top, double bottom}) extentOf(SceneLayout layout) {
    final camera = layout.landingCamera;
    var (top, bottom) = (double.infinity, double.negativeInfinity);
    for (final (center, reach) in disks) {
      final y = camera.project(center, layout.screen)!.y;
      final radius = camera.projectedRadius(center, reach);
      top = math.min(top, y - radius);
      bottom = math.max(bottom, y + radius);
    }
    return (top: top, bottom: bottom);
  }

  test('on the Landing, the bodies lie on one line through the hole, in '
      'page order: left to right, or top to bottom on the column', () {
    for (final screen in screens) {
      final layout = SceneLayout(screen);
      final camera = layout.landingCamera;
      final hole = camera.targetPixel(screen);
      final along = layout.isLandingColumn ? Vector2(0, 1) : Vector2(1, 0);
      final places = <double>[];
      for (final body in pageOrder) {
        final offset = camera.project(body.positionAt(0), screen)! - hole;
        expect(offset.cross(along), nearlyEquals(0), reason: screen.name);
        places.add(offset.dot(along));
      }
      expect(places, orderedEquals([...places]..sort()), reason: screen.name);
    }
  });

  test("on the Landing, the hole's shadow and every body are whole on the "
      'screen and above the top of the reading screen', () {
    for (final screen in screens) {
      final camera = SceneLayout(screen).landingCamera;
      for (final (center, reach) in disks) {
        final pixel = camera.project(center, screen)!;
        final radius = camera.projectedRadius(center, reach);
        final reason = screen.name;
        expect(pixel.x - radius, greaterThan(0), reason: reason);
        expect(pixel.x + radius, lessThan(screen.width), reason: reason);
        expect(pixel.y - radius, greaterThan(0), reason: reason);
        expect(
          pixel.y + radius,
          lessThan(
            screen.height -
                ReadingScreen.landingPeekHeight(WidthClass.expanded),
          ),
          reason: reason,
        );
      }
    }
  });

  test('a floor below the lowest body leaves the line where it is', () {
    for (final screen in screens) {
      final free = SceneLayout(screen, bodies: pageOrder);
      final floored = SceneLayout(
        screen,
        bodies: pageOrder,
        landingFloor: extentOf(free).bottom + 1,
      );
      expect(
        floored.landingScreenPoint,
        free.landingScreenPoint,
        reason: screen.name,
      );
    }
  });

  test('a floor above the lowest body lifts the line until the lowest '
      'body touches the floor', () {
    for (final screen in screens) {
      final free = extentOf(SceneLayout(screen, bodies: pageOrder));
      final floor = free.bottom - free.top / 2;
      final floored = extentOf(
        SceneLayout(screen, bodies: pageOrder, landingFloor: floor),
      );
      expect(floored.bottom, nearlyEquals(floor), reason: screen.name);
    }
  });

  test('a floor lifts the line no farther than until the highest body '
      'touches the top of the screen', () {
    for (final screen in screens) {
      final floored = extentOf(
        SceneLayout(screen, bodies: pageOrder, landingFloor: 0),
      );
      expect(floored.top, nearlyEquals(0), reason: screen.name);
    }
  });
}

extension on Screen {
  String get name => '${width}x$height';
}
