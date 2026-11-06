import 'package:flutter_test/flutter_test.dart';
import 'package:homepage_v2/content/content.dart';
import 'package:homepage_v2/content/site_content.dart';

void main() {
  final slugPattern = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$');

  test('category slugs are URL-safe, unique and not reserved', () {
    final slugs = [for (final category in categories) category.slug];

    expect(slugs, everyElement(matches(slugPattern)));
    expect(duplicates(slugs), isEmpty, reason: 'duplicate slugs');
    expect(slugs.where(reservedSlugs.contains), isEmpty, reason: 'reserved');
  });

  test('message slugs are URL-safe and unique within their category', () {
    for (final category in categories) {
      final slugs = [for (final message in category.messages) message.slug];

      expect(slugs, everyElement(matches(slugPattern)), reason: category.slug);
      expect(duplicates(slugs), isEmpty, reason: category.slug);
    }
  });
}

/// The values that appear more than once in [values].
List<String> duplicates(List<String> values) {
  final seen = <String>{};
  return [
    for (final value in values)
      if (!seen.add(value)) value,
  ];
}
