/// The site's spacing, in logical pixels.
abstract final class SiteSpacing {
  /// Rims, rules and ticks.
  static const hairline = 1.0;

  /// The gap between the ticks of a scale.
  static const tickGap = 6.0;

  /// The smaller gap inside instruments and labels.
  static const xs = 8.0;

  /// The larger gap inside instruments and labels.
  static const sm = 12.0;

  /// The space between the window's edge and the reading screen.
  static const gutter = 16.0;

  /// The space between paragraphs.
  static const paragraph = 16.0;

  /// The space between a heading and the text under it.
  static const headingGap = 28.0;

  /// The space between the lowest body and the row of body titles.
  static const titleRow = 44.0;

  /// How far a body title moves down when it would overlap another.
  static const titleTier = 48.0;

  /// The space between the entries of a section.
  static const entryGap = 56.0;

  /// The space between the reading screen's edge and its text.
  static const readerPad = 72.0;

  /// The space between sections.
  static const sectionGap = 88.0;

  /// How much of the reading screen shows below the Landing.
  static const peek = 116.0;
}
