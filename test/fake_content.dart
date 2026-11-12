import 'package:homepage_v2/content/content.dart';
import 'package:homepage_v2/navigation/map_location.dart';
import 'package:homepage_v2/space/body.dart';
import 'package:homepage_v2/space/orbit.dart';

/// Content for tests, so they don't change when the site's copy does.
const fakeContent = [
  Category(
    slug: 'projects',
    name: 'Projects',
    messages: [
      Message(slug: 'one', title: 'One', text: 'The first project.'),
      Message(slug: 'two', title: 'Two', text: 'The second project.'),
    ],
  ),
  Category(
    slug: 'contact',
    name: 'Contact',
    messages: [Message(slug: 'mail', title: 'Mail', text: 'Write to me.')],
  ),
];

/// A body for each of [fakeContent]'s categories.
const fakeBodies = {
  'projects': Body(
    orbit: CircularOrbit(radius: 6, tilt: 0, node: 0),
    phase: 0,
    radius: 0.5,
  ),
  'contact': Body(
    orbit: CircularOrbit(radius: 10, tilt: 0, node: 0),
    phase: 0,
    radius: 0.5,
  ),
};

/// Every location of [fakeContent].
final fakeLocations = <MapLocation>[
  const OverviewLocation(),
  for (final category in fakeContent) ...[
    CategoryLocation(category),
    for (final message in category.messages) MessageLocation(category, message),
  ],
];
