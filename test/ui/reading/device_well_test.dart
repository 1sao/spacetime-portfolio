import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spacetime_portfolio/ui/reading/device_well.dart';
import 'package:spacetime_portfolio/ui/theme.dart';
import 'package:spacetime_portfolio/viewport/window_size.dart';

void main() {
  testWidgets('select all leaves out the text in a device well', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: siteTheme(WidthClass.compact),
        home: const SelectionArea(
          child: Column(
            children: [
              Text('Beside'),
              DeviceWell(caption: 'Inside'),
            ],
          ),
        ),
      ),
    );
    tester
        .state<SelectableRegionState>(find.byType(SelectableRegion))
        .selectAll();
    await tester.pump();
    bool isSelected(String text) => tester
        .renderObject<RenderParagraph>(
          find.descendant(of: find.text(text), matching: find.byType(RichText)),
        )
        .selections
        .isNotEmpty;
    expect(isSelected('Beside'), isTrue);
    expect(isSelected('Inside'), isFalse);
  });
}
