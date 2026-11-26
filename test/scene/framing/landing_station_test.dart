import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:spacetime_portfolio/content/site_content.dart';
import 'package:spacetime_portfolio/scene/framing/focal_lengths.dart';
import 'package:spacetime_portfolio/scene/framing/landing_station.dart';
import 'package:spacetime_portfolio/space/camera/camera.dart';
import 'package:spacetime_portfolio/space/station/framing.dart';
import 'package:spacetime_portfolio/space/station/station.dart';
import 'package:spacetime_portfolio/space/system/body.dart';
import 'package:spacetime_portfolio/space/system/system.dart';
import 'package:spacetime_portfolio/ui/reading_screen.dart';
import 'package:spacetime_portfolio/viewport/window_size.dart';
import 'package:vector_math/vector_math_64.dart';

import '../../matchers.dart';
import 'screens.dart';

void main() {
  final pageOrder = [for (final section in sections) ?bodies[section.id]];

  final disks = [
    (Vector3.zero(), holeShadowRadius),
    for (final body in pageOrder) (body.positionAt(0), body.reach),
  ];

  Framing framingOf(
    Screen screen, {
    List<Body> bodies = const [],
    double floor = double.infinity,
  }) => landingFraming(
    screen,
    focalLength: FocalLengths.of(screen).landing,
    bodies: bodies,
    floor: floor,
  );

  Camera landingCamera(
    Screen screen, {
    List<Body> bodies = const [],
    double floor = double.infinity,
  }) =>
      Station.landing(framingOf(screen, bodies: bodies, floor: floor))
          .cameraAt(0);

  ({double top, double bottom}) extentOf(Screen screen, {double? floor}) {
    final camera = landingCamera(
      screen,
      bodies: pageOrder,
      floor: floor ?? double.infinity,
    );
    var (top, bottom) = (double.infinity, double.negativeInfinity);
    for (final (center, reach) in disks) {
      final y = camera.project(center, screen)!.y;
      final radius = camera.projectedRadius(center, reach);
      top = math.min(top, y - radius);
      bottom = math.max(bottom, y + radius);
    }
    return (top: top, bottom: bottom);
  }

  test('on the Landing, the bodies lie on one line through the hole, in '
      'page order: left to right, or top to bottom on the column', () {
    for (final screen in screens) {
      final camera = landingCamera(screen);
      final hole = camera.targetPixel(screen);
      final along = switch (WidthClass.of(screen.width)
          .landingNavigationOrientation) {
        LandingNavigationOrientation.horizontal => Vector2(1, 0),
        LandingNavigationOrientation.vertical => Vector2(0, 1),
      };
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
      final camera = landingCamera(screen);
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
                ReadingScreen.landingPeekHeight(SectionLayout.panel),
          ),
          reason: reason,
        );
      }
    }
  });

  test('a floor below the lowest body leaves the line where it is', () {
    for (final screen in screens) {
      final free = framingOf(screen, bodies: pageOrder);
      final floored = framingOf(
        screen,
        bodies: pageOrder,
        floor: extentOf(screen).bottom + 1,
      );
      expect(
        floored.screenPoint.at(0),
        free.screenPoint.at(0),
        reason: screen.name,
      );
    }
  });

  test('a floor above the lowest body lifts the line until the lowest '
      'body touches the floor', () {
    for (final screen in screens) {
      final free = extentOf(screen);
      final floor = free.bottom - free.top / 2;
      final floored = extentOf(screen, floor: floor);
      expect(floored.bottom, nearlyEquals(floor), reason: screen.name);
    }
  });

  test('a floor lifts the line no farther than until the highest body '
      'touches the top of the screen', () {
    for (final screen in screens) {
      final floored = extentOf(screen, floor: 0);
      expect(floored.top, nearlyEquals(0), reason: screen.name);
    }
  });
}
