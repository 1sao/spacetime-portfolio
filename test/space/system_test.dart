import 'package:flutter_test/flutter_test.dart';
import 'package:homepage_v2/content/content.dart';
import 'package:homepage_v2/scene/looks.dart';
import 'package:homepage_v2/space/system.dart';

void main() {
  /// How far each body is drawn from its centre, rings included.
  double reachOf(SectionId id) =>
      bodies[id]!.radius * siteLooks.bodies[id]!.reach;

  test('on the Landing, no body is lensed: the line of sight to each body '
      'stays outside the lensing radius', () {
    final camera = lineUpViewpoint.toVector3();
    for (final MapEntry(key: id, value: body) in bodies.entries) {
      final toBody = body.positionAt(0) - camera;
      // The point of the line of sight nearest to the hole: the camera
      // moved along toBody by the share of it that points at the hole.
      final share = (-camera.dot(toBody) / toBody.length2).clamp(0.0, 1.0);
      final nearest = camera + toBody * share;
      expect(
        nearest.length - reachOf(id),
        greaterThan(holeLensingRadius),
        reason: id.name,
      );
    }
  });
}
