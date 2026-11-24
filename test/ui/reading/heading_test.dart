import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spacetime_portfolio/ui/reading/heading.dart';

void main() {
  testWidgets('a heading tells screen readers its level', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Heading('Title', level: 2),
      ),
    );
    expect(
      tester.getSemantics(find.text('Title')).getSemanticsData().headingLevel,
      2,
    );
    semantics.dispose();
  });
}
