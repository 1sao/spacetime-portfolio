import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spacetime_portfolio/app.dart';

void main() {
  testWidgets("the app starts dark, on the page's background", (tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));

    final scaffold = find.byType(Scaffold);
    expect(Theme.of(tester.element(scaffold)).brightness, Brightness.dark);

    final surface = tester.widget<Material>(
      find.descendant(of: scaffold, matching: find.byType(Material)).first,
    );
    expect(surface.color, App.backgroundColor);
  });

  testWidgets('the app gives the browser its title and background color', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: App()));

    final title = tester.widget<Title>(find.byType(Title));
    expect(title.title, App.title);
    expect(title.color, App.backgroundColor);
  });
}
