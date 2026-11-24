import 'package:material_ui/material_ui.dart';

import '../viewport/window_size.dart';
import 'colours.dart';

/// The font families that `pubspec.yaml` bundles.
abstract final class SiteFonts {
  /// For names, headings and labels.
  static const saira = 'Saira';

  /// For reading text.
  static const atkinson = 'Atkinson Hyperlegible Next';
}

/// The site's type styles for one set of window widths. Widgets read them
/// with `context.type`.
///
/// A [TextStyle] cannot change the case, so the text of [roleLabel] and
/// [listLabel] should be in uppercase already.
class SiteType extends ThemeExtension<SiteType> {
  const SiteType({
    required this.ownerName,
    required this.sectionHeading,
    required this.entryHeading,
    required this.firstLine,
    required this.welcome,
    required this.body,
    required this.entryDetails,
    required this.roleLabel,
    required this.listLabel,
  });

  SiteType._({required bool isCompact})
    : this(
        ownerName: _saira(
          size: isCompact ? 34 : 44,
          weight: 700,
          width: 115,
          letterSpacing: isCompact ? -0.17 : -0.22,
          colour: SiteColours.lampWhite,
        ),
        sectionHeading: _saira(
          size: isCompact ? 46 : 64,
          weight: 700,
          width: 118,
          letterSpacing: isCompact ? -0.46 : -0.64,
          colour: SiteColours.lampWhite,
        ),
        entryHeading: _saira(
          size: isCompact ? 25 : 30,
          weight: 650,
          width: 105,
          height: 1.2,
          colour: SiteColours.lampWhite,
        ),
        firstLine: _atkinson(
          size: isCompact ? 20 : 22,
          height: 1.5,
          colour: SiteColours.lampWhite,
        ),
        welcome: _atkinson(size: isCompact ? 17 : 19, height: 1.5),
        body: _atkinson(size: 18, height: 1.6),
        entryDetails: _atkinson(
          size: 15,
          height: 1.5,
          colour: SiteColours.dialGrey,
        ),
        roleLabel: _saira(
          size: 15,
          weight: 600,
          height: 1.2,
          letterSpacing: 1.05,
          colour: SiteColours.dialGrey,
        ),
        listLabel: _saira(
          size: 14,
          weight: 600,
          height: 1.2,
          letterSpacing: 0.56,
          colour: SiteColours.dialGrey,
        ),
      );

  static final _compact = SiteType._(isCompact: true);
  static final _standard = SiteType._(isCompact: false);

  static SiteType of(WidthClass widthClass) =>
      widthClass == WidthClass.compact ? _compact : _standard;

  /// The owner's name on the Landing.
  final TextStyle ownerName;

  /// The title of a section, such as About or Work.
  final TextStyle sectionHeading;

  /// The title of an entry, such as a project.
  final TextStyle entryHeading;

  /// The first line of a section, larger than the reading text.
  final TextStyle firstLine;

  /// The welcome sentence on the Landing.
  final TextStyle welcome;

  /// Reading text.
  final TextStyle body;

  /// Client, years and platforms under an entry heading.
  final TextStyle entryDetails;

  /// The owner's role on the Landing.
  final TextStyle roleLabel;

  /// The terms of a list, such as the contact list.
  final TextStyle listLabel;

  @override
  SiteType copyWith({
    TextStyle? ownerName,
    TextStyle? sectionHeading,
    TextStyle? entryHeading,
    TextStyle? firstLine,
    TextStyle? welcome,
    TextStyle? body,
    TextStyle? entryDetails,
    TextStyle? roleLabel,
    TextStyle? listLabel,
  }) => SiteType(
    ownerName: ownerName ?? this.ownerName,
    sectionHeading: sectionHeading ?? this.sectionHeading,
    entryHeading: entryHeading ?? this.entryHeading,
    firstLine: firstLine ?? this.firstLine,
    welcome: welcome ?? this.welcome,
    body: body ?? this.body,
    entryDetails: entryDetails ?? this.entryDetails,
    roleLabel: roleLabel ?? this.roleLabel,
    listLabel: listLabel ?? this.listLabel,
  );

  @override
  SiteType lerp(SiteType? other, double t) {
    if (other == null) return this;
    TextStyle mix(TextStyle a, TextStyle b) => TextStyle.lerp(a, b, t)!;
    return SiteType(
      ownerName: mix(ownerName, other.ownerName),
      sectionHeading: mix(sectionHeading, other.sectionHeading),
      entryHeading: mix(entryHeading, other.entryHeading),
      firstLine: mix(firstLine, other.firstLine),
      welcome: mix(welcome, other.welcome),
      body: mix(body, other.body),
      entryDetails: mix(entryDetails, other.entryDetails),
      roleLabel: mix(roleLabel, other.roleLabel),
      listLabel: mix(listLabel, other.listLabel),
    );
  }
}

extension SiteTypeOfContext on BuildContext {
  SiteType get type => Theme.of(this).extension<SiteType>()!;
}

TextStyle _saira({
  required double size,
  required int weight,
  required Color colour,
  double width = 100,
  double letterSpacing = 0,
  double height = 1,
}) => TextStyle(
  fontFamily: SiteFonts.saira,
  fontSize: size,
  fontWeight: FontWeight(weight),
  fontVariations: [FontVariation.width(width)],
  letterSpacing: letterSpacing,
  height: height,
  color: colour,
);

TextStyle _atkinson({
  required double size,
  required double height,
  Color colour = SiteColours.readingCream,
}) => TextStyle(
  fontFamily: SiteFonts.atkinson,
  fontSize: size,
  fontWeight: FontWeight.w400,
  height: height,
  color: colour,
);
