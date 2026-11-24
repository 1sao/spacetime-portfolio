import 'package:flutter_test/flutter_test.dart';

import '../pump_app.dart';

void main() {
  testWidgets('the counter shows the frames per second of the scene', (
    tester,
  ) async {
    await pumpApp(tester, isSceneRunning: true);
    expect(find.text('– fps'), findsOneWidget);

    // 0.5 s of frames 8 ms apart: 125 a second.
    for (var i = 0; i < 64; i++) {
      await tester.pump(const Duration(milliseconds: 8));
    }
    expect(find.text('125 fps'), findsOneWidget);
  });
}
