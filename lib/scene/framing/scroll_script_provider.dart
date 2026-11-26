import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../space/scroll/camera_route.dart';
import '../../space/scroll/hold_offsets.dart';
import '../../space/scroll/scroll_script.dart';
import '../../viewport/window_size.dart';
import 'landing_station.dart';
import 'reading_screen_geometry.dart';
import 'section_framing.dart';
import 'section_stations.dart';

/// Holds at the Landing until the reading screen measures its sections.
final scrollScriptProvider = Provider<ScrollScript>((ref) {
  final landing = ref.watch(landingStationProvider);
  final page = ref.watch(measuredReadingScreenGeometryProvider);
  if (page == null) return ScrollScript.holding(landing);
  final viewHeight = ref.watch(
    windowSizeProvider.select((window) => window.smallHeight),
  );
  return ScrollScript(
    stations: [landing, ...ref.watch(sectionStationsProvider)!],
    holdOffsets: holdOffsetsFor(
      sectionTops: page.sectionTops,
      viewHeight: viewHeight,
      maxScroll: page.maxScroll,
      lines: ref.watch(sectionFramingProvider).holdLines,
    ),
    route: const CameraRoute.aroundTheHole(),
    viewHeight: viewHeight,
  );
});
