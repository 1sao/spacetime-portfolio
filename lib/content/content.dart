/// One item in a [Section], such as a project in Work.
class Entry {
  const Entry({required this.title, required this.text});

  final String title;
  final String text;
}

/// The sections of the page, in page order. The name is the section's URL
/// fragment: `/#work`.
enum SectionId { about, work, personal, contact, credits }

/// A section of the page, such as About or Work.
class Section {
  const Section({
    required this.id,
    required this.title,
    this.descriptor,
    required this.entries,
  });

  final SectionId id;
  final String title;

  /// The short line under the section's title on the Landing, if the
  /// section has a title there.
  final String? descriptor;
  final List<Entry> entries;
}
