import 'package:homepage_v2/content/content.dart';

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
