import 'package:vector_math/vector_math_64.dart';

import '../camera/camera.dart';
import '../camera/direction_and_distance.dart';
import 'screen_point.dart';

/// The parts of a camera that the view sets.
class Framing {
  Framing({
    required this.screenPoint,
    required this.focalLength,
    this.roll = 0,
  });

  final ScreenPoint screenPoint;
  final double focalLength;
  final double roll;

  Camera cameraAt(
    Vector3 target,
    DirectionAndDistance fromTarget, {
    double scrollOffset = 0,
  }) => Camera(
    target: target,
    fromTarget: fromTarget,
    focalLength: focalLength,
    screenPoint: screenPoint.at(scrollOffset),
    roll: roll,
  );
}
