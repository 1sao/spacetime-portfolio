import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homepage_v2/providers.dart';
import 'package:homepage_v2/ui/list_page.dart';
import 'package:material_ui/material_ui.dart';

import '../fake_content.dart';

void main() {
  testWidgets('category names and message titles are headings', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [contentProvider.overrideWithValue(fakeContent)],
        child: const MaterialApp(home: ListPage()),
      ),
    );

    // The label check catches a heading merged with the text below it.
    (String, int) headingOf(String text) {
      final data = tester.getSemantics(find.text(text)).getSemanticsData();
      return (data.label, data.headingLevel);
    }

    for (final category in fakeContent) {
      expect(headingOf(category.name), (category.name, 2));
      for (final message in category.messages) {
        expect(headingOf(message.title), (message.title, 3));
      }
    }
  });
}
