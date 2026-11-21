import 'package:web/web.dart' as web;

/// The browser's small and large viewport heights, in logical pixels: the
/// heights of two hidden elements, `100svh` and `100lvh` tall. A logical
/// pixel of Flutter on the web is a CSS pixel.
({double small, double large}) measureBrowserViewport() => (
  small: _small.getBoundingClientRect().height,
  large: _large.getBoundingClientRect().height,
);

final _small = _probe('100svh');
final _large = _probe('100lvh');

web.HTMLElement _probe(String height) {
  final probe = web.document.createElement('viewport-probe') as web.HTMLElement;
  probe.style
    ..position = 'fixed'
    ..top = '0'
    ..width = '0'
    ..height = height
    ..visibility = 'hidden';
  // Outside <body>, which Flutter owns.
  web.document.documentElement!.append(probe);
  return probe;
}
