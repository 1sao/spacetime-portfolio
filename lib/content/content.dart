/// One entry in a [Category], such as one project.
class Message {
  const Message({required this.slug, required this.title, required this.text});

  /// The second URL segment: `/<category>/<message>`.
  final String slug;
  final String title;
  final String text;
}

/// A section of the site, such as projects or contact.
class Category {
  const Category({
    required this.slug,
    required this.name,
    required this.messages,
  });

  /// The first URL segment: `/<category>`.
  final String slug;
  final String name;
  final List<Message> messages;
}

/// Slugs a category can't take: `/list` is the list view, and `flutter run`
/// handles paths under `/assets`, `/canvaskit` and `/packages` itself
/// instead of loading the app.
const Set<String> reservedSlugs = {'list', 'assets', 'canvaskit', 'packages'};
