/// The sections of the page, in page order.
enum SectionId { about, work, personal, contact, credits }

/// What the reading screen and the Landing both show for a section of the
/// page.
class Section {
  const Section({required this.id, required this.title, this.descriptor});

  final SectionId id;
  final String title;

  /// The short line under the section's title on the Landing, if the
  /// section has a title there.
  final String? descriptor;
}

/// A work by another author that the site uses.
class Credit {
  const Credit({
    required this.workName,
    required this.author,
    required this.licenseName,
    required this.licenseFile,
  });

  final String workName;
  final String author;
  final String licenseName;
  final String licenseFile;
}
