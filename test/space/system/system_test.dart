import 'package:flutter_test/flutter_test.dart';
import 'package:spacetime_portfolio/space/system/system.dart';

void main() {
  test('on the Landing, no body is lensed: the line of sight to each body '
      'stays outside the lensing radius', () {
    final camera = lineUpViewpoint.toVector3();
    for (final MapEntry(key: id, value: body) in bodies.entries) {
      final toBody = body.positionAt(0) - camera;
      // The point of the line of sight nearest to the hole: the camera
      // moved along toBody by the fraction of it that points at the hole.
      final fraction = (-camera.dot(toBody) / toBody.length2).clamp(0.0, 1.0);
      final nearest = camera + toBody * fraction;
      expect(
        nearest.length - body.reach,
        greaterThan(holeLensingRadius),
        reason: id.name,
      );
    }
  });
}
