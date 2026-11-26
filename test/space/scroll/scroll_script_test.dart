import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:spacetime_portfolio/space/camera/camera.dart';
import 'package:spacetime_portfolio/space/scroll/camera_route.dart';
import 'package:spacetime_portfolio/space/scroll/hold_lines.dart';
import 'package:spacetime_portfolio/space/scroll/hold_offsets.dart';
import 'package:spacetime_portfolio/space/scroll/scroll_script.dart';
import 'package:spacetime_portfolio/space/station/station.dart';
import 'package:vector_math/vector_math_64.dart';

import '../../matchers.dart';
import '../station/stations.dart';

void main() {
  const route = CameraRoute.aroundTheHole();
  const sectionTops = [700.0, 2600.0, 3800.0, 6000.0, 7400.0];
  const maxScroll = 8600.0;
  const wideScreen = Screen(width: 1600, height: 1000);
  const phoneScreen = Screen(width: 390, height: 844);
  final stations = wideWindowStations();

  const viewHeight = 800.0;
  ScrollScript scriptOf(List<Station> stations, HoldLines lines) =>
      ScrollScript(
        stations: stations,
        holdOffsets: holdOffsetsFor(
          sectionTops: sectionTops,
          viewHeight: viewHeight,
          maxScroll: maxScroll,
          lines: lines,
        ),
        route: route,
        viewHeight: viewHeight,
      );

  final layouts = [
    (
      name: 'beside the panel',
      screen: wideScreen,
      script: scriptOf(stations, HoldLines.besidePanel),
    ),
    (
      name: 'between the cards',
      screen: phoneScreen,
      script: scriptOf(
        phoneStations(sectionTops, screenHeight: phoneScreen.height),
        HoldLines.betweenCards,
      ),
    ),
  ];

  // A fixed point in front of the cameras, whose pixel moves with every
  // part of the camera: position, direction, screen point, roll and focal
  // length.
  Vector2 pixelOfAheadPoint(Camera camera, Screen screen) =>
      camera.project(camera.position + camera.forward * 10, screen)! +
      camera.project(camera.target, screen)!;

  double angleBetween(Vector3 a, Vector3 b) =>
      math.acos(a.normalized().dot(b.normalized()).clamp(-1.0, 1.0));

  // A step small enough that the fastest move stays far below the limits,
  // so only a jump fails.
  Iterable<({String reason, double time, Camera camera})> pageScrolledDown(
    ScrollScript script,
  ) sync* {
    const step = 0.25;
    for (var offset = 0.0; offset <= maxScroll; offset += step) {
      final time = script.scrollTimeAt(offset);
      yield (
        reason: 'at $offset',
        time: time,
        camera: script.cameraAt(offset, time),
      );
    }
  }

  /// Each camera of each move, with the one a step before it.
  Iterable<
    ({String reason, Camera camera, Camera previous, Camera from, Camera to})
  >
  movesAtEveryOrbitPhase() sync* {
    for (var orbitTime = 0.0; orbitTime < 40; orbitTime += 0.5) {
      for (var station = 0; station + 1 < stations.length; station++) {
        final from = stations[station].cameraAt(orbitTime);
        final to = stations[station + 1].cameraAt(orbitTime);
        var previous = from;
        for (var fraction = 0.0; fraction <= 1; fraction += 0.005) {
          final camera = mixCameras(
            from,
            to,
            fraction,
            route,
            fromAtDeparture: from,
            toAtDeparture: to,
          );
          yield (
            reason: 'station $station at $orbitTime, $fraction',
            camera: camera,
            previous: previous,
            from: from,
            to: to,
          );
          previous = camera;
        }
      }
    }
  }

  for (final (:name, :screen, :script) in layouts) {
    test('$name: as the page scrolls down, the time runs on without a '
        'jump', () {
      double? last;
      for (final (:reason, :time, camera: _) in pageScrolledDown(script)) {
        if (last != null) {
          expect(time - last, inInclusiveRange(0, 0.05), reason: reason);
        }
        last = time;
      }
    });

    test('$name: as the page scrolls down, the camera does not jump', () {
      Camera? last;
      for (final (:reason, time: _, :camera) in pageScrolledDown(script)) {
        if (last != null) {
          expect(
            camera.position.distanceTo(last.position),
            lessThan(0.25),
            reason: reason,
          );
          expect(
            angleBetween(camera.forward, last.forward),
            lessThan(0.02),
            reason: reason,
          );
          expect(
            camera.targetPixel(screen).distanceTo(last.targetPixel(screen)),
            lessThan(1),
            reason: reason,
          );
        }
        last = camera;
      }
    });

    test('$name: a move starts and ends with the same camera as its '
        'stations', () {
      const orbitTime = 5.0;
      for (final move in script.cues.whereType<Move>()) {
        for (final (offset, station) in [
          (move.scrollOffsets.start, move.from),
          (move.scrollOffsets.end, move.to),
        ]) {
          final expected = station.cameraAt(orbitTime, scrollOffset: offset);
          final moving = move.cameraAt(offset, orbitTime);
          final reason = 'at $offset';
          expect(
            pixelOfAheadPoint(
              moving,
              screen,
            ).distanceTo(pixelOfAheadPoint(expected, screen)),
            nearlyEquals(0),
            reason: reason,
          );
          expect(moving.roll, nearlyEquals(expected.roll), reason: reason);
        }
      }
    });

    test('$name: a scroll past either end of the page holds the end '
        'stations, as a bounce does', () {
      final end = script.cues.last.scrollOffsets.end;
      expect(script.cueAt(-200), same(script.cues.first));
      expect(script.cueAt(end + 300), same(script.cues.last));
      expect(script.scrollTimeAt(-200), script.scrollTimeAt(0));
      expect(script.scrollTimeAt(end + 300), script.scrollTimeAt(end));
    });
  }

  test('a move keeps the hole no farther from the look than at its ends, '
      'at every orbit phase', () {
    double holeAngleOf(Camera camera) =>
        angleBetween(camera.forward, -camera.position);
    for (final (:reason, :camera, previous: _, :from, :to)
        in movesAtEveryOrbitPhase()) {
      expect(
        holeAngleOf(camera),
        atMostNearly(math.max(holeAngleOf(from), holeAngleOf(to))),
        reason: reason,
      );
    }
  });

  test('a move turns the camera without a jump, at every orbit phase', () {
    for (final (:reason, :camera, :previous, from: _, to: _)
        in movesAtEveryOrbitPhase()) {
      expect(
        angleBetween(camera.forward, previous.forward),
        lessThan(0.05),
        reason: reason,
      );
    }
  });

  test('a move keeps the camera clear of the elevation clamp, at every '
      'orbit phase', () {
    for (final (:reason, :camera, previous: _, from: _, to: _)
        in movesAtEveryOrbitPhase()) {
      expect(
        camera.fromTarget.elevation.abs(),
        lessThan(maxElevation),
        reason: reason,
      );
    }
  });
}
