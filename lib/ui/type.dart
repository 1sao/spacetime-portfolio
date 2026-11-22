import 'package:flutter_riverpod/flutter_riverpod.dart';
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

/// The site's type styles for one set of window widths.
///
/// A [TextStyle] cannot change the case, so the text of [roleLabel] and
/// [listLabel] should be in uppercase already.
class SiteType {
  SiteType._({required bool isCompact})
    : ownerName = _saira(
        size: isCompact ? 34 : 44,
        weight: 700,
        width: 115,
        tracking: -0.005,
        colour: SiteColours.lampWhite,
      ),
      sectionHeading = _saira(
        size: isCompact ? 46 : 64,
        weight: 700,
        width: 118,
        tracking: -0.01,
        colour: SiteColours.lampWhite,
      ),
      entryHeading = _saira(
        size: isCompact ? 25 : 30,
        weight: 650,
        width: 105,
        height: 1.2,
        colour: SiteColours.lampWhite,
      ),
      firstLine = _atkinson(
        size: isCompact ? 20 : 22,
        height: 1.5,
        colour: SiteColours.lampWhite,
      ),
      welcome = _atkinson(size: isCompact ? 17 : 19, height: 1.5);

  /// For windows in [WidthClass.compact].
  static final compact = SiteType._(isCompact: true);

  /// For wider windows.
  static final standard = SiteType._(isCompact: false);

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
  final TextStyle body = _atkinson(size: 18, height: 1.6);

  /// Client, years and platforms under an entry heading.
  final TextStyle entryDetails = _atkinson(
    size: 15,
    height: 1.5,
    colour: SiteColours.dialGrey,
  );

  /// The owner's role on the Landing.
  final TextStyle roleLabel = _saira(
    size: 15,
    weight: 600,
    height: 1.2,
    tracking: 0.07,
    colour: SiteColours.dialGrey,
  );

  /// The terms of a list, such as the contact list.
  final TextStyle listLabel = _saira(
    size: 14,
    weight: 600,
    height: 1.2,
    tracking: 0.04,
    colour: SiteColours.dialGrey,
  );
}

/// The type styles for the window's width.
final siteTypeProvider = Provider<SiteType>((ref) {
  final widthClass = ref.watch(
    windowSizeProvider.select((window) => window.widthClass),
  );
  return widthClass == WidthClass.compact
      ? SiteType.compact
      : SiteType.standard;
});

/// A Saira style. [width] is Saira's width axis, in percent of its normal
/// width. [tracking] is in ems, as `letter-spacing` in CSS. [height] is
/// the line height, as a multiple of [size].
TextStyle _saira({
  required double size,
  required int weight,
  required Color colour,
  double width = 100,
  double tracking = 0,
  double height = 1,
}) => TextStyle(
  fontFamily: SiteFonts.saira,
  fontSize: size,
  fontWeight: FontWeight(weight),
  fontVariations: [FontVariation.width(width)],
  letterSpacing: tracking * size,
  height: height,
  color: colour,
);

/// An Atkinson style. [height] is the line height, as a multiple of
/// [size].
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
