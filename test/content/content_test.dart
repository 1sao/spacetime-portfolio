import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spacetime_portfolio/content/content.dart';
import 'package:spacetime_portfolio/content/site_content.dart';

void main() {
  test('the content has each section once, in the order of SectionId', () {
    expect([for (final section in sections) section.id], SectionId.values);
  });

  test('the credits name each license file in LICENSES/ once', () {
    final files = [
      for (final file in Directory('LICENSES').listSync())
        if (file.path.endsWith('.txt')) file.uri.pathSegments.last,
    ];
    expect([
      for (final credit in credits) credit.licenseFile,
    ], unorderedEquals(files));
  });
}
