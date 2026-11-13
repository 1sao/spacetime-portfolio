import 'package:flutter_test/flutter_test.dart';
import 'package:homepage_v2/space/camera.dart';
import 'package:vector_math/vector_math_64.dart';

/// Matches a [Camera] at the position of [expected] that looks in the same
/// direction. The distance between the positions, and between the forward
/// directions of length 1, is [tolerance] or less.
Matcher isCameraCloseTo(Camera expected, {double tolerance = 1e-9}) =>
    _CameraCloseTo(expected, tolerance);

/// Matches a point from [Camera.project] that is inside [screen]: in front
/// of the camera, and within the width and height.
Matcher isOnScreen(Screen screen) => _OnScreen(screen);

class _CameraCloseTo extends Matcher {
  const _CameraCloseTo(this.expected, this.tolerance);

  final Camera expected;
  final double tolerance;

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) =>
      item is Camera &&
      item.position.distanceTo(expected.position) <= tolerance &&
      item.forward.distanceTo(expected.forward) <= tolerance;

  @override
  Description describe(Description description) => description.add(
    'a camera within $tolerance of ${expected.position}, looking along '
    '${expected.forward}',
  );

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) => item is Camera
      ? mismatchDescription.add(
          'is at ${item.position}, looking along ${item.forward}',
        )
      : mismatchDescription.add('is not a camera');
}

class _OnScreen extends Matcher {
  const _OnScreen(this.screen);

  final Screen screen;

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) =>
      item is Vector2 &&
      item.x >= 0 &&
      item.x <= screen.width &&
      item.y >= 0 &&
      item.y <= screen.height;

  @override
  Description describe(Description description) =>
      description.add('a point on a ${screen.width}x${screen.height} screen');

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) => item == null
      ? mismatchDescription.add('is behind the camera')
      : mismatchDescription.add('is $item');
}
