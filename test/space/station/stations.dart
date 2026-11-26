import 'dart:math' as math;

import 'package:spacetime_portfolio/space/station/backdrop.dart';
import 'package:spacetime_portfolio/space/station/framing.dart';
import 'package:spacetime_portfolio/space/station/screen_point.dart';
import 'package:spacetime_portfolio/space/station/station.dart';
import 'package:spacetime_portfolio/space/system/body.dart';
import 'package:spacetime_portfolio/space/system/system.dart';
import 'package:vector_math/vector_math_64.dart';

final wideWindowBackdrop = Backdrop.hole(offsetFromBody: Vector2(-0.25, -0.09));

Station wideWindowBodyStation(Body body) => Station.body(
  body,
  Framing(
    screenPoint: ScreenPoint.fixed(Vector2(0.78, 0.5)),
    focalLength: 1400,
  ),
  backdrop: wideWindowBackdrop,
);

/// The site's stations, framed as on a wide window: the Landing, a body
/// station for each body with the hole at the panel's edge, then the hole.
List<Station> wideWindowStations() {
  final bodyStations = [
    for (final body in bodies.values) wideWindowBodyStation(body),
  ];
  return [
    Station.landing(
      Framing(
        screenPoint: ScreenPoint.fixed(Vector2(0.5, 0.32)),
        focalLength: 1400,
      ),
    ),
    ...bodyStations,
    Station.hole(
      Framing(
        screenPoint: ScreenPoint.fixed(Vector2(0.82, 0.5)),
        focalLength: 1400,
      ),
      sideOf: bodyStations.last,
    ),
  ];
}

/// The site's stations, framed as on a phone: each station shows its
/// subject in the gap above its section's top, of [sectionTops], and the
/// subject scrolls with the gap.
List<Station> phoneStations(
  List<double> sectionTops, {
  required double screenHeight,
}) {
  Framing framingAbove(double sectionTop) => Framing(
    screenPoint: ScreenPoint.onPage(
      x: 0.5,
      scrollOffsetAtTop: sectionTop - 0.15 * screenHeight,
      screenHeight: screenHeight,
    ),
    focalLength: 390,
  );
  final bodyStations = [
    for (final (index, body) in bodies.values.indexed)
      Station.body(
        body,
        framingAbove(sectionTops[index]),
        backdrop: Backdrop.hole(offsetFromBody: Vector2(0, -0.3)),
      ),
  ];
  return [
    Station.landing(
      Framing(
        screenPoint: ScreenPoint.fixed(Vector2(0.3, 0.36)),
        focalLength: 390,
        roll: math.pi / 2,
      ),
    ),
    ...bodyStations,
    Station.hole(
      framingAbove(sectionTops[bodyStations.length]),
      sideOf: bodyStations.last,
    ),
  ];
}
