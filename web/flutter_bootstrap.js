{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  config: {
    // Flutter downloads the fonts that it does not have from this path:
    // a font for a glyph that no bundled font has, and Roboto. The site
    // has no files there, so such a glyph shows as a box.
    fontFallbackBaseUrl: 'font-fallbacks/',
  },
});
