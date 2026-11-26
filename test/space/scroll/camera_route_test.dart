import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:spacetime_portfolio/space/camera/direction_and_distance.dart';
import 'package:spacetime_portfolio/space/scroll/camera_route.dart';
import 'package:vector_math/vector_math_64.dart';

import '../../matchers.dart';

void main() {
  final random = math.Random(7);
  Vector3 randomPointBetween(double near, double far) {
    final direction = Vector3(
      random.nextDouble() * 2 - 1,
      random.nextDouble() * 2 - 1,
      random.nextDouble() * 2 - 1,
    ).normalized();
    return direction * (near + random.nextDouble() * (far - near));
  }

  final fractions = [for (var i = 0; i <= 200; i++) i / 200];

  test("a route around the hole stays between its ends' distances from the "
      'hole, and starts and ends at its ends', () {
    const route = CameraRoute.aroundTheHole();
    for (var i = 0; i < 300; i++) {
      final from = randomPointBetween(3, 40);
      final to = randomPointBetween(3, 40);
      final nearer = math.min(from.length, to.length);
      final farther = math.max(from.length, to.length);
      for (final fraction in fractions) {
        final distance = route.positionAt(from, to, fraction).length;
        expect(distance, atLeastNearly(nearer));
        expect(distance, atMostNearly(farther));
      }
      expect(route.positionAt(from, to, 0).distanceTo(from), nearlyEquals(0));
      expect(route.positionAt(from, to, 1).distanceTo(to), nearlyEquals(0));
    }
  });

  test('a route around the hole turns the short way around', () {
    const route = CameraRoute.aroundTheHole();
    final from = const DirectionAndDistance(
      azimuth: 3,
      elevation: 0,
      distance: 20,
    ).toVector3();
    final to = const DirectionAndDistance(
      azimuth: -3,
      elevation: 0,
      distance: 20,
    ).toVector3();
    final middle = DirectionAndDistance.of(route.positionAt(from, to, 0.5));
    expect(middle.azimuth.abs(), nearlyEquals(math.pi));
  });
}
