import 'package:homepage_v2/content/content.dart';
import 'package:homepage_v2/providers.dart';
import 'package:homepage_v2/space/body.dart';
import 'package:homepage_v2/space/orbit.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:vector_math/vector_math_64.dart';

/// Content for tests, so they don't change when the site's copy does.
const fakeContent = [
  Section(
    id: SectionId.work,
    title: 'Work',
    descriptor: 'Projects',
    entries: [
      Entry(title: 'One', text: 'The first project.'),
      Entry(title: 'Two', text: 'The second project.'),
    ],
  ),
  Section(
    id: SectionId.credits,
    title: 'Credits',
    entries: [Entry(title: 'Thanks', text: 'To the authors.')],
  ),
];

/// A body for [fakeContent]'s first section. The second has none.
final fakeBodies = {
  SectionId.work: Body(
    orbit: Orbit(start: Vector3(6, 0, 0), tilt: 0),
    radius: 0.5,
    spinRate: 1,
    obliquity: 0.2,
  ),
};

/// The overrides that put [fakeContent] and [fakeBodies] in place of the
/// site's own.
final fakeOverrides = <Override>[
  contentProvider.overrideWithValue(fakeContent),
  bodiesProvider.overrideWithValue(fakeBodies),
];
