import 'package:material_ui/material_ui.dart';

import '../viewport/window_size.dart';
import 'colours.dart';
import 'type.dart';

ThemeData siteTheme(WidthClass widthClass) => ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: SiteColours.deepSpace,
  textTheme: ThemeData(brightness: Brightness.dark).textTheme.apply(
    fontFamily: SiteFonts.atkinson,
    bodyColor: SiteColours.readingCream,
    displayColor: SiteColours.lampWhite,
  ),
  textSelectionTheme: TextSelectionThemeData(
    // Flutter paints the selection behind the text and cannot recolour the
    // selected text.
    selectionColor: SiteColours.signalAmber.withValues(alpha: 0.4),
  ),
  extensions: [SiteType.of(widthClass)],
);
