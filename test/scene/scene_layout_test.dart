import 'package:flutter_test/flutter_test.dart';
import 'package:homepage_v2/content/content.dart';
import 'package:homepage_v2/content/site_content.dart';
import 'package:homepage_v2/scene/looks.dart';
import 'package:homepage_v2/scene/scene_layout.dart';
import 'package:homepage_v2/space/camera.dart';
import 'package:homepage_v2/space/system.dart';
import 'package:homepage_v2/ui/spacing.dart';
import 'package:vector_math/vector_math_64.dart';

import '../matchers.dart';

void main() {
  /// Desktop, short, wide, both sides of the column's breakpoint, and a
  /// phone upright and on its side. None has an address bar.
  const screens = [
    Screen(width: 1600, height: 1000),
    Screen(width: 1280, height: 720),
    Screen(width: 2560, height: 900),
    Screen(width: 600, height: 800),
    Screen(width: 599, height: 800),
    Screen(width: 390, height: 844),
    Screen(width: 844, height: 390),
  ];

  /// The bodies in page order.
  final pageOrder = [
    for (final section in sections)
      if (bodies[section.id] case final body?) (section.id, body),
  ];

  String nameOf(Screen screen) => '${screen.width}x${screen.height}';

  test('on the Landing, the bodies lie on one line through the hole, in '
      'page order: left to right, or top to bottom on the column', () {
    for (final screen in screens) {
      final layout = SceneLayout(screen);
      final camera = layout.landingCamera;
      final hole = camera.targetPixel(screen);
      final along = layout.isColumn ? Vector2(0, 1) : Vector2(1, 0);
      final places = <double>[];
      for (final (_, body) in pageOrder) {
        final offset = camera.project(body.positionAt(0), screen)! - hole;
        expect(offset.cross(along), nearlyEquals(0), reason: nameOf(screen));
        places.add(offset.dot(along));
      }
      expect(
        places,
        orderedEquals([...places]..sort()),
        reason: nameOf(screen),
      );
    }
  });

  test("on the Landing, the hole's shadow and every body are whole on the "
      'screen and above the top of the reading screen', () {
    /// How far each body is drawn from its centre, rings included.
    double reachOf(SectionId id) =>
        bodies[id]!.radius * siteLooks.bodies[id]!.reach;

    for (final screen in screens) {
      final camera = SceneLayout(screen).landingCamera;
      final discs = [
        (Vector3.zero(), holeShadowRadius),
        for (final (id, body) in pageOrder) (body.positionAt(0), reachOf(id)),
      ];
      for (final (centre, reach) in discs) {
        final pixel = camera.project(centre, screen)!;
        final depth = (centre - camera.position).dot(camera.forward);
        final radius = reach * camera.focalLength / depth;
        final reason = nameOf(screen);
        expect(pixel.x - radius, greaterThan(0), reason: reason);
        expect(pixel.x + radius, lessThan(screen.width), reason: reason);
        expect(pixel.y - radius, greaterThan(0), reason: reason);
        expect(
          pixel.y + radius,
          lessThan(screen.height - SiteSpacing.peek),
          reason: reason,
        );
      }
    }
  });
}
