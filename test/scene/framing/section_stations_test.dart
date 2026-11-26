import 'package:flutter_test/flutter_test.dart';
import 'package:spacetime_portfolio/content/site_content.dart';
import 'package:spacetime_portfolio/scene/framing/focal_lengths.dart';
import 'package:spacetime_portfolio/scene/framing/landing_station.dart';
import 'package:spacetime_portfolio/scene/framing/reading_screen_geometry.dart';
import 'package:spacetime_portfolio/scene/framing/section_framing.dart';
import 'package:spacetime_portfolio/scene/framing/section_stations.dart';
import 'package:spacetime_portfolio/space/camera/camera.dart';
import 'package:spacetime_portfolio/space/station/station.dart';
import 'package:spacetime_portfolio/space/system/system.dart';

import '../../matchers.dart';
import 'screens.dart';

void main() {
  final sectionBodies = [for (final section in sections) bodies[section.id]];

  /// Sections a screen tall, with a third of a screen between them.
  ReadingScreenGeometry pageOn(Screen screen) {
    final height = screen.height;
    return ReadingScreenGeometry(
      sections: [
        for (var section = 0; section < sections.length; section++)
          (
            top: height * (1 + 4 / 3 * section),
            bottom: height * (2 + 4 / 3 * section),
          ),
      ],
      maxScroll: height * (1 + 4 / 3 * sections.length),
    );
  }

  List<Station> stationsOn(Screen screen, ReadingScreenGeometry page) {
    final focalLengths = FocalLengths.of(screen);
    return sectionStationsFor(
      sectionBodies,
      page,
      framing: SectionFraming.of(screen, focalLength: focalLengths.sections),
      landing: Station.landing(
        landingFraming(
          screen,
          focalLength: focalLengths.landing,
          bodies: const [],
          floor: double.infinity,
        ),
      ),
    );
  }

  test("at every window size, no section's station reaches the elevation "
      'clamp, at any orbit time', () {
    for (final screen in [...screens, const Screen(width: 390, height: 932)]) {
      final stations = stationsOn(screen, pageOn(screen));
      for (var orbitTime = 0.0; orbitTime < 30; orbitTime += 0.25) {
        for (final station in stations) {
          expect(
            station.cameraAt(orbitTime).fromTarget.elevation.abs(),
            lessThan(maxElevation),
            reason: '${screen.name} at $orbitTime',
          );
        }
      }
    }
  });

  test("between the cards, a body's station shows its body in the middle "
      'of the gap above its card, as the page scrolls, and keeps it on the '
      'screen', () {
    const screen = Screen(width: 390, height: 844);
    final page = pageOn(screen);
    final stations = stationsOn(screen, page);
    for (final (section, body) in sectionBodies.indexed) {
      if (body == null) continue;
      final gapMiddle = page.gapMiddleAbove(section);
      for (final below in [-0.5, 0.1, 0.5, 0.9, 1.5]) {
        final scrollOffset = gapMiddle - below * screen.height;
        final camera = stations[section].cameraAt(
          2,
          scrollOffset: scrollOffset,
        );
        expect(
          camera.project(body.positionAt(2), screen)!.y,
          nearlyEquals((gapMiddle - scrollOffset).clamp(0.0, screen.height)),
          reason: 'section $section, $below down the screen',
        );
      }
    }
  });
}
