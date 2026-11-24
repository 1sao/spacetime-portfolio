import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spacetime_portfolio/ui/type.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the app bundles the fonts that the type styles name', () async {
    expect(
      await _bundledFamilies(),
      containsAll([SiteFonts.saira, SiteFonts.atkinson]),
    );
  });

  // Without it, Flutter web downloads Roboto, its default family, at
  // start-up.
  test('the app bundles a family named Roboto', () async {
    expect(await _bundledFamilies(), contains('Roboto'));
  });
}

Future<Set<String>> _bundledFamilies() async {
  final manifest = jsonDecode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<Object?>;
  return {for (final family in manifest) (family! as Map)['family'] as String};
}
