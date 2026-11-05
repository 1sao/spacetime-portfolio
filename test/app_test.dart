import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homepage_v2/app.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('the app starts dark, on a black background', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));

    final scaffold = find.byType(Scaffold);
    expect(Theme.of(tester.element(scaffold)).brightness, Brightness.dark);

    final surface = tester.widget<Material>(
      find.descendant(of: scaffold, matching: find.byType(Material)).first,
    );
    expect(surface.color, App.background);
  });
}
