import 'package:material_ui/material_ui.dart';

/// The site's colours.
abstract final class SiteColours {
  /// The page and the scene's background.
  static const deepSpace = Color(0xFF05060A);

  /// Panels to read on: the reading screen, phone cards, the time readout.
  static const enamel = Color(0xFF1B1916);

  /// Recessed areas in [enamel] that hold the device mocks.
  static const enamelWell = Color(0xFF141210);

  /// The 1 px inner rim of every [enamel] surface.
  static const enamelRim = Color(0xFF2D2922);

  /// The rule between sections on the reading screen.
  static const ruleLine = Color(0xFF3D372E);

  /// Unlit ticks of a scale. Too dark for text.
  static const scaleTick = Color(0xFF4A4236);

  /// Names, headings, the first line of each section and hovered titles.
  static const lampWhite = Color(0xFFF4EAD4);

  /// Body text.
  static const readingCream = Color(0xFFE3D8C0);

  /// Secondary text on [enamel] and hovered descriptors.
  static const softCream = Color(0xFFCFC4AB);

  /// Labels, meta lines and title descriptors.
  static const dialGrey = Color(0xFFA99D84);

  /// The drag hint and the captions with device mocks: the lowest text
  /// tone.
  static const fadedPrint = Color(0xFF8D836D);

  /// Everything that points at the sky, links or measures: titles,
  /// leaders, links, the focus ring and the moving pointers on scales.
  static const signalAmber = Color(0xFFF2A54C);
}
