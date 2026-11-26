import 'package:riverpod/misc.dart' show Override;
import 'package:spacetime_portfolio/content/content.dart';
import 'package:spacetime_portfolio/providers.dart';
import 'package:spacetime_portfolio/space/rgb.dart';
import 'package:spacetime_portfolio/space/system/body.dart';
import 'package:spacetime_portfolio/space/system/body_look.dart';
import 'package:spacetime_portfolio/space/system/orbit.dart';
import 'package:vector_math/vector_math_64.dart';

/// Fixed bodies, so that the tests do not change when the site's bodies do.
final fakeBodies = {
  SectionId.about: Body(
    orbit: Orbit(start: Vector3(6, 0, 0), tilt: 0),
    radius: 0.5,
    spinRate: 1,
    obliquity: 0.2,
    look: FlatLook(Rgb.gray(1)),
    cameraDistanceInRadii: 10,
  ),
};

final fakeOverrides = <Override>[bodiesProvider.overrideWithValue(fakeBodies)];
