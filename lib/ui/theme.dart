import 'package:material_ui/material_ui.dart';

import '../viewport/window_size.dart';
import 'colors.dart';
import 'type.dart';

ThemeData siteTheme(WidthClass widthClass) => ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: SiteColors.deepSpace,
  textTheme: ThemeData(brightness: Brightness.dark).textTheme.apply(
    fontFamily: SiteFonts.atkinson,
    bodyColor: SiteColors.readingCream,
    displayColor: SiteColors.lampWhite,
  ),
  textSelectionTheme: TextSelectionThemeData(
    // Flutter paints the selection behind the text and cannot recolor the
    // selected text.
    selectionColor: SiteColors.signalAmber.withValues(alpha: 0.4),
  ),
  extensions: [SiteType.of(widthClass)],
);
