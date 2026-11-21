import 'package:flutter_test/flutter_test.dart';
import 'package:homepage_v2/content/content.dart';
import 'package:homepage_v2/content/site_content.dart';
import 'package:homepage_v2/scene/looks.dart';
import 'package:homepage_v2/space/camera.dart';
import 'package:homepage_v2/space/system.dart';

import '../matchers.dart';

void main() {
  const screen = Screen(width: 1600, height: 1000);

  test("on the Landing, the bodies lie on the line through the hole's "
      'place on the screen, from left to right in page order', () {
    final points = [
      for (final section in sections)
        if (bodies[section.id] case final body?)
          landingCamera.project(body.positionAt(0), screen)!,
    ];
    for (final point in points) {
      expect(point.y, nearlyEquals(landingCamera.targetPixel(screen).y));
    }
    final across = [for (final point in points) point.x];
    expect(across, orderedEquals([...across]..sort()));
  });

  /// How far each body is drawn from its centre, rings included.
  double reachOf(SectionId id) =>
      bodies[id]!.radius * siteLooks.bodies[id]!.reach;

  test('on the Landing, no body is lensed: the line of sight to each body '
      'stays outside the lensing radius', () {
    final camera = landingCamera.position;
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
