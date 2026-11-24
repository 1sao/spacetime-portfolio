import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../viewport/window_size.dart';
import 'colors.dart';
import 'theme.dart';
import 'type.dart';

/// A part of the reading screen on enamel, as on a phone and on a wide
/// window.
final class ReadingPreview extends MultiPreview {
  const ReadingPreview(this.group);

  final String group;

  @override
  List<Preview> get previews => [
    Preview(
      group: group,
      name: 'Compact',
      size: const Size.fromWidth(346),
      wrapper: onPhone,
    ),
    Preview(
      group: group,
      name: 'Expanded',
      size: const Size.fromWidth(640),
      wrapper: onWideWindow,
    ),
  ];
}

/// A part of the page on the page's background, in a phone and in a wide
/// window.
final class PagePreview extends MultiPreview {
  const PagePreview(this.group);

  final String group;

  @override
  List<Preview> get previews => [
    Preview(
      group: group,
      name: 'Compact',
      size: const Size(390, 844),
      wrapper: phonePage,
    ),
    Preview(
      group: group,
      name: 'Expanded',
      size: const Size(1280, 800),
      wrapper: wideWindowPage,
    ),
  ];
}

const _phone = WindowSize(width: 390, smallHeight: 844, largeHeight: 844);
const _wideWindow = WindowSize(width: 1280, smallHeight: 800, largeHeight: 800);

Widget onPhone(Widget child) => _onEnamel(_phone, child);

Widget onWideWindow(Widget child) => _onEnamel(_wideWindow, child);

Widget phonePage(Widget child) => _page(_phone, child);

Widget wideWindowPage(Widget child) => _page(_wideWindow, child);

Widget _onEnamel(WindowSize window, Widget child) => _site(
  window,
  ColoredBox(
    color: SiteColors.enamel,
    child: Padding(padding: const EdgeInsets.all(24), child: child),
  ),
);

Widget _page(WindowSize window, Widget child) => _site(
  window,
  ColoredBox(
    color: SiteColors.deepSpace,
    child: SingleChildScrollView(child: child),
  ),
);

// The previewer bundles the site's fonts under the package's name, so the
// families that the styles name are not there until this loads them.
final Future<void> _siteFonts = Future.wait([
  for (final (family, file) in [
    (SiteFonts.saira, 'Saira.ttf'),
    (SiteFonts.atkinson, 'AtkinsonHyperlegibleNext.ttf'),
    ('Roboto', 'AtkinsonHyperlegibleNext.ttf'),
  ])
    (FontLoader(
          family,
        )..addFont(rootBundle.load('packages/spacetime_portfolio/fonts/$file')))
        .load(),
]);

Widget _site(WindowSize window, Widget child) {
  unawaited(_siteFonts);
  return ProviderScope(
    overrides: [windowSizeProvider.overrideWithBuild((_, _) => window)],
    child: Theme(data: siteTheme(window.widthClass), child: child),
  );
}
