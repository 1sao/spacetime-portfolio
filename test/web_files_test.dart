import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:homepage_v2/app.dart';
import 'package:html/parser.dart' as html;

void main() {
  final page = html.parse(File('web/index.html').readAsStringSync());
  final manifest = jsonDecode(
    File('web/manifest.json').readAsStringSync(),
  ) as Map<String, Object?>;

  /// The `content` of every `<meta>` whose [attribute] is [value], such as
  /// `name="description"`. A list, so a duplicate tag fails the comparison.
  List<String?> metaContents(String attribute, String value) => [
    for (final tag in page.querySelectorAll('meta[$attribute="$value"]'))
      tag.attributes['content'],
  ];

  final titles = [for (final tag in page.querySelectorAll('title')) tag.text];
  final descriptions = metaContents('name', 'description');

  test('there is one title and one description', () {
    expect(titles, [isNotEmpty]);
    expect(descriptions, [isNotEmpty]);
  });

  test(
    'link-preview tags and the manifest repeat the title and description',
    () {
      expect(
        {
          'og:title': metaContents('property', 'og:title'),
          'og:description': metaContents('property', 'og:description'),
          'og:type': metaContents('property', 'og:type'),
          'twitter:card': metaContents('name', 'twitter:card'),
          'manifest name': [manifest['name']],
          'manifest description': [manifest['description']],
          'manifest short_name': [manifest['short_name']],
        },
        {
          'og:title': titles,
          'og:description': descriptions,
          'og:type': ['website'],
          'twitter:card': ['summary'],
          'manifest name': titles,
          'manifest description': descriptions,
          'manifest short_name': metaContents(
            'name',
            'apple-mobile-web-app-title',
          ),
        },
      );
    },
  );

  test('the app keeps the page title once it starts', () {
    expect([App.title], titles);
  });

  test('the page, the manifest and the app share one background colour', () {
    final styles = page.querySelectorAll('style').map((style) => style.text);
    final cssBackground = RegExp(r'background:\s*(#\w+)');
    final colours = {
      'theme-color meta': metaContents('name', 'theme-color'),
      'page background': [
        for (final css in styles)
          for (final match in cssBackground.allMatches(css)) match[1],
      ],
      'manifest background_color': [manifest['background_color']],
      'manifest theme_color': [manifest['theme_color']],
    };
    final hexRgb = (App.background.toARGB32() & 0xFFFFFF).toRadixString(16);
    final background = '#${hexRgb.padLeft(6, '0')}';
    expect(
      {
        for (final MapEntry(key: where, value: hexes) in colours.entries)
          where: [for (final hex in hexes) '$hex'.toLowerCase()],
      },
      {
        for (final where in colours.keys) where: [background],
      },
    );
  });
}
