import 'package:flutter_test/flutter_test.dart';
import 'package:homepage_v2/content/content.dart';
import 'package:homepage_v2/content/site_content.dart';

void main() {
  test('the content has each section once, in the order of SectionId', () {
    expect([for (final section in sections) section.id], SectionId.values);
  });
}
