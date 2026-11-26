import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import '../../space/station/station.dart';
import '../../space/system/body.dart';
import 'landing_station.dart';
import 'reading_screen_geometry.dart';
import 'section_framing.dart';

/// Null until the reading screen measures its sections.
final sectionStationsProvider = Provider<List<Station>?>((ref) {
  final page = ref.watch(measuredReadingScreenGeometryProvider);
  if (page == null) return null;
  final sections = ref.watch(sectionsProvider);
  assert(
    page.sections.length == sections.length,
    'The page measured ${page.sections.length} sections, not '
    '${sections.length}.',
  );
  final bodies = ref.watch(bodiesProvider);
  return sectionStationsFor(
    [for (final section in sections) bodies[section.id]],
    page,
    framing: ref.watch(sectionFramingProvider),
    landing: ref.watch(landingStationProvider),
  );
});

/// A station for each section, after [landing]. [sectionBodies] has each
/// section's body, or null for the hole.
List<Station> sectionStationsFor(
  List<Body?> sectionBodies,
  ReadingScreenGeometry page, {
  required SectionFraming framing,
  required Station landing,
}) {
  final stations = <Station>[];
  for (final (section, body) in sectionBodies.indexed) {
    stations.add(switch (body) {
      null => Station.hole(
        framing.holeFraming(section, page),
        sideOf: stations.lastOrNull ?? landing,
      ),
      final body => Station.body(
        body,
        framing.bodyFraming(section, page),
        backdrop: framing.backdrop,
      ),
    });
  }
  return stations;
}
